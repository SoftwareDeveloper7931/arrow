import 'arrow.dart';

/// Represents the N x N grid of the puzzle board.
class Board {
  final int size;
  final List<List<Arrow?>> _cells;

  Board._(this.size, this._cells);

  /// Creates an empty board of dimension [size] x [size].
  factory Board.empty(int size) {
    return Board._(
      size,
      List.generate(size, (_) => List<Arrow?>.filled(size, null)),
    );
  }

  /// Creates a board populated with the provided [arrows].
  factory Board.fromArrows(int size, Iterable<Arrow> arrows) {
    final cells = List.generate(size, (_) => List<Arrow?>.filled(size, null));
    for (final arrow in arrows) {
      if (arrow.row >= 0 &&
          arrow.row < size &&
          arrow.col >= 0 &&
          arrow.col < size) {
        cells[arrow.row][arrow.col] = arrow;
      }
    }
    return Board._(size, cells);
  }

  /// Returns the arrow located at [row], [col], or null if empty or out of bounds.
  Arrow? arrowAt(int row, int col) {
    if (!isInside(row, col)) return null;
    return _cells[row][col];
  }

  /// Checks if [row], [col] is within the grid boundaries.
  bool isInside(int row, int col) {
    return row >= 0 && row < size && col >= 0 && col < size;
  }

  /// Checks if [row], [col] is valid and has no arrow.
  bool isCellEmpty(int row, int col) {
    return isInside(row, col) && _cells[row][col] == null;
  }

  /// Returns an unmodifiable list of all remaining arrows on the board.
  List<Arrow> get arrows {
    final list = <Arrow>[];
    for (int r = 0; r < size; r++) {
      for (int c = 0; c < size; c++) {
        final a = _cells[r][c];
        if (a != null) list.add(a);
      }
    }
    return list;
  }

  /// Total number of remaining arrows.
  int get remainingCount {
    int count = 0;
    for (int r = 0; r < size; r++) {
      for (int c = 0; c < size; c++) {
        if (_cells[r][c] != null) count++;
      }
    }
    return count;
  }

  /// True if all arrows have been cleared.
  bool get isCleared => remainingCount == 0;

  /// Returns a new Board with the given [arrow] removed.
  Board removeArrow(Arrow arrow) {
    final newCells = List.generate(
      size,
      (r) => List<Arrow?>.from(_cells[r]),
    );
    if (isInside(arrow.row, arrow.col)) {
      newCells[arrow.row][arrow.col] = null;
    }
    return Board._(size, newCells);
  }

  /// Returns a new Board with the given [arrow] placed.
  Board withArrow(Arrow arrow) {
    final newCells = List.generate(
      size,
      (r) => List<Arrow?>.from(_cells[r]),
    );
    if (isInside(arrow.row, arrow.col)) {
      newCells[arrow.row][arrow.col] = arrow;
    }
    return Board._(size, newCells);
  }

  Board clone() {
    return Board._(
      size,
      List.generate(size, (r) => List<Arrow?>.from(_cells[r])),
    );
  }

  @override
  String toString() {
    final buffer = StringBuffer('Board($size x $size):\n');
    for (int r = 0; r < size; r++) {
      for (int c = 0; c < size; c++) {
        final a = _cells[r][c];
        buffer.write(a != null ? '${a.direction.symbol} ' : '. ');
      }
      buffer.writeln();
    }
    return buffer.toString();
  }
}
