/// Son N cevabın performans geçmişini tutar (yalnızca şu anki seviyede).
class PerformanceState {
  static const int _windowSize = 5;

  final List<bool> _recentAnswers = [];
  final List<double> _responseTimes = [];
  int _wrongStreak = 0;
  int currentDifficulty;

  PerformanceState({int initialDifficulty = 0})
    : currentDifficulty = initialDifficulty;

  /// [known]: ipucusuz doğru. İpucuyla doğru cevap oranı yükseltmez ama
  /// can kaybettirmediği için yanlış serisini de uzatmaz.
  void addAnswer(bool known, double responseTimeSec, {bool wrong = false}) {
    _recentAnswers.add(known);
    _responseTimes.add(responseTimeSec);
    if (_recentAnswers.length > _windowSize) _recentAnswers.removeAt(0);
    if (_responseTimes.length > _windowSize) _responseTimes.removeAt(0);
    _wrongStreak = wrong ? _wrongStreak + 1 : 0;
  }

  /// Seviye değişince: yeni seviye kendi cevaplarıyla değerlendirilir.
  void resetWindow() {
    _recentAnswers.clear();
    _responseTimes.clear();
    _wrongStreak = 0;
  }

  /// Son penceredeki doğru cevap oranı
  double get correctRate {
    if (_recentAnswers.isEmpty) return 0.5;
    return _recentAnswers.where((a) => a).length / _recentAnswers.length;
  }

  /// Son penceredeki ortalama yanıt süresi (saniye)
  double get avgResponseTime {
    if (_responseTimes.isEmpty) return 5.0;
    return _responseTimes.fold(0.0, (a, b) => a + b) / _responseTimes.length;
  }

  int get totalAnswers => _recentAnswers.length;

  /// Üst üste kaç yanlış (can kaybı) yapıldı.
  int get lastWrongStreak => _wrongStreak;
}
