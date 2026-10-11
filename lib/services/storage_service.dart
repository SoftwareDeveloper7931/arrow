import 'package:shared_preferences/shared_preferences.dart';
import '../logic/game_constants.dart';

/// Handles persistent local storage of game progress, stars, hints, and user preferences.
class StorageService {
  final SharedPreferences _prefs;

  StorageService(this._prefs);

  static const String _keyCurrentLevel = 'arrow_flow_current_level';
  static const String _keyUnlockedLevel = 'arrow_flow_unlocked_level';
  static const String _keyHintCount = 'arrow_flow_hints';
  static const String _keySoundEnabled = 'arrow_flow_sound';
  static const String _keyHapticsEnabled = 'arrow_flow_haptics';
  static const String _keyAdsRemoved = 'arrow_flow_ads_removed';
  static const String _prefixStars = 'arrow_flow_stars_lvl_';

  static Future<StorageService> init() async {
    final prefs = await SharedPreferences.getInstance();
    return StorageService(prefs);
  }

  int getCurrentLevel() {
    return _prefs.getInt(_keyCurrentLevel) ?? 1;
  }

  Future<void> setCurrentLevel(int level) async {
    await _prefs.setInt(_keyCurrentLevel, level);
  }

  int getHighestUnlockedLevel() {
    return _prefs.getInt(_keyUnlockedLevel) ?? 1;
  }

  Future<void> setHighestUnlockedLevel(int level) async {
    final current = getHighestUnlockedLevel();
    if (level > current) {
      await _prefs.setInt(_keyUnlockedLevel, level);
    }
  }

  int getStarsForLevel(int level) {
    return _prefs.getInt('$_prefixStars$level') ?? 0;
  }

  Future<void> setStarsForLevel(int level, int stars) async {
    final currentStars = getStarsForLevel(level);
    // Keep highest stars earned for that level
    if (stars > currentStars) {
      await _prefs.setInt('$_prefixStars$level', stars);
    }
  }

  int getTotalStars() {
    int total = 0;
    final maxLvl = getHighestUnlockedLevel();
    for (int i = 1; i <= maxLvl; i++) {
      total += getStarsForLevel(i);
    }
    return total;
  }

  int getHintCount() {
    return _prefs.getInt(_keyHintCount) ?? GameConstants.defaultHintStock;
  }

  Future<void> setHintCount(int count) async {
    await _prefs.setInt(_keyHintCount, count);
  }

  bool isSoundEnabled() {
    return _prefs.getBool(_keySoundEnabled) ?? true;
  }

  Future<void> setSoundEnabled(bool enabled) async {
    await _prefs.setBool(_keySoundEnabled, enabled);
  }

  bool isHapticsEnabled() {
    return _prefs.getBool(_keyHapticsEnabled) ?? true;
  }

  Future<void> setHapticsEnabled(bool enabled) async {
    await _prefs.setBool(_keyHapticsEnabled, enabled);
  }

  bool isAdsRemoved() {
    return _prefs.getBool(_keyAdsRemoved) ?? false;
  }

  Future<void> setAdsRemoved(bool removed) async {
    await _prefs.setBool(_keyAdsRemoved, removed);
  }

  /// Resets all player progression, returning back to level 1 with default hints.
  Future<void> resetProgress() async {
    final sound = isSoundEnabled();
    final haptics = isHapticsEnabled();
    final ads = isAdsRemoved();

    await _prefs.clear();

    await setSoundEnabled(sound);
    await setHapticsEnabled(haptics);
    await setAdsRemoved(ads);
    await setCurrentLevel(1);
    await setHighestUnlockedLevel(1);
    await setHintCount(GameConstants.defaultHintStock);
  }
}
