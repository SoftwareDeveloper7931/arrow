import 'dart:math' as math;
import '../models/arrow.dart';
import '../models/shape_mask.dart';

/// Partitions all active cells of a [ShapeMask] into a set of contiguous snake paths
/// with 90-degree turns and zero overlapping or missing cells.
class PathPartitioner {
  PathPartitioner._();

  /// Partitions [mask] into non-overlapping snake paths using a seeded random walk.
  ///
  /// [minLen] and [maxLen] control snake lengths (scaling with difficulty).
  static List<List<Cell>> partition({
    required ShapeMask mask,
    required math.Random random,
    required int minLen,
    required int maxLen,
  }) {
    final unvisited = <Cell>{};
    for (int y = 0; y < mask.height; y++) {
      for (int x = 0; x < mask.width; x++) {
        if (mask.isSet(x, y)) {
          unvisited.add(Cell(y, x));
        }
      }
    }

    if (unvisited.isEmpty) return const [];

    final paths = <List<Cell>>[];

    while (unvisited.isNotEmpty) {
      // Pick start cell: prefer cells with lowest unvisited degree (Warnsdorff's heuristic)
      // to avoid stranding isolated cells.
      Cell start = unvisited.first;
      int minDegree = 999;
      final candidates = unvisited.toList()..shuffle(random);

      for (final cell in candidates.take(12)) {
        final deg = _countUnvisitedNeighbors(cell, unvisited);
        if (deg < minDegree) {
          minDegree = deg;
          start = cell;
        }
      }

      unvisited.remove(start);
      final currentPath = <Cell>[start];
      final targetLength = minLen + random.nextInt(maxLen - minLen + 1);

      while (currentPath.length < targetLength) {
        final neighbors = _getUnvisitedNeighbors(currentPath.last, unvisited);
        if (neighbors.isEmpty) {
          // Can we extend from the beginning of the path?
          final frontNeighbors =
              _getUnvisitedNeighbors(currentPath.first, unvisited);
          if (frontNeighbors.isNotEmpty) {
            frontNeighbors.shuffle(random);
            final front = frontNeighbors.first;
            unvisited.remove(front);
            currentPath.insert(0, front);
            continue;
          }
          break;
        }

        // Pick neighbor with fewest unvisited neighbors
        neighbors.sort((a, b) => _countUnvisitedNeighbors(a, unvisited)
            .compareTo(_countUnvisitedNeighbors(b, unvisited)));

        final next = neighbors.first;
        unvisited.remove(next);
        currentPath.add(next);
      }

      paths.add(currentPath);
    }

    // Post-processing: eliminate any 1-cell paths
    final mergedPaths = <List<Cell>>[];
    final smallPaths = <List<Cell>>[];

    for (final p in paths) {
      if (p.length < 2) {
        smallPaths.add(p);
      } else {
        mergedPaths.add(p);
      }
    }

    final unmerged = <List<Cell>>[];

    for (final small in smallPaths) {
      final cell = small.first;
      bool merged = false;

      // 1. Try to attach to an endpoint of an existing path
      for (final p in mergedPaths) {
        if (_areAdjacent(cell, p.first)) {
          p.insert(0, cell);
          merged = true;
          break;
        } else if (_areAdjacent(cell, p.last)) {
          p.add(cell);
          merged = true;
          break;
        }
      }

      if (!merged) {
        unmerged.add(small);
      }
    }

    // 2. Try to pair adjacent 1-cell paths together into a 2-cell path
    final remainingUnmerged = <List<Cell>>[];
    final pairedIndices = <int>{};

    for (int i = 0; i < unmerged.length; i++) {
      if (pairedIndices.contains(i)) continue;
      bool paired = false;
      for (int j = i + 1; j < unmerged.length; j++) {
        if (pairedIndices.contains(j)) continue;
        if (_areAdjacent(unmerged[i].first, unmerged[j].first)) {
          mergedPaths.add([unmerged[i].first, unmerged[j].first]);
          pairedIndices.add(i);
          pairedIndices.add(j);
          paired = true;
          break;
        }
      }
      if (!paired) {
        remainingUnmerged.add(unmerged[i]);
      }
    }

    // 3. Try to split a longer path (length >= 4) that is adjacent to the small cell
    for (final small in remainingUnmerged) {
      final cell = small.first;
      bool merged = false;

      for (int pIdx = 0; pIdx < mergedPaths.length; pIdx++) {
        final p = mergedPaths[pIdx];
        if (p.length >= 4) {
          for (int i = 1; i < p.length - 1; i++) {
            if (_areAdjacent(cell, p[i])) {
              // Split p at index i: [p[0]..p[i], cell] and [p[i+1]..p[last]]
              final p1 = [...p.sublist(0, i + 1), cell];
              final p2 = p.sublist(i + 1);
              if (p1.length >= 2 && p2.length >= 2) {
                mergedPaths[pIdx] = p1;
                mergedPaths.add(p2);
                merged = true;
                break;
              }
            }
          }
          if (merged) break;
        }
      }

      if (!merged) {
        mergedPaths.add(small);
      }
    }

    return mergedPaths;
  }

  static bool _areAdjacent(Cell a, Cell b) {
    return (a.row - b.row).abs() + (a.col - b.col).abs() == 1;
  }

  static int _countUnvisitedNeighbors(Cell cell, Set<Cell> unvisited) {
    return _getUnvisitedNeighbors(cell, unvisited).length;
  }

  static List<Cell> _getUnvisitedNeighbors(Cell cell, Set<Cell> unvisited) {
    final list = <Cell>[];
    for (final offset in const [(-1, 0), (1, 0), (0, -1), (0, 1)]) {
      final test = Cell(cell.row + offset.$1, cell.col + offset.$2);
      if (unvisited.contains(test)) {
        list.add(test);
      }
    }
    return list;
  }
}
