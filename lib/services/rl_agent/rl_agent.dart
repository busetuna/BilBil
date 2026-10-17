import 'dart:math';

import 'epsilon_greedy_bandit.dart';
import 'state_manager.dart';
import 'reward_calculator.dart';
import 'action_selector.dart';

class DifficultyConfig {
  final double ttsRate;
  final String label;

  const DifficultyConfig({required this.ttsRate, required this.label});
}

/// Zorluk ayarlayan ajan. Öğrendikleri (Q tablosu) ve son seviye
/// [toJson] ile saklanır; bir sonraki quiz kaldığı yerden başlar.
class RLAgent {
  final EpsilonGreedyBandit _bandit;
  final PerformanceState _state;

  /// Son karar: hangi seviyedeyken hangi kol seçildi. Ödülü, sonucunu
  /// gördüğümüz ilk cevapla gelir. Quiz'in ilk cevabından önce karar
  /// yoktur; önceden ilk cevap hiç seçilmemiş "aynı kal" koluna yazılıyordu.
  ({int state, int arm})? _pending;

  static const configs = [
    // Konuşma hızı (flutter_tts'te 0.5 normal): kolayda biraz yavaş ama yine
    // canlı; eski 0.35 çocuklara sıkıcı ve düz geliyordu.
    DifficultyConfig(ttsRate: 0.46, label: 'Kolay'),
    DifficultyConfig(ttsRate: 0.50, label: 'Orta'),
    DifficultyConfig(ttsRate: 0.54, label: 'Zor'),
  ];

  /// Yeni seviyede karar vermeden önce görülecek en az cevap.
  static const minEvidence = 3;

  final int _maxDifficulty;

  /// [saved]: önceki quiz'lerden [toJson] çıktısı. İçindeki seviye
  /// [initialDifficulty]'nin önüne geçer; ikisi de yaş sınırına kırpılır.
  RLAgent({
    double epsilon = 0.2,
    int initialDifficulty = 0,
    int maxDifficulty = 2,
    Map<String, dynamic>? saved,
    Random? rng,
  }) : _maxDifficulty = maxDifficulty.clamp(0, 2),
       _bandit = EpsilonGreedyBandit(epsilon: epsilon, rng: rng),
       _state = PerformanceState(
         initialDifficulty:
             ((saved?['level'] as num?)?.toInt() ?? initialDifficulty).clamp(
               0,
               maxDifficulty.clamp(0, 2),
             ),
       ) {
    _bandit.load(saved);
  }

  int get currentDifficulty => _state.currentDifficulty;
  DifficultyConfig get config => configs[_state.currentDifficulty];
  double get correctRate => _state.correctRate;
  double get avgResponseTime => _state.avgResponseTime;
  List<List<double>> get qValues => _bandit.qValues;
  List<List<int>> get counts => _bandit.counts;

  Map<String, dynamic> toJson() => {
    ..._bandit.toJson(),
    'level': _state.currentDifficulty,
  };

  /// Her cevap sonrası çağrılır. Yeni zorluk seviyesini döner.
  ///
  /// [itemDifficulty]: cevaplanan sorunun seviyesi. Başka seviyeden gelen
  /// bir tekrar sorusu bu seviye hakkında bilgi vermez; atlanır.
  int processAnswer({
    required bool isCorrect,
    required double responseTimeSec,
    bool hintUsed = false,
    int? itemDifficulty,
  }) {
    final level = _state.currentDifficulty;
    if (itemDifficulty != null && itemDifficulty != level) return level;

    // 1. Ödül hesapla: çocuğu bu seviyeye getiren kararı puanla
    final pending = _pending;
    if (pending != null) {
      _bandit.update(
        pending.state,
        pending.arm,
        RewardCalculator.calculate(
          isCorrect: isCorrect,
          responseTimeSec: responseTimeSec,
          difficulty: level,
          hintUsed: hintUsed,
        ),
      );
    }

    // 2. Performans geçmişine ekle (ipucuyla doğru, "biliyor" sayılmaz)
    _state.addAnswer(
      isCorrect && !hintUsed,
      responseTimeSec,
      wrong: !isCorrect,
    );

    // 3. Kol seç
    final arm = _chooseArm(level);
    _pending = (state: level, arm: arm);

    // 4. Zorluk güncelle (yaş sınırını aşamaz). Seviye değişince geçmiş
    // sıfırlanır: önceden Kolay'daki 5 doğru, Orta'ya geçer geçmez tek
    // cevapla Zor'a da atlatıyordu.
    final next = ActionSelector.adjustDifficulty(
      level,
      arm,
    ).clamp(0, _maxDifficulty);
    if (next != level) _state.resetWindow();
    _state.currentDifficulty = next;
    return next;
  }

  /// Uçlarda kurallar (can kaybını önlemek ve sıkılmamak için), arada
  /// bandit karar verir.
  int _chooseArm(int level) {
    final canEase = level > 0;
    final canHarden = level < _maxDifficulty;
    const ease = 0, stay = EpsilonGreedyBandit.stay, harden = 2;
    int banditChoice({bool allowEase = true}) => _bandit.selectArm(
      level,
      allowed: [if (canEase && allowEase) ease, stay, if (canHarden) harden],
    );

    // Üst üste iki yanlış (iki can): beklemeden kolaylaştır.
    if (canEase && _state.lastWrongStreak >= 2) return ease;
    if (_state.totalAnswers < minEvidence) return stay;

    final rate = _state.correctRate;
    if (rate <= 0.3) return canEase ? ease : stay;
    if (rate >= 0.8) {
      // Çok iyi gidiyor: asla kolaylaştırma, zorlaştırmayı dene. Ama ajan
      // bu seviyeden zorlaştırmanın kötü gittiğini zaten öğrendiyse kural
      // zorlamaz; önceden çocuk her 3/3'te Zor'a itilip iki can kaybediyordu.
      if (!canHarden) return stay;
      final learnedWorse =
          _bandit.knows(level, harden) &&
          _bandit.valueOf(level, harden) < _bandit.valueOf(level, stay);
      return learnedWorse ? banditChoice(allowEase: false) : harden;
    }
    return banditChoice();
  }
}
