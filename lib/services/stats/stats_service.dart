import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

class StatsService extends ChangeNotifier {
  static const _boxName = 'stats';
  late Box _box;

  Future<void> init() async {
    _box = await Hive.openBox(_boxName);
  }

  // ── Okuma ──────────────────────────────────────────────────────────────────

  int get totalCorrect => _box.get('totalCorrect', defaultValue: 0) as int;
  int get totalWrong => _box.get('totalWrong', defaultValue: 0) as int;
  int get totalAnswers => totalCorrect + totalWrong;
  double get successRate =>
      totalAnswers == 0 ? 0.0 : totalCorrect / totalAnswers;

  List<int> get difficultyHistory {
    final raw = _box.get('difficultyHistory');
    if (raw == null) return [];
    return List<int>.from(raw as List);
  }

  String get pin => _box.get('pin', defaultValue: '1234') as String;
  int get startingDifficulty =>
      _box.get('startingDifficulty', defaultValue: 0) as int;

  // ── Yazma ──────────────────────────────────────────────────────────────────

  void recordAnswer({required bool correct, required int difficulty}) {
    _box.put('totalCorrect', totalCorrect + (correct ? 1 : 0));
    _box.put('totalWrong', totalWrong + (correct ? 0 : 1));

    final history = difficultyHistory;
    history.add(difficulty);
    if (history.length > 300) history.removeAt(0); // en fazla 300 kayıt
    _box.put('difficultyHistory', history);
    notifyListeners();
  }

  void changePin(String newPin) {
    _box.put('pin', newPin);
    notifyListeners();
  }

  void setStartingDifficulty(int diff) {
    _box.put('startingDifficulty', diff.clamp(0, 2));
    notifyListeners();
  }

  bool verifyPin(String entered) => entered == pin;

  Future<void> resetStats() async {
    await _box.put('totalCorrect', 0);
    await _box.put('totalWrong', 0);
    await _box.put('difficultyHistory', <int>[]);
    notifyListeners();
  }
}