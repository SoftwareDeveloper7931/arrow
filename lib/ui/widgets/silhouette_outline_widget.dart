import 'package:flutter/material.dart';
import '../../models/level.dart';
import '../../theme/game_theme.dart';

/// Renders a beautiful finished silhouette outline of the cleared level.
class SilhouetteOutlineWidget extends StatelessWidget {
  final Level level;
  final GameTheme theme;
  final double size;

  const SilhouetteOutlineWidget({
    super.key,
    required this.level,
    required this.theme,
    this.size = 140.0,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size,
          height: size,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: theme.lineColor.withValues(alpha: 0.15),
              width: 1.5,
            ),
          ),
          child: CustomPaint(
            size: Size(size, size),
            painter: _SilhouettePainter(
              level: level,
              color: theme.lineColor,
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          level.shapeName,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
            color: theme.textPrimaryColor,
          ),
        ),
      ],
    );
  }
}

class _SilhouettePainter extends CustomPainter {
  final Level level;
  final Color color;

  _SilhouettePainter({
    required this.level,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final mask = level.mask;
    if (mask == null) return;

    final cellW = size.width / mask.width;
    final cellH = size.height / mask.height;
    final cellSize = cellW < cellH ? cellW : cellH;

    final offsetX = (size.width - cellSize * mask.width) / 2;
    final offsetY = (size.height - cellSize * mask.height) / 2;

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    final radius = Radius.circular((cellSize * 0.28).clamp(2.0, 5.0));

    for (int y = 0; y < mask.height; y++) {
      for (int x = 0; x < mask.width; x++) {
        if (mask.isSet(x, y)) {
          final rect = RRect.fromRectAndRadius(
            Rect.fromLTWH(
              offsetX + x * cellSize + 1.0,
              offsetY + y * cellSize + 1.0,
              cellSize - 2.0,
              cellSize - 2.0,
            ),
            radius,
          );
          canvas.drawRRect(rect, paint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _SilhouettePainter oldDelegate) {
    return oldDelegate.level != level || oldDelegate.color != color;
  }
}
