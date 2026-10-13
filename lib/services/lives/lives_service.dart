import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../api/api_service.dart';

class LivesService extends ChangeNotifier {
  static const int maxLives = 5;
  static const _boxName = 'lives_box';
  static const _livesKey = 'lives';

  late Box _box;
  int _lives = maxLives;

  ApiService? _api;

  int get lives => _lives;
  bool get hasLives => _lives > 0;

  Future<void> init() async {
    _box = await Hive.openBox(_boxName);
    _lives = (_box.get(_livesKey, defaultValue: maxLives) as num).toInt();
  }

  void setCloudSync(ApiService api) => _api = api;

  void clearCloudSync() => _api = null;

  Future<void> loadFromCloud(dynamic data) async {
    if (data == null) return;
    _lives = (data as num).toInt().clamp(0, maxLives);
    await _box.put(_livesKey, _lives);
    notifyListeners();
  }

  void _syncToCloud() => _api?.saveLives(_lives);

  void loseLife() {
    if (_lives <= 0) return;
    _lives = (_lives - 1).clamp(0, maxLives);
    _box.put(_livesKey, _lives);
    _syncToCloud();
    notifyListeners();
  }

  void refillLives() {
    _lives = maxLives;
    _box.put(_livesKey, _lives);
    _syncToCloud();
    notifyListeners();
  }
}