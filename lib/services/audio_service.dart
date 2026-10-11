import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Provides audio playback and tactile haptic feedback for game events.
class AudioService {
  AudioPlayer? _player;
  bool soundEnabled;
  bool hapticsEnabled;
  final bool isTestMode;

  AudioService({
    this.soundEnabled = true,
    this.hapticsEnabled = true,
    this.isTestMode = false,
  }) {
    if (!isTestMode) {
      _initPlayer();
    }
  }

  void _initPlayer() {
    try {
      _player = AudioPlayer();
      _player!.setAudioContext(
        AudioContext(
          android: const AudioContextAndroid(
            isSpeakerphoneOn: false,
            stayAwake: false,
            contentType: AndroidContentType.sonification,
            usageType: AndroidUsageType.game,
            audioFocus: AndroidAudioFocus.gainTransientMayDuck,
          ),
          iOS: AudioContextIOS(
            category: AVAudioSessionCategory.ambient,
          ),
        ),
      );
      _player?.setReleaseMode(ReleaseMode.stop);
    } catch (e) {
      debugPrint('AudioService: context init warning: $e');
    }
  }

  /// Plays an asset sound file gracefully without interrupting the game loop if missing.
  Future<void> _playSound(String assetFileName) async {
    if (!soundEnabled || isTestMode || _player == null) return;
    try {
      await _player!.stop();
      await _player!.play(AssetSource('audio/$assetFileName'), volume: 0.6);
    } catch (e) {
      debugPrint('AudioService: Failed to play $assetFileName (handled gracefully): $e');
    }
  }

  /// Gentle whoosh sound when an arrow successfully slides off the board.
  Future<void> playWhoosh() async {
    await _playSound('whoosh.wav');
  }

  /// Subtle soft tap sound.
  Future<void> playTap() async {
    await _playSound('tap.wav');
  }

  /// Low error tone when an arrow tap is blocked.
  Future<void> playError() async {
    await _playSound('error.wav');
  }

  /// Ascending celebratory chime on level win.
  Future<void> playWin() async {
    await _playSound('win.wav');
  }

  /// Success haptic tap when arrow slides off.
  void hapticSuccess() {
    if (!hapticsEnabled) return;
    try {
      HapticFeedback.lightImpact();
    } catch (e) {
      debugPrint('HapticFeedback error: $e');
    }
  }

  /// Gentle error haptic when an arrow is blocked.
  void hapticError() {
    if (!hapticsEnabled) return;
    try {
      HapticFeedback.mediumImpact();
    } catch (e) {
      debugPrint('HapticFeedback error: $e');
    }
  }

  /// Light selection tick for general button clicks.
  void hapticSelection() {
    if (!hapticsEnabled) return;
    try {
      HapticFeedback.selectionClick();
    } catch (e) {
      debugPrint('HapticFeedback error: $e');
    }
  }

  void dispose() {
    _player?.dispose();
  }
}
