import '../models/arrow.dart';
import '../models/board.dart';
import 'move_validator.dart';

class SolverResult {
  final bool isSolvable;
  final List<Arrow> solutionSteps;

  const SolverResult({
    required this.isSolvable,
    required this.solutionSteps,
  });
}

/// Solves and verifies silhouette arrow puzzles.
class Solver {
  Solver._();

  static bool isSolvable(Board board) {
    return solve(board).isSolvable;
  }

  /// Finds a full removal order of arrows to clear the board.
  static SolverResult solve(Board board) {
    var currentBoard = board.clone();
    final steps = <Arrow>[];

    while (!currentBoard.isCleared) {
      final escapable = MoveValidator.findEscapableArrows(currentBoard);
      if (escapable.isEmpty) {
        return SolverResult(isSolvable: false, solutionSteps: steps);
      }

      // Pick the best step: prioritize one that unlocks the most future arrows
      final chosen = _selectOptimal(currentBoard, escapable);
      steps.add(chosen);
      currentBoard = currentBoard.removeArrow(chosen);
    }

    return SolverResult(isSolvable: true, solutionSteps: steps);
  }

  /// Returns a valid next arrow hint for the player.
  static Arrow? getNextHint(Board board) {
    final escapable = MoveValidator.findEscapableArrows(board);
    if (escapable.isEmpty) return null;
    return _selectOptimal(board, escapable);
  }

  static Arrow _selectOptimal(Board board, List<Arrow> candidates) {
    if (candidates.length == 1) return candidates.first;

    Arrow best = candidates.first;
    int maxFreed = -1;

    for (final arrow in candidates) {
      final nextBoard = board.removeArrow(arrow);
      final freed = MoveValidator.findEscapableArrows(nextBoard).length;
      if (freed > maxFreed) {
        maxFreed = freed;
        best = arrow;
      }
    }

    return best;
  }
}
