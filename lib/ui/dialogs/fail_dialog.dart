import 'package:flutter/material.dart';
import '../../theme/game_theme.dart';

class FailDialog extends StatelessWidget {
  final int levelNumber;
  final GameTheme theme;
  final VoidCallback onRetry;
  final VoidCallback onWatchAdContinue;

  const FailDialog({
    super.key,
    required this.levelNumber,
    required this.theme,
    required this.onRetry,
    required this.onWatchAdContinue,
  });

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
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.errorFlashColor.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.water_drop_outlined,
                color: theme.errorFlashColor,
                size: 40,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'Level Failed',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                letterSpacing: -0.4,
                color: theme.textPrimaryColor,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Out of water drops. Trace the straight escape rays carefully before tapping.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: theme.textSecondaryColor,
              ),
            ),
            const SizedBox(height: 24),
            // Watch Ad to Continue Button (placeholder)
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: onWatchAdContinue,
                icon: const Icon(Icons.play_circle_outline_rounded, size: 22),
                label: const Text(
                  'Watch Ad to Continue (+2 Drops)',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.lineColor,
                  foregroundColor: theme.backgroundColor,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            // Retry Button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton(
                onPressed: onRetry,
                style: OutlinedButton.styleFrom(
                  foregroundColor: theme.textPrimaryColor,
                  side: BorderSide(
                    color: theme.lineColor.withValues(alpha: 0.25),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  'Retry Level',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
