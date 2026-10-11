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

    // Post-processing: try to merge any tiny 1-cell paths into neighboring path endpoints
    final mergedPaths = <List<Cell>>[];
    final smallPaths = <List<Cell>>[];

    for (final p in paths) {
      if (p.length < 2) {
        smallPaths.add(p);
      } else {
        mergedPaths.add(p);
      }
    }

    for (final small in smallPaths) {
      final cell = small.first;
      bool merged = false;

      // Try to attach to an endpoint of an existing path
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
        // If cannot merge to an endpoint, keep as is
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
