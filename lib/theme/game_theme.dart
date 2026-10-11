import 'package:flutter/material.dart';

enum GameThemeType {
  eyeComfort,
  dark,
  paper,
  sepia,
}

/// Dynamic game theme holding colors for the minimalist line-arrow board and HUD.
class GameTheme {
  final GameThemeType type;
  final String name;
  final Color backgroundColor;
  final Color lineColor;
  final Color gridDotColor;
  final Color textPrimaryColor;
  final Color textSecondaryColor;
  final Color waterDropActiveColor;
  final Color waterDropInactiveColor;
  final Color hintColor;
  final Color guidanceColor;
  final Color errorFlashColor;
  final Color cardColor;

  const GameTheme({
    required this.type,
    required this.name,
    required this.backgroundColor,
    required this.lineColor,
    required this.gridDotColor,
    required this.textPrimaryColor,
    required this.textSecondaryColor,
    required this.waterDropActiveColor,
    required this.waterDropInactiveColor,
    required this.hintColor,
    required this.guidanceColor,
    required this.errorFlashColor,
    required this.cardColor,
  });

  /// Default Eye Comfort Theme (Warm cream background with dark brown thin lines)
  static const eyeComfort = GameTheme(
    type: GameThemeType.eyeComfort,
    name: 'Eye Comfort',
    backgroundColor: Color(0xFFF5EFEB),
    lineColor: Color(0xFF2C1E18),
    gridDotColor: Color(0xFFDCD2C7),
    textPrimaryColor: Color(0xFF2C1E18),
    textSecondaryColor: Color(0xFF7D6C63),
    waterDropActiveColor: Color(0xFF3880FF),
    waterDropInactiveColor: Color(0xFFD6CBC2),
    hintColor: Color(0xFFD97706),
    guidanceColor: Color(0xFF059669),
    errorFlashColor: Color(0xFFDC2626),
    cardColor: Color(0xFFEBE3DD),
  );

  /// Dark Theme (Deep near-black with soft luminous lines)
  static const dark = GameTheme(
    type: GameThemeType.dark,
    name: 'Dark',
    backgroundColor: Color(0xFF14171E),
    lineColor: Color(0xFF7DD3FC),
    gridDotColor: Color(0xFF262C38),
    textPrimaryColor: Color(0xFFF1F5F9),
    textSecondaryColor: Color(0xFF94A3B8),
    waterDropActiveColor: Color(0xFF60A5FA),
    waterDropInactiveColor: Color(0xFF334155),
    hintColor: Color(0xFFFBBF24),
    guidanceColor: Color(0xFF34D399),
    errorFlashColor: Color(0xFFF87171),
    cardColor: Color(0xFF1E232E),
  );

  /// Paper Theme (Crisp book white with deep charcoal lines)
  static const paper = GameTheme(
    type: GameThemeType.paper,
    name: 'Paper',
    backgroundColor: Color(0xFFFAF9F6),
    lineColor: Color(0xFF212529),
    gridDotColor: Color(0xFFE2E4E8),
    textPrimaryColor: Color(0xFF212529),
    textSecondaryColor: Color(0xFF6C757D),
    waterDropActiveColor: Color(0xFF2563EB),
    waterDropInactiveColor: Color(0xFFDEE2E6),
    hintColor: Color(0xFFEA580C),
    guidanceColor: Color(0xFF16A34A),
    errorFlashColor: Color(0xFFE11D48),
    cardColor: Color(0xFFF1F0EC),
  );

  /// Sepia Theme (Vintage parchment with warm rich umber lines)
  static const sepia = GameTheme(
    type: GameThemeType.sepia,
    name: 'Sepia',
    backgroundColor: Color(0xFFEFE2D0),
    lineColor: Color(0xFF4A3425),
    gridDotColor: Color(0xFFD5C4B0),
    textPrimaryColor: Color(0xFF4A3425),
    textSecondaryColor: Color(0xFF866F5E),
    waterDropActiveColor: Color(0xFF2B7FFF),
    waterDropInactiveColor: Color(0xFFCFBDAA),
    hintColor: Color(0xFFB45309),
    guidanceColor: Color(0xFF047857),
    errorFlashColor: Color(0xFFB91C1C),
    cardColor: Color(0xFFE3D4C0),
  );

  static GameTheme getByType(GameThemeType type) {
    switch (type) {
      case GameThemeType.eyeComfort:
        return eyeComfort;
      case GameThemeType.dark:
        return dark;
      case GameThemeType.paper:
        return paper;
      case GameThemeType.sepia:
        return sepia;
    }
  }

  static GameTheme fromName(String name) {
    return GameThemeType.values
        .map(getByType)
        .firstWhere((t) => t.name == name, orElse: () => eyeComfort);
  }
}
