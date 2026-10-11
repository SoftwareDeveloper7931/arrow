import 'package:flutter_test/flutter_test.dart';
import 'package:arrow_flow/models/arrow.dart';
import 'package:arrow_flow/models/board.dart';
import 'package:arrow_flow/models/direction.dart';
import 'package:arrow_flow/logic/move_validator.dart';

void main() {
  group('MoveValidator Tests (Snake Paths)', () {
    test('Snake arrow pointing directly towards edge can escape', () {
      // 8x8 board
      // Arrow from (4, 4) to (4, 6) pointing right
      final arrowA = Arrow(
        id: 'a',
        cells: const [Cell(4, 4), Cell(4, 5), Cell(4, 6)],
        headDirection: Direction.right,
      );

      final board = Board.fromArrows(rows: 8, cols: 8, arrows: [arrowA]);

      expect(MoveValidator.canEscape(board, arrowA), isTrue);
      expect(MoveValidator.findBlockingArrow(board, arrowA), isNull);
    });

    test('Snake arrow blocked by another snake arrow is correctly detected', () {
      // 8x8 board
      // Arrow A from (4, 2) to (4, 4) pointing right
      final arrowA = Arrow(
        id: 'a',
        cells: const [Cell(4, 2), Cell(4, 3), Cell(4, 4)],
        headDirection: Direction.right,
      );

      // Arrow B from (2, 6) to (5, 6) pointing down (lies in (4, 6) which is along A's ray!)
      final arrowB = Arrow(
        id: 'b',
        cells: const [Cell(2, 6), Cell(3, 6), Cell(4, 6), Cell(5, 6)],
        headDirection: Direction.down,
      );

      final board = Board.fromArrows(rows: 8, cols: 8, arrows: [arrowA, arrowB]);

      // Arrow A points right: at (4, 6) it hits Arrow B!
      expect(MoveValidator.canEscape(board, arrowA), isFalse);
      final blocker = MoveValidator.findBlockingArrow(board, arrowA);
      expect(blocker, isNotNull);
      expect(blocker!.id, equals('b'));

      // Arrow B points down: head is at (5, 6), row 6 and 7 are empty. Arrow B can escape!
      expect(MoveValidator.canEscape(board, arrowB), isTrue);
    });
  });
}
