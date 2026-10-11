import 'package:flutter/material.dart';
import '../../logic/game_constants.dart';
import '../../theme/app_colors.dart';

/// Renders the 3 hearts with smooth animated transitions when lost.
class HeartsWidget extends StatelessWidget {
  final int remainingHearts;

  const HeartsWidget({
    super.key,
    required this.remainingHearts,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(GameConstants.maxHearts, (index) {
        final isFilled = index < remainingHearts;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 3.0),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            transitionBuilder: (child, animation) {
              return ScaleTransition(
                scale: animation,
                child: child,
              );
            },
            child: Icon(
              isFilled ? Icons.favorite_rounded : Icons.favorite_outline_rounded,
              key: ValueKey('heart_${index}_$isFilled'),
              color: isFilled
                  ? AppColors.heartRed
                  : (Theme.of(context).brightness == Brightness.dark
                      ? Colors.white24
                      : Colors.black26),
              size: 24,
            ),
          ),
        );
      }),
    );
  }
}
