import 'direction.dart';

/// Represents a single cell position on the grid.
class Cell {
  final int row;
  final int col;

  const Cell(this.row, this.col);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Cell &&
          runtimeType == other.runtimeType &&
          row == other.row &&
          col == other.col;

  @override
  int get hashCode => Object.hash(row, col);

  @override
  String toString() => '($row, $col)';
}

/// A snake-like arrow consisting of an ordered sequence of contiguous grid cells.
///
/// [cells.first] is the tail (rounded line cap).
/// [cells.last] is the head (with an arrowhead pointing in [headDirection]).
class Arrow {
  final String id;
  final List<Cell> cells;
  final Direction headDirection;
  final int colorVariant;

  const Arrow({
    required this.id,
    required this.cells,
    required this.headDirection,
    this.colorVariant = 0,
  });

  Cell get tail => cells.first;
  Cell get head => cells.last;
  int get length => cells.length;

  bool containsCell(int r, int c) {
    for (final cell in cells) {
      if (cell.row == r && cell.col == c) return true;
    }
    return false;
  }

  Arrow copyWith({
    String? id,
    List<Cell>? cells,
    Direction? headDirection,
    int? colorVariant,
  }) {
    return Arrow(
      id: id ?? this.id,
      cells: cells ?? this.cells,
      headDirection: headDirection ?? this.headDirection,
      colorVariant: colorVariant ?? this.colorVariant,
    );
  }

  /// Reverses the arrow path: the old tail becomes the head, and vice-versa.
  Arrow reversed({required Direction newHeadDirection}) {
    return Arrow(
      id: id,
      cells: cells.reversed.toList(),
      headDirection: newHeadDirection,
      colorVariant: colorVariant,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Arrow && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'Arrow($id: len=$length, head=$head ${headDirection.symbol})';
}
