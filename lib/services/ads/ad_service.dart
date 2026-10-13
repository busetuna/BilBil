import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'ad_pacing.dart';

/// Ödüllü reklamın sonucu.
enum RewardedResult {
  /// Reklam sonuna kadar izlendi; ödül verilebilir.
  earned,

  /// Reklam açıldı ama ödül kazanılmadan kapatıldı.
  skipped,

  /// Reklam yok (yüklenemedi, internet yok ya da platform desteklemiyor).
  unavailable,
}

/// AdMob reklamları: moladaki ödüllü reklam ve quiz bitişindeki geçiş reklamı.
///
/// Uygulama 2–5 yaş çocuklara yönelik olduğu için her istek "çocuğa yönelik"
/// işaretlenir: AdMob kişiselleştirilmiş reklam göstermez, içerik G
/// derecesiyle sınırlanır. Geçiş reklamının sıklığını [AdPacing] sınırlar.
///
/// Debug/profile derlemelerinde Google'ın test reklamları, release
/// derlemesinde BilBil'in gerçek reklam birimleri kullanılır: geliştirirken
/// gerçek reklama dokunmak AdMob hesabını askıya aldırabilir. Gerekirse
/// derlemede değiştirilebilir:
///   flutter build apk --dart-define=ADMOB_REWARDED_ANDROID=ca-app-pub-xxx/yyy
/// Uygulama kimliği ayrıca AndroidManifest.xml ve ios/Runner/Info.plist'te.
class AdService extends ChangeNotifier {
  static const _testRewardedAndroid = 'ca-app-pub-3940256099942544/5224354917';
  static const _testRewardedIos = 'ca-app-pub-3940256099942544/1712485313';
  static const _testInterstitialAndroid =
      'ca-app-pub-3940256099942544/1033173712';
  static const _testInterstitialIos = 'ca-app-pub-3940256099942544/4411468910';

  // AdMob → BilBil (Android)
  static const _bilbilRewardedAndroid =
      'ca-app-pub-9093997172830553/8158551336'; // "Mola - can doldur"
  static const _bilbilInterstitialAndroid =
      'ca-app-pub-9093997172830553/3596314787'; // "Quiz sonu"

  static const _rewardedAndroid = String.fromEnvironment(
    'ADMOB_REWARDED_ANDROID',
    defaultValue: kReleaseMode ? _bilbilRewardedAndroid : _testRewardedAndroid,
  );
  static const _interstitialAndroid = String.fromEnvironment(
    'ADMOB_INTERSTITIAL_ANDROID',
    defaultValue: kReleaseMode
        ? _bilbilInterstitialAndroid
        : _testInterstitialAndroid,
  );
  // iOS için AdMob'da henüz uygulama yok; o eklenene kadar test reklamları.
  static const _rewardedIos = String.fromEnvironment(
    'ADMOB_REWARDED_IOS',
    defaultValue: _testRewardedIos,
  );
  static const _interstitialIos = String.fromEnvironment(
    'ADMOB_INTERSTITIAL_IOS',
    defaultValue: _testInterstitialIos,
  );

  static const _request = AdRequest(nonPersonalizedAds: true);

  final AdPacing pacing;

  AdService({AdPacing? pacing}) : pacing = pacing ?? AdPacing();

  RewardedAd? _rewardedAd;
  InterstitialAd? _interstitialAd;
  bool _loadingRewarded = false;
  bool _loadingInterstitial = false;
  bool _initialized = false;

  /// Reklamlar yalnızca Android ve iOS'ta var (testlerde ve masaüstünde yok).
  bool get isSupported => !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  bool get isLoaded => _rewardedAd != null;

  /// Açılışta bir kez çağrılır; beklenmesi gerekmez.
  Future<void> init() async {
    if (!isSupported || _initialized) return;
    _initialized = true;
    try {
      await pacing.init();
      await MobileAds.instance.updateRequestConfiguration(
        RequestConfiguration(
          tagForChildDirectedTreatment: TagForChildDirectedTreatment.yes,
          tagForUnderAgeOfConsent: TagForUnderAgeOfConsent.yes,
          maxAdContentRating: MaxAdContentRating.g,
        ),
      );
      await MobileAds.instance.initialize();
      preload();
      preloadInterstitial();
    } catch (e) {
      debugPrint('AdService.init: $e');
    }
  }

  // ── Ödüllü (mola) ──────────────────────────────────────────────────────────

  /// Bir sonraki gösterim için ödüllü reklamı önceden yükler.
  void preload() {
    if (!isSupported ||
        !_initialized ||
        _loadingRewarded ||
        _rewardedAd != null) {
      return;
    }
    _loadingRewarded = true;
    RewardedAd.load(
      adUnitId: Platform.isIOS ? _rewardedIos : _rewardedAndroid,
      request: _request,
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _loadingRewarded = false;
          _rewardedAd = ad;
          notifyListeners();
        },
        onAdFailedToLoad: (error) {
          _loadingRewarded = false;
          debugPrint('RewardedAd yüklenemedi: $error');
          notifyListeners();
        },
      ),
    );
  }

  /// Ödüllü reklamı gösterir ve kapanana kadar bekler.
  Future<RewardedResult> showRewarded() async {
    final ad = _rewardedAd;
    if (!isSupported || ad == null) {
      preload();
      return RewardedResult.unavailable;
    }
    _rewardedAd = null;

    final result = Completer<RewardedResult>();
    var earned = false;
    void finish(RewardedResult r) {
      if (!result.isCompleted) result.complete(r);
      preload();
    }

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (_) => pacing.markFullScreenShown(),
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        finish(earned ? RewardedResult.earned : RewardedResult.skipped);
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        debugPrint('RewardedAd gösterilemedi: $error');
        ad.dispose();
        finish(RewardedResult.unavailable);
      },
    );
    try {
      await ad.show(onUserEarnedReward: (_, _) => earned = true);
    } catch (e) {
      debugPrint('RewardedAd.show: $e');
      ad.dispose();
      finish(RewardedResult.unavailable);
    }
    return result.future;
  }

  // ── Geçiş (quiz bitişi) ────────────────────────────────────────────────────

  void preloadInterstitial() {
    if (!isSupported ||
        !_initialized ||
        _loadingInterstitial ||
        _interstitialAd != null) {
      return;
    }
    _loadingInterstitial = true;
    InterstitialAd.load(
      adUnitId: Platform.isIOS ? _interstitialIos : _interstitialAndroid,
      request: _request,
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _loadingInterstitial = false;
          _interstitialAd = ad;
        },
        onAdFailedToLoad: (error) {
          _loadingInterstitial = false;
          debugPrint('InterstitialAd yüklenemedi: $error');
        },
      ),
    );
  }

  /// Çocuk quiz'den kendi isteğiyle çıkarken çağrılır. Sıklık kuralları
  /// ([AdPacing]) izin verir ve reklam hazırsa gösterir; gösterildiyse true.
  Future<bool> showQuizEndAd({required int answersThisSession}) async {
    if (!isSupported || !pacing.canShowQuizEnd(answersThisSession)) {
      return false;
    }
    final ad = _interstitialAd;
    if (ad == null) {
      preloadInterstitial();
      return false;
    }
    _interstitialAd = null;

    final done = Completer<bool>();
    void finish(bool shown) {
      if (!done.isCompleted) done.complete(shown);
      preloadInterstitial();
    }

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (_) => pacing.markFullScreenShown(),
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        finish(true);
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        debugPrint('InterstitialAd gösterilemedi: $error');
        ad.dispose();
        finish(false);
      },
    );
    try {
      await ad.show();
    } catch (e) {
      debugPrint('InterstitialAd.show: $e');
      ad.dispose();
      finish(false);
    }
    return done.future;
  }
}
