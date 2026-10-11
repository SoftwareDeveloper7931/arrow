import '../models/board.dart';
import '../models/level.dart';
import '../logic/game_constants.dart';

enum GameStatus {
  playing,
  animating,
  won,
  failed,
}

class GameState {
  final Level level;
  final Board board;
  final int hearts;
  final int availableHints;
  final GameStatus status;
  final String? animatingArrowId;
  final String? shakingArrowId;
  final String? blockingArrowId;
  final String? hintedArrowId;
  final Set<String> guidanceArrowIds;
  final int starsEarned;

  const GameState({
    required this.level,
    required this.board,
    this.hearts = GameConstants.initialHearts,
    this.availableHints = GameConstants.defaultHintStock,
    this.status = GameStatus.playing,
    this.animatingArrowId,
    this.shakingArrowId,
    this.blockingArrowId,
    this.hintedArrowId,
    this.guidanceArrowIds = const {},
    this.starsEarned = 0,
  });

  bool get isInteractionBlocked =>
      status == GameStatus.animating ||
      status == GameStatus.won ||
      status == GameStatus.failed;

  GameState copyWith({
    Level? level,
    Board? board,
    int? hearts,
    int? availableHints,
    GameStatus? status,
    String? animatingArrowId,
    bool clearAnimatingArrow = false,
    String? shakingArrowId,
    bool clearShakingArrow = false,
    String? blockingArrowId,
    bool clearBlockingArrow = false,
    String? hintedArrowId,
    bool clearHintedArrow = false,
    Set<String>? guidanceArrowIds,
    int? starsEarned,
  }) {
    return GameState(
      level: level ?? this.level,
      board: board ?? this.board,
      hearts: hearts ?? this.hearts,
      availableHints: availableHints ?? this.availableHints,
      status: status ?? this.status,
      animatingArrowId: clearAnimatingArrow
          ? null
          : (animatingArrowId ?? this.animatingArrowId),
      shakingArrowId: clearShakingArrow
          ? null
          : (shakingArrowId ?? this.shakingArrowId),
      blockingArrowId: clearBlockingArrow
          ? null
          : (blockingArrowId ?? this.blockingArrowId),
      hintedArrowId:
          clearHintedArrow ? null : (hintedArrowId ?? this.hintedArrowId),
      guidanceArrowIds: guidanceArrowIds ?? this.guidanceArrowIds,
      starsEarned: starsEarned ?? this.starsEarned,
    );
  }
}
