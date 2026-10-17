import 'dart:io';
import 'dart:math';

import 'package:app/services/rl_agent/epsilon_greedy_bandit.dart';
import 'package:app/services/rl_agent/reward_calculator.dart';
import 'package:app/services/rl_agent/rl_agent.dart';
import 'package:app/services/stats/stats_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

void main() {
  group('Ödül', () {
    double r(bool ok, double s, {int level = 0, bool hint = false}) =>
        RewardCalculator.calculate(
          isCorrect: ok,
          responseTimeSec: s,
          difficulty: level,
          hintUsed: hint,
        );

    test(
      'hızlı doğru > tereddütlü doğru > yavaş doğru > ipucuyla > yanlış',
      () {
        expect(r(true, 1), 1.5);
        expect(r(true, 4), 1.25);
        expect(r(true, 9), 1.0);
        expect(r(true, 1, hint: true), RewardCalculator.hinted);
        expect(r(false, 1), -1.0);
      },
    );

    test(
      'aynı başarı zor seviyede daha değerli (kolaya kaçma eğilimi yok)',
      () {
        expect(r(true, 1, level: 1), greaterThan(r(true, 1, level: 0)));
        expect(r(true, 1, level: 2), greaterThan(r(true, 1, level: 1)));
        expect(r(false, 1, level: 2), r(false, 1, level: 0));
      },
    );
  });

  group('Bandit', () {
    test('geçersiz kol seçilmez; eşitlikte "aynı kal"', () {
      final b = EpsilonGreedyBandit(epsilon: 1, rng: Random(1));
      for (var i = 0; i < 200; i++) {
        expect(b.selectArm(0, allowed: [1, 2]), isNot(0));
      }
      final greedy = EpsilonGreedyBandit(epsilon: 0, minEpsilon: 0);
      expect(greedy.selectArm(1, allowed: [0, 1, 2]), 1);
      greedy.update(1, 2, 0.5);
      expect(greedy.selectArm(1, allowed: [0, 1, 2]), 2);
      expect(
        greedy.selectArm(0, allowed: [0, 1, 2]),
        1,
        reason: 'durumlar ayrı',
      );
    });

    test('deneyim arttıkça keşif azalır', () {
      final b = EpsilonGreedyBandit(epsilon: 0.2, minEpsilon: 0.05);
      expect(b.epsilonFor(0), 0.2);
      for (var i = 0; i < 100; i++) {
        b.update(0, 1, 1);
      }
      expect(b.epsilonFor(0), 0.05);
      expect(b.epsilonFor(1), 0.2, reason: 'diğer seviye etkilenmez');
    });

    test('bozuk kayıt yüklenmez', () {
      final b = EpsilonGreedyBandit();
      for (final bad in <Map<String, dynamic>?>[
        null,
        {'q': 'x'},
        {
          'q': [
            [1, 2],
          ],
          'n': [
            [1, 2],
          ],
        },
        {
          'q': List.filled(3, ['a', 'b', 'c']),
          'n': List.filled(3, [1, 1, 1]),
        },
      ]) {
        b.load(bad);
        expect(b.counts.expand((r) => r), everyElement(0), reason: '$bad');
      }
    });
  });

  group('RLAgent', () {
    test(
      'sürekli yanlış cevap en kolaya indirir ve orada tutar (her tohumda)',
      () {
        for (var seed = 0; seed < 200; seed++) {
          final agent = RLAgent(
            initialDifficulty: 2,
            maxDifficulty: 2,
            rng: Random(seed),
          );
          for (var i = 0; i < 30; i++) {
            agent.processAnswer(isCorrect: false, responseTimeSec: 3);
            if (i >= 3) {
              expect(
                agent.currentDifficulty,
                0,
                reason: 'tohum $seed, cevap $i',
              );
            }
          }
        }
      },
    );

    test(
      'sürekli doğru cevap en zora çıkarır ve orada tutar (her tohumda)',
      () {
        for (var seed = 0; seed < 200; seed++) {
          final agent = RLAgent(
            initialDifficulty: 0,
            maxDifficulty: 2,
            rng: Random(seed),
          );
          for (var i = 0; i < 30; i++) {
            agent.processAnswer(isCorrect: true, responseTimeSec: 1);
            if (i >= 5) {
              expect(
                agent.currentDifficulty,
                2,
                reason: 'tohum $seed, cevap $i',
              );
            }
          }
        }
      },
    );

    test('yeni seviye kendi cevaplarıyla değerlendirilir (seviye atlamaz)', () {
      final agent = RLAgent(initialDifficulty: 0, rng: Random(1));
      final levels = [
        for (var i = 0; i < 6; i++)
          agent.processAnswer(isCorrect: true, responseTimeSec: 1),
      ];
      expect(levels, [0, 0, 1, 1, 1, 2], reason: 'Orta atlanmadan Zor\'a');
    });

    test('ipucuyla doğru zorluğu artırmaz', () {
      for (var seed = 0; seed < 50; seed++) {
        final agent = RLAgent(initialDifficulty: 0, rng: Random(seed));
        for (var i = 0; i < 20; i++) {
          agent.processAnswer(
            isCorrect: true,
            responseTimeSec: 1,
            hintUsed: true,
          );
          expect(agent.currentDifficulty, 0, reason: 'tohum $seed, cevap $i');
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
          agent.processAnswer(
            isCorrect: i % 3 != 0,
            responseTimeSec: (i % 12).toDouble(),
            hintUsed: i % 7 == 0,
          );
          expect(agent.currentDifficulty, inInclusiveRange(0, max));
          expect(() => agent.config, returnsNormally);
        }
      }
    });

    test(
      'ilk cevap hiçbir kola yazılmaz; ödül kararı veren seviyeye gider',
      () {
        final agent = RLAgent(initialDifficulty: 1, rng: Random(1));
        agent.processAnswer(isCorrect: true, responseTimeSec: 1);
        expect(agent.counts.expand((r) => r), everyElement(0));
        agent.processAnswer(isCorrect: true, responseTimeSec: 1);
        expect(agent.counts[1][1], 1, reason: 'Orta\'da "aynı kal" kararı');
        expect(agent.qValues[1][1], 2.5, reason: '1 + 0.5 hız + 1 Orta');
      },
    );

    test('başka seviyeden gelen tekrar sorusu ajanı etkilemez', () {
      final agent = RLAgent(initialDifficulty: 1, rng: Random(1));
      agent.processAnswer(isCorrect: true, responseTimeSec: 1);
      final before = agent.toJson();
      for (var i = 0; i < 5; i++) {
        agent.processAnswer(
          isCorrect: false,
          responseTimeSec: 1,
          itemDifficulty: 0,
        );
      }
      expect(agent.toJson(), before);
      expect(agent.currentDifficulty, 1);
    });

    test('öğrendikleri ve seviyesi kaydedilip geri yüklenir', () {
      final agent = RLAgent(initialDifficulty: 0, rng: Random(2));
      for (var i = 0; i < 12; i++) {
        agent.processAnswer(isCorrect: i % 4 != 0, responseTimeSec: 2);
      }
      final saved = agent.toJson();
      final restored = RLAgent(initialDifficulty: 0, saved: saved);
      expect(restored.qValues, agent.qValues);
      expect(restored.counts, agent.counts);
      expect(restored.currentDifficulty, agent.currentDifficulty);

      final younger = RLAgent(maxDifficulty: 0, saved: {...saved, 'level': 2});
      expect(younger.currentDifficulty, 0, reason: 'yaş sınırına kırpılır');
      final noLevel = RLAgent(
        initialDifficulty: 1,
        saved: {...saved}..remove('level'),
      );
      expect(noLevel.currentDifficulty, 1, reason: 'ebeveynin seçtiği seviye');
    });

    /// Çocuğun her seviyedeki başarı olasılığı [p]; 10 quiz oynar, öğrenme
    /// her quiz arasında saklanır. Son 5 quiz'de seviye payları ve yanlış oranı.
    ({List<double> share, double wrong}) simulate(List<double> p) {
      final at = [0, 0, 0];
      var total = 0, wrong = 0;
      for (var seed = 0; seed < 50; seed++) {
        final child = Random(1000 + seed);
        Map<String, dynamic>? saved;
        for (var session = 0; session < 10; session++) {
          final agent = RLAgent(saved: saved, rng: Random(seed * 31 + session));
          for (var q = 0; q < 15; q++) {
            final level = agent.currentDifficulty;
            final ok = child.nextDouble() < p[level];
            if (session >= 5) {
              total++;
              at[level]++;
              if (!ok) wrong++;
            }
            agent.processAnswer(isCorrect: ok, responseTimeSec: ok ? 2 : 4);
          }
          saved = agent.toJson();
        }
      }
      return (share: [for (final c in at) c / total], wrong: wrong / total);
    }

    // Eski ajanla aynı simülasyonda (karşılaştırma için ölçüldü): A'da Orta
    // %21 / yanlış %34, C'de Kolay %48 / yanlış %41.
    test("simüle çocuk A: Orta'yı çoğunlukla bilen Orta'da kalır", () {
      final r = simulate([0.98, 0.8, 0.35]);
      expect(r.share[1], greaterThan(0.55), reason: '${r.share}');
      expect(r.wrong, lessThan(0.22));
    });

    test("simüle çocuk B: her şeyi bilen Zor'a çıkar", () {
      final r = simulate([0.98, 0.95, 0.88]);
      expect(r.share[2], greaterThan(0.75), reason: '${r.share}');
    });

    test("simüle çocuk C: zorlanan Kolay'da kalır, az can kaybeder", () {
      final r = simulate([0.85, 0.5, 0.2]);
      expect(r.share[0], greaterThan(0.75), reason: '${r.share}');
      expect(r.wrong, lessThan(0.27));
    });

    test("simüle çocuk D: Zor'da %60 bilen Zor'a itilmez", () {
      final r = simulate([0.98, 0.9, 0.6]);
      expect(r.share[1], greaterThan(0.7), reason: '${r.share}');
    });
  });

  group('Kalıcılık (StatsService)', () {
    late Directory dir;
    late StatsService stats;

    setUp(() async {
      dir = await Directory.systemTemp.createTemp('bilbil_rl_test');
      Hive.init(dir.path);
      stats = StatsService();
      await stats.init();
    });

    tearDown(() async {
      await Hive.deleteFromDisk();
      await dir.delete(recursive: true);
    });

    test('cevapla birlikte saklanır, hesap değişince silinir', () async {
      expect(stats.rlAgentState, isNull);
      final agent = RLAgent(initialDifficulty: 1);
      agent
        ..processAnswer(isCorrect: true, responseTimeSec: 1)
        ..processAnswer(isCorrect: true, responseTimeSec: 1);
      stats.recordAnswer(correct: true, difficulty: 1, rlState: agent.toJson());
      expect(stats.rlAgentState, agent.toJson());

      await stats.clearAccountData();
      expect(stats.rlAgentState, isNull);
    });

    test(
      'ebeveyn başlangıç seviyesini değiştirince kalınan seviye unutulur',
      () {
        stats.recordAnswer(
          correct: true,
          difficulty: 2,
          rlState: RLAgent(initialDifficulty: 2).toJson(),
        );
        stats.setStartingDifficulty(0);
        final agent = RLAgent(
          initialDifficulty: stats.startingDifficulty,
          saved: stats.rlAgentState,
        );
        expect(agent.currentDifficulty, 0);
        expect(stats.rlAgentState, contains('q'), reason: 'öğrendikleri kalır');
      },
    );

    test('buluttan gelir; bulutta yoksa yereldeki silinir', () async {
      final rl = RLAgent(initialDifficulty: 1).toJson();
      await stats.loadFromCloud({'rlAgent': rl});
      expect(stats.rlAgentState, rl);
      await stats.loadFromCloud({'totalCorrect': 3});
      expect(stats.rlAgentState, isNull);
    });
  });
}
