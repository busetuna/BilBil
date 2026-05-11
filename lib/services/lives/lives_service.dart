import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

class LivesService extends ChangeNotifier {
  static const int maxLives = 5;
  static const _boxName = 'lives_box';
  static const _livesKey = 'lives';

  late Box _box;
  int _lives = maxLives;

  int get lives => _lives;
  bool get hasLives => _lives > 0;

  Future<void> init() async {
    _box = await Hive.openBox(_boxName);
    _lives = (_box.get(_livesKey, defaultValue: maxLives) as num).toInt();
  }

  void loseLife() {
    if (_lives <= 0) return;
    _lives = (_lives - 1).clamp(0, maxLives);
    _box.put(_livesKey, _lives);
    notifyListeners();
  }

  void refillLives() {
    _lives = maxLives;
    _box.put(_livesKey, _lives);
    notifyListeners();
  }
}