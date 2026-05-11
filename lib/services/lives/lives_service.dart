import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../firestore/firestore_service.dart';

class LivesService extends ChangeNotifier {
  static const int maxLives = 5;
  static const _boxName = 'lives_box';
  static const _livesKey = 'lives';

  late Box _box;
  int _lives = maxLives;

  String? _uid;
  FirestoreService? _firestore;

  int get lives => _lives;
  bool get hasLives => _lives > 0;

  Future<void> init() async {
    _box = await Hive.openBox(_boxName);
    _lives = (_box.get(_livesKey, defaultValue: maxLives) as num).toInt();
  }

  void setCloudSync(String uid, FirestoreService svc) {
    _uid = uid;
    _firestore = svc;
  }

  void clearCloudSync() {
    _uid = null;
    _firestore = null;
  }

  Future<void> loadFromCloud(dynamic data) async {
    if (data == null) return;
    _lives = (data as num).toInt().clamp(0, maxLives);
    await _box.put(_livesKey, _lives);
    notifyListeners();
  }

  void _syncToCloud() {
    final uid = _uid;
    final firestore = _firestore;
    if (uid == null || firestore == null) return;
    firestore.saveLives(uid, _lives);
  }

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