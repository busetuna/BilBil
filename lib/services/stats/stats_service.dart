import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../firestore/firestore_service.dart';

class StatsService extends ChangeNotifier {
  static const _boxName = 'stats';
  late Box _box;

  String? _uid;
  FirestoreService? _firestore;

  Future<void> init() async {
    _box = await Hive.openBox(_boxName);
  }

  void setCloudSync(String uid, FirestoreService svc) {
    _uid = uid;
    _firestore = svc;
  }

  void clearCloudSync() {
    _uid = null;
    _firestore = null;
  }

  Future<void> loadFromCloud(Map<String, dynamic>? data) async {
    if (data == null) return;
    await _box.put('totalCorrect', (data['totalCorrect'] as num?)?.toInt() ?? 0);
    await _box.put('totalWrong', (data['totalWrong'] as num?)?.toInt() ?? 0);
    await _box.put('difficultyHistory',
        List<int>.from((data['difficultyHistory'] as List? ?? [])));
    await _box.put('startingDifficulty',
        (data['startingDifficulty'] as num?)?.toInt() ?? 0);
    await _box.put('pin', data['pin'] as String? ?? '1234');
    await _box.put('totalAsrAttempts', (data['totalAsrAttempts'] as num?)?.toInt() ?? 0);
    await _box.put('exactAsrMatches', (data['exactAsrMatches'] as num?)?.toInt() ?? 0);
    await _box.put('totalLatencyMs', (data['totalLatencyMs'] as num?)?.toInt() ?? 0);
    await _box.put('latencyHistory', List<int>.from((data['latencyHistory'] as List? ?? [])));
    await _box.put('categoryWrong', Map<String, int>.from(
        (data['categoryWrong'] as Map? ?? {}).map((k, v) => MapEntry(k.toString(), (v as num).toInt()))));
    await _box.put('categoryTotal', Map<String, int>.from(
        (data['categoryTotal'] as Map? ?? {}).map((k, v) => MapEntry(k.toString(), (v as num).toInt()))));
    await _box.put('childAge', (data['childAge'] as num?)?.toInt() ?? 3);
    notifyListeners();
  }

  void _syncToCloud() {
    final uid = _uid;
    final firestore = _firestore;
    if (uid == null || firestore == null) return;
    firestore.saveStats(uid, {
      'totalCorrect': totalCorrect,
      'totalWrong': totalWrong,
      'difficultyHistory': difficultyHistory,
      'startingDifficulty': startingDifficulty,
      'pin': pin,
      'totalAsrAttempts': totalAsrAttempts,
      'exactAsrMatches': exactAsrMatches,
      'totalLatencyMs': totalLatencyMs,
      'latencyHistory': latencyHistory,
      'categoryWrong': categoryWrongCounts,
      'categoryTotal': categoryTotalCounts,
      'childAge': childAge,
    });
  }

  // ── Okuma ──────────────────────────────────────────────────────────────────

  int get totalCorrect => (_box.get('totalCorrect', defaultValue: 0) as num).toInt();
  int get totalWrong => (_box.get('totalWrong', defaultValue: 0) as num).toInt();
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

  String get pin => _box.get('pin', defaultValue: '1234') as String;
  int get startingDifficulty =>
      (_box.get('startingDifficulty', defaultValue: 0) as num).toInt();

  // ── Yazma ──────────────────────────────────────────────────────────────────

  void recordAnswer({required bool correct, required int difficulty}) {
    _box.put('totalCorrect', totalCorrect + (correct ? 1 : 0));
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

  void changePin(String newPin) {
    _box.put('pin', newPin);
    _syncToCloud();
    notifyListeners();
  }

  void setStartingDifficulty(int diff) {
    _box.put('startingDifficulty', diff.clamp(0, 2));
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
  String get asrEngine =>
      _box.get('asrEngine', defaultValue: 'vosk') as String;

  void setAsrEngine(String engine) {
    assert(engine == 'vosk' || engine == 'platform');
    _box.put('asrEngine', engine);
    _syncToCloud();
    notifyListeners();
  }

  bool verifyPin(String entered) => entered == pin;

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