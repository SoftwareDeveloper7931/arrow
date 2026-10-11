import 'arrow.dart';
import 'board.dart';

/// Represents a puzzle level configuration.
class Level {
  final int number;
  final int size;
  final List<Arrow> initialArrows;
  final List<String> guaranteedSolutionOrder;

  const Level({
    required this.number,
    required this.size,
    required this.initialArrows,
    this.guaranteedSolutionOrder = const [],
  });

  /// Instantiates a fresh initial [Board] for this level.
  Board createInitialBoard() {
    return Board.fromArrows(size, initialArrows);
  }

  /// Calculates stars awarded based on remaining hearts (3 max).
  /// 3 hearts left (0 errors) -> 3 stars
  /// 2 hearts left (1 error)  -> 2 stars
  /// 1 heart left (2 errors)  -> 1 star
  /// 0 hearts -> 0 stars
  static int calculateStars(int remainingHearts) {
    if (remainingHearts >= 3) return 3;
    if (remainingHearts == 2) return 2;
    if (remainingHearts == 1) return 1;
    return 0;
  }

  Map<String, dynamic> toJson() => {
        'number': number,
        'size': size,
        'arrows': initialArrows.map((a) => a.toJson()).toList(),
        'solutionOrder': guaranteedSolutionOrder,
      };

  factory Level.fromJson(Map<String, dynamic> json) {
    final rawArrows = (json['arrows'] as List<dynamic>)
        .map((e) => Arrow.fromJson(e as Map<String, dynamic>))
        .toList();
    final sol = (json['solutionOrder'] as List<dynamic>?)
            ?.map((e) => e as String)
            .toList() ??
        const [];
    return Level(
      number: json['number'] as int,
      size: json['size'] as int,
      initialArrows: rawArrows,
      guaranteedSolutionOrder: sol,
    );
  }

  @override
  String toString() =>
      'Level(number: $number, size: $size x $size, arrows: ${initialArrows.length})';
}
