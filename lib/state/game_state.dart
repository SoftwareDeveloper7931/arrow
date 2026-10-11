import '../logic/game_constants.dart';
import '../models/arrow.dart';
import '../models/board.dart';
import '../models/level.dart';
import '../theme/game_theme.dart';

enum GameStatus {
  playing,
  animating,
  won,
  failed,
}

class GameState {
  final Level level;
  final Board board;
  final int waterDrops;
  final int availableHints;
  final bool showDotGrid;
  final GameTheme currentTheme;
  final GameStatus status;
  final Arrow? animatingArrow;
  final String? shakingArrowId;
  final String? blockingArrowId;
  final String? hintedArrowId;
  final Set<String> guidanceArrowIds;
  final int starsEarned;

  const GameState({
    required this.level,
    required this.board,
    this.waterDrops = GameConstants.initialHearts,
    this.availableHints = GameConstants.defaultHintStock,
    this.showDotGrid = false,
    this.currentTheme = GameTheme.eyeComfort,
    this.status = GameStatus.playing,
    this.animatingArrow,
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
    int? waterDrops,
    int? availableHints,
    bool? showDotGrid,
    GameTheme? currentTheme,
    GameStatus? status,
    Arrow? animatingArrow,
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
      waterDrops: waterDrops ?? this.waterDrops,
      availableHints: availableHints ?? this.availableHints,
      showDotGrid: showDotGrid ?? this.showDotGrid,
      currentTheme: currentTheme ?? this.currentTheme,
      status: status ?? this.status,
      animatingArrow: clearAnimatingArrow
          ? null
          : (animatingArrow ?? this.animatingArrow),
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
