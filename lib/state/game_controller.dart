import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../logic/game_constants.dart';
import '../logic/level_generator.dart';
import '../logic/move_validator.dart';
import '../logic/solver.dart';
import '../models/arrow.dart';
import '../models/level.dart';
import '../services/ads_service.dart';
import '../services/audio_service.dart';
import '../services/storage_service.dart';
import '../theme/game_theme.dart';
import 'game_state.dart';

class GameController extends StateNotifier<GameState> {
  final StorageService storageService;
  final AudioService audioService;
  final AdsService adsService;

  Timer? _hintDismissTimer;

  GameController({
    required this.storageService,
    required this.audioService,
    required this.adsService,
    int? initialLevelNumber,
  }) : super(_createInitialState(
          levelNumber: initialLevelNumber ?? storageService.getCurrentLevel(),
          hints: storageService.getHintCount(),
          theme: GameTheme.getByType(storageService.getTheme()),
          showDotGrid: storageService.getShowDotGrid(),
        ));

  static GameState _createInitialState({
    required int levelNumber,
    required int hints,
    required GameTheme theme,
    required bool showDotGrid,
  }) {
    final level = LevelGenerator.generateLevel(levelNumber);
    return GameState(
      level: level,
      board: level.createInitialBoard(),
      waterDrops: GameConstants.initialHearts,
      availableHints: hints,
      currentTheme: theme,
      showDotGrid: showDotGrid,
      status: GameStatus.playing,
    );
  }

  /// Loads a specific level by number.
  void loadLevel(int levelNumber) {
    _hintDismissTimer?.cancel();
    final level = LevelGenerator.generateLevel(levelNumber);
    storageService.setCurrentLevel(levelNumber);

    state = GameState(
      level: level,
      board: level.createInitialBoard(),
      waterDrops: GameConstants.initialHearts,
      availableHints: storageService.getHintCount(),
      currentTheme: state.currentTheme,
      showDotGrid: state.showDotGrid,
      status: GameStatus.playing,
    );
  }

  /// Restarts the current active level with fresh water drops.
  void restartLevel() {
    _hintDismissTimer?.cancel();
    state = GameState(
      level: state.level,
      board: state.level.createInitialBoard(),
      waterDrops: GameConstants.initialHearts,
      availableHints: storageService.getHintCount(),
      currentTheme: state.currentTheme,
      showDotGrid: state.showDotGrid,
      status: GameStatus.playing,
    );
  }

  /// Advances to the next level.
  void nextLevel() {
    final nextLvl = state.level.number + 1;
    loadLevel(nextLvl);
  }

  /// Toggles faint dot grid visibility under the board.
  void toggleDotGrid() {
    final nextVal = !state.showDotGrid;
    storageService.setShowDotGrid(nextVal);
    state = state.copyWith(showDotGrid: nextVal);
  }

  /// Cycles to the next color theme (Eye Comfort -> Dark -> Paper -> Sepia -> Eye Comfort).
  void cycleTheme() {
    final values = GameThemeType.values;
    final nextIndex = (state.currentTheme.type.index + 1) % values.length;
    final nextThemeType = values[nextIndex];
    setTheme(nextThemeType);
  }

  /// Sets the active game theme.
  void setTheme(GameThemeType themeType) {
    storageService.setTheme(themeType);
    final theme = GameTheme.getByType(themeType);
    state = state.copyWith(currentTheme: theme);
  }

  /// Called when an arrow is tapped by the player.
  Future<void> onArrowTapped(Arrow arrow) async {
    // Ignore input if currently animating, won, or failed.
    if (state.isInteractionBlocked) return;

    // Clear active hints if player acts
    _hintDismissTimer?.cancel();

    final validation = MoveValidator.validateMove(state.board, arrow);

    if (validation.canEscape) {
      // SUCCESS: Arrow has an unblocked path to the edge
      audioService.playWhoosh();
      audioService.hapticSuccess();

      state = state.copyWith(
        status: GameStatus.animating,
        animatingArrow: arrow,
        clearHintedArrow: true,
        guidanceArrowIds: {},
      );

      // Wait for the slide-off animation to complete
      await Future.delayed(
        const Duration(milliseconds: GameConstants.slideDurationMs),
      );

      // Remove arrow from board
      final updatedBoard = state.board.removeArrow(arrow);
      final isCleared = updatedBoard.isCleared;

      if (isCleared) {
        final stars = Level.calculateStars(state.waterDrops);
        audioService.playWin();

        // Save progress
        await storageService.setStarsForLevel(state.level.number, stars);
        await storageService.setHighestUnlockedLevel(state.level.number + 1);

        state = state.copyWith(
          board: updatedBoard,
          status: GameStatus.won,
          clearAnimatingArrow: true,
          starsEarned: stars,
        );

        // Check if an interstitial ad should be shown (every 3 completed levels, min level 5)
        await adsService.showInterstitial(
          completedLevelNumber: state.level.number,
        );
      } else {
        state = state.copyWith(
          board: updatedBoard,
          status: GameStatus.playing,
          clearAnimatingArrow: true,
        );
      }
    } else {
      // ERROR: Arrow is blocked
      audioService.playError();
      audioService.hapticError();

      final newDrops = state.waterDrops - 1;
      final blocker = validation.blockingArrow;

      state = state.copyWith(
        status: GameStatus.animating,
        waterDrops: newDrops,
        shakingArrowId: arrow.id,
        blockingArrowId: blocker?.id,
        clearHintedArrow: true,
        guidanceArrowIds: {},
      );

      // Wait for shake animation and blocker flash
      await Future.delayed(
        const Duration(milliseconds: GameConstants.shakeDurationMs),
      );

      if (newDrops <= 0) {
        state = state.copyWith(
          status: GameStatus.failed,
          clearShakingArrow: true,
          clearBlockingArrow: true,
        );
      } else {
        state = state.copyWith(
          status: GameStatus.playing,
          clearShakingArrow: true,
          clearBlockingArrow: true,
        );
      }
    }
  }

  /// Activates guidance mode: highlights all arrows that currently have an unobstructed exit.
  void showGuidance() {
    if (state.isInteractionBlocked) return;
    audioService.hapticSelection();

    final unblocked = MoveValidator.findEscapableArrows(state.board);
    final unblockedIds = unblocked.map((a) => a.id).toSet();

    state = state.copyWith(guidanceArrowIds: unblockedIds);
  }

  /// Deactivates guidance mode.
  void hideGuidance() {
    if (state.guidanceArrowIds.isNotEmpty) {
      state = state.copyWith(guidanceArrowIds: {});
    }
  }

  /// Request a hint for a valid next move.
  bool requestHint() {
    if (state.isInteractionBlocked) return false;

    if (state.availableHints <= 0) {
      return false; // Out of hints
    }

    final hintArrow = Solver.getNextHint(state.board);
    if (hintArrow == null) return false;

    audioService.hapticSelection();
    final newHintCount = state.availableHints - 1;
    storageService.setHintCount(newHintCount);

    state = state.copyWith(
      availableHints: newHintCount,
      hintedArrowId: hintArrow.id,
    );

    // Auto-clear hint highlight after a few seconds
    _hintDismissTimer?.cancel();
    _hintDismissTimer = Timer(
      const Duration(milliseconds: GameConstants.hintPulseDurationMs * 3),
      () {
        if (mounted && state.hintedArrowId != null) {
          state = state.copyWith(clearHintedArrow: true);
        }
      },
    );

    return true;
  }

  /// Rewarded ad hook to gain extra hints.
  Future<bool> watchAdForHints() async {
    final success = await adsService.showRewarded(placement: 'extra_hints');
    if (success) {
      final updated = state.availableHints + GameConstants.rewardedAdHintReward;
      await storageService.setHintCount(updated);
      state = state.copyWith(availableHints: updated);
      audioService.playWin();
      return true;
    }
    return false;
  }

  /// Rewarded ad hook to revive on level fail.
  Future<bool> watchAdToContinue() async {
    final success = await adsService.showRewarded(placement: 'revive_level');
    if (success) {
      state = state.copyWith(
        waterDrops: GameConstants.rewardedAdHeartsReward,
        status: GameStatus.playing,
      );
      audioService.playWin();
      return true;
    }
    return false;
  }

  @override
  void dispose() {
    _hintDismissTimer?.cancel();
    super.dispose();
  }
}
