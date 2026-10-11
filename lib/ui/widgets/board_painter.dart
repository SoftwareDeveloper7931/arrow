import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../../models/arrow.dart';
import '../../models/board.dart';
import '../../models/direction.dart';
import '../../models/shape_mask.dart';
import '../../theme/app_colors.dart';
import '../../theme/game_theme.dart';

/// Single-pass custom painter that renders the entire minimalist silhouette board.
///
/// Draws only thin continuous lines with rounded tail caps, 90-degree turns, and
/// crisp arrowheads. No cell borders, no boxes, no tiles.
class BoardPainter extends CustomPainter {
  final Board board;
  final GameTheme theme;
  final double cellSize;
  final ShapeMask? mask;
  final bool showDotGrid;
  final Arrow? animatingArrow;
  final double animationProgress; // 0.0 to 1.0
  final String? shakingArrowId;
  final double shakeProgress; // 0.0 to 1.0
  final String? blockingArrowId;
  final String? hintedArrowId;
  final double hintPulseProgress; // 0.0 to 1.0
  final Set<String> guidanceArrowIds;
  final bool isCompletedSilhouette;

  BoardPainter({
    required this.board,
    required this.theme,
    required this.cellSize,
    this.mask,
    this.showDotGrid = false,
    this.animatingArrow,
    this.animationProgress = 0.0,
    this.shakingArrowId,
    this.shakeProgress = 0.0,
    this.blockingArrowId,
    this.hintedArrowId,
    this.hintPulseProgress = 0.0,
    this.guidanceArrowIds = const {},
    this.isCompletedSilhouette = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final isDark = theme.type == GameThemeType.dark;

    // 1. Draw subtle silhouette shape backdrop so the puzzle silhouette is recognizable
    if (mask != null) {
      _drawSilhouetteBackdrop(canvas, isDark);
    }

    // 2. Draw faint dot grid if enabled
    if (showDotGrid) {
      _drawDotGrid(canvas, size);
    }

    // Line stroke width scaled to cell size
    final strokeWidth = (cellSize * 0.17).clamp(2.5, 6.0);

    final linePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..isAntiAlias = true;

    final headPaint = Paint()
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    // 3. Render all static arrows
    for (final arrow in board.arrows) {
      if (animatingArrow != null && arrow.id == animatingArrow!.id) {
        // Handled in animating layer
        continue;
      }

      // Determine styling & state
      final isShaking = arrow.id == shakingArrowId;
      final isBlocker = arrow.id == blockingArrowId;
      final isHinted = arrow.id == hintedArrowId;
      final isGuidance = guidanceArrowIds.contains(arrow.id);

      Color color;
      double currentStrokeWidth = strokeWidth;

      if (isBlocker) {
        color = theme.errorFlashColor;
        currentStrokeWidth = strokeWidth * 1.25;
      } else if (isHinted) {
        final pulse = 0.7 + 0.3 * math.sin(hintPulseProgress * math.pi * 2);
        color = Color.lerp(theme.lineColor, theme.hintColor, pulse)!;
        currentStrokeWidth = strokeWidth * 1.35;
      } else if (isGuidance) {
        color = theme.guidanceColor;
        currentStrokeWidth = strokeWidth * 1.2;
      } else {
        // Use harmonic arrow color variant for visual clarity between snakes
        color = AppColors.getArrowColor(arrow.colorVariant, isDark);
      }

      linePaint.color = color;
      linePaint.strokeWidth = currentStrokeWidth;
      headPaint.color = color;

      canvas.save();

      // Apply shake translation if this arrow is blocked
      if (isShaking) {
        final shakeOffset = math.sin(shakeProgress * math.pi * 6) * (cellSize * 0.22);
        canvas.translate(shakeOffset, 0);
      }

      // Draw arrow polyline body on the fly (no stale cross-level cache pollution)
      final path = _buildArrowPath(arrow);
      canvas.drawPath(path, linePaint);

      // Draw arrowhead at head cell
      _drawArrowHead(
        canvas: canvas,
        arrow: arrow,
        paint: headPaint,
        strokeWidth: currentStrokeWidth,
      );

      canvas.restore();
    }

    // 4. Render the animating escaping arrow (slides along body trail & off board)
    if (animatingArrow != null) {
      _drawSlidingArrow(
        canvas: canvas,
        arrow: animatingArrow!,
        progress: animationProgress,
        baseStrokeWidth: strokeWidth,
        isDark: isDark,
      );
    }
  }

  /// Draws a soft, calm silhouette backdrop track behind the active cells.
  void _drawSilhouetteBackdrop(Canvas canvas, bool isDark) {
    final backdropPaint = Paint()
      ..color = (isDark ? const Color(0xFF64B5F6) : const Color(0xFF334155))
          .withValues(alpha: isDark ? 0.05 : 0.035)
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = (isDark ? const Color(0xFF64B5F6) : const Color(0xFF334155))
          .withValues(alpha: isDark ? 0.09 : 0.06)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final radius = Radius.circular((cellSize * 0.28).clamp(3.0, 7.0));

    for (int r = 0; r < board.rows; r++) {
      for (int c = 0; c < board.cols; c++) {
        if (mask!.isSet(c, r)) {
          final rect = RRect.fromRectAndRadius(
            Rect.fromLTWH(
              c * cellSize + 2.0,
              r * cellSize + 2.0,
              cellSize - 4.0,
              cellSize - 4.0,
            ),
            radius,
          );
          canvas.drawRRect(rect, backdropPaint);
          canvas.drawRRect(rect, borderPaint);
        }
      }
    }
  }

  /// Draws a subtle background dot grid under the puzzle board.
  void _drawDotGrid(Canvas canvas, Size size) {
    final dotPaint = Paint()
      ..color = theme.gridDotColor.withValues(alpha: 0.8)
      ..style = PaintingStyle.fill;

    final dotRadius = (cellSize * 0.05).clamp(1.2, 2.8);

    for (int r = 0; r < board.rows; r++) {
      for (int c = 0; c < board.cols; c++) {
        final center = Offset(
          (c + 0.5) * cellSize,
          (r + 0.5) * cellSize,
        );
        canvas.drawCircle(center, dotRadius, dotPaint);
      }
    }
  }

  /// Builds a clean vector Path for an [Arrow] directly without static cache corruption.
  Path _buildArrowPath(Arrow arrow) {
    final path = Path();
    if (arrow.cells.isEmpty) return path;

    if (arrow.cells.length == 1) {
      final cell = arrow.cells.first;
      final center = Offset((cell.col + 0.5) * cellSize, (cell.row + 0.5) * cellSize);
      final dirVec = _getDirectionVector(arrow.headDirection);
      final start = center - dirVec * (cellSize * 0.30);
      final end = center + dirVec * (cellSize * 0.10);
      path.moveTo(start.dx, start.dy);
      path.lineTo(end.dx, end.dy);
      return path;
    }

    final startCell = arrow.cells.first;
    path.moveTo(
      (startCell.col + 0.5) * cellSize,
      (startCell.row + 0.5) * cellSize,
    );

    for (int i = 1; i < arrow.cells.length; i++) {
      final cell = arrow.cells[i];
      path.lineTo(
        (cell.col + 0.5) * cellSize,
        (cell.row + 0.5) * cellSize,
      );
    }
    return path;
  }

  /// Draws a clean, crisp triangular arrowhead at the arrow's head.
  void _drawArrowHead({
    required Canvas canvas,
    required Arrow arrow,
    required Paint paint,
    required double strokeWidth,
  }) {
    final headCell = arrow.head;
    final headCenter = Offset(
      (headCell.col + 0.5) * cellSize,
      (headCell.row + 0.5) * cellSize,
    );

    final dirVec = _getDirectionVector(arrow.headDirection);
    final perpVec = Offset(-dirVec.dy, dirVec.dx);

    final headLen = (cellSize * 0.42).clamp(10.0, 24.0);
    final headHalfWidth = (cellSize * 0.28).clamp(6.0, 16.0);

    // Tip extends forward in pointing direction
    final tip = headCenter + dirVec * (headLen * 0.50);
    final baseCenter = tip - dirVec * headLen;
    final leftBarb = baseCenter + perpVec * headHalfWidth;
    final rightBarb = baseCenter - perpVec * headHalfWidth;
    final notch = baseCenter + dirVec * (headLen * 0.22);

    final headPath = Path()
      ..moveTo(tip.dx, tip.dy)
      ..lineTo(leftBarb.dx, leftBarb.dy)
      ..lineTo(notch.dx, notch.dy)
      ..lineTo(rightBarb.dx, rightBarb.dy)
      ..close();

    canvas.drawPath(headPath, paint);
  }

  /// Animates the snake sliding out along its body trail, continuing straight off the board.
  void _drawSlidingArrow({
    required Canvas canvas,
    required Arrow arrow,
    required double progress,
    required double baseStrokeWidth,
    required bool isDark,
  }) {
    final trajectoryPath = Path();
    if (arrow.cells.isEmpty) return;

    final startCell = arrow.cells.first;
    trajectoryPath.moveTo(
      (startCell.col + 0.5) * cellSize,
      (startCell.row + 0.5) * cellSize,
    );

    for (int i = 1; i < arrow.cells.length; i++) {
      final cell = arrow.cells[i];
      trajectoryPath.lineTo(
        (cell.col + 0.5) * cellSize,
        (cell.row + 0.5) * cellSize,
      );
    }

    // Straight escape ray continuing off the board
    final headCell = arrow.head;
    final dirVec = _getDirectionVector(arrow.headDirection);
    final boardSpan = math.max(board.rows, board.cols) * 1.5 * cellSize;
    final farTarget = Offset(
      (headCell.col + 0.5) * cellSize + dirVec.dx * boardSpan,
      (headCell.row + 0.5) * cellSize + dirVec.dy * boardSpan,
    );
    trajectoryPath.lineTo(farTarget.dx, farTarget.dy);

    final metrics = trajectoryPath.computeMetrics().toList();
    if (metrics.isEmpty) return;
    final metric = metrics.first;

    final bodyLength = arrow.cells.length == 1
        ? cellSize * 0.4
        : (arrow.cells.length - 1) * cellSize;

    final totalSlide = boardSpan * 0.8;
    final currentHeadDist = bodyLength + progress * totalSlide;
    final currentTailDist = math.max(0.0, currentHeadDist - bodyLength);

    if (currentTailDist >= metric.length) return;

    final subPath = metric.extractPath(currentTailDist, currentHeadDist.clamp(0.0, metric.length));

    final baseColor = AppColors.getArrowColor(arrow.colorVariant, isDark);
    final alpha = ((1.0 - progress * 0.7)).clamp(0.0, 1.0);
    final slideColor = baseColor.withValues(alpha: alpha);

    final linePaint = Paint()
      ..color = slideColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = baseStrokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..isAntiAlias = true;

    canvas.drawPath(subPath, linePaint);

    // Draw arrowhead at sliding head position
    final headTangent = metric.getTangentForOffset(currentHeadDist.clamp(0.0, metric.length));
    if (headTangent != null) {
      final headCenter = headTangent.position;
      final tangentVec = headTangent.vector;
      final headDirVec = Offset(tangentVec.dx, tangentVec.dy);
      final perpVec = Offset(-headDirVec.dy, headDirVec.dx);

      final headLen = (cellSize * 0.42).clamp(10.0, 24.0);
      final headHalfWidth = (cellSize * 0.28).clamp(6.0, 16.0);

      final tip = headCenter + headDirVec * (headLen * 0.50);
      final baseCenter = tip - headDirVec * headLen;
      final leftBarb = baseCenter + perpVec * headHalfWidth;
      final rightBarb = baseCenter - perpVec * headHalfWidth;
      final notch = baseCenter + headDirVec * (headLen * 0.22);

      final headPath = Path()
        ..moveTo(tip.dx, tip.dy)
        ..lineTo(leftBarb.dx, leftBarb.dy)
        ..lineTo(notch.dx, notch.dy)
        ..lineTo(rightBarb.dx, rightBarb.dy)
        ..close();

      final headPaint = Paint()
        ..color = slideColor
        ..style = PaintingStyle.fill
        ..isAntiAlias = true;

      canvas.drawPath(headPath, headPaint);
    }
  }

  static Offset _getDirectionVector(Direction dir) {
    switch (dir) {
      case Direction.up:
        return const Offset(0, -1);
      case Direction.down:
        return const Offset(0, 1);
      case Direction.left:
        return const Offset(-1, 0);
      case Direction.right:
        return const Offset(1, 0);
    }
  }

  @override
  bool shouldRepaint(covariant BoardPainter oldDelegate) {
    return oldDelegate.board != board ||
        oldDelegate.theme != theme ||
        oldDelegate.cellSize != cellSize ||
        oldDelegate.mask != mask ||
        oldDelegate.showDotGrid != showDotGrid ||
        oldDelegate.animatingArrow != animatingArrow ||
        oldDelegate.animationProgress != animationProgress ||
        oldDelegate.shakingArrowId != shakingArrowId ||
        oldDelegate.shakeProgress != shakeProgress ||
        oldDelegate.blockingArrowId != blockingArrowId ||
        oldDelegate.hintedArrowId != hintedArrowId ||
        oldDelegate.hintPulseProgress != hintPulseProgress ||
        oldDelegate.guidanceArrowIds != guidanceArrowIds ||
        oldDelegate.isCompletedSilhouette != isCompletedSilhouette;
  }
}
