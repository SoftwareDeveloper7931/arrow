import 'dart:math' as math;

/// Represents the four cardinal directions an arrow can point.
enum Direction {
  up(dRow: -1, dCol: 0),
  down(dRow: 1, dCol: 0),
  left(dRow: 0, dCol: -1),
  right(dRow: 0, dCol: 1);

  const Direction({required this.dRow, required this.dCol});

  final int dRow;
  final int dCol;

  /// Rotation angle in radians, assuming standard right-facing base arrow (0 rad = right).
  double get rotationRadians {
    switch (this) {
      case Direction.right:
        return 0.0;
      case Direction.down:
        return math.pi / 2;
      case Direction.left:
        return math.pi;
      case Direction.up:
        return -math.pi / 2;
    }
  }

  /// Opposite direction.
  Direction get opposite {
    switch (this) {
      case Direction.up:
        return Direction.down;
      case Direction.down:
        return Direction.up;
      case Direction.left:
        return Direction.right;
      case Direction.right:
        return Direction.left;
    }
  }

  /// Human-readable arrow symbol for debug/logging.
  String get symbol {
    switch (this) {
      case Direction.up:
        return '↑';
      case Direction.down:
        return '↓';
      case Direction.left:
        return '←';
      case Direction.right:
        return '→';
    }
  }

  static Direction fromString(String name) {
    return Direction.values.firstWhere(
      (d) => d.name.toLowerCase() == name.toLowerCase(),
      orElse: () => Direction.up,
    );
  }
}
