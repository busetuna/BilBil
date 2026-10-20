import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../api/api_service.dart';

/// Canlar biterse Bilbil [restDuration] boyunca "uyur": bu, 2–5 yaş için
/// bir ceza değil ekran molasıdır. Süre dolunca canlar kendiliğinden dolar;
/// ebeveyn molayı erken bitirebilir ([refillLives]).
class LivesService extends ChangeNotifier {
  static const int maxLives = 5;
  static const restDuration = Duration(minutes: 3);
  static const _boxName = 'lives_box';
  static const _livesKey = 'lives';
  static const _restUntilKey = 'rest_until';

  late Box _box;
  int _lives = maxLives;
  final DateTime Function() _now;

  ApiService? _api;

  LivesService({DateTime Function()? clock}) : _now = clock ?? DateTime.now;

  int get lives => _lives;
  bool get hasLives => _lives > 0;

  Future<void> init() async {
    _box = await Hive.openBox(_boxName);
    _lives = (_box.get(_livesKey, defaultValue: maxLives) as num).toInt();
  }

  void setCloudSync(ApiService api) => _api = api;

  void clearCloudSync() => _api = null;

  /// Yereldeki durumu olduğu gibi buluta yazar (çevrimdışı değişiklikler).
  void pushToCloud() => _syncToCloud();

  Future<void> loadFromCloud(dynamic data) async {
    if (data == null) return;
    _lives = (data as num).toInt().clamp(0, maxLives);
    await _box.put(_livesKey, _lives);
    notifyListeners();
  }

  void _syncToCloud() => _api?.saveLives(_lives);

  /// Molanın bitmesine kalan süre; mola yoksa ya da bittiyse null.
  Duration? get restRemaining {
    if (_lives > 0) return null;
    final until = _box.get(_restUntilKey) as int?;
    // Mola zamanı kayıtlı değilse (ör. 0 can başka cihazdan geldi) mola bitmiş sayılır.
    if (until == null) return null;
    final left = DateTime.fromMillisecondsSinceEpoch(until).difference(_now());
    return left > Duration.zero ? left : null;
  }

  /// Oynanabilir mi? Canlar bitmiş ama mola dolmuşsa canları doldurur.
  bool ensurePlayable() {
    if (_lives > 0) return true;
    if (restRemaining != null) return false;
    refillLives();
    return true;
  }

  void loseLife() {
    if (_lives <= 0) return;
    _lives = (_lives - 1).clamp(0, maxLives);
    _box.put(_livesKey, _lives);
    if (_lives == 0) {
      _box.put(_restUntilKey, _now().add(restDuration).millisecondsSinceEpoch);
    }
    _syncToCloud();
    notifyListeners();
  }

  void refillLives() {
    _lives = maxLives;
    _box.put(_livesKey, _lives);
    _box.delete(_restUntilKey);
    _syncToCloud();
    notifyListeners();
  }
}
