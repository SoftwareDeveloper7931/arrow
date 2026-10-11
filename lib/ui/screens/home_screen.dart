import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../logic/game_constants.dart';
import '../../state/providers.dart';
import '../../theme/app_colors.dart';
import '../widgets/arrow_painter.dart';
import '../../models/direction.dart';
import 'game_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final storage = ref.watch(storageServiceProvider);
    final currentLevel = storage.getCurrentLevel();
    final unlockedLevel = storage.getHighestUnlockedLevel();
    final totalStars = storage.getTotalStars();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            tooltip: 'Settings',
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28.0),
          child: Column(
            children: [
              const Spacer(flex: 2),

              // Decorative aesthetic emblem
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurface : Colors.white,
                  borderRadius: BorderRadius.circular(26),
                  boxShadow: [
                    BoxShadow(
                      color: isDark
                          ? Colors.black.withValues(alpha: 0.3)
                          : Colors.black.withValues(alpha: 0.06),
                      blurRadius: 18,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Center(
                  child: CustomPaint(
                    size: const Size(44, 44),
                    painter: ArrowPainter(
                      direction: Direction.up,
                      color: AppColors.primarySage,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Title & Subtitle
              Text(
                'Arrow Flow',
                style: TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.8,
                  color: isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.lightTextPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'A calm arrow-clearing puzzle',
                style: TextStyle(
                  fontSize: 16,
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.lightTextSecondary,
                  letterSpacing: -0.2,
                ),
              ),

              const Spacer(flex: 3),

              // Progression stats row
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurface : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isDark
                        ? const Color(0xFF282C37)
                        : const Color(0xFFEAEFF5),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatItem(
                      label: 'Current Level',
                      value: '$currentLevel',
                      icon: Icons.flag_rounded,
                      iconColor: AppColors.primarySage,
                      context: context,
                    ),
                    Container(
                      height: 32,
                      width: 1,
                      color: isDark ? Colors.white12 : Colors.black12,
                    ),
                    _buildStatItem(
                      label: 'Stars Collected',
                      value: '$totalStars',
                      icon: Icons.star_rounded,
                      iconColor: AppColors.hintGold,
                      context: context,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Play / Continue Button
              SizedBox(
                width: double.infinity,
                height: 58,
                child: ElevatedButton(
                  onPressed: () {
                    ref
                        .read(gameControllerProvider.notifier)
                        .loadLevel(currentLevel);
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const GameScreen()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primarySage,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  child: Text(
                    currentLevel == 1 ? 'Start Playing' : 'Continue Level $currentLevel',
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.2,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Level Select Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton.icon(
                  onPressed: () {
                    _showLevelSelectModal(context, ref, unlockedLevel, storage);
                  },
                  icon: const Icon(Icons.grid_view_rounded, size: 20),
                  label: const Text(
                    'Select Level',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.lightTextPrimary,
                    side: BorderSide(
                      color: isDark
                          ? const Color(0xFF282C37)
                          : const Color(0xFFE2E8F0),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                ),
              ),

              const Spacer(flex: 3),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem({
    required String label,
    required String value,
    required IconData icon,
    required Color iconColor,
    required BuildContext context,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: iconColor),
            const SizedBox(width: 6),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDark
                    ? AppColors.darkTextPrimary
                    : AppColors.lightTextPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isDark
                ? AppColors.darkTextSecondary
                : AppColors.lightTextSecondary,
          ),
        ),
      ],
    );
  }

  void _showLevelSelectModal(
    BuildContext context,
    WidgetRef ref,
    int unlockedLevel,
    dynamic storage,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return Container(
          height: MediaQuery.of(ctx).size.height * 0.75,
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : Colors.black12,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Select Level (1 - ${GameConstants.minLevelCount})',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.lightTextPrimary,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 5,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  itemCount: GameConstants.minLevelCount,
                  itemBuilder: (context, index) {
                    final lvl = index + 1;
                    final isUnlocked = lvl <= unlockedLevel;
                    final stars = storage.getStarsForLevel(lvl);

                    return InkWell(
                      onTap: isUnlocked
                          ? () {
                              ref
                                  .read(gameControllerProvider.notifier)
                                  .loadLevel(lvl);
                              Navigator.of(ctx).pop();
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const GameScreen(),
                                ),
                              );
                            }
                          : null,
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        decoration: BoxDecoration(
                          color: isUnlocked
                              ? (isDark
                                  ? const Color(0xFF262A35)
                                  : AppColors.lightGridBg)
                              : (isDark
                                  ? const Color(0xFF1B1E26)
                                  : const Color(0xFFF1F3F6)),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isUnlocked
                                ? (isDark
                                    ? const Color(0xFF323846)
                                    : const Color(0xFFDFE4EA))
                                : Colors.transparent,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (!isUnlocked)
                              Icon(
                                Icons.lock_outline_rounded,
                                size: 16,
                                color: isDark ? Colors.white24 : Colors.black26,
                              )
                            else ...[
                              Text(
                                '$lvl',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                  color: isDark
                                      ? AppColors.darkTextPrimary
                                      : AppColors.lightTextPrimary,
                                ),
                              ),
                              if (stars > 0)
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: List.generate(
                                    stars,
                                    (_) => const Icon(
                                      Icons.star_rounded,
                                      size: 10,
                                      color: AppColors.hintGold,
                                    ),
                                  ),
                                ),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
