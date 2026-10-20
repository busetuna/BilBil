import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../api/api_service.dart';

class StatsService extends ChangeNotifier {
  static const _boxName = 'stats';
  late Box _box;

  ApiService? _api;
  final DateTime Function() _now;

  StatsService({DateTime Function()? clock}) : _now = clock ?? DateTime.now;

  Future<void> init() async {
    _box = await Hive.openBox(_boxName);
    _migrateLegacyPin(_box.get('pin') as String?);
  }

  void setCloudSync(ApiService api) => _api = api;

  void clearCloudSync() => _api = null;

  /// Yereldeki durumu olduğu gibi buluta yazar (çevrimdışı değişiklikler).
  void pushToCloud() => _syncToCloud();

  Future<void> loadFromCloud(Map<String, dynamic>? data) async {
    if (data == null) return;
    await _box.put(
      'totalCorrect',
      (data['totalCorrect'] as num?)?.toInt() ?? 0,
    );
    await _box.put('totalWrong', (data['totalWrong'] as num?)?.toInt() ?? 0);
    await _box.put(
      'difficultyHistory',
      List<int>.from((data['difficultyHistory'] as List? ?? [])),
    );
    await _box.put(
      'startingDifficulty',
      (data['startingDifficulty'] as num?)?.toInt() ?? 0,
    );
    // Bulutta PIN yoksa (hiç senkronlanmamış) yereldeki korunur.
    final pinHash = data['pinHash'] as String?;
    final pinSalt = data['pinSalt'] as String?;
    if (pinHash != null && pinSalt != null) {
      await _box.put('pinHash', pinHash);
      await _box.put('pinSalt', pinSalt);
    } else {
      _migrateLegacyPin(data['pin'] as String?);
    }
    await _box.put(
      'totalAsrAttempts',
      (data['totalAsrAttempts'] as num?)?.toInt() ?? 0,
    );
    await _box.put(
      'exactAsrMatches',
      (data['exactAsrMatches'] as num?)?.toInt() ?? 0,
    );
    await _box.put(
      'totalLatencyMs',
      (data['totalLatencyMs'] as num?)?.toInt() ?? 0,
    );
    await _box.put(
      'latencyHistory',
      List<int>.from((data['latencyHistory'] as List? ?? [])),
    );
    await _box.put(
      'categoryWrong',
      Map<String, int>.from(
        (data['categoryWrong'] as Map? ?? {}).map(
          (k, v) => MapEntry(k.toString(), (v as num).toInt()),
        ),
      ),
    );
    await _box.put(
      'categoryTotal',
      Map<String, int>.from(
        (data['categoryTotal'] as Map? ?? {}).map(
          (k, v) => MapEntry(k.toString(), (v as num).toInt()),
        ),
      ),
    );
    await _box.put('childAge', (data['childAge'] as num?)?.toInt() ?? 3);
    final rl = data['rlAgent'];
    if (rl is Map) {
      await _box.put('rlAgent', Map<String, dynamic>.from(rl));
    } else {
      await _box.delete('rlAgent');
    }
    notifyListeners();
  }

  void _syncToCloud() {
    _api?.saveStats({
      'totalCorrect': totalCorrect,
      'totalWrong': totalWrong,
      'difficultyHistory': difficultyHistory,
      'startingDifficulty': startingDifficulty,
      'pinHash': _box.get('pinHash'),
      'pinSalt': _box.get('pinSalt'),
      'totalAsrAttempts': totalAsrAttempts,
      'exactAsrMatches': exactAsrMatches,
      'totalLatencyMs': totalLatencyMs,
      'latencyHistory': latencyHistory,
      'categoryWrong': categoryWrongCounts,
      'categoryTotal': categoryTotalCounts,
      'childAge': childAge,
      'rlAgent': rlAgentState,
    });
  }

  // ── Okuma ──────────────────────────────────────────────────────────────────

  int get totalCorrect =>
      (_box.get('totalCorrect', defaultValue: 0) as num).toInt();
  int get totalWrong =>
      (_box.get('totalWrong', defaultValue: 0) as num).toInt();
  int get totalAnswers => totalCorrect + totalWrong;
  double get successRate =>
      totalAnswers == 0 ? 0.0 : totalCorrect / totalAnswers;

  // ASR metrics
  int get totalAsrAttempts =>
      (_box.get('totalAsrAttempts', defaultValue: 0) as num).toInt();
  int get exactAsrMatches =>
      (_box.get('exactAsrMatches', defaultValue: 0) as num).toInt();
  int get totalLatencyMs =>
      (_box.get('totalLatencyMs', defaultValue: 0) as num).toInt();
  double get asrAccuracy =>
      totalAsrAttempts == 0 ? 0.0 : exactAsrMatches / totalAsrAttempts;
  double get avgLatencyMs =>
      totalAsrAttempts == 0 ? 0.0 : totalLatencyMs / totalAsrAttempts;

  List<int> get latencyHistory {
    final raw = _box.get('latencyHistory');
    if (raw == null) return [];
    return List<int>.from(raw as List);
  }

  Map<String, int> get categoryWrongCounts {
    final raw = _box.get('categoryWrong');
    if (raw == null) return {};
    return Map<String, int>.from(raw as Map);
  }

  Map<String, int> get categoryTotalCounts {
    final raw = _box.get('categoryTotal');
    if (raw == null) return {};
    return Map<String, int>.from(raw as Map);
  }

  List<int> get difficultyHistory {
    final raw = _box.get('difficultyHistory');
    if (raw == null) return [];
    return List<int>.from(raw as List);
  }

  int get startingDifficulty =>
      (_box.get('startingDifficulty', defaultValue: 0) as num).toInt();

  /// Zorluk ajanının öğrendikleri ve son seviyesi (bkz. RLAgent.toJson).
  Map<String, dynamic>? get rlAgentState {
    final raw = _box.get('rlAgent');
    return raw is Map ? Map<String, dynamic>.from(raw) : null;
  }

  // ── Yazma ──────────────────────────────────────────────────────────────────

  void recordAnswer({
    required bool correct,
    required int difficulty,
    Map<String, dynamic>? rlState,
  }) {
    _box.put('totalCorrect', totalCorrect + (correct ? 1 : 0));
    if (rlState != null) _box.put('rlAgent', rlState);
    _box.put('totalWrong', totalWrong + (correct ? 0 : 1));

    final history = difficultyHistory;
    history.add(difficulty);
    if (history.length > 300) history.removeAt(0);
    _box.put('difficultyHistory', history);

    _syncToCloud();
    notifyListeners();
  }

  void recordAsrResult({required bool isMatch, required int latencyMs}) {
    _box.put('totalAsrAttempts', totalAsrAttempts + 1);
    if (isMatch) _box.put('exactAsrMatches', exactAsrMatches + 1);
    _box.put('totalLatencyMs', totalLatencyMs + latencyMs);

    final lHistory = latencyHistory;
    lHistory.add(latencyMs);
    if (lHistory.length > 300) lHistory.removeAt(0);
    _box.put('latencyHistory', lHistory);

    _syncToCloud();
    notifyListeners();
  }

  void recordCategoryAnswer({required String category, required bool correct}) {
    final totals = categoryTotalCounts;
    totals[category] = (totals[category] ?? 0) + 1;
    _box.put('categoryTotal', totals);

    if (!correct) {
      final wrongs = categoryWrongCounts;
      wrongs[category] = (wrongs[category] ?? 0) + 1;
      _box.put('categoryWrong', wrongs);
    }
    notifyListeners();
  }

  // ── Ebeveyn PIN'i ─────────────────────────────────────────────────────────
  // PIN düz metin saklanmaz: rastgele tuzla SHA-256 özeti tutulur ve buluta
  // da özet gider (PIN diğer cihazlarda da geçerli olsun diye). 4 haneli bir
  // PIN'in özeti kaba kuvvetle çözülebilir; asıl koruma deneme sınırıdır.

  static const maxPinAttempts = 5;
  static const pinLockDuration = Duration(seconds: 30);

  /// Ebeveyn bir PIN belirlemiş mi? Değilse PIN ekranı önce PIN belirletir.
  bool get hasPin => _box.get('pinHash') != null && _box.get('pinSalt') != null;

  static String _hashPin(String pin, String salt) =>
      sha256.convert(utf8.encode('$salt:$pin')).toString();

  static String _newSalt() {
    final rng = Random.secure();
    return List.generate(
      16,
      (_) => rng.nextInt(256).toRadixString(16).padLeft(2, '0'),
    ).join();
  }

  void _storePin(String pin) {
    final salt = _newSalt();
    _box.put('pinSalt', salt);
    _box.put('pinHash', _hashPin(pin, salt));
    _box.delete('pin');
    _resetPinFailures();
  }

  /// Eski sürümler PIN'i düz metin saklıyordu: özete çevir. Varsayılan
  /// '1234' "PIN belirlenmemiş" sayılır, ebeveynden yenisi istenir.
  void _migrateLegacyPin(String? legacy) {
    if (legacy == null) return;
    _box.delete('pin');
    if (legacy != '1234' && !hasPin) _storePin(legacy);
  }

  void changePin(String newPin) {
    _storePin(newPin);
    _syncToCloud();
    notifyListeners();
  }

  /// PIN'ini unutan ebeveyn için; hesap şifresi doğrulandıktan sonra
  /// çağrılır. Sonraki girişte yeni PIN belirletilir.
  void clearPin() {
    _box.delete('pinHash');
    _box.delete('pinSalt');
    _box.delete('pin');
    _resetPinFailures();
    _syncToCloud();
    notifyListeners();
  }

  /// Kilitliyse kalan süre, değilse null.
  Duration? get pinLockRemaining {
    final until = _box.get('pinLockedUntil') as int?;
    if (until == null) return null;
    final left = DateTime.fromMillisecondsSinceEpoch(until).difference(_now());
    return left > Duration.zero ? left : null;
  }

  /// Art arda [maxPinAttempts] yanlıştan sonra PIN [pinLockDuration] boyunca
  /// kilitlenir; kilit uygulama kapatılsa da sürer.
  bool verifyPin(String entered) {
    if (!hasPin || pinLockRemaining != null) return false;
    final salt = _box.get('pinSalt') as String;
    if (_hashPin(entered, salt) == _box.get('pinHash')) {
      _resetPinFailures();
      return true;
    }
    final failures = ((_box.get('pinFailures') as int?) ?? 0) + 1;
    if (failures >= maxPinAttempts) {
      _box.delete('pinFailures');
      _box.put(
        'pinLockedUntil',
        _now().add(pinLockDuration).millisecondsSinceEpoch,
      );
    } else {
      _box.put('pinFailures', failures);
    }
    notifyListeners();
    return false;
  }

  /// Kilitlenmeden önce kalan deneme hakkı.
  int get pinAttemptsLeft =>
      maxPinAttempts - ((_box.get('pinFailures') as int?) ?? 0);

  void _resetPinFailures() {
    _box.delete('pinFailures');
    _box.delete('pinLockedUntil');
  }

  /// Ebeveynin seçimi: bir sonraki quiz bu seviyeden başlar (ajanın
  /// kaldığı seviye unutulur, öğrendikleri kalır).
  void setStartingDifficulty(int diff) {
    _box.put('startingDifficulty', diff.clamp(0, 2));
    final rl = rlAgentState;
    if (rl != null) _box.put('rlAgent', rl..remove('level'));
    _syncToCloud();
    notifyListeners();
  }

  // ── Çocuk yaşı ────────────────────────────────────────────────────────────
  /// 2–5 arası yaş. Yaşa göre RL agent'ın erişebileceği zorluk seviyesi kısıtlanır.
  int get childAge => (_box.get('childAge', defaultValue: 3) as num).toInt();

  void setChildAge(int age) {
    _box.put('childAge', age.clamp(2, 5));
    _syncToCloud();
    notifyListeners();
  }

  /// Yaştan maksimum zorluk seviyesi: 2yaş→0, 3yaş→1, 4-5yaş→2
  int get maxDifficultyForAge {
    final age = childAge;
    if (age <= 2) return 0;
    if (age == 3) return 1;
    return 2;
  }

  // ── ASR motor seçimi ───────────────────────────────────────────────────────
  /// 'vosk' veya 'platform'
  String get asrEngine => _box.get('asrEngine', defaultValue: 'vosk') as String;

  void setAsrEngine(String engine) {
    assert(engine == 'vosk' || engine == 'platform');
    _box.put('asrEngine', engine);
    _syncToCloud();
    notifyListeners();
  }

  /// Hesap değişince: önceki hesaba ait her şeyi (PIN, yaş, ayarlar dahil)
  /// siler, cihaz tercihi olan ASR motorunu korur. Buluta yazmaz.
  Future<void> clearAccountData() async {
    final engine = asrEngine;
    await _box.clear();
    await _box.put('asrEngine', engine);
    notifyListeners();
  }

  Future<void> resetStats() async {
    await _box.put('totalCorrect', 0);
    await _box.put('totalWrong', 0);
    await _box.put('difficultyHistory', <int>[]);
    await _box.put('latencyHistory', <int>[]);
    await _box.put('totalAsrAttempts', 0);
    await _box.put('exactAsrMatches', 0);
    await _box.put('totalLatencyMs', 0);
    await _box.put('categoryWrong', <String, int>{});
    await _box.put('categoryTotal', <String, int>{});
    _syncToCloud();
    notifyListeners();
  }
}
