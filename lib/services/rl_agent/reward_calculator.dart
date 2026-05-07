/// PDF'teki ödül fonksiyonu: hızlı+doğru=+1.5, yavaş+doğru=+1.0,
/// kısmen ilerleme=+0.5, yanlış/süre aşımı=-1.0
class RewardCalculator {
  static const double _fastThresholdSec = 4.0;
  static const double _slowThresholdSec = 10.0;

  static double calculate({
    required bool isCorrect,
    required double responseTimeSec,
  }) {
    if (!isCorrect) return -1.0;
    if (responseTimeSec <= _fastThresholdSec) return 1.5; // hızlı ve doğru
    if (responseTimeSec <= _slowThresholdSec) return 1.0; // doğru ama yavaş
    return 0.5; // çok geç ama doğru
  }
}