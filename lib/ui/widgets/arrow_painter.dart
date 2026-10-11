import 'package:flutter/material.dart';
import '../../models/direction.dart';

/// Pixel-perfect vector canvas rendering for rounded arrows.
class ArrowPainter extends CustomPainter {
  final Direction direction;
  final Color color;
  final bool isHighlighted;
  final Color? glowColor;

  ArrowPainter({
    required this.direction,
    required this.color,
    this.isHighlighted = false,
    this.glowColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final w = size.width;

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(direction.rotationRadians);
    canvas.translate(-center.dx, -center.dy);

    if (glowColor != null) {
      final glowPaint = Paint()
        ..color = glowColor!.withValues(alpha: 0.4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.18
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);

      _drawArrowPath(canvas, size, glowPaint);
    }

    final arrowPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = (w * 0.13).clamp(2.5, 7.0)
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    _drawArrowPath(canvas, size, arrowPaint);

    canvas.restore();
  }

  void _drawArrowPath(Canvas canvas, Size size, Paint paint) {
    final w = size.width;
    final h = size.height;

    // Shaft line
    canvas.drawLine(
      Offset(w * 0.22, h * 0.5),
      Offset(w * 0.72, h * 0.5),
      paint,
    );

    // Chevron head
    final headPath = Path()
      ..moveTo(w * 0.52, h * 0.28)
      ..lineTo(w * 0.74, h * 0.5)
      ..lineTo(w * 0.52, h * 0.72);

    canvas.drawPath(headPath, paint);
  }

  @override
  bool shouldRepaint(covariant ArrowPainter oldDelegate) {
    return oldDelegate.direction != direction ||
        oldDelegate.color != color ||
        oldDelegate.isHighlighted != isHighlighted ||
        oldDelegate.glowColor != glowColor;
  }
}
