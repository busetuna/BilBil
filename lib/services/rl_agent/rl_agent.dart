import 'epsilon_greedy_bandit.dart';
import 'state_manager.dart';
import 'reward_calculator.dart';
import 'action_selector.dart';

class DifficultyConfig {
  final double ttsRate;
  final String label;
  final List<String> categories;

  const DifficultyConfig({
    required this.ttsRate,
    required this.label,
    required this.categories,
  });
}

class RLAgent {
  final EpsilonGreedyBandit _bandit;
  final PerformanceState _state;
  int _lastArm = 1;

  static const configs = [
    DifficultyConfig(
      ttsRate: 0.35,
      label: 'Kolay',
      categories: ['animals', 'colors', 'shapes'],
    ),
    DifficultyConfig(
      ttsRate: 0.45,
      label: 'Orta',
      categories: ['fruits_vegetables', 'body_parts', 'clothes'],
    ),
    DifficultyConfig(
      ttsRate: 0.55,
      label: 'Zor',
      categories: ['daily_objects', 'weather', 'actions', 'adjectives'],
    ),
  ];

  RLAgent({double epsilon = 0.2})
      : _bandit = EpsilonGreedyBandit(epsilon: epsilon),
        _state = PerformanceState();

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
      if (rate >= 0.8 && _state.currentDifficulty < 2) {
        _lastArm = 2; // son 3+ cevabın 80%'i doğru → zorlaştır
      } else if (rate <= 0.3 && _state.currentDifficulty > 0) {
        _lastArm = 0; // 30% veya altında → kolaylaştır
      } else {
        _lastArm = _bandit.selectArm(); // orta bölge → bandit karar verir
      }
    } else {
      _lastArm = _bandit.selectArm();
    }

    // 4. Zorluk güncelle
    _state.currentDifficulty = ActionSelector.adjustDifficulty(
      _state.currentDifficulty,
      _lastArm,
    );

    return _state.currentDifficulty;
  }
}