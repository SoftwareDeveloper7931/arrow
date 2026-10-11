import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../logic/game_constants.dart';
import '../../state/game_state.dart';
import '../../state/providers.dart';
import '../../theme/game_theme.dart';
import '../dialogs/fail_dialog.dart';
import '../dialogs/hint_reward_dialog.dart';
import '../dialogs/win_dialog.dart';
import '../widgets/board_widget.dart';
import '../widgets/water_drops_widget.dart';
import 'settings_screen.dart';

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
    if (state == AppLifecycleState.paused) {
      ref.read(gameControllerProvider.notifier).hideGuidance();
    }
  }

  void _listenForStatusChanges(
      BuildContext context, GameState? prev, GameState next) {
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
              level: next.level,
              stars: next.starsEarned,
              theme: next.currentTheme,
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
    } else if (next.status == GameStatus.failed &&
        prev?.status != GameStatus.failed) {
      _dialogOpen = true;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => FailDialog(
          levelNumber: next.level.number,
          theme: next.currentTheme,
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
              ref.read(gameControllerProvider.notifier).restartLevel();
            }
          },
        ),
      );
    }
  }

  void _showThemePicker(BuildContext context, GameTheme currentTheme) {
    showModalBottomSheet(
      context: context,
      backgroundColor: currentTheme.backgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Choose Theme',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: currentTheme.textPrimaryColor,
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close_rounded,
                          color: currentTheme.textSecondaryColor),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: GameThemeType.values.map((type) {
                    final theme = GameTheme.getByType(type);
                    final isSelected = theme.type == currentTheme.type;

                    return InkWell(
                      onTap: () {
                        ref
                            .read(gameControllerProvider.notifier)
                            .setTheme(type);
                        Navigator.of(context).pop();
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        width: 150,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: theme.cardColor,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected
                                ? theme.lineColor
                                : theme.lineColor.withValues(alpha: 0.2),
                            width: isSelected ? 2.5 : 1.0,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                color: theme.backgroundColor,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: theme.lineColor,
                                  width: 2.5,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                theme.name,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.w500,
                                  color: theme.textPrimaryColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<GameState>(
      gameControllerProvider,
      (prev, next) => _listenForStatusChanges(context, prev, next),
    );

    final gameState = ref.watch(gameControllerProvider);
    final theme = gameState.currentTheme;

    return Scaffold(
      backgroundColor: theme.backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar: Back, "Level N", Theme palette icon, Settings icon
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: theme.textPrimaryColor,
                      size: 22,
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Level ${gameState.level.number}',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.3,
                            color: theme.textPrimaryColor,
                          ),
                        ),
                        Text(
                          gameState.level.shapeName,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: theme.textSecondaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Theme Palette',
                    icon: Icon(
                      Icons.palette_outlined,
                      color: theme.textPrimaryColor,
                      size: 24,
                    ),
                    onPressed: () => _showThemePicker(context, theme),
                  ),
                  IconButton(
                    tooltip: 'Settings',
                    icon: Icon(
                      Icons.settings_outlined,
                      color: theme.textPrimaryColor,
                      size: 24,
                    ),
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const SettingsScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),

            // Water-drop lives indicator (3 blue drops)
            Padding(
              padding: const EdgeInsets.only(top: 2.0, bottom: 8.0),
              child: WaterDropsWidget(
                remainingDrops: gameState.waterDrops,
                theme: theme,
              ),
            ),

            // Centered minimalist silhouette puzzle board
            const Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 12.0),
                child: BoardWidget(),
              ),
            ),

            // Bottom circular control buttons (Grid-toggle and Hint button)
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 32.0, vertical: 18.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Circular Grid-Toggle Button
                  Tooltip(
                    message: gameState.showDotGrid
                        ? 'Hide dot grid'
                        : 'Show dot grid',
                    child: InkWell(
                      onTap: () {
                        ref
                            .read(gameControllerProvider.notifier)
                            .toggleDotGrid();
                      },
                      borderRadius: BorderRadius.circular(30),
                      child: Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: gameState.showDotGrid
                              ? theme.cardColor
                              : theme.backgroundColor,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: gameState.showDotGrid
                                ? theme.lineColor
                                : theme.lineColor.withValues(alpha: 0.25),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.grid_3x3_rounded,
                          color: gameState.showDotGrid
                              ? theme.lineColor
                              : theme.textSecondaryColor,
                          size: 26,
                        ),
                      ),
                    ),
                  ),

                  // Circular Hint Button with counter badge
                  Tooltip(
                    message: 'Get hint',
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        InkWell(
                          onTap: () {
                            final success = ref
                                .read(gameControllerProvider.notifier)
                                .requestHint();
                            if (!success) {
                              showDialog(
                                context: context,
                                builder: (_) => HintRewardDialog(
                                  theme: theme,
                                  onWatchAd: () {
                                    ref
                                        .read(gameControllerProvider.notifier)
                                        .watchAdForHints();
                                  },
                                ),
                              );
                            }
                          },
                          borderRadius: BorderRadius.circular(30),
                          child: Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              color: gameState.hintedArrowId != null
                                  ? theme.hintColor.withValues(alpha: 0.15)
                                  : theme.backgroundColor,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: gameState.hintedArrowId != null
                                    ? theme.hintColor
                                    : theme.lineColor.withValues(alpha: 0.25),
                                width: 1.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.05),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.lightbulb_outline_rounded,
                              color: gameState.availableHints > 0
                                  ? theme.hintColor
                                  : theme.textSecondaryColor,
                              size: 26,
                            ),
                          ),
                        ),
                        // Badge counter
                        Positioned(
                          right: -4,
                          top: -4,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: theme.hintColor,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.15),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Text(
                              '${gameState.availableHints}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
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
