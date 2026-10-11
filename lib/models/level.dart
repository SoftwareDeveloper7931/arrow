import 'arrow.dart';
import 'board.dart';
import 'shape_mask.dart';

/// Represents a silhouette puzzle level configuration.
class Level {
  final int number;
  final String shapeName;
  final int rows;
  final int cols;
  final List<Arrow> initialArrows;
  final ShapeMask? mask;

  const Level({
    required this.number,
    required this.shapeName,
    required this.rows,
    required this.cols,
    required this.initialArrows,
    this.mask,
  });

  /// Instantiates a fresh initial [Board] for this level.
  Board createInitialBoard() {
    return Board.fromArrows(
      rows: rows,
      cols: cols,
      arrows: initialArrows,
    );
  }

  /// Calculates stars awarded based on remaining water drops (3 max).
  static int calculateStars(int remainingDrops) {
    if (remainingDrops >= 3) return 3;
    if (remainingDrops == 2) return 2;
    if (remainingDrops == 1) return 1;
    return 0;
  }

  @override
  String toString() =>
      'Level($number: "$shapeName", ${rows}x$cols, arrows=${initialArrows.length})';
}
