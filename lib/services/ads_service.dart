import 'package:flutter/foundation.dart';
import '../logic/game_constants.dart';
import 'storage_service.dart';

/// Contract defining ad displays and premium ad-removal status.
abstract class IAdsService {
  bool isRemoveAdsPurchased();
  Future<void> purchaseRemoveAds();
  Future<bool> showInterstitial({required int completedLevelNumber});
  Future<bool> showRewarded({required String placement});
}

/// Mock/test implementation of [IAdsService] adhering to monetization rules.
///
/// Contains explicit `TODO` markers showing where `google_mobile_ads` and
/// `in_app_purchase` integrate in production.
class AdsService implements IAdsService {
  final StorageService _storageService;

  AdsService(this._storageService);

  @override
  bool isRemoveAdsPurchased() {
    return _storageService.isAdsRemoved();
  }

  @override
  Future<void> purchaseRemoveAds() async {
    // TODO: Plug in `in_app_purchase` package here:
    // 1. InAppPurchase.instance.buyNonConsumable(purchaseParam: PurchaseParam(productDetails: productDetails))
    // 2. Listen to purchaseStream and verify receipt with server/store
    // 3. Upon successful transaction:
    await _storageService.setAdsRemoved(true);
    debugPrint('AdsService: "Remove Ads" purchased successfully (Mock).');
  }

  /// Displays an interstitial ad if conditions are satisfied:
  /// - Ads must not be purchased/removed
  /// - Level must be >= minLevelForInterstitial (Level 5)
  /// - Must be every 3 completed levels (e.g. 6, 9, 12...)
  /// - NEVER during gameplay
  @override
  Future<bool> showInterstitial({required int completedLevelNumber}) async {
    if (isRemoveAdsPurchased()) {
      debugPrint('AdsService: Interstitial skipped (ads removed by user).');
      return false;
    }

    if (completedLevelNumber < GameConstants.minLevelForInterstitial) {
      debugPrint('AdsService: Interstitial skipped (level $completedLevelNumber < ${GameConstants.minLevelForInterstitial}).');
      return false;
    }

    if (completedLevelNumber % GameConstants.interstitialLevelFrequency != 0) {
      debugPrint('AdsService: Interstitial skipped (cadence: level $completedLevelNumber).');
      return false;
    }

    // TODO: Plug in `google_mobile_ads` InterstitialAd here:
    // InterstitialAd.load(
    //   adUnitId: 'ca-app-pub-3940256099942544/1033173712', // test ID
    //   request: const AdRequest(),
    //   adLoadCallback: InterstitialAdLoadCallback(
    //     onAdLoaded: (ad) => ad.show(),
    //     onAdFailedToLoad: (error) => debugPrint('Ad failed: $error'),
    //   ),
    // );

    debugPrint('AdsService: [MOCK INTERSTITIAL] Displaying interstitial ad for level $completedLevelNumber completion.');
    return true;
  }

  /// Displays a rewarded video ad (e.g., for extra hints or 2nd-chance hearts).
  /// Returns `true` if reward was earned.
  @override
  Future<bool> showRewarded({required String placement}) async {
    // TODO: Plug in `google_mobile_ads` RewardedAd here:
    // RewardedAd.load(
    //   adUnitId: 'ca-app-pub-3940256099942544/5224354917', // test ID
    //   request: const AdRequest(),
    //   rewardedAdLoadCallback: RewardedAdLoadCallback(
    //     onAdLoaded: (ad) => ad.show(onUserEarnedReward: (ad, reward) => ...),
    //     onAdFailedToLoad: (err) => ...,
    //   ),
    // );

    debugPrint('AdsService: [MOCK REWARDED] Playing rewarded ad for placement: $placement.');
    // In mock mode, simulate successful ad watch
    await Future.delayed(const Duration(milliseconds: 300));
    return true;
  }
}
