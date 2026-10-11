import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

/// Animated star rating display for win dialogs and level completion screens.
class StarsDisplay extends StatefulWidget {
  final int stars;
  final double size;

  const StarsDisplay({
    super.key,
    required this.stars,
    this.size = 36.0,
  });

  @override
  State<StarsDisplay> createState() => _StarsDisplayState();
}

class _StarsDisplayState extends State<StarsDisplay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (index) {
        final isFilled = index < widget.stars;
        final delay = index * 0.2;

        final animation = CurvedAnimation(
          parent: _controller,
          curve: Interval(delay, (delay + 0.6).clamp(0.0, 1.0),
              curve: Curves.elasticOut),
        );

        return ScaleTransition(
          scale: animation,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: Icon(
              isFilled ? Icons.star_rounded : Icons.star_outline_rounded,
              color: isFilled ? AppColors.hintGold : Colors.grey.shade400,
              size: widget.size,
              shadows: isFilled
                  ? [
                      BoxShadow(
                        color: AppColors.hintGold.withValues(alpha: 0.4),
                        blurRadius: 10,
                      )
                    ]
                  : null,
            ),
          ),
        );
      }),
    );
  }
}
