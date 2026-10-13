import 'package:hive_flutter/hive_flutter.dart';

import '../api/api_service.dart';
import '../lives/lives_service.dart';
import '../rewards/reward_service.dart';
import '../stats/stats_service.dart';

/// Oturum açan hesabın yerel verisini bulutla eşler.
///
/// İstatistik, ödül ve can kutuları cihaz geneldir. Bu sınıf hangi hesaba
/// ait olduklarını hatırlar; başka bir hesap girince önceki hesabın verisi
/// yeni hesaba geçip onun bulut kaydına yazılmaz.
class AccountSync {
  static const _boxName = 'account';
  static const _ownerKey = 'owner_uid';

  final ApiService api;
  final StatsService stats;
  final RewardService rewards;
  final LivesService lives;
  late Box _box;

  AccountSync({
    required this.api,
    required this.stats,
    required this.rewards,
    required this.lives,
  });

  Future<void> init() async {
    _box = await Hive.openBox(_boxName);
  }

  Future<void> onSignedIn(String uid) async {
    _detach();

    final owner = _box.get(_ownerKey) as String?;
    // owner == null: cihaz bu sürümden önce kullanılmış. Verinin giren
    // hesaba ait olduğunu varsay; silmek tek kopyayı kaybettirebilir.
    if (owner != null && owner != uid) {
      await stats.clearAccountData();
      await rewards.resetRewards();
      lives.refillLives();
    }
    await _box.put(_ownerKey, uid);

    switch (await api.fetchUserData()) {
      case UserDataFound(:final data):
        await stats.loadFromCloud(data['stats'] as Map<String, dynamic>?);
        await rewards.loadFromCloud(data['rewards'] as Map<String, dynamic>?);
        await lives.loadFromCloud(data['lives']);
        _attach();
      case UserDataMissing():
        _attach();
      case UserDataUnavailable():
        // Buluttaki veri bilinmeden senkron açılırsa yerel (belki boş) veri
        // onu ezer. Bu oturumda yalnızca yerelde çalışılır; bir sonraki
        // açılışta yeniden denenir.
        break;
    }
  }

  void onSignedOut() => _detach();

  /// Hesap silindi: cihazdaki verisi de silinir.
  Future<void> onAccountDeleted() async {
    _detach();
    await stats.clearAccountData();
    await rewards.resetRewards();
    lives.refillLives();
    await _box.delete(_ownerKey);
  }

  void _attach() {
    stats.setCloudSync(api);
    rewards.setCloudSync(api);
    lives.setCloudSync(api);
  }

  void _detach() {
    stats.clearCloudSync();
    rewards.clearCloudSync();
    lives.clearCloudSync();
  }
}
