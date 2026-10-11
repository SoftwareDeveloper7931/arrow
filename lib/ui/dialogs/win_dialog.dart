import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../widgets/stars_display.dart';

class WinDialog extends StatelessWidget {
  final int levelNumber;
  final int stars;
  final VoidCallback onNextLevel;
  final VoidCallback onReplay;

  const WinDialog({
    super.key,
    required this.levelNumber,
    required this.stars,
    required this.onNextLevel,
    required this.onReplay,
  });

  String get _celebrationTitle {
    if (stars >= 3) return 'Flawless!';
    if (stars == 2) return 'Great Job!';
    return 'Level Cleared!';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _celebrationTitle,
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                letterSpacing: -0.5,
                color: isDark
                    ? AppColors.darkTextPrimary
                    : AppColors.lightTextPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Level $levelNumber Completed',
              style: TextStyle(
                fontSize: 15,
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightTextSecondary,
              ),
            ),
            const SizedBox(height: 24),
            StarsDisplay(stars: stars, size: 44),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: onNextLevel,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primarySage,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  'Next Level',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: onReplay,
              child: Text(
                'Replay Level',
                style: TextStyle(
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.lightTextSecondary,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
