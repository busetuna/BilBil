import 'epsilon_greedy_bandit.dart';
import 'state_manager.dart';
import 'reward_calculator.dart';
import 'action_selector.dart';

/// Difficulty → TTS hızı ve ipucu davranışı
class DifficultyConfig {
  final double ttsRate;
  final bool showHintAfterDelay;
  final int hintDelaySeconds;
  final String label;

  const DifficultyConfig({
    required this.ttsRate,
    required this.showHintAfterDelay,
    required this.hintDelaySeconds,
    required this.label,
  });
}

class RLAgent {
  final EpsilonGreedyBandit _bandit;
  final PerformanceState _state;
  int _lastArm = 1; // başlangıçta "aynı kal"

  static const configs = [
    DifficultyConfig(
      ttsRate: 0.35,
      showHintAfterDelay: true,
      hintDelaySeconds: 5,
      label: 'Kolay',
    ),
    DifficultyConfig(
      ttsRate: 0.45,
      showHintAfterDelay: false,
      hintDelaySeconds: 0,
      label: 'Orta',
    ),
    DifficultyConfig(
      ttsRate: 0.55,
      showHintAfterDelay: false,
      hintDelaySeconds: 0,
      label: 'Zor',
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
    // 1. Ödül hesapla
    final reward = RewardCalculator.calculate(
      isCorrect: isCorrect,
      responseTimeSec: responseTimeSec,
    );

    // 2. Son kolu güncelle
    _bandit.update(_lastArm, reward);

    // 3. Performans geçmişine ekle
    _state.addAnswer(isCorrect, responseTimeSec);

    // 4. Yeni kol seç (ε-greedy)
    _lastArm = _bandit.selectArm();

    // 5. Zorluk güncelle
    _state.currentDifficulty = ActionSelector.adjustDifficulty(
      _state.currentDifficulty,
      _lastArm,
    );

    return _state.currentDifficulty;
  }
}