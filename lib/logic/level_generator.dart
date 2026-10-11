import 'dart:math' as math;

import '../models/arrow.dart';
import '../models/board.dart';
import '../models/direction.dart';
import '../models/level.dart';
import 'game_constants.dart';
import 'move_validator.dart';
import 'solver.dart';

/// Generates deterministic, guaranteed-solvable puzzle levels using reverse placement.
class LevelGenerator {
  LevelGenerator._();

  /// Computes the board grid size for a given [levelNumber].
  /// Scales smoothly from 4x4 up to 10x10.
  static int getGridSizeForLevel(int levelNumber) {
    if (levelNumber <= 10) return 4;
    if (levelNumber <= 30) return 5;
    if (levelNumber <= 65) return 6;
    if (levelNumber <= 115) return 7;
    if (levelNumber <= 180) return 8;
    if (levelNumber <= 250) return 9;
    return 10;
  }

  /// Computes the target number of arrows for [levelNumber] on grid of [size].
  static int getTargetArrowCount(int levelNumber, int size) {
    final totalCells = size * size;

    // Density scales with progression from ~30% up to ~65% of grid cells.
    double density;
    if (levelNumber <= 3) {
      density = 0.28; // Tutorial ease
    } else if (levelNumber <= 15) {
      density = 0.35;
    } else if (levelNumber <= 50) {
      density = 0.42;
    } else if (levelNumber <= 120) {
      density = 0.50;
    } else if (levelNumber <= 220) {
      density = 0.58;
    } else {
      density = 0.65;
    }

    final count = (totalCells * density).round();
    // Ensure at least 3 arrows and never exceed totalCells - 1 (leave room).
    return count.clamp(3, totalCells - 1);
  }

  /// Generates a [Level] for [levelNumber].
  /// Deterministic via `Random(levelNumber)`.
  static Level generateLevel(int levelNumber) {
    assert(levelNumber >= 1, 'Level number must be >= 1');

    final size = getGridSizeForLevel(levelNumber);
    final targetCount = getTargetArrowCount(levelNumber, size);
    final random = math.Random(levelNumber * 31337);

    // Dependency bias increases with level: higher chance of placing an arrow
    // that directly blocks an already-placed arrow to create deep puzzle chains.
    final dependencyBias = (0.35 + (levelNumber / GameConstants.minLevelCount) * 0.55)
        .clamp(0.35, 0.90);

    var board = Board.empty(size);
    final placedInReverse = <Arrow>[];

    // Candidate search
    for (int step = 0; step < targetCount; step++) {
      final validPlacements = <({int row, int col, Direction dir, int blocksExistingCount})>[];

      // Find all empty cells and directions where an arrow would have an unobstructed path out
      // given the arrows placed so far.
      for (int r = 0; r < size; r++) {
        for (int c = 0; c < size; c++) {
          if (!board.isCellEmpty(r, c)) continue;

          for (final dir in Direction.values) {
            final testArrow = Arrow(
              id: 'test',
              row: r,
              col: c,
              direction: dir,
            );

            // Must have clear path to edge right now
            if (MoveValidator.canExit(board, testArrow)) {
              // Count how many already-placed arrows would be blocked by placing this arrow
              int blocksExisting = 0;
              for (final existing in placedInReverse) {
                // Check if (r, c) lies along existing's ray
                int er = existing.row + existing.direction.dRow;
                int ec = existing.col + existing.direction.dCol;
                while (board.isInside(er, ec)) {
                  if (er == r && ec == c) {
                    blocksExisting++;
                    break;
                  }
                  er += existing.direction.dRow;
                  ec += existing.direction.dCol;
                }
              }

              validPlacements.add((
                row: r,
                col: c,
                dir: dir,
                blocksExistingCount: blocksExisting,
              ));
            }
          }
        }
      }

      if (validPlacements.isEmpty) {
        // No more valid placements can be made without breaking clear exits.
        break;
      }

      // Filter or sort candidates by dependency bias
      validPlacements.shuffle(random);

      ({int row, int col, Direction dir, int blocksExistingCount}) chosen;
      if (random.nextDouble() < dependencyBias) {
        // Prefer placing an arrow that blocks at least 1 existing arrow
        final blockingCandidates =
            validPlacements.where((p) => p.blocksExistingCount > 0).toList();
        if (blockingCandidates.isNotEmpty) {
          chosen = blockingCandidates[random.nextInt(blockingCandidates.length)];
        } else {
          chosen = validPlacements[random.nextInt(validPlacements.length)];
        }
      } else {
        chosen = validPlacements[random.nextInt(validPlacements.length)];
      }

      final colorVariant = (step + random.nextInt(3)) % GameConstants.totalColorVariants;
      final newArrow = Arrow(
        id: 'arrow_${chosen.row}_${chosen.col}',
        row: chosen.row,
        col: chosen.col,
        direction: chosen.dir,
        colorVariant: colorVariant,
      );

      board = board.withArrow(newArrow);
      placedInReverse.add(newArrow);
    }

    // Guaranteed solution order is the reverse of placement:
    // The last arrow placed has no blockers from any earlier arrow, so it can exit first!
    final guaranteedSolutionOrder =
        placedInReverse.reversed.map((a) => a.id).toList();

    final level = Level(
      number: levelNumber,
      size: size,
      initialArrows: List.unmodifiable(placedInReverse),
      guaranteedSolutionOrder: List.unmodifiable(guaranteedSolutionOrder),
    );

    // In-code assertion and debug verification of solvability
    assert(() {
      final initialBoard = level.createInitialBoard();
      final isSolvable = Solver.isSolvable(initialBoard);
      if (!isSolvable) {
        throw StateError('Generated level $levelNumber is NOT solvable!');
      }
      return true;
    }(), 'Level $levelNumber must be solvable');

    return level;
  }
}
