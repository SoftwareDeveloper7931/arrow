import 'dart:math' as math;

import '../models/arrow.dart';
import '../models/board.dart';
import '../models/direction.dart';
import '../models/level.dart';
import '../models/shape_mask.dart';
import 'game_constants.dart';
import 'path_partitioner.dart';
import 'shape_library.dart';
import 'solver.dart';

/// Generates deterministic silhouette-based puzzle levels.
class LevelGenerator {
  LevelGenerator._();

  /// Computes grid dimensions for [levelNumber].
  /// Scales smoothly from 12x12 up to 36x36.
  static (int rows, int cols) getGridDimensions(int levelNumber) {
    if (levelNumber <= 5) return (12, 12);
    if (levelNumber <= 20) return (14, 14);
    if (levelNumber <= 50) return (16, 16);
    if (levelNumber <= 100) return (20, 20);
    if (levelNumber <= 180) return (24, 24);
    if (levelNumber <= 250) return (28, 28);
    return (32, 32);
  }

  /// Min and max snake path lengths for [levelNumber].
  static (int minLen, int maxLen) getSnakeLengthRange(int levelNumber) {
    if (levelNumber <= 5) return (2, 4);
    if (levelNumber <= 25) return (2, 5);
    if (levelNumber <= 80) return (3, 7);
    if (levelNumber <= 160) return (4, 9);
    return (4, 12);
  }

  /// Generates a complete, verified solvable [Level].
  static Level generateLevel(int levelNumber) {
    assert(levelNumber >= 1, 'Level number must be >= 1');

    final baseShape = ShapeLibrary.getShapeForLevel(levelNumber);
    final (targetRows, targetCols) = getGridDimensions(levelNumber);
    final (minLen, maxLen) = getSnakeLengthRange(levelNumber);

    // Resample shape mask to target dimensions
    final mask = baseShape.resample(targetCols, targetRows);

    // Try multiple deterministic seed derivations with intelligent cycle-breaking
    for (int attempt = 0; attempt < 80; attempt++) {
      final seed = levelNumber * 73856093 ^ attempt * 19349663;
      final random = math.Random(seed);

      // Adaptively adjust maxLen slightly on higher attempts to increase freedom
      final effectiveMaxLen = attempt > 40 ? math.max(minLen, maxLen - 1) : maxLen;

      final rawPaths = PathPartitioner.partition(
        mask: mask,
        random: random,
        minLen: minLen,
        maxLen: effectiveMaxLen,
      );

      if (rawPaths.isEmpty) continue;

      // Assign heads and directions to paths
      var arrows = _assignHeadsAndDirections(
        rawPaths,
        targetRows,
        targetCols,
        random,
        strictOutward: attempt == 0,
      );

      var board = Board.fromArrows(
        rows: targetRows,
        cols: targetCols,
        arrows: arrows,
      );

      // 1. Initial solvability check
      var result = Solver.solve(board);
      if (result.isSolvable && result.solutionSteps.length == arrows.length) {
        return _buildLevel(levelNumber, baseShape.name, targetRows, targetCols, arrows, mask);
      }

      // 2. Local cycle repair: flip stuck arrows to break deadlocks
      final solvedIds = result.solutionSteps.map((s) => s.id).toSet();
      final stuckArrows = arrows.where((a) => !solvedIds.contains(a.id)).toList();

      bool repaired = false;
      for (final stuck in stuckArrows) {
        if (stuck.length < 2) continue;
        final flipped = _flipArrow(stuck);
        final candidateArrows = arrows.map((a) => a.id == stuck.id ? flipped : a).toList();
        final candidateBoard = Board.fromArrows(
          rows: targetRows,
          cols: targetCols,
          arrows: candidateArrows,
        );
        final check = Solver.solve(candidateBoard);
        if (check.isSolvable && check.solutionSteps.length == candidateArrows.length) {
          arrows = candidateArrows;
          repaired = true;
          break;
        }
      }

      if (repaired) {
        return _buildLevel(levelNumber, baseShape.name, targetRows, targetCols, arrows, mask);
      }

      // 3. Try double flip if stuck arrows count is small
      if (stuckArrows.length >= 2 && stuckArrows.length <= 6) {
        for (int i = 0; i < stuckArrows.length; i++) {
          if (repaired) break;
          for (int j = i + 1; j < stuckArrows.length; j++) {
            final a1 = stuckArrows[i];
            final a2 = stuckArrows[j];
            if (a1.length < 2 || a2.length < 2) continue;

            final f1 = _flipArrow(a1);
            final f2 = _flipArrow(a2);
            final candidateArrows = arrows.map((a) {
              if (a.id == a1.id) return f1;
              if (a.id == a2.id) return f2;
              return a;
            }).toList();

            final candidateBoard = Board.fromArrows(
              rows: targetRows,
              cols: targetCols,
              arrows: candidateArrows,
            );
            final check = Solver.solve(candidateBoard);
            if (check.isSolvable && check.solutionSteps.length == candidateArrows.length) {
              arrows = candidateArrows;
              repaired = true;
              break;
            }
          }
        }
        if (repaired) {
          return _buildLevel(levelNumber, baseShape.name, targetRows, targetCols, arrows, mask);
        }
      }
    }

    // Fallback: Partition with length 2 paths and strict outward orientation
    final fallbackLevel = _generateGuaranteedOutwardLevel(
      levelNumber: levelNumber,
      baseShape: baseShape,
      targetRows: targetRows,
      targetCols: targetCols,
      mask: mask,
    );

    return fallbackLevel;
  }

  static Arrow _flipArrow(Arrow arrow) {
    assert(arrow.length >= 2);
    final reversedCells = arrow.cells.reversed.toList();
    final newHeadDir = _getContinuationDirection(
      reversedCells[reversedCells.length - 2],
      reversedCells.last,
    );
    return Arrow(
      id: arrow.id,
      cells: reversedCells,
      headDirection: newHeadDir,
      colorVariant: arrow.colorVariant,
    );
  }

  static Level _buildLevel(
    int levelNumber,
    String shapeName,
    int rows,
    int cols,
    List<Arrow> arrows,
    ShapeMask mask,
  ) {
    final level = Level(
      number: levelNumber,
      shapeName: shapeName,
      rows: rows,
      cols: cols,
      initialArrows: arrows,
      mask: mask,
    );

    assert(() {
      final testBoard = level.createInitialBoard();
      return Solver.isSolvable(testBoard);
    }(), 'Level $levelNumber must be verified solvable');

    return level;
  }

  /// Assigns head end and direction for each path with outward bias.
  static List<Arrow> _assignHeadsAndDirections(
    List<List<Cell>> paths,
    int rows,
    int cols,
    math.Random random, {
    bool strictOutward = false,
  }) {
    final arrows = <Arrow>[];

    for (int i = 0; i < paths.length; i++) {
      final path = paths[i];
      final color = i % GameConstants.totalColorVariants;

      if (path.length == 1) {
        final c = path.first;
        final dir = _directionTowardsNearestBorder(c, rows, cols);
        arrows.add(Arrow(
          id: 'arr_$i',
          cells: [c],
          headDirection: dir,
          colorVariant: color,
        ));
        continue;
      }

      final dirA = _getContinuationDirection(
        path[path.length - 2],
        path.last,
      );

      final dirB = _getContinuationDirection(
        path[1],
        path.first,
      );

      final distA = _distanceToBorder(path.last, dirA, rows, cols);
      final distB = _distanceToBorder(path.first, dirB, rows, cols);

      bool useEndA;
      if (strictOutward) {
        useEndA = distA <= distB;
      } else if (distA < distB) {
        useEndA = random.nextDouble() < 0.85;
      } else if (distB < distA) {
        useEndA = random.nextDouble() < 0.15;
      } else {
        useEndA = random.nextBool();
      }

      if (useEndA) {
        arrows.add(Arrow(
          id: 'arr_$i',
          cells: List.of(path),
          headDirection: dirA,
          colorVariant: color,
        ));
      } else {
        arrows.add(Arrow(
          id: 'arr_$i',
          cells: path.reversed.toList(),
          headDirection: dirB,
          colorVariant: color,
        ));
      }
    }

    return arrows;
  }

  static Direction _getContinuationDirection(Cell prev, Cell current) {
    final dr = current.row - prev.row;
    final dc = current.col - prev.col;
    if (dr < 0) return Direction.up;
    if (dr > 0) return Direction.down;
    if (dc < 0) return Direction.left;
    return Direction.right;
  }

  static Direction _directionTowardsNearestBorder(
      Cell cell, int rows, int cols) {
    final distUp = cell.row;
    final distDown = rows - 1 - cell.row;
    final distLeft = cell.col;
    final distRight = cols - 1 - cell.col;

    final minDist =
        math.min(math.min(distUp, distDown), math.min(distLeft, distRight));
    if (minDist == distUp) return Direction.up;
    if (minDist == distDown) return Direction.down;
    if (minDist == distLeft) return Direction.left;
    return Direction.right;
  }

  static int _distanceToBorder(Cell cell, Direction dir, int rows, int cols) {
    switch (dir) {
      case Direction.up:
        return cell.row;
      case Direction.down:
        return rows - 1 - cell.row;
      case Direction.left:
        return cell.col;
      case Direction.right:
        return cols - 1 - cell.col;
    }
  }

  static Level _generateGuaranteedOutwardLevel({
    required int levelNumber,
    required ShapeMask baseShape,
    required int targetRows,
    required int targetCols,
    required ShapeMask mask,
  }) {
    // Try deterministic seeds with length 2 paths until solvable
    for (int seedOffset = 0; seedOffset < 100; seedOffset++) {
      final random = math.Random(levelNumber * 10007 + seedOffset * 31);
      final rawPaths = PathPartitioner.partition(
        mask: mask,
        random: random,
        minLen: 2,
        maxLen: 3,
      );

      var arrows = _assignHeadsAndDirections(
        rawPaths,
        targetRows,
        targetCols,
        random,
      );

      var board = Board.fromArrows(
        rows: targetRows,
        cols: targetCols,
        arrows: arrows,
      );

      var result = Solver.solve(board);
      if (result.isSolvable && result.solutionSteps.length == arrows.length) {
        return _buildLevel(levelNumber, baseShape.name, targetRows, targetCols, arrows, mask);
      }

      // Quick flip repair
      final solvedIds = result.solutionSteps.map((s) => s.id).toSet();
      final stuck = arrows.where((a) => !solvedIds.contains(a.id)).toList();
      for (final s in stuck) {
        if (s.length < 2) continue;
        final f = _flipArrow(s);
        final cand = arrows.map((a) => a.id == s.id ? f : a).toList();
        final candB = Board.fromArrows(
          rows: targetRows,
          cols: targetCols,
          arrows: cand,
        );
        final chk = Solver.solve(candB);
        if (chk.isSolvable && chk.solutionSteps.length == cand.length) {
          return _buildLevel(levelNumber, baseShape.name, targetRows, targetCols, cand, mask);
        }
      }
    }

    // Absolute fallback: length 1 cells pointing directly to nearest border
    final arrows = <Arrow>[];
    int idCounter = 0;
    for (int r = 0; r < targetRows; r++) {
      for (int c = 0; c < targetCols; c++) {
        if (mask.isSet(c, r)) {
          arrows.add(Arrow(
            id: 'arr_${idCounter++}',
            cells: [Cell(r, c)],
            headDirection: _directionTowardsNearestBorder(Cell(r, c), targetRows, targetCols),
            colorVariant: idCounter % GameConstants.totalColorVariants,
          ));
        }
      }
    }

    return Level(
      number: levelNumber,
      shapeName: baseShape.name,
      rows: targetRows,
      cols: targetCols,
      initialArrows: arrows,
      mask: mask,
    );
  }
}
