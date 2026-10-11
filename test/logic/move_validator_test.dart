import 'package:flutter_test/flutter_test.dart';
import 'package:arrow_flow/models/arrow.dart';
import 'package:arrow_flow/models/board.dart';
import 'package:arrow_flow/models/direction.dart';
import 'package:arrow_flow/logic/move_validator.dart';

void main() {
  group('MoveValidator Tests', () {
    test('Arrow pointing directly at board edge can exit', () {
      final board = Board.empty(4);
      // Arrow at (0, 1) pointing UP (immediately exits off row 0)
      final arrowUp = Arrow.create(row: 0, col: 1, direction: Direction.up);
      // Arrow at (3, 2) pointing DOWN (immediately exits off row 3)
      final arrowDown = Arrow.create(row: 3, col: 2, direction: Direction.down);
      // Arrow at (2, 0) pointing LEFT (immediately exits off col 0)
      final arrowLeft = Arrow.create(row: 2, col: 0, direction: Direction.left);
      // Arrow at (1, 3) pointing RIGHT (immediately exits off col 3)
      final arrowRight = Arrow.create(row: 1, col: 3, direction: Direction.right);

      final populatedBoard = board
          .withArrow(arrowUp)
          .withArrow(arrowDown)
          .withArrow(arrowLeft)
          .withArrow(arrowRight);

      expect(MoveValidator.canExit(populatedBoard, arrowUp), isTrue);
      expect(MoveValidator.canExit(populatedBoard, arrowDown), isTrue);
      expect(MoveValidator.canExit(populatedBoard, arrowLeft), isTrue);
      expect(MoveValidator.canExit(populatedBoard, arrowRight), isTrue);
    });

    test('Arrow blocked by another arrow cannot exit and identifies blocker', () {
      final board = Board.empty(4);
      final arrowA = Arrow.create(row: 2, col: 0, direction: Direction.right);
      final arrowB = Arrow.create(row: 2, col: 2, direction: Direction.up);

      final populatedBoard = board.withArrow(arrowA).withArrow(arrowB);

      // arrowA points right: (2, 1) is empty, but (2, 2) has arrowB!
      expect(MoveValidator.canExit(populatedBoard, arrowA), isFalse);
      final blocker = MoveValidator.findBlockingArrow(populatedBoard, arrowA);
      expect(blocker, isNotNull);
      expect(blocker!.id, equals(arrowB.id));

      // arrowB points up: (1, 2) and (0, 2) are empty. It can exit!
      expect(MoveValidator.canExit(populatedBoard, arrowB), isTrue);
      expect(MoveValidator.findBlockingArrow(populatedBoard, arrowB), isNull);
    });

    test('validateMove computes full exit path', () {
      final board = Board.empty(4);
      final arrow = Arrow.create(row: 0, col: 1, direction: Direction.down);
      final populatedBoard = board.withArrow(arrow);

      final res = MoveValidator.validateMove(populatedBoard, arrow);
      expect(res.canExit, isTrue);
      // Traversed cells: (1, 1), (2, 1), (3, 1)
      expect(res.exitPath.length, equals(3));
      expect(res.exitPath[0], equals((1, 1)));
      expect(res.exitPath[1], equals((2, 1)));
      expect(res.exitPath[2], equals((3, 1)));
    });

    test('findExitClearArrows returns only free arrows', () {
      final board = Board.empty(4);
      final arrow1 = Arrow.create(row: 1, col: 1, direction: Direction.left); // exits via col 0
      final arrow2 = Arrow.create(row: 1, col: 2, direction: Direction.left); // blocked by arrow1

      final populatedBoard = board.withArrow(arrow1).withArrow(arrow2);

      final clear = MoveValidator.findExitClearArrows(populatedBoard);
      expect(clear.length, equals(1));
      expect(clear.first.id, equals(arrow1.id));
    });
  });
}
