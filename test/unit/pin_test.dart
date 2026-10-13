import 'dart:convert';
import 'dart:io';

import 'package:app/services/api/api_service.dart';
import 'package:app/services/stats/stats_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  late Directory dir;
  late DateTime now;
  late StatsService stats;

  Future<StatsService> open() async {
    final s = StatsService(clock: () => now);
    await s.init();
    return s;
  }

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('bilbil_pin_test');
    Hive.init(dir.path);
    now = DateTime(2026, 10, 13, 12);
    stats = await open();
  });

  tearDown(() async {
    await Hive.deleteFromDisk();
    await dir.delete(recursive: true);
  });

  test('başta PIN yoktur; hiçbir PIN kabul edilmez', () {
    expect(stats.hasPin, isFalse);
    expect(stats.verifyPin('1234'), isFalse);
  });

  test('PIN belirlenince doğrusu kabul, yanlışı ret; düz metin saklanmaz', () {
    stats.changePin('2468');
    expect(stats.hasPin, isTrue);
    expect(stats.verifyPin('2468'), isTrue);
    expect(stats.verifyPin('1357'), isFalse);

    final box = Hive.box('stats');
    expect(box.get('pin'), isNull);
    expect(box.values.whereType<String>(), isNot(contains('2468')));
  });

  test('5 yanlıştan sonra kilitlenir, süre dolunca açılır', () {
    stats.changePin('2468');
    for (var i = 0; i < StatsService.maxPinAttempts - 1; i++) {
      expect(stats.verifyPin('0000'), isFalse);
    }
    expect(stats.pinAttemptsLeft, 1);
    expect(stats.pinLockRemaining, isNull);

    expect(stats.verifyPin('0000'), isFalse);
    expect(stats.pinLockRemaining, isNotNull);
    expect(stats.verifyPin('2468'), isFalse, reason: 'kilitliyken doğru PIN de reddedilir');

    now = now.add(StatsService.pinLockDuration + const Duration(seconds: 1));
    expect(stats.pinLockRemaining, isNull);
    expect(stats.verifyPin('2468'), isTrue);
    expect(stats.pinAttemptsLeft, StatsService.maxPinAttempts);
  });

  test('kilit uygulama yeniden açılsa da sürer', () async {
    stats.changePin('2468');
    for (var i = 0; i < StatsService.maxPinAttempts; i++) {
      stats.verifyPin('0000');
    }
    final reopened = await open();
    expect(reopened.pinLockRemaining, isNotNull);
  });

  test('eski sürümün düz metin PIN\'i özete çevrilir', () async {
    await Hive.deleteFromDisk();
    Hive.init(dir.path);
    await (await Hive.openBox('stats')).put('pin', '5678');

    final migrated = await open();
    expect(migrated.hasPin, isTrue);
    expect(migrated.verifyPin('5678'), isTrue);
    expect(Hive.box('stats').get('pin'), isNull);
  });

  test('eski varsayılan 1234 "PIN belirlenmemiş" sayılır', () async {
    await Hive.deleteFromDisk();
    Hive.init(dir.path);
    await (await Hive.openBox('stats')).put('pin', '1234');

    final migrated = await open();
    expect(migrated.hasPin, isFalse);
  });

  test('PIN sıfırlanınca (unuttum) yenisi belirlenene kadar PIN yoktur', () {
    stats.changePin('2468');
    stats.clearPin();
    expect(stats.hasPin, isFalse);
    expect(stats.verifyPin('2468'), isFalse);
  });

  test('buluta düz PIN değil özet gider; özet başka cihazda da çalışır',
      () async {
    final bodies = <Map<String, dynamic>>[];
    stats.setCloudSync(ApiService(
      baseUrl: 'https://api.test',
      getToken: () async => 'tok',
      client: MockClient((req) async {
        bodies.add(jsonDecode(req.body) as Map<String, dynamic>);
        return http.Response('', 204);
      }),
    ));
    stats.changePin('2468');
    await Future<void>.delayed(const Duration(milliseconds: 20));

    final sent = bodies.last;
    expect(sent.containsKey('pin'), isFalse);
    expect(sent['pinHash'], matches(RegExp(r'^[0-9a-f]{64}$')));
    expect(sent['pinSalt'], matches(RegExp(r'^[0-9a-f]{32}$')));

    // Başka cihaz: boş veriyle başlar, buluttakini yükler.
    stats.clearCloudSync();
    await stats.clearAccountData();
    expect(stats.hasPin, isFalse);
    await stats.loadFromCloud(sent);
    expect(stats.verifyPin('2468'), isTrue);
  });
}
