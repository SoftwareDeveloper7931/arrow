import 'direction.dart';

/// Represents a single arrow tile placed in a cell on the board.
class Arrow {
  final String id;
  final int row;
  final int col;
  final Direction direction;
  final int colorVariant;

  const Arrow({
    required this.id,
    required this.row,
    required this.col,
    required this.direction,
    this.colorVariant = 0,
  });

  /// Factory to generate a default stable ID based on initial coordinates.
  factory Arrow.create({
    required int row,
    required int col,
    required Direction direction,
    int colorVariant = 0,
    String? id,
  }) {
    return Arrow(
      id: id ?? 'arr_${row}_$col',
      row: row,
      col: col,
      direction: direction,
      colorVariant: colorVariant,
    );
  }

  Arrow copyWith({
    String? id,
    int? row,
    int? col,
    Direction? direction,
    int? colorVariant,
  }) {
    return Arrow(
      id: id ?? this.id,
      row: row ?? this.row,
      col: col ?? this.col,
      direction: direction ?? this.direction,
      colorVariant: colorVariant ?? this.colorVariant,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'row': row,
        'col': col,
        'direction': direction.name,
        'colorVariant': colorVariant,
      };

  factory Arrow.fromJson(Map<String, dynamic> json) {
    return Arrow(
      id: json['id'] as String,
      row: json['row'] as int,
      col: json['col'] as int,
      direction: Direction.fromString(json['direction'] as String),
      colorVariant: (json['colorVariant'] as int?) ?? 0,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Arrow &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          row == other.row &&
          col == other.col &&
          direction == other.direction;

  @override
  int get hashCode => Object.hash(id, row, col, direction);

  @override
  String toString() => 'Arrow($id: ($row, $col) ${direction.symbol})';
}
