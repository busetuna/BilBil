import 'dart:io';

import 'package:app/services/lives/lives_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

void main() {
  late Directory dir;
  late DateTime now;
  late LivesService lives;

  Future<LivesService> open() async {
    final s = LivesService(clock: () => now);
    await s.init();
    return s;
  }

  void loseAll(LivesService s) {
    for (var i = 0; i < LivesService.maxLives; i++) {
      s.loseLife();
    }
  }

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('bilbil_lives_test');
    Hive.init(dir.path);
    now = DateTime(2026, 10, 13, 12);
    lives = await open();
  });

  tearDown(() async {
    await Hive.deleteFromDisk();
    await dir.delete(recursive: true);
  });

  test('başta canlar dolu, mola yok', () {
    expect(lives.lives, LivesService.maxLives);
    expect(lives.restRemaining, isNull);
    expect(lives.ensurePlayable(), isTrue);
  });

  test('canlar bitince mola başlar, mola bitmeden oynanamaz', () {
    loseAll(lives);
    expect(lives.lives, 0);
    expect(lives.restRemaining, LivesService.restDuration);
    expect(lives.ensurePlayable(), isFalse);
    expect(lives.lives, 0);

    lives.loseLife(); // 0'ın altına inmez
    expect(lives.lives, 0);
  });

  test('mola dolunca canlar kendiliğinden dolar', () {
    loseAll(lives);
    now = now.add(LivesService.restDuration + const Duration(seconds: 1));
    expect(lives.restRemaining, isNull);
    expect(lives.ensurePlayable(), isTrue);
    expect(lives.lives, LivesService.maxLives);
  });

  test('ebeveyn molayı erken bitirebilir', () {
    loseAll(lives);
    lives.refillLives();
    expect(lives.lives, LivesService.maxLives);
    expect(lives.restRemaining, isNull);
  });

  test('mola uygulama yeniden açılsa da sürer', () async {
    loseAll(lives);
    now = now.add(const Duration(minutes: 1));
    final reopened = await open();
    expect(reopened.lives, 0);
    expect(reopened.restRemaining, LivesService.restDuration - const Duration(minutes: 1));
    expect(reopened.ensurePlayable(), isFalse);
  });

  test('buluttan 0 can gelirse (mola zamanı bilinmiyor) oyun kilitli kalmaz', () async {
    await lives.loadFromCloud(0);
    expect(lives.ensurePlayable(), isTrue);
    expect(lives.lives, LivesService.maxLives);
  });
}
