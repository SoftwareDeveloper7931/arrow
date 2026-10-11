import 'package:flutter/material.dart';
import '../../models/level.dart';
import '../../theme/game_theme.dart';
import '../widgets/silhouette_outline_widget.dart';
import '../widgets/stars_display.dart';

class WinDialog extends StatelessWidget {
  final Level level;
  final int stars;
  final GameTheme theme;
  final VoidCallback onNextLevel;
  final VoidCallback onReplay;

  const WinDialog({
    super.key,
    required this.level,
    required this.stars,
    required this.theme,
    required this.onNextLevel,
    required this.onReplay,
  });

  String get _celebrationTitle {
    if (stars >= 3) return 'Flawless!';
    if (stars == 2) return 'Well Done!';
    return 'Level Cleared!';
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: theme.backgroundColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(28),
        side: BorderSide(
          color: theme.lineColor.withValues(alpha: 0.15),
          width: 1.5,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _celebrationTitle,
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                letterSpacing: -0.5,
                color: theme.textPrimaryColor,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Level ${level.number} • ${level.shapeName}',
              style: TextStyle(
                fontSize: 14,
                color: theme.textSecondaryColor,
              ),
            ),
            const SizedBox(height: 18),
            // Unveiled silhouette preview
            SilhouetteOutlineWidget(
              level: level,
              theme: theme,
              size: 130,
            ),
            const SizedBox(height: 18),
            StarsDisplay(stars: stars, size: 40),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: onNextLevel,
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.lineColor,
                  foregroundColor: theme.backgroundColor,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  'Next Level',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: onReplay,
              child: Text(
                'Replay Level',
                style: TextStyle(
                  color: theme.textSecondaryColor,
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
