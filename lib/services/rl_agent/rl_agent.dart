import 'dart:math';

import 'epsilon_greedy_bandit.dart';
import 'state_manager.dart';
import 'reward_calculator.dart';
import 'action_selector.dart';

class DifficultyConfig {
  final double ttsRate;
  final String label;

  const DifficultyConfig({
    required this.ttsRate,
    required this.label,
  });
}

class RLAgent {
  final EpsilonGreedyBandit _bandit;
  final PerformanceState _state;
  int _lastArm = 1;

  static const configs = [
    // Konuşma hızı (flutter_tts'te 0.5 normal): kolayda biraz yavaş ama yine
    // canlı; eski 0.35 çocuklara sıkıcı ve düz geliyordu.
    DifficultyConfig(ttsRate: 0.46, label: 'Kolay'),
    DifficultyConfig(ttsRate: 0.50, label: 'Orta'),
    DifficultyConfig(ttsRate: 0.54, label: 'Zor'),
  ];

  final int _maxDifficulty;

  RLAgent({
    double epsilon = 0.2,
    int initialDifficulty = 0,
    int maxDifficulty = 2,
    Random? rng,
  })  : _maxDifficulty = maxDifficulty.clamp(0, 2),
        _bandit = EpsilonGreedyBandit(epsilon: epsilon, rng: rng),
        _state = PerformanceState(
            initialDifficulty: initialDifficulty.clamp(0, maxDifficulty.clamp(0, 2)));

  int get currentDifficulty => _state.currentDifficulty;
  DifficultyConfig get config => configs[_state.currentDifficulty];
  double get correctRate => _state.correctRate;
  double get avgResponseTime => _state.avgResponseTime;
  List<double> get qValues => _bandit.qValues;

  /// Her cevap sonrası çağrılır. Yeni zorluk seviyesini döner.
  int processAnswer({
    required bool isCorrect,
    required double responseTimeSec,
  }) {
    // 1. Ödül hesapla ve banditi güncelle
    final reward = RewardCalculator.calculate(
      isCorrect: isCorrect,
      responseTimeSec: responseTimeSec,
    );
    _bandit.update(_lastArm, reward);

    // 2. Performans geçmişine ekle
    _state.addAnswer(isCorrect, responseTimeSec);

    // 3. Kol seç: yeterli veri varsa performans eşiği öncelikli
    if (_state.totalAnswers >= 3) {
      final rate = _state.correctRate;
      if (rate >= 0.8) {
        // Çok iyi gidiyor: zorlaştır; zaten en zordaysa kal (asla kolaylaştırma).
        _lastArm = _state.currentDifficulty < _maxDifficulty ? 2 : 1;
      } else if (rate <= 0.3) {
        // Zorlanıyor: kolaylaştır; zaten en kolaydaysa kal. Önceden en
        // kolayda karar bandit'e kalıyor, bazen zorluğu artırıyordu.
        _lastArm = _state.currentDifficulty > 0 ? 0 : 1;
      } else {
        _lastArm = _bandit.selectArm(); // orta bölge → bandit karar verir
      }
    } else {
      _lastArm = _bandit.selectArm();
    }

    // 4. Zorluk güncelle (yaş sınırını aşamaz)
    _state.currentDifficulty = ActionSelector.adjustDifficulty(
      _state.currentDifficulty,
      _lastArm,
    ).clamp(0, _maxDifficulty);

    return _state.currentDifficulty;
  }
}