import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:app/services/api/api_service.dart';
import 'package:app/services/learning/learning_scheduler.dart';
import 'package:app/services/learning/word_progress_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  group('WordProgressService (Leitner kutuları)', () {
    late Directory dir;
    late WordProgressService progress;

    setUp(() async {
      dir = await Directory.systemTemp.createTemp('bilbil_progress_test');
      Hive.init(dir.path);
      progress = WordProgressService(clock: () => DateTime(2026, 10, 14));
      await progress.init();
    });

    tearDown(() async {
      await Hive.deleteFromDisk();
      await dir.delete(recursive: true);
    });

    test(
      'doğru cevap kutuyu bir artırır (en fazla 4), yanlış 0\'a indirir',
      () {
        expect(progress.boxOf('Kedi'), isNull);
        progress.record('Kedi', correct: true);
        expect(progress.boxOf('Kedi'), 0);
        for (var i = 0; i < 10; i++) {
          progress.record('Kedi', correct: true);
        }
        expect(progress.boxOf('Kedi'), WordProgressService.maxBox);

        progress.record('Kedi', correct: false);
        expect(
          progress.boxOf('kedi'),
          0,
          reason: 'büyük/küçük harf aynı kelime',
        );
        expect(progress.stateOf('Kedi')!.wrong, 1);
        expect(progress.stateOf('Kedi')!.seen, 12);
      },
    );

    test('ipucuyla doğru: kutu yükselmez ama düşmez de', () {
      progress
        ..record('Kedi', correct: true)
        ..record('Kedi', correct: true)
        ..record('Kedi', correct: true, hinted: true);
      expect(progress.boxOf('Kedi'), 1);
      progress.record('Fil', correct: true, hinted: true);
      expect(progress.boxOf('Fil'), 0);
      expect(progress.stateOf('Fil')!.wrong, 0);
    });

    test('zorlandığı kelimeler: yanlış yapılmış ve oturmamış, çoktan aza', () {
      progress
        ..record('Kedi', correct: false)
        ..record('Zürafa', correct: false)
        ..record('Zürafa', correct: false)
        ..record('Elma', correct: true);
      for (var i = 0; i < 3; i++) {
        progress.record('Köpek', correct: i == 0 ? false : true);
      }
      final words = progress.struggling().map((s) => s.word).toList();
      expect(words, [
        'Zürafa',
        'Kedi',
      ], reason: 'Elma hiç yanlış yapılmadı, Köpek artık oturdu (kutu 2)');
    });

    test("quiz'den çıkarılmış kelimeler zorlandıkları listesinde görünmez", () {
      progress
        ..record('Yumruk', correct: false)
        ..record('Kedi', correct: false);
      expect(progress.struggling().map((s) => s.word), contains('Yumruk'));
      final only = {WordProgressService.keyOf('Kedi')};
      expect(progress.struggling(onlyWords: only).map((s) => s.word), ['Kedi']);
    });

    test('buluta kelime durumu gider ve geri yüklenir', () async {
      final bodies = <Map<String, dynamic>>[];
      progress.setCloudSync(
        ApiService(
          baseUrl: 'https://api.test',
          getToken: () async => 'tok',
          client: MockClient((req) async {
            bodies.add(jsonDecode(req.body) as Map<String, dynamic>);
            return http.Response('', 204);
          }),
        ),
      );
      progress.record('Muhabbet kuşu', correct: false);
      await Future<void>.delayed(const Duration(milliseconds: 20));
      final words = bodies.last['words'] as Map<String, dynamic>;
      expect(words['muhabbet kuşu'], containsPair('word', 'Muhabbet kuşu'));
      expect(words['muhabbet kuşu'], containsPair('box', 0));

      progress.clearCloudSync();
      await progress.clearAccountData();
      expect(progress.boxOf('Muhabbet kuşu'), isNull);
      await progress.loadFromCloud(words);
      expect(progress.stateOf('Muhabbet kuşu')!.wrong, 1);
    });
  });

  group('LearningScheduler', () {
    test('zorlanılan kelimeler sıranın başına daha sık gelir', () {
      final rng = Random(1);
      final items = List.generate(20, (i) => i);
      // 0..4 zorlanıyor (kutu 0), 15..19 iyi biliniyor (kutu 4)
      double weight(int i) => LearningScheduler.weightOf(
        i < 5
            ? 0
            : i >= 15
            ? 4
            : 2,
      );
      var weakFirst = 0, strongFirst = 0;
      for (var t = 0; t < 2000; t++) {
        final first = LearningScheduler.order(items, weight, rng).first;
        if (first < 5) weakFirst++;
        if (first >= 15) strongFirst++;
      }
      expect(weakFirst, greaterThan(strongFirst * 5));
    });

    test('sıralama hiçbir soruyu atmaz', () {
      final items = List.generate(50, (i) => i);
      final ordered = LearningScheduler.order(items, (_) => 1, Random(3));
      expect(ordered.toSet(), items.toSet());
    });
  });

  group('ReviewQueue (oturum içi tekrar)', () {
    test('bilinemeyen soru 3 soru sonra gelir', () {
      final q = ReviewQueue<String>()..scheduleAfterMiss('kedi', 5);
      expect(q.takeDue(6), isNull);
      expect(q.takeDue(7), isNull);
      expect(q.takeDue(8), 'kedi');
      expect(q.isEmpty, isTrue);
    });

    test('aynı soru bir oturumda en fazla 2 kez tekrar edilir', () {
      final q = ReviewQueue<String>();
      for (var i = 0; i < 5; i++) {
        q.scheduleAfterMiss('kedi', i * 10);
        if (i < ReviewQueue.maxPerItem) {
          expect(q.takeDue(i * 10 + ReviewQueue.delay), 'kedi');
        } else {
          expect(q.takeDue(i * 10 + ReviewQueue.delay), isNull);
        }
      }
    });

    test('şu an ekrandaki soru tekrar olarak seçilmez', () {
      final q = ReviewQueue<String>()..scheduleAfterMiss('kedi', 0);
      expect(q.takeDue(3, exclude: 'kedi'), isNull);
      expect(q.takeDue(4), 'kedi');
    });
  });
}
