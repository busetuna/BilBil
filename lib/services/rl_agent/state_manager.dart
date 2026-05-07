/// Son N cevabın performans geçmişini tutar
class PerformanceState {
  static const int _windowSize = 5;

  final List<bool> _recentAnswers = [];
  final List<double> _responseTimes = [];
  int currentDifficulty;

  PerformanceState({int initialDifficulty = 0}) : currentDifficulty = initialDifficulty;

  void addAnswer(bool correct, double responseTimeSec) {
    _recentAnswers.add(correct);
    _responseTimes.add(responseTimeSec);
    if (_recentAnswers.length > _windowSize) _recentAnswers.removeAt(0);
    if (_responseTimes.length > _windowSize) _responseTimes.removeAt(0);
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
}