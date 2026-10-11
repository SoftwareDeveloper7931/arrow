import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../logic/game_constants.dart';
import '../../models/arrow.dart';
import '../../state/game_state.dart';
import '../../state/providers.dart';
import 'board_painter.dart';

/// Interactive board hosting the single-pass CustomPainter with zoom, pan,
/// double-tap reset, generous hit-testing, and fluid 60fps animations.
class BoardWidget extends ConsumerStatefulWidget {
  const BoardWidget({super.key});

  @override
  ConsumerState<BoardWidget> createState() => _BoardWidgetState();
}

class _BoardWidgetState extends ConsumerState<BoardWidget>
    with TickerProviderStateMixin {
  late final TransformationController _transformationController;
  late final AnimationController _slideController;
  late final AnimationController _shakeController;
  late final AnimationController _hintPulseController;

  @override
  void initState() {
    super.initState();
    _transformationController = TransformationController();

    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: GameConstants.slideDurationMs),
    );

    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: GameConstants.shakeDurationMs),
    );

    _hintPulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: GameConstants.hintPulseDurationMs),
    );
  }

  @override
  void dispose() {
    _transformationController.dispose();
    _slideController.dispose();
    _shakeController.dispose();
    _hintPulseController.dispose();
    super.dispose();
  }

  void _resetZoom() {
    _transformationController.value = Matrix4.identity();
  }

  /// Locates the nearest arrow to [tapOffset] within generous tolerance.
  Arrow? _findHitArrow({
    required Offset tapOffset,
    required double cellSize,
    required List<Arrow> arrows,
  }) {
    Arrow? bestArrow;
    double minDistance = double.infinity;
    final maxTolerance = cellSize * 0.58;

    for (final arrow in arrows) {
      if (arrow.cells.isEmpty) continue;

      double arrowMinDist = double.infinity;

      if (arrow.cells.length == 1) {
        final c = arrow.cells.first;
        final center = Offset((c.col + 0.5) * cellSize, (c.row + 0.5) * cellSize);
        arrowMinDist = (tapOffset - center).distance;
      } else {
        for (int i = 0; i < arrow.cells.length - 1; i++) {
          final c1 = arrow.cells[i];
          final c2 = arrow.cells[i + 1];
          final p1 = Offset((c1.col + 0.5) * cellSize, (c1.row + 0.5) * cellSize);
          final p2 = Offset((c2.col + 0.5) * cellSize, (c2.row + 0.5) * cellSize);

          final dist = _distanceToSegment(tapOffset, p1, p2);
          if (dist < arrowMinDist) {
            arrowMinDist = dist;
          }
        }
      }

      if (arrowMinDist < minDistance && arrowMinDist <= maxTolerance) {
        minDistance = arrowMinDist;
        bestArrow = arrow;
      }
    }

    return bestArrow;
  }

  double _distanceToSegment(Offset p, Offset a, Offset b) {
    final ab = b - a;
    final lengthSq = ab.dx * ab.dx + ab.dy * ab.dy;
    if (lengthSq == 0) return (p - a).distance;

    final t = (((p.dx - a.dx) * ab.dx + (p.dy - a.dy) * ab.dy) / lengthSq)
        .clamp(0.0, 1.0);
    final projection = Offset(a.dx + t * ab.dx, a.dy + t * ab.dy);
    return (p - projection).distance;
  }

  @override
  Widget build(BuildContext context) {
    // Listen for animation triggers from controller
    ref.listen<GameState>(gameControllerProvider, (prev, next) {
      if (next.animatingArrow != null &&
          (prev?.animatingArrow?.id != next.animatingArrow?.id)) {
        _slideController.forward(from: 0.0);
      }
      if (next.shakingArrowId != null &&
          (prev?.shakingArrowId != next.shakingArrowId)) {
        _shakeController.forward(from: 0.0);
      }
      if (next.hintedArrowId != null && prev?.hintedArrowId == null) {
        _hintPulseController.repeat(reverse: true);
      } else if (next.hintedArrowId == null && prev?.hintedArrowId != null) {
        _hintPulseController.stop();
        _hintPulseController.value = 0.0;
      }
    });

    final gameState = ref.watch(gameControllerProvider);
    final board = gameState.board;
    final theme = gameState.currentTheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth;
        final availableHeight = constraints.maxHeight;

        // Compute cellSize maintaining aspect ratio and centering board
        final maxBoardW = availableWidth - 24.0;
        final maxBoardH = availableHeight - 24.0;

        final cellByW = maxBoardW / board.cols;
        final cellByH = maxBoardH / board.rows;
        final cellSize = math.min(cellByW, cellByH);

        final boardWidth = cellSize * board.cols;
        final boardHeight = cellSize * board.rows;

        return InteractiveViewer(
          transformationController: _transformationController,
          minScale: 1.0,
          maxScale: 3.5,
          boundaryMargin: const EdgeInsets.all(40.0),
          child: Center(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onDoubleTap: _resetZoom,
              onLongPressStart: (_) {
                ref.read(gameControllerProvider.notifier).showGuidance();
              },
              onLongPressEnd: (_) {
                ref.read(gameControllerProvider.notifier).hideGuidance();
              },
              onTapUp: (details) {
                if (gameState.isInteractionBlocked) return;

                final localTap = details.localPosition;
                final tappedArrow = _findHitArrow(
                  tapOffset: localTap,
                  cellSize: cellSize,
                  arrows: board.arrows,
                );

                if (tappedArrow != null) {
                  ref
                      .read(gameControllerProvider.notifier)
                      .onArrowTapped(tappedArrow);
                }
              },
              child: AnimatedBuilder(
                animation: Listenable.merge([
                  _slideController,
                  _shakeController,
                  _hintPulseController,
                ]),
                builder: (context, child) {
                  return RepaintBoundary(
                    child: CustomPaint(
                      size: Size(boardWidth, boardHeight),
                      painter: BoardPainter(
                        board: board,
                        theme: theme,
                        cellSize: cellSize,
                        showDotGrid: gameState.showDotGrid,
                        animatingArrow: gameState.animatingArrow,
                        animationProgress: _slideController.value,
                        shakingArrowId: gameState.shakingArrowId,
                        shakeProgress: _shakeController.value,
                        blockingArrowId: gameState.blockingArrowId,
                        hintedArrowId: gameState.hintedArrowId,
                        hintPulseProgress: _hintPulseController.value,
                        guidanceArrowIds: gameState.guidanceArrowIds,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}
