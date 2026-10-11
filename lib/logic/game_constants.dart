/// Centralized game configuration constants.
class GameConstants {
  GameConstants._();

  // Core Game Rules
  static const int initialHearts = 3;
  static const int maxHearts = 3;
  static const int minGridSize = 4;
  static const int maxGridSize = 10;
  static const int defaultHintStock = 3;
  static const int rewardedAdHintReward = 2;
  static const int rewardedAdHeartsReward = 2;
  static const int minLevelCount = 300;

  // Animation Timings (in milliseconds)
  static const int slideDurationMs = 280;
  static const int shakeDurationMs = 380;
  static const int blockHighlightDurationMs = 600;
  static const int hintPulseDurationMs = 900;
  static const int guidanceDisplayDurationMs = 1500;
  static const int winCelebrationDelayMs = 350;

  // Monetization Rules
  static const int interstitialLevelFrequency = 3;
  static const int minLevelForInterstitial = 5;

  // Color Variants for Arrows (calm aesthetic palette)
  static const int totalColorVariants = 5;
}
