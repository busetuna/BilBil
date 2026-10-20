import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../api/api_service.dart';
import '../learning/word_progress_service.dart';
import '../lives/lives_service.dart';
import '../rewards/reward_service.dart';
import '../stats/stats_service.dart';

/// Oturum açan hesabın yerel verisini bulutla eşler.
///
/// İstatistik, ödül ve can kutuları cihaz geneldir. Bu sınıf hangi hesaba
/// ait olduklarını hatırlar; başka bir hesap girince önceki hesabın verisi
/// yeni hesaba geçip onun bulut kaydına yazılmaz.
///
/// Sunucuya ulaşılamazsa artan aralıklarla yeniden denenir. Bu arada yerelde
/// değişen bir şey olduysa (çocuk internetsiz oynadıysa) bağlantı gelince
/// yerel veri buluta yazılır; buluttaki eski veri onun üstüne yazılmaz.
/// Önceden aynı oturumda hiç yeniden denenmiyor, sonraki açılışta da bulut
/// yerel ilerlemeyi eziyordu. "Buluta yazılmamış değişiklik var" bilgisi
/// cihazda saklanır, uygulama kapanıp açılsa da kaybolmaz.
class AccountSync {
  static const _boxName = 'account';
  static const _ownerKey = 'owner_uid';
  static const _unsyncedKey = 'unsynced_uid';

  static const defaultRetryDelays = [
    Duration(seconds: 30),
    Duration(minutes: 2),
    Duration(minutes: 5),
    Duration(minutes: 10),
  ];

  final ApiService api;
  final StatsService stats;
  final RewardService rewards;
  final LivesService lives;
  final WordProgressService progress;
  final List<Duration> retryDelays;
  late Box _box;

  String? _uid;
  bool _attached = false;
  Timer? _retry;
  int _retryAttempt = 0;

  AccountSync({
    required this.api,
    required this.stats,
    required this.rewards,
    required this.lives,
    required this.progress,
    this.retryDelays = defaultRetryDelays,
  });

  List<ChangeNotifier> get _services => [stats, rewards, lives, progress];

  Future<void> init() async {
    _box = await Hive.openBox(_boxName);
    api.unsynced.addListener(_onApiUnsynced);
  }

  /// Bu hesabın buluta yazılmamış yerel değişikliği var mı.
  @visibleForTesting
  bool get hasUnsyncedChanges => _box.get(_unsyncedKey) == _uid && _uid != null;

  Future<void> onSignedIn(String uid) async {
    _detach();
    _uid = uid;
    _retryAttempt = 0;

    final owner = _box.get(_ownerKey) as String?;
    // owner == null: cihaz bu sürümden önce kullanılmış. Verinin giren
    // hesaba ait olduğunu varsay; silmek tek kopyayı kaybettirebilir.
    if (owner != null && owner != uid) {
      await stats.clearAccountData();
      await rewards.resetRewards();
      lives.refillLives();
      await progress.clearAccountData();
      await _box.delete(_unsyncedKey); // önceki hesabın yazılmamışları gitti
    }
    await _box.put(_ownerKey, uid);
    await _connect(uid);
  }

  Future<void> _connect(String uid) async {
    final result = await api.fetchUserData();
    if (_uid != uid) return; // bu arada çıkış yapıldı ya da hesap değişti
    final localIsNewer = _box.get(_unsyncedKey) == uid;
    switch (result) {
      case UserDataFound(:final data) when !localIsNewer:
        await stats.loadFromCloud(data['stats'] as Map<String, dynamic>?);
        await rewards.loadFromCloud(data['rewards'] as Map<String, dynamic>?);
        await lives.loadFromCloud(data['lives']);
        await progress.loadFromCloud(
          data['wordProgress'] as Map<String, dynamic>?,
        );
        _attach();
      case UserDataFound() || UserDataMissing():
        _attach();
        if (localIsNewer) _pushLocal(uid);
      case UserDataUnavailable():
        // Buluttaki veri bilinmeden senkron açılırsa yerel (belki boş) veri
        // onu ezer. Şimdilik yerelde çalışılır, değişiklikler işaretlenir.
        _watchOffline();
        _scheduleRetry(uid);
    }
  }

  void _scheduleRetry(String uid) {
    _retry?.cancel();
    final delay = retryDelays[min(_retryAttempt++, retryDelays.length - 1)];
    _retry = Timer(delay, () {
      if (_uid == uid && !_attached) _connect(uid);
    });
  }

  void _pushLocal(String uid) {
    stats.pushToCloud();
    rewards.pushToCloud();
    lives.pushToCloud();
    progress.pushToCloud();
    // Hepsi gittiyse işaret kalkar; gidemeyen ApiService'te yeniden denenir.
    api.whenIdle().then((_) {
      if (_uid == uid && !api.unsynced.value) _box.delete(_unsyncedKey);
    });
  }

  // Çevrimdışıyken her yerel değişiklik "buluta yazılmadı" diye işaretlenir.
  void _watchOffline() {
    for (final s in _services) {
      s.removeListener(_markUnsynced);
      s.addListener(_markUnsynced);
    }
  }

  void _markUnsynced() {
    final uid = _uid;
    if (uid != null && !_attached) _box.put(_unsyncedKey, uid);
  }

  // Bağlıyken gönderilemeyen kayıt da işaretlenir (uygulama bu arada
  // kapanabilir); hepsi gidince işaret kalkar.
  void _onApiUnsynced() {
    final uid = _uid;
    if (uid == null || !_attached) return;
    if (api.unsynced.value) {
      _box.put(_unsyncedKey, uid);
    } else if (_box.get(_unsyncedKey) == uid) {
      _box.delete(_unsyncedKey);
    }
  }

  void onSignedOut() {
    _detach();
    _uid = null;
  }

  /// Hesap silindi: cihazdaki verisi de silinir.
  Future<void> onAccountDeleted() async {
    _detach();
    _uid = null;
    await stats.clearAccountData();
    await rewards.resetRewards();
    lives.refillLives();
    await progress.clearAccountData();
    await _box.delete(_ownerKey);
    await _box.delete(_unsyncedKey);
  }

  void _attach() {
    for (final s in _services) {
      s.removeListener(_markUnsynced);
    }
    _attached = true;
    stats.setCloudSync(api);
    rewards.setCloudSync(api);
    lives.setCloudSync(api);
    progress.setCloudSync(api);
  }

  void _detach() {
    _retry?.cancel();
    _retry = null;
    for (final s in _services) {
      s.removeListener(_markUnsynced);
    }
    _attached = false;
    // Eski hesabın bekleyen kayıtları yeni hesaba gitmesin.
    api.discardPending();
    stats.clearCloudSync();
    rewards.clearCloudSync();
    lives.clearCloudSync();
    progress.clearCloudSync();
  }

  @visibleForTesting
  void dispose() {
    _detach();
    api.unsynced.removeListener(_onApiUnsynced);
  }
}
