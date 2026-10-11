import '../models/arrow.dart';
import '../models/board.dart';
import 'move_validator.dart';

/// The result returned by [Solver.solve].
class SolverResult {
  final bool isSolvable;
  final List<Arrow> solutionSteps;

  const SolverResult({
    required this.isSolvable,
    required this.solutionSteps,
  });
}

/// Solves and verifies board puzzles using monotone topological reduction.
///
/// Because removing an unblocked arrow only removes obstacles and never adds them,
/// the clearance property is strictly monotonic. If a board has a solution,
/// greedy peeling of any available unblocked arrow will terminate with an empty board.
class Solver {
  Solver._();

  /// Checks if [board] can be completely cleared according to the game rules.
  static bool isSolvable(Board board) {
    return solve(board).isSolvable;
  }

  /// Solves the puzzle starting from [board].
  /// Returns [SolverResult] containing solvability flag and the sequence of arrows removed.
  static SolverResult solve(Board board) {
    var currentBoard = board.clone();
    final steps = <Arrow>[];

    while (!currentBoard.isCleared) {
      final unblocked = MoveValidator.findExitClearArrows(currentBoard);
      if (unblocked.isEmpty) {
        // Deadlock reached: no arrow can exit, but board still has arrows.
        return SolverResult(
          isSolvable: false,
          solutionSteps: steps,
        );
      }

      // Pick the next unblocked arrow.
      // Prioritize the arrow that unlocks the most future arrows if desired,
      // or simply the first available valid arrow.
      final chosen = _selectOptimalStep(currentBoard, unblocked);
      steps.add(chosen);
      currentBoard = currentBoard.removeArrow(chosen);
    }

    return SolverResult(
      isSolvable: true,
      solutionSteps: steps,
    );
  }

  /// Recommends a single valid next arrow to tap from the current [board] state.
  /// Returns `null` if the board is deadlocked or already cleared.
  static Arrow? getNextHint(Board board) {
    final unblocked = MoveValidator.findExitClearArrows(board);
    if (unblocked.isEmpty) return null;
    return _selectOptimalStep(board, unblocked);
  }

  /// Heuristic to choose the most helpful move among available unblocked arrows:
  /// We evaluate how many newly unblocked arrows are unlocked by removing each candidate.
  static Arrow _selectOptimalStep(Board board, List<Arrow> candidates) {
    if (candidates.length == 1) return candidates.first;

    Arrow best = candidates.first;
    int maxNewlyFreed = -1;

    for (final arrow in candidates) {
      final nextBoard = board.removeArrow(arrow);
      final newlyFreed = MoveValidator.findExitClearArrows(nextBoard).length;
      if (newlyFreed > maxNewlyFreed) {
        maxNewlyFreed = newlyFreed;
        best = arrow;
      }
    }

    return best;
  }
}
