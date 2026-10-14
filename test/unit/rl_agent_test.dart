import 'dart:math';

import 'package:app/services/rl_agent/reward_calculator.dart';
import 'package:app/services/rl_agent/rl_agent.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('ödül: hızlı doğru > yavaş doğru > çok geç doğru > yanlış', () {
    double r(bool ok, double s) =>
        RewardCalculator.calculate(isCorrect: ok, responseTimeSec: s);
    expect(r(true, 2), 1.5);
    expect(r(true, 7), 1.0);
    expect(r(true, 20), 0.5);
    expect(r(false, 2), -1.0);
  });

  test('sürekli yanlış cevap en kolaya indirir ve orada tutar (her tohumda)', () {
    for (var seed = 0; seed < 200; seed++) {
      final agent =
          RLAgent(initialDifficulty: 2, maxDifficulty: 2, rng: Random(seed));
      for (var i = 0; i < 30; i++) {
        agent.processAnswer(isCorrect: false, responseTimeSec: 9);
        if (i >= 4) {
          expect(agent.currentDifficulty, 0, reason: 'tohum $seed, cevap $i');
        }
      }
    }
  });

  test('sürekli doğru cevap en zora çıkarır ve orada tutar (her tohumda)', () {
    for (var seed = 0; seed < 200; seed++) {
      final agent =
          RLAgent(initialDifficulty: 0, maxDifficulty: 2, rng: Random(seed));
      for (var i = 0; i < 30; i++) {
        agent.processAnswer(isCorrect: true, responseTimeSec: 2);
        if (i >= 4) {
          expect(agent.currentDifficulty, 2, reason: 'tohum $seed, cevap $i');
        }
      }
    }
  });

  test('yaş sınırı aşılmaz (2 yaş → yalnızca kolay)', () {
    final agent = RLAgent(initialDifficulty: 2, maxDifficulty: 0);
    expect(agent.currentDifficulty, 0);
    for (var i = 0; i < 20; i++) {
      agent.processAnswer(isCorrect: true, responseTimeSec: 1);
      expect(agent.currentDifficulty, 0);
    }
  });

  test('rastgele cevaplarda zorluk hep geçerli aralıkta kalır', () {
    for (var max = 0; max <= 2; max++) {
      final agent = RLAgent(maxDifficulty: max);
      for (var i = 0; i < 200; i++) {
        agent.processAnswer(isCorrect: i % 3 != 0, responseTimeSec: (i % 12).toDouble());
        expect(agent.currentDifficulty, inInclusiveRange(0, max));
        expect(() => agent.config, returnsNormally);
      }
    }
  });
}
