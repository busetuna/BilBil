import 'dart:math';

/// 3 kollu bandit: 0=zorluk azalt, 1=aynı kal, 2=zorluk artır
class EpsilonGreedyBandit {
  final double epsilon;
  final List<double> _qValues;
  final List<int> _counts;
  final Random _rng = Random();

  EpsilonGreedyBandit({this.epsilon = 0.2})
      : _qValues = [0.0, 0.0, 0.0],
        _counts = [0, 0, 0];

  int selectArm() {
    if (_rng.nextDouble() < epsilon) {
      return _rng.nextInt(3); // keşif
    }
    // sömürü: en yüksek Q değerli kol
    double best = _qValues[0];
    int bestArm = 0;
    for (int i = 1; i < 3; i++) {
      if (_qValues[i] > best) {
        best = _qValues[i];
        bestArm = i;
      }
    }
    return bestArm;
  }

  /// Artımlı ortalama ile Q-değerini güncelle
  void update(int arm, double reward) {
    _counts[arm]++;
    _qValues[arm] += (reward - _qValues[arm]) / _counts[arm];
  }

  List<double> get qValues => List.unmodifiable(_qValues);
  List<int> get counts => List.unmodifiable(_counts);
}