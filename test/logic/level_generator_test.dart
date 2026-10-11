import 'package:flutter_test/flutter_test.dart';
import 'package:arrow_flow/logic/level_generator.dart';
import 'package:arrow_flow/logic/solver.dart';

void main() {
  group('LevelGenerator Tests', () {
    test('Scales grid size correctly with level progression', () {
      expect(LevelGenerator.getGridSizeForLevel(1), equals(4));
      expect(LevelGenerator.getGridSizeForLevel(10), equals(4));
      expect(LevelGenerator.getGridSizeForLevel(11), equals(5));
      expect(LevelGenerator.getGridSizeForLevel(30), equals(5));
      expect(LevelGenerator.getGridSizeForLevel(31), equals(6));
      expect(LevelGenerator.getGridSizeForLevel(70), equals(7));
      expect(LevelGenerator.getGridSizeForLevel(130), equals(8));
      expect(LevelGenerator.getGridSizeForLevel(190), equals(9));
      expect(LevelGenerator.getGridSizeForLevel(300), equals(10));
    });

    test('Generates deterministic levels for the same seed/level number', () {
      final levelA = LevelGenerator.generateLevel(42);
      final levelB = LevelGenerator.generateLevel(42);

      expect(levelA.size, equals(levelB.size));
      expect(levelA.initialArrows.length, equals(levelB.initialArrows.length));
      for (int i = 0; i < levelA.initialArrows.length; i++) {
        expect(levelA.initialArrows[i].id, equals(levelB.initialArrows[i].id));
        expect(levelA.initialArrows[i].row, equals(levelB.initialArrows[i].row));
        expect(levelA.initialArrows[i].col, equals(levelB.initialArrows[i].col));
        expect(levelA.initialArrows[i].direction,
            equals(levelB.initialArrows[i].direction));
      }
    });

    test('Levels 1 to 300 are all strictly 100% solvable', () {
      // Test all 300 levels as required by specifications!
      for (int lvl = 1; lvl <= 300; lvl++) {
        final level = LevelGenerator.generateLevel(lvl);
        expect(level.initialArrows, isNotEmpty,
            reason: 'Level $lvl must have arrows');
        final board = level.createInitialBoard();
        final result = Solver.solve(board);
        expect(result.isSolvable, isTrue,
            reason: 'Level $lvl must be completely solvable');
        expect(result.solutionSteps.length, equals(level.initialArrows.length),
            reason: 'All arrows in Level $lvl must be clearable');
      }
    });
  });
}
