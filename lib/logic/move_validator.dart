import '../models/arrow.dart';
import '../models/board.dart';

/// Validation result providing details on whether an arrow can exit or why it cannot.
class MoveValidationResult {
  final bool canExit;
  final Arrow? blockingArrow;
  final List<(int row, int col)> exitPath;

  const MoveValidationResult({
    required this.canExit,
    this.blockingArrow,
    this.exitPath = const [],
  });
}

/// Evaluates arrow movements, raycasts paths to the edge, and detects blockers.
class MoveValidator {
  MoveValidator._();

  /// Determines if [arrow] can slide off [board] without obstruction.
  /// An arrow can exit if every cell in its pointing direction up to the boundary is empty.
  static bool canExit(Board board, Arrow arrow) {
    int r = arrow.row + arrow.direction.dRow;
    int c = arrow.col + arrow.direction.dCol;

    while (board.isInside(r, c)) {
      if (board.arrowAt(r, c) != null) {
        return false;
      }
      r += arrow.direction.dRow;
      c += arrow.direction.dCol;
    }
    return true;
  }

  /// Locates the first blocking [Arrow] in [arrow]'s trajectory, if any.
  /// Returns `null` if the path to the edge is unobstructed.
  static Arrow? findBlockingArrow(Board board, Arrow arrow) {
    int r = arrow.row + arrow.direction.dRow;
    int c = arrow.col + arrow.direction.dCol;

    while (board.isInside(r, c)) {
      final obstacle = board.arrowAt(r, c);
      if (obstacle != null) {
        return obstacle;
      }
      r += arrow.direction.dRow;
      c += arrow.direction.dCol;
    }
    return null;
  }

  /// Performs full validation and calculates the cells traversed until boundary exit.
  static MoveValidationResult validateMove(Board board, Arrow arrow) {
    final path = <(int row, int col)>[];
    int r = arrow.row + arrow.direction.dRow;
    int c = arrow.col + arrow.direction.dCol;

    while (board.isInside(r, c)) {
      final obstacle = board.arrowAt(r, c);
      if (obstacle != null) {
        return MoveValidationResult(
          canExit: false,
          blockingArrow: obstacle,
          exitPath: path,
        );
      }
      path.add((r, c));
      r += arrow.direction.dRow;
      c += arrow.direction.dCol;
    }

    return MoveValidationResult(
      canExit: true,
      blockingArrow: null,
      exitPath: path,
    );
  }

  /// Returns all arrows on the current [board] that currently have a completely free path.
  /// Powers the guidance (long-press) and hint selection.
  static List<Arrow> findExitClearArrows(Board board) {
    final clear = <Arrow>[];
    for (final arrow in board.arrows) {
      if (canExit(board, arrow)) {
        clear.add(arrow);
      }
    }
    return clear;
  }
}
