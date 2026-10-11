import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../../logic/game_constants.dart';
import '../../models/arrow.dart';
import '../../theme/app_colors.dart';
import 'arrow_painter.dart';

/// Individual interactive arrow tile with slide-off, shake, hint, and blocker animations.
class ArrowTile extends StatefulWidget {
  final Arrow arrow;
  final double cellSize;
  final bool isAnimatingSlide;
  final bool isShaking;
  final bool isBlocker;
  final bool isHinted;
  final bool isGuidance;
  final VoidCallback onTap;

  const ArrowTile({
    super.key,
    required this.arrow,
    required this.cellSize,
    required this.isAnimatingSlide,
    required this.isShaking,
    required this.isBlocker,
    required this.isHinted,
    required this.isGuidance,
    required this.onTap,
  });

  @override
  State<ArrowTile> createState() => _ArrowTileState();
}

class _ArrowTileState extends State<ArrowTile> with TickerProviderStateMixin {
  late AnimationController _slideController;
  late Animation<double> _slideAnimation;
  late Animation<double> _fadeAnimation;

  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    // Slide-off animation
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: GameConstants.slideDurationMs),
    );
    _slideAnimation = CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeInQuad,
    );
    _fadeAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _slideController,
        curve: const Interval(0.5, 1.0, curve: Curves.easeOut),
      ),
    );

    // Shake animation
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: GameConstants.shakeDurationMs),
    );
    _shakeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.linear),
    );

    // Subtle pulse animation (hints / guidance)
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: GameConstants.hintPulseDurationMs),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.96, end: 1.06).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    if (widget.isAnimatingSlide) {
      _slideController.forward();
    }
  }

  @override
  void didUpdateWidget(covariant ArrowTile oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (!oldWidget.isAnimatingSlide && widget.isAnimatingSlide) {
      _slideController.forward(from: 0.0);
    }

    if (!oldWidget.isShaking && widget.isShaking) {
      _shakeController.forward(from: 0.0);
    }

    if (!oldWidget.isHinted && widget.isHinted) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _slideController.dispose();
    _shakeController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = AppColors.getArrowColor(widget.arrow.colorVariant, isDark);

    // Determine outline and glow
    Color tileBg = isDark ? const Color(0xFF1E222B) : Colors.white;
    Color strokeColor = Colors.transparent;
    Color? glowColor;

    if (widget.isBlocker) {
      tileBg = AppColors.blockerRed.withValues(alpha: isDark ? 0.35 : 0.2);
      strokeColor = AppColors.blockerRed;
      glowColor = AppColors.blockerRed;
    } else if (widget.isHinted) {
      strokeColor = AppColors.hintGold;
      glowColor = AppColors.hintGold;
      tileBg = AppColors.hintGold.withValues(alpha: isDark ? 0.25 : 0.15);
    } else if (widget.isGuidance) {
      strokeColor = AppColors.guidanceGreen;
      glowColor = AppColors.guidanceGreen;
      tileBg = AppColors.guidanceGreen.withValues(alpha: isDark ? 0.22 : 0.12);
    }

    return AnimatedBuilder(
      animation: Listenable.merge([
        _slideController,
        _shakeController,
        _pulseController,
      ]),
      builder: (context, child) {
        // Slide translation
        final slideDist = _slideAnimation.value * (widget.cellSize * 3.5);
        final dxSlide = widget.arrow.direction.dCol * slideDist;
        final dySlide = widget.arrow.direction.dRow * slideDist;

        // Shake offset: damped sine oscillation
        double dxShake = 0.0;
        if (_shakeController.isAnimating) {
          final t = _shakeAnimation.value;
          final amplitude = (1.0 - t) * (widget.cellSize * 0.15);
          dxShake = math.sin(t * math.pi * 5) * amplitude;
        }

        // Pulse scale
        final scale = (widget.isHinted || widget.isGuidance)
            ? _pulseAnimation.value
            : 1.0;

        final opacity = _fadeAnimation.value.clamp(0.0, 1.0);

        return Transform.translate(
          offset: Offset(dxSlide + dxShake, dySlide),
          child: Transform.scale(
            scale: scale,
            child: Opacity(
              opacity: opacity,
              child: child,
            ),
          ),
        );
      },
      child: GestureDetector(
        onTap: widget.onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          margin: EdgeInsets.all(widget.cellSize * 0.06),
          decoration: BoxDecoration(
            color: tileBg,
            borderRadius: BorderRadius.circular(widget.cellSize * 0.24),
            border: Border.all(
              color: strokeColor != Colors.transparent
                  ? strokeColor
                  : (isDark ? const Color(0xFF2E3442) : const Color(0xFFE2E8F0)),
              width: (widget.isHinted || widget.isBlocker || widget.isGuidance)
                  ? 2.5
                  : 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: glowColor != null
                    ? glowColor.withValues(alpha: 0.35)
                    : (isDark
                        ? Colors.black.withValues(alpha: 0.3)
                        : Colors.black.withValues(alpha: 0.06)),
                blurRadius: glowColor != null ? 8 : 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: CustomPaint(
            size: Size(widget.cellSize, widget.cellSize),
            painter: ArrowPainter(
              direction: widget.arrow.direction,
              color: (widget.isBlocker)
                  ? AppColors.blockerRed
                  : (widget.isHinted ? AppColors.hintGold : baseColor),
              isHighlighted: widget.isHinted || widget.isGuidance,
              glowColor: glowColor,
            ),
          ),
        ),
      ),
    );
  }
}
