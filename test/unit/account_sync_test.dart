import 'dart:convert';
import 'dart:io';

import 'package:app/services/api/api_service.dart';
import 'package:app/services/lives/lives_service.dart';
import 'package:app/services/rewards/reward_service.dart';
import 'package:app/services/stats/stats_service.dart';
import 'package:app/services/sync/account_sync.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  late Directory dir;
  late StatsService stats;
  late RewardService rewards;
  late LivesService lives;
  late AccountSync sync;
  // Sunucunun GET /v1/me cevabı; testler hesaba göre değiştirir.
  late http.Response Function() me;
  final puts = <http.Request>[];

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('bilbil_test');
    Hive.init(dir.path);
    puts.clear();
    me = () => http.Response('', 404);
    final api = ApiService(
      baseUrl: 'https://api.test',
      getToken: () async => 'tok',
      client: MockClient((req) async {
        if (req.method == 'GET') return me();
        puts.add(req);
        return http.Response('', 204);
      }),
    );
    stats = StatsService();
    await stats.init();
    rewards = RewardService();
    await rewards.init();
    lives = LivesService();
    await lives.init();
    sync = AccountSync(api: api, stats: stats, rewards: rewards, lives: lives);
    await sync.init();
  });

  tearDown(() async {
    await Hive.deleteFromDisk();
    await dir.delete(recursive: true);
  });

  Future<void> settle() => Future<void>.delayed(const Duration(milliseconds: 20));

  List<Map<String, dynamic>> sentStats() => puts
      .where((r) => r.url.path == '/v1/me/stats')
      .map((r) => jsonDecode(r.body) as Map<String, dynamic>)
      .toList();

  Future<void> play(int correct) async {
    for (var i = 0; i < correct; i++) {
      stats.recordAnswer(correct: true, difficulty: 0);
      await rewards.addCorrect();
    }
    lives.loseLife();
  }

  test('başka hesap girince önceki hesabın verisi taşınmaz ve buluta yazılmaz',
      () async {
    await sync.onSignedIn('a');
    await play(3);
    stats.changePin('9876');
    sync.onSignedOut();

    await sync.onSignedIn('b'); // b'nin bulutta verisi yok (404)
    expect(stats.totalCorrect, 0);
    expect(stats.pin, '1234');
    expect(rewards.totalCorrect, 0);
    expect(lives.lives, LivesService.maxLives);

    puts.clear();
    stats.recordAnswer(correct: true, difficulty: 0);
    await settle();
    expect(sentStats().last['totalCorrect'], 1);
  });

  test('aynı hesap yeniden girince yerel veri korunur', () async {
    await sync.onSignedIn('a');
    await play(3);
    sync.onSignedOut();

    await sync.onSignedIn('a');
    expect(stats.totalCorrect, 3);
    expect(rewards.totalCorrect, 3);
  });

  test('güncellemeden önce kullanılan cihazda (sahip kaydı yok) veri silinmez',
      () async {
    await play(2); // eski sürümde birikmiş veri
    await sync.onSignedIn('a');
    expect(stats.totalCorrect, 2);
  });

  test('bulutta veri varsa yerele yüklenir', () async {
    me = () => http.Response(
        jsonEncode({
          'stats': {'totalCorrect': 7, 'totalWrong': 1, 'childAge': 4},
          'rewards': {'totalCorrect': 7, 'earnedIds': [], 'puzzlePieces': {}},
          'lives': 2,
        }),
        200);
    await sync.onSignedIn('a');
    expect(stats.totalCorrect, 7);
    expect(stats.childAge, 4);
    expect(rewards.totalCorrect, 7);
    expect(lives.lives, 2);
  });

  test('sunucuya ulaşılamazsa senkron açılmaz, buluttaki veri ezilmez',
      () async {
    me = () => http.Response('', 503);
    await sync.onSignedIn('a');
    stats.recordAnswer(correct: true, difficulty: 0);
    lives.loseLife();
    await settle();
    expect(puts, isEmpty);
  });

  test('hesap değişince cihaz tercihi (ASR motoru) korunur', () async {
    await sync.onSignedIn('a');
    stats.setAsrEngine('platform');
    sync.onSignedOut();
    await sync.onSignedIn('b');
    expect(stats.asrEngine, 'platform');
  });
}
