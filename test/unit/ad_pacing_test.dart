import 'dart:io';

import 'package:app/services/ads/ad_pacing.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

void main() {
  late Directory dir;
  late DateTime now;
  late AdPacing pacing;

  Future<AdPacing> open() async {
    final p = AdPacing(clock: () => now);
    await p.init();
    return p;
  }

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('bilbil_ads_test');
    Hive.init(dir.path);
    now = DateTime(2026, 10, 13, 12);
    pacing = await open();
  });

  tearDown(() async {
    await Hive.deleteFromDisk();
    await dir.delete(recursive: true);
  });

  test('az oynandıysa quiz bitişi reklamı yok', () {
    expect(pacing.canShowQuizEnd(0), isFalse);
    expect(pacing.canShowQuizEnd(AdPacing.minAnswersForQuizEnd - 1), isFalse);
    expect(pacing.canShowQuizEnd(AdPacing.minAnswersForQuizEnd), isTrue);
  });

  test('bir tam ekran reklamdan sonra 10 dakika başka reklam yok', () {
    pacing.markFullScreenShown();
    expect(pacing.canShowQuizEnd(20), isFalse);

    now = now.add(AdPacing.minGap - const Duration(seconds: 1));
    expect(pacing.canShowQuizEnd(20), isFalse);

    now = now.add(const Duration(seconds: 1));
    expect(pacing.canShowQuizEnd(20), isTrue);
  });

  test('sınır uygulama yeniden açılsa da sürer', () async {
    pacing.markFullScreenShown();
    final reopened = await open();
    expect(reopened.canShowQuizEnd(20), isFalse);
  });

  test('sıklık kaydı açılamadıysa reklam gösterilmez', () {
    final uninitialized = AdPacing(clock: () => now);
    expect(uninitialized.canShowQuizEnd(20), isFalse);
  });
}
