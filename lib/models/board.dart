import 'arrow.dart';

/// Represents the 2D grid containing silhouette snake-arrows.
class Board {
  final int rows;
  final int cols;
  final List<Arrow> arrows;
  final List<List<Arrow?>> _cellToArrow;

  Board._(
    this.rows,
    this.cols,
    this.arrows,
    this._cellToArrow,
  );

  /// Creates a board from a list of snake arrows.
  factory Board.fromArrows({
    required int rows,
    required int cols,
    required Iterable<Arrow> arrows,
  }) {
    final cellToArrow =
        List.generate(rows, (_) => List<Arrow?>.filled(cols, null));

    for (final arrow in arrows) {
      for (final cell in arrow.cells) {
        if (cell.row >= 0 &&
            cell.row < rows &&
            cell.col >= 0 &&
            cell.col < cols) {
          cellToArrow[cell.row][cell.col] = arrow;
        }
      }
    }

    return Board._(
      rows,
      cols,
      List.unmodifiable(arrows),
      cellToArrow,
    );
  }

  /// Factory for an empty board.
  factory Board.empty(int rows, int cols) {
    return Board._(
      rows,
      cols,
      const [],
      List.generate(rows, (_) => List<Arrow?>.filled(cols, null)),
    );
  }

  bool isInside(int r, int c) {
    return r >= 0 && r < rows && c >= 0 && c < cols;
  }

  Arrow? arrowAt(int r, int c) {
    if (!isInside(r, c)) return null;
    return _cellToArrow[r][c];
  }

  bool isOccupied(int r, int c) {
    return arrowAt(r, c) != null;
  }

  int get remainingCount => arrows.length;
  bool get isCleared => arrows.isEmpty;

  /// Returns a new Board with [arrow] removed.
  Board removeArrow(Arrow arrow) {
    final newArrows = arrows.where((a) => a.id != arrow.id).toList();
    final newCellToArrow =
        List.generate(rows, (r) => List<Arrow?>.from(_cellToArrow[r]));

    for (final cell in arrow.cells) {
      if (isInside(cell.row, cell.col)) {
        newCellToArrow[cell.row][cell.col] = null;
      }
    }

    return Board._(
      rows,
      cols,
      List.unmodifiable(newArrows),
      newCellToArrow,
    );
  }

  Board clone() {
    return Board._(
      rows,
      cols,
      List.unmodifiable(arrows),
      List.generate(rows, (r) => List<Arrow?>.from(_cellToArrow[r])),
    );
  }
}
