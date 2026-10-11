import '../models/arrow.dart';
import '../models/board.dart';

/// Validation result detailing whether a snake-arrow can escape or why it cannot.
class MoveValidationResult {
  final bool canEscape;
  final Arrow? blockingArrow;

  const MoveValidationResult({
    required this.canEscape,
    this.blockingArrow,
  });
}

/// Evaluates whether an arrow has an unobstructed straight ray from its head to the board edge.
class MoveValidator {
  MoveValidator._();

  /// Determines if [arrow] can escape off the board.
  ///
  /// The straight ray from its head cell, in the head direction, to the board edge
  /// must cross no cell occupied by any other remaining arrow.
  static bool canEscape(Board board, Arrow arrow) {
    int r = arrow.head.row + arrow.headDirection.dRow;
    int c = arrow.head.col + arrow.headDirection.dCol;

    while (board.isInside(r, c)) {
      final obstacle = board.arrowAt(r, c);
      if (obstacle != null && obstacle.id != arrow.id) {
        return false;
      }
      r += arrow.headDirection.dRow;
      c += arrow.headDirection.dCol;
    }
    return true;
  }

  /// Locates the first blocking [Arrow] in [arrow]'s exit ray, or `null` if free.
  static Arrow? findBlockingArrow(Board board, Arrow arrow) {
    int r = arrow.head.row + arrow.headDirection.dRow;
    int c = arrow.head.col + arrow.headDirection.dCol;

    while (board.isInside(r, c)) {
      final obstacle = board.arrowAt(r, c);
      if (obstacle != null && obstacle.id != arrow.id) {
        return obstacle;
      }
      r += arrow.headDirection.dRow;
      c += arrow.headDirection.dCol;
    }
    return null;
  }

  /// Performs full move validation.
  static MoveValidationResult validateMove(Board board, Arrow arrow) {
    final blocker = findBlockingArrow(board, arrow);
    return MoveValidationResult(
      canEscape: blocker == null,
      blockingArrow: blocker,
    );
  }

  /// Finds all arrows on the current [board] that can escape immediately.
  static List<Arrow> findEscapableArrows(Board board) {
    final escapable = <Arrow>[];
    for (final arrow in board.arrows) {
      if (canEscape(board, arrow)) {
        escapable.add(arrow);
      }
    }
    return escapable;
  }
}
