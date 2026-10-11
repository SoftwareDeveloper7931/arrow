import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../state/providers.dart';
import '../../theme/app_colors.dart';
import 'arrow_tile.dart';

/// Renders the responsive square puzzle board and hosts arrow interactions.
class BoardWidget extends ConsumerWidget {
  const BoardWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gameState = ref.watch(gameControllerProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return LayoutBuilder(
      builder: (context, constraints) {
        // Guarantee square aspect ratio with comfortable padding
        final availableSize = math.min(constraints.maxWidth, constraints.maxHeight);
        final boardSize = math.max(100.0, availableSize - 16.0);
        final gridSize = gameState.level.size;
        final cellSize = boardSize / gridSize;

        return Center(
          child: GestureDetector(
            onLongPressStart: (_) {
              ref.read(gameControllerProvider.notifier).showGuidance();
            },
            onLongPressEnd: (_) {
              ref.read(gameControllerProvider.notifier).hideGuidance();
            },
            child: Container(
              width: boardSize,
              height: boardSize,
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkGridBg : AppColors.lightGridBg,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: isDark
                        ? Colors.black.withValues(alpha: 0.4)
                        : Colors.black.withValues(alpha: 0.04),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // Subtle empty cell background markers
                  CustomPaint(
                    size: Size(boardSize, boardSize),
                    painter: _GridBackgroundPainter(
                      gridSize: gridSize,
                      cellSize: cellSize,
                      dotColor: isDark
                          ? AppColors.darkCellEmpty
                          : AppColors.lightCellEmpty,
                    ),
                  ),

                  // Active arrows
                  for (final arrow in gameState.board.arrows)
                    Positioned(
                      left: arrow.col * cellSize,
                      top: arrow.row * cellSize,
                      width: cellSize,
                      height: cellSize,
                      child: ArrowTile(
                        key: ValueKey(arrow.id),
                        arrow: arrow,
                        cellSize: cellSize,
                        isAnimatingSlide:
                            gameState.animatingArrowId == arrow.id,
                        isShaking: gameState.shakingArrowId == arrow.id,
                        isBlocker: gameState.blockingArrowId == arrow.id,
                        isHinted: gameState.hintedArrowId == arrow.id,
                        isGuidance:
                            gameState.guidanceArrowIds.contains(arrow.id),
                        onTap: () {
                          ref
                              .read(gameControllerProvider.notifier)
                              .onArrowTapped(arrow);
                        },
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Draws subtle rounded square cell placeholders on the background.
class _GridBackgroundPainter extends CustomPainter {
  final int gridSize;
  final double cellSize;
  final Color dotColor;

  _GridBackgroundPainter({
    required this.gridSize,
    required this.cellSize,
    required this.dotColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = dotColor.withValues(alpha: 0.45)
      ..style = PaintingStyle.fill;

    final dotRadius = (cellSize * 0.08).clamp(2.0, 5.0);

    for (int r = 0; r < gridSize; r++) {
      for (int c = 0; c < gridSize; c++) {
        final center = Offset(
          c * cellSize + cellSize / 2,
          r * cellSize + cellSize / 2,
        );
        canvas.drawCircle(center, dotRadius, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _GridBackgroundPainter oldDelegate) {
    return oldDelegate.gridSize != gridSize ||
        oldDelegate.cellSize != cellSize ||
        oldDelegate.dotColor != dotColor;
  }
}
