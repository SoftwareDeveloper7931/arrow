# Arrow Flow 🏹

A complete, production-quality Android puzzle game built in Flutter & Dart. **Arrow Flow** is an original arrow-clearing puzzle in the style of calm, minimalist casual games.

---

## 🎯 Game Concept & Mechanics

A grid contains rounded arrows pointing in four cardinal directions (Up, Down, Left, Right). The player taps an arrow to slide it off the board. An arrow can only exit if every cell along its pointing direction, up to the board edge, is currently empty. Removing arrows opens lanes for other arrows, so the core challenge is discovering the correct clearance order.

### Core Rules
- **Free Path Exit**: Tapping an arrow with an unobstructed exit slides it off the board with a gentle whoosh sound and haptic response.
- **Blocked Obstruction**: Tapping a blocked arrow triggers a shake animation, flashes the blocking obstacle, plays an error tone with haptic feedback, and deducts 1 heart for that level.
- **Hearts**: Each level starts with 3 hearts. If all 3 hearts are lost, a "Level Failed" dialog offers **Restart** or **Watch Ad to Continue** (+2 hearts revive).
- **Long-Press Guidance**: Holding down anywhere on the board highlights all arrows that currently have a clear path to the edge.
- **Hints**: The hint button highlights one optimal next arrow to tap. Players start with 3 hints, and can earn +2 hints anytime via a rewarded video ad.
- **Star Rating**:
  - ⭐⭐⭐ (3 Stars): Cleared with 0 mistakes (all 3 hearts remaining).
  - ⭐⭐ (2 Stars): Cleared with 1 mistake (2 hearts remaining).
  - ⭐ (1 Star): Cleared with 2 mistakes (1 heart remaining).

---

## 🧠 Level Generation & Mathematical Solvability

Every single level is **100% guaranteed to be solvable** and deterministic.

### Reverse-Placement Algorithm
Rather than trying to generate a random board and hoping it is solvable, `LevelGenerator` builds levels **in reverse**:
1. Starts with an empty grid of size $S \times S$.
2. Places arrows one by one ($A_1, A_2, \dots, A_N$).
3. When placing candidate arrow $A_k$, it must have a clear path out to the board edge with respect only to the previously placed arrows $\{A_1, \dots, A_{k-1}\}$.
4. Candidate selection uses a **dependency bias** that intentionally places arrows in front of already placed arrows, constructing deep, interconnected puzzle chains.
5. In forward gameplay, $A_N$ has no obstacles and can exit first, followed by $A_{N-1}$, all the way down to $A_1$. This yields a guaranteed valid solution order by construction.
6. The generator uses `math.Random(levelNumber * 31337)` so that every level is deterministic, identical across play sessions, and requires zero network requests.
7. Over **300 levels** are supported on demand, with difficulty scaling smoothly from $4 \times 4$ up to $10 \times 10$ grids.
8. An in-code assertion (`assert(Solver.isSolvable(initialBoard))`) and unit tests verify all 300 levels.

---

## 📁 Project Structure

```
arrow_flow/
├── android/                   # Native Android host configuration (portrait locked)
├── assets/
│   └── audio/                 # Sound effects (whoosh, tap, error, win)
├── lib/
│   ├── logic/
│   │   ├── game_constants.dart  # Centralized limits, timings, and ad cadence
│   │   ├── level_generator.dart # Seeded reverse placement level generator
│   │   ├── move_validator.dart  # Raycasting, obstacle detection, exit clearance
│   │   └── solver.dart          # Monotone greedy solver & optimal hint engine
│   ├── models/
│   │   ├── arrow.dart           # Arrow entity, coordinates, direction, color
│   │   ├── board.dart           # 2D cell grid, ray queries, immutable copies
│   │   ├── direction.dart       # Cardinal directions, angles, offsets
│   │   └── level.dart           # Level configuration & star calculation
│   ├── services/
│   │   ├── ads_service.dart     # Ads abstraction (interstitials, rewarded, IAP)
│   │   ├── audio_service.dart   # AudioPlayer & HapticFeedback with graceful fallbacks
│   │   └── storage_service.dart # SharedPreferences for progress, stars & settings
│   ├── state/
│   │   ├── game_controller.dart # Riverpod StateNotifier for game flow & animations
│   │   ├── game_state.dart      # Immutable game state
│   │   └── providers.dart       # Dependency injection & providers
│   ├── theme/
│   │   ├── app_colors.dart      # Calm pastel/neutral light & dark color palettes
│   │   └── app_theme.dart       # Material 3 typography & shape definitions
│   ├── ui/
│   │   ├── dialogs/             # WinDialog, FailDialog, HintRewardDialog
│   │   ├── screens/             # HomeScreen, GameScreen, SettingsScreen
│   │   └── widgets/             # BoardWidget, ArrowTile, ArrowPainter, Hearts, Stars
│   └── main.dart                # App entrypoint, portrait orientation lock, Riverpod scope
└── test/
    ├── logic/
    │   ├── level_generator_test.dart # Solvability test across levels 1–300
    │   ├── move_validator_test.dart  # Raycast & blocker tests
    │   └── solver_test.dart          # Solution order & dead-end detection tests
    └── widget_test.dart              # Home screen UI smoke test
```

---

## 💰 Monetization Hooks (Production Integration Guide)

The game includes a dedicated `AdsService` abstraction (`lib/services/ads_service.dart`) following non-intrusive monetization standards:
- **No ads before level 5**.
- **Never during gameplay** (only after level completion).
- **Interstitial Cadence**: Shown every 3 completed levels (e.g. Levels 6, 9, 12, ...), automatically bypassed if "Remove Ads" is purchased.
- **Rewarded Video Ads**: Available on-demand for +2 hints or to revive on level fail (+2 hearts).

### To plug in `google_mobile_ads`:
1. Add `google_mobile_ads: ^5.2.0` to `pubspec.yaml`.
2. Add your AdMob App ID in `android/app/src/main/AndroidManifest.xml`:
   ```xml
   <meta-data
       android:name="com.google.android.gms.ads.APPLICATION_ID"
       android:value="ca-app-pub-################~##########"/>
   ```
3. In `lib/services/ads_service.dart`, replace the mock calls inside `showInterstitial()` and `showRewarded()` with `InterstitialAd.load` and `RewardedAd.load`.

### To plug in `in_app_purchase`:
1. Add `in_app_purchase: ^3.2.0` to `pubspec.yaml`.
2. In `lib/services/ads_service.dart`, implement `purchaseRemoveAds()` using `InAppPurchase.instance.buyNonConsumable()` targeting product ID `remove_ads`.
3. When the purchase completes, call `await _storageService.setAdsRemoved(true)`.

---

## 🚀 Getting Started

### Prerequisites
- Flutter SDK `^3.13.0` (Dart `^3.0.0`)
- Android Studio / Android SDK (API 34+)

### Run Tests
```bash
flutter test
```
All 11 tests will execute, validating `MoveValidator`, `Solver`, `ArrowFlowApp` UI, and confirming **100% solvability for all 300 levels**.

### Run Linter
```bash
flutter analyze
```

### Run Locally on Android Device / Emulator
```bash
flutter run
```

### Build Production Android APK
```bash
flutter build apk --release
```
