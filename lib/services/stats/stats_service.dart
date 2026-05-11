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
    _syncToCloud();
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

  bool verifyPin(String entered) => entered == pin;

  Future<void> resetStats() async {
    await _box.put('totalCorrect', 0);
    await _box.put('totalWrong', 0);
    await _box.put('difficultyHistory', <int>[]);
    _syncToCloud();
    notifyListeners();
  }
}