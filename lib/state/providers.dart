import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/ads_service.dart';
import '../services/audio_service.dart';
import '../services/storage_service.dart';
import 'game_controller.dart';
import 'game_state.dart';

/// Must be overridden in ProviderScope at startup once SharedPreferences is initialized.
final storageServiceProvider = Provider<StorageService>((ref) {
  throw UnimplementedError('StorageService must be initialized in main()');
});

final audioServiceProvider = Provider<AudioService>((ref) {
  final storage = ref.watch(storageServiceProvider);
  final service = AudioService(
    soundEnabled: storage.isSoundEnabled(),
    hapticsEnabled: storage.isHapticsEnabled(),
  );
  ref.onDispose(() => service.dispose());
  return service;
});

final adsServiceProvider = Provider<AdsService>((ref) {
  final storage = ref.watch(storageServiceProvider);
  return AdsService(storage);
});

final gameControllerProvider =
    StateNotifierProvider<GameController, GameState>((ref) {
  final storage = ref.watch(storageServiceProvider);
  final audio = ref.watch(audioServiceProvider);
  final ads = ref.watch(adsServiceProvider);

  return GameController(
    storageService: storage,
    audioService: audio,
    adsService: ads,
  );
});

/// Theme mode provider (supports light and dark themes)
final themeModeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.system);
