import 'package:flutter_test/flutter_test.dart';
import 'package:arrow_flow/models/arrow.dart';
import 'package:arrow_flow/models/board.dart';
import 'package:arrow_flow/models/direction.dart';
import 'package:arrow_flow/logic/solver.dart';

void main() {
  group('Solver Tests', () {
    test('Solves a simple sequential 3-arrow chain', () {
      // Arrow 3 at (0, 2) pointing UP (can exit immediately)
      // Arrow 2 at (1, 2) pointing UP (blocked by Arrow 3)
      // Arrow 1 at (1, 1) pointing RIGHT (blocked by Arrow 2)
      final a3 = Arrow.create(row: 0, col: 2, direction: Direction.up, id: 'a3');
      final a2 = Arrow.create(row: 1, col: 2, direction: Direction.up, id: 'a2');
      final a1 = Arrow.create(row: 1, col: 1, direction: Direction.right, id: 'a1');

      final board = Board.fromArrows(4, [a1, a2, a3]);

      final result = Solver.solve(board);
      expect(result.isSolvable, isTrue);
      expect(result.solutionSteps.length, equals(3));
      // First step must be a3
      expect(result.solutionSteps[0].id, equals('a3'));
      // Second step must be a2
      expect(result.solutionSteps[1].id, equals('a2'));
      // Third step must be a1
      expect(result.solutionSteps[2].id, equals('a1'));
    });

    test('Correctly identifies an unsolvable deadlocked board', () {
      // 4 arrows in a cycle blocking each other
      // (1,1) -> (1,2)
      //  ^         |
      //  |         v
      // (2,1) <- (2,2)
      final top = Arrow.create(row: 1, col: 1, direction: Direction.right, id: 'top');
      final right = Arrow.create(row: 1, col: 2, direction: Direction.down, id: 'right');
      final bottom = Arrow.create(row: 2, col: 2, direction: Direction.left, id: 'bottom');
      final left = Arrow.create(row: 2, col: 1, direction: Direction.up, id: 'left');

      final board = Board.fromArrows(4, [top, right, bottom, left]);

      expect(Solver.isSolvable(board), isFalse);
      final result = Solver.solve(board);
      expect(result.isSolvable, isFalse);
      expect(result.solutionSteps, isEmpty);
    });

    test('getNextHint provides an immediately playable arrow', () {
      final a1 = Arrow.create(row: 0, col: 0, direction: Direction.up, id: 'a1');
      final a2 = Arrow.create(row: 1, col: 0, direction: Direction.up, id: 'a2');

      final board = Board.fromArrows(4, [a1, a2]);

      final hint = Solver.getNextHint(board);
      expect(hint, isNotNull);
      expect(hint!.id, equals('a1'));
    });
  });
}
