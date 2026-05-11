import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdService {
  // TEST ID — üretimde gerçek ad unit ID ile değiştir
  static const String _rewardedAdUnitId =
      'ca-app-pub-3940256099942544/5224354917';

  RewardedAd? _rewardedAd;
  bool _isLoaded = false;

  bool get isLoaded => _isLoaded;

  Future<void> loadRewardedAd() async {
    await RewardedAd.load(
      adUnitId: _rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
          _isLoaded = true;
        },
        onAdFailedToLoad: (error) {
          debugPrint('RewardedAd yüklenemedi: $error');
          _isLoaded = false;
        },
      ),
    );
  }

  Future<bool> showRewardedAd({required VoidCallback onRewarded}) async {
    if (!_isLoaded || _rewardedAd == null) return false;

    _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _rewardedAd = null;
        _isLoaded = false;
        loadRewardedAd(); // sonraki için önceden yükle
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        _rewardedAd = null;
        _isLoaded = false;
      },
    );

    await _rewardedAd!.show(
      onUserEarnedReward: (_, __) => onRewarded(),
    );
    return true;
  }
}