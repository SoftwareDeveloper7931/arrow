import 'package:flutter_test/flutter_test.dart';
import 'package:arrow_flow/models/arrow.dart';
import 'package:arrow_flow/models/board.dart';
import 'package:arrow_flow/models/direction.dart';
import 'package:arrow_flow/logic/solver.dart';

void main() {
  group('Solver Tests (Snake Paths)', () {
    test('Solves a 2-arrow dependency chain', () {
      // Arrow 1 at (4, 4) pointing right, blocked by Arrow 2 at (4, 6)
      // Arrow 2 points UP towards row 0 (free path)
      final a1 = Arrow(
        id: 'a1',
        cells: const [Cell(4, 3), Cell(4, 4)],
        headDirection: Direction.right,
      );

      final a2 = Arrow(
        id: 'a2',
        cells: const [Cell(5, 6), Cell(4, 6)],
        headDirection: Direction.up,
      );

      final board = Board.fromArrows(rows: 8, cols: 8, arrows: [a1, a2]);

      final result = Solver.solve(board);
      expect(result.isSolvable, isTrue);
      expect(result.solutionSteps.length, equals(2));
      expect(result.solutionSteps[0].id, equals('a2'));
      expect(result.solutionSteps[1].id, equals('a1'));
    });

    test('Identifies cyclic deadlock', () {
      // a1 blocks a2, a2 blocks a1
      final a1 = Arrow(
        id: 'a1',
        cells: const [Cell(2, 2)],
        headDirection: Direction.right, // points towards col 4
      );
      final a2 = Arrow(
        id: 'a2',
        cells: const [Cell(2, 4)],
        headDirection: Direction.left, // points towards col 2
      );

      final board = Board.fromArrows(rows: 8, cols: 8, arrows: [a1, a2]);
      expect(Solver.isSolvable(board), isFalse);
    });
  });
}
