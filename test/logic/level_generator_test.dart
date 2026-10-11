import 'package:flutter_test/flutter_test.dart';
import 'package:arrow_flow/logic/level_generator.dart';
import 'package:arrow_flow/logic/solver.dart';

void main() {
  group('LevelGenerator Silhouette Tests', () {
    test('Level 1 is a Trophy silhouette and is 100% solvable', () {
      final level1 = LevelGenerator.generateLevel(1);
      expect(level1.shapeName, equals('Trophy'));
      expect(level1.initialArrows, isNotEmpty);

      final board = level1.createInitialBoard();
      final result = Solver.solve(board);
      expect(result.isSolvable, isTrue);
      expect(result.solutionSteps.length, equals(level1.initialArrows.length));
    });

    test('Generates deterministic levels for the same seed/level number', () {
      final lA = LevelGenerator.generateLevel(2);
      final lB = LevelGenerator.generateLevel(2);
      expect(lA.shapeName, equals(lB.shapeName));
      expect(lA.initialArrows.length, equals(lB.initialArrows.length));
      for (int i = 0; i < lA.initialArrows.length; i++) {
        expect(lA.initialArrows[i].id, equals(lB.initialArrows[i].id));
        expect(lA.initialArrows[i].head, equals(lB.initialArrows[i].head));
        expect(lA.initialArrows[i].headDirection,
            equals(lB.initialArrows[i].headDirection));
      }
    });

    test('Sampled progression levels (1 through 30) are all strictly solvable', () {
      for (int lvl = 1; lvl <= 30; lvl++) {
        final level = LevelGenerator.generateLevel(lvl);
        expect(level.initialArrows, isNotEmpty,
            reason: 'Level $lvl must generate arrows');
        final board = level.createInitialBoard();
        final result = Solver.solve(board);
        expect(result.isSolvable, isTrue,
            reason: 'Level $lvl (${level.shapeName}) must be 100% solvable');
      }
    });
  });
}
