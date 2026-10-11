import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../logic/game_constants.dart';
import '../../state/game_state.dart';
import '../../state/providers.dart';
import '../../theme/app_colors.dart';
import '../dialogs/fail_dialog.dart';
import '../dialogs/hint_reward_dialog.dart';
import '../dialogs/win_dialog.dart';
import '../widgets/board_widget.dart';
import '../widgets/hearts_widget.dart';

class GameScreen extends ConsumerStatefulWidget {
  const GameScreen({super.key});

  @override
  ConsumerState<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends ConsumerState<GameScreen>
    with WidgetsBindingObserver {
  bool _dialogOpen = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Graceful handling of backgrounding mid-level
    if (state == AppLifecycleState.paused) {
      ref.read(gameControllerProvider.notifier).hideGuidance();
    }
  }

  void _listenForStatusChanges(BuildContext context, GameState? prev, GameState next) {
    if (_dialogOpen) return;

    if (next.status == GameStatus.won && prev?.status != GameStatus.won) {
      _dialogOpen = true;
      Future.delayed(
        const Duration(milliseconds: GameConstants.winCelebrationDelayMs),
        () {
          if (!mounted || !context.mounted) return;
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (_) => WinDialog(
              levelNumber: next.level.number,
              stars: next.starsEarned,
              onNextLevel: () {
                _dialogOpen = false;
                Navigator.of(context).pop();
                ref.read(gameControllerProvider.notifier).nextLevel();
              },
              onReplay: () {
                _dialogOpen = false;
                Navigator.of(context).pop();
                ref.read(gameControllerProvider.notifier).restartLevel();
              },
            ),
          );
        },
      );
    } else if (next.status == GameStatus.failed && prev?.status != GameStatus.failed) {
      _dialogOpen = true;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => FailDialog(
          levelNumber: next.level.number,
          onRetry: () {
            _dialogOpen = false;
            Navigator.of(context).pop();
            ref.read(gameControllerProvider.notifier).restartLevel();
          },
          onWatchAdContinue: () async {
            _dialogOpen = false;
            Navigator.of(context).pop();
            final revived = await ref
                .read(gameControllerProvider.notifier)
                .watchAdToContinue();
            if (!revived && mounted) {
              // Fallback to restart if ad was cancelled
              ref.read(gameControllerProvider.notifier).restartLevel();
            }
          },
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<GameState>(
      gameControllerProvider,
      (prev, next) => _listenForStatusChanges(context, prev, next),
    );

    final gameState = ref.watch(gameControllerProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Column(
          children: [
            Text(
              'Level ${gameState.level.number}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            Text(
              '${gameState.level.size}x${gameState.level.size} Grid',
              style: TextStyle(
                fontSize: 12,
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightTextSecondary,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Restart Level',
            icon: const Icon(Icons.refresh_rounded, size: 22),
            onPressed: () {
              ref.read(gameControllerProvider.notifier).restartLevel();
            },
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Status bar (Hearts, Hint Button)
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  HeartsWidget(remainingHearts: gameState.hearts),

                  // Hint Button with badge counter
                  InkWell(
                    onTap: () {
                      final hasHints = ref
                          .read(gameControllerProvider.notifier)
                          .requestHint();
                      if (!hasHints) {
                        showDialog(
                          context: context,
                          builder: (_) => HintRewardDialog(
                            onWatchAd: () {
                              ref
                                  .read(gameControllerProvider.notifier)
                                  .watchAdForHints();
                            },
                          ),
                        );
                      }
                    },
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF222631)
                            : const Color(0xFFEDF2F7),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: gameState.hintedArrowId != null
                              ? AppColors.hintGold
                              : Colors.transparent,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.lightbulb_rounded,
                            size: 18,
                            color: gameState.availableHints > 0
                                ? AppColors.hintGold
                                : (isDark ? Colors.white30 : Colors.black26),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '${gameState.availableHints}',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: isDark
                                  ? AppColors.darkTextPrimary
                                  : AppColors.lightTextPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Centered responsive puzzle board
            const Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0),
                child: BoardWidget(),
              ),
            ),

            // Bottom informational banner
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
              child: Column(
                children: [
                  Text(
                    '${gameState.board.remainingCount} arrows remaining',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.touch_app_outlined,
                        size: 14,
                        color: isDark ? Colors.white38 : Colors.black38,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Hold to reveal clear paths',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.white38 : Colors.black45,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
