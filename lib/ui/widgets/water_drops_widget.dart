import 'package:flutter/material.dart';
import '../../theme/game_theme.dart';

/// Renders the 3 water-drop lives indicator in the HUD.
/// Active drops are vivid blue; lost drops become faded/empty.
class WaterDropsWidget extends StatelessWidget {
  final int remainingDrops;
  final int totalDrops;
  final GameTheme theme;

  const WaterDropsWidget({
    super.key,
    required this.remainingDrops,
    this.totalDrops = 3,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(totalDrops, (index) {
        final isActive = index < remainingDrops;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4.0),
          child: AnimatedScale(
            scale: isActive ? 1.0 : 0.85,
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutBack,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              transitionBuilder: (child, animation) => FadeTransition(
                opacity: animation,
                child: child,
              ),
              child: Icon(
                isActive ? Icons.water_drop : Icons.water_drop_outlined,
                key: ValueKey('drop_${index}_$isActive'),
                color: isActive
                    ? theme.waterDropActiveColor
                    : theme.waterDropInactiveColor,
                size: 26,
              ),
            ),
          ),
        );
      }),
    );
  }
}
