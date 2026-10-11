import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../../models/arrow.dart';
import '../../models/board.dart';
import '../../models/direction.dart';
import '../../theme/game_theme.dart';

/// Single-pass custom painter that renders the entire minimalist silhouette board.
///
/// Draws only thin continuous lines with rounded tail caps, 90-degree turns, and
/// crisp arrowheads. No cell borders, no boxes, no tiles.
class BoardPainter extends CustomPainter {
  final Board board;
  final GameTheme theme;
  final double cellSize;
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

  // Cached paths for non-animating arrows to maximize 60fps rendering performance
  static final Map<String, Path> _pathCache = {};

  BoardPainter({
    required this.board,
    required this.theme,
    required this.cellSize,
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
    // 1. Draw faint dot grid if enabled
    if (showDotGrid) {
      _drawDotGrid(canvas, size);
    }

    // Line stroke width scaled to cell size
    final strokeWidth = (cellSize * 0.18).clamp(2.5, 6.5);

    final linePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..isAntiAlias = true;

    final headPaint = Paint()
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    // 2. Render all static arrows
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

      Color color = theme.lineColor;
      double currentStrokeWidth = strokeWidth;

      if (isBlocker) {
        color = theme.errorFlashColor;
        currentStrokeWidth = strokeWidth * 1.25;
      } else if (isHinted) {
        // Pulsing hint highlight
        final pulse = 0.7 + 0.3 * math.sin(hintPulseProgress * math.pi * 2);
        color = Color.lerp(theme.lineColor, theme.hintColor, pulse)!;
        currentStrokeWidth = strokeWidth * 1.35;
      } else if (isGuidance) {
        color = theme.guidanceColor;
        currentStrokeWidth = strokeWidth * 1.2;
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

      // Draw arrow polyline body
      final path = _getOrCreatePath(arrow);
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

    // 3. Render the animating escaping arrow (slides along body trail & off board)
    if (animatingArrow != null) {
      _drawSlidingArrow(
        canvas: canvas,
        arrow: animatingArrow!,
        progress: animationProgress,
        baseStrokeWidth: strokeWidth,
      );
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

  /// Constructs or retrieves a cached Path for an [Arrow].
  Path _getOrCreatePath(Arrow arrow) {
    final cacheKey = '${arrow.id}_${arrow.length}_$cellSize';
    final cached = _pathCache[cacheKey];
    if (cached != null) return cached;

    final path = Path();
    if (arrow.cells.isEmpty) return path;

    if (arrow.cells.length == 1) {
      // 1-cell stub: short segment pointing along headDirection
      final cell = arrow.cells.first;
      final center = Offset((cell.col + 0.5) * cellSize, (cell.row + 0.5) * cellSize);
      final dirVec = _getDirectionVector(arrow.headDirection);
      final start = center - dirVec * (cellSize * 0.25);
      final end = center + dirVec * (cellSize * 0.15);
      path.moveTo(start.dx, start.dy);
      path.lineTo(end.dx, end.dy);
    } else {
      // Multi-cell snake polyline
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
    }

    _pathCache[cacheKey] = path;
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

    final headLen = (cellSize * 0.38).clamp(8.0, 24.0);
    final headHalfWidth = (cellSize * 0.26).clamp(5.0, 16.0);

    // Tip extends slightly beyond cell center in pointing direction
    final tip = headCenter + dirVec * (headLen * 0.45);
    final baseCenter = tip - dirVec * headLen;
    final leftBarb = baseCenter + perpVec * headHalfWidth;
    final rightBarb = baseCenter - perpVec * headHalfWidth;

    final headPath = Path()
      ..moveTo(tip.dx, tip.dy)
      ..lineTo(leftBarb.dx, leftBarb.dy)
      ..lineTo(baseCenter.dx + dirVec.dx * (headLen * 0.2), baseCenter.dy + dirVec.dy * (headLen * 0.2))
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
  }) {
    // 1. Build the full continuous trajectory (body path + extended escape ray off-board)
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

    // Measure metrics
    final metrics = trajectoryPath.computeMetrics().toList();
    if (metrics.isEmpty) return;
    final metric = metrics.first;

    // Body length of the arrow
    final bodyLength = arrow.cells.length == 1
        ? cellSize * 0.4
        : (arrow.cells.length - 1) * cellSize;

    // Total distance the head slides during animation
    final totalSlide = boardSpan * 0.8;
    final currentHeadDist = bodyLength + progress * totalSlide;
    final currentTailDist = math.max(0.0, currentHeadDist - bodyLength);

    if (currentTailDist >= metric.length) return;

    final subPath = metric.extractPath(currentTailDist, currentHeadDist.clamp(0.0, metric.length));

    // Smooth fade as it exits
    final alpha = ((1.0 - progress * 0.7)).clamp(0.0, 1.0);
    final slideColor = theme.lineColor.withValues(alpha: alpha);

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

      final headLen = (cellSize * 0.38).clamp(8.0, 24.0);
      final headHalfWidth = (cellSize * 0.26).clamp(5.0, 16.0);

      final tip = headCenter + headDirVec * (headLen * 0.45);
      final baseCenter = tip - headDirVec * headLen;
      final leftBarb = baseCenter + perpVec * headHalfWidth;
      final rightBarb = baseCenter - perpVec * headHalfWidth;

      final headPath = Path()
        ..moveTo(tip.dx, tip.dy)
        ..lineTo(leftBarb.dx, leftBarb.dy)
        ..lineTo(baseCenter.dx + headDirVec.dx * (headLen * 0.2), baseCenter.dy + headDirVec.dy * (headLen * 0.2))
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
