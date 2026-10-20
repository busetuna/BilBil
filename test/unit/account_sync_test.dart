import 'dart:convert';
import 'dart:io';

import 'package:app/services/api/api_service.dart';
import 'package:app/services/learning/word_progress_service.dart';
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
  late WordProgressService progress;
  late AccountSync sync;
  // Sunucunun GET /v1/me cevabı; testler hesaba göre değiştirir.
  late http.Response Function() me;
  // PUT'lara verilecek cevap; testler sunucu hatası verdirebilir.
  late int putStatus;
  final puts = <http.Request>[];

  ApiService makeApi() => ApiService(
    baseUrl: 'https://api.test',
    getToken: () async => 'tok',
    retryDelays: const [Duration(milliseconds: 5)],
    client: MockClient((req) async {
      if (req.method == 'GET') return me();
      puts.add(req);
      return http.Response('', putStatus);
    }),
  );

  AccountSync makeSync(ApiService api) => AccountSync(
    api: api,
    stats: stats,
    rewards: rewards,
    lives: lives,
    progress: progress,
    retryDelays: const [Duration(milliseconds: 30)],
  );

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('bilbil_test');
    Hive.init(dir.path);
    puts.clear();
    me = () => http.Response('', 404);
    putStatus = 204;
    final api = makeApi();
    stats = StatsService();
    await stats.init();
    rewards = RewardService();
    await rewards.init();
    lives = LivesService();
    await lives.init();
    progress = WordProgressService();
    await progress.init();
    sync = makeSync(api);
    await sync.init();
  });

  tearDown(() async {
    sync.dispose();
    await Hive.deleteFromDisk();
    await dir.delete(recursive: true);
  });

  Future<void> settle() =>
      Future<void>.delayed(const Duration(milliseconds: 20));

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

  test(
    'başka hesap girince önceki hesabın verisi taşınmaz ve buluta yazılmaz',
    () async {
      await sync.onSignedIn('a');
      await play(3);
      stats.changePin('9876');
      progress.record('Kedi', correct: false);
      sync.onSignedOut();

      await sync.onSignedIn('b'); // b'nin bulutta verisi yok (404)
      expect(
        progress.boxOf('Kedi'),
        isNull,
        reason: 'kelime geçmişi de taşınmaz',
      );
      expect(stats.totalCorrect, 0);
      expect(stats.hasPin, isFalse);
      expect(rewards.totalCorrect, 0);
      expect(lives.lives, LivesService.maxLives);

      puts.clear();
      stats.recordAnswer(correct: true, difficulty: 0);
      await settle();
      expect(sentStats().last['totalCorrect'], 1);
    },
  );

  test('aynı hesap yeniden girince yerel veri korunur', () async {
    await sync.onSignedIn('a');
    await play(3);
    sync.onSignedOut();

    await sync.onSignedIn('a');
    expect(stats.totalCorrect, 3);
    expect(rewards.totalCorrect, 3);
  });

  test(
    'güncellemeden önce kullanılan cihazda (sahip kaydı yok) veri silinmez',
    () async {
      await play(2); // eski sürümde birikmiş veri
      await sync.onSignedIn('a');
      expect(stats.totalCorrect, 2);
    },
  );

  test('bulutta veri varsa yerele yüklenir', () async {
    me = () => http.Response(
      jsonEncode({
        'stats': {'totalCorrect': 7, 'totalWrong': 1, 'childAge': 4},
        'rewards': {'totalCorrect': 7, 'earnedIds': [], 'puzzlePieces': {}},
        'lives': 2,
        'wordProgress': {
          'kedi': {'word': 'Kedi', 'box': 3, 'seen': 4, 'wrong': 1, 'last': 1},
        },
      }),
      200,
    );
    await sync.onSignedIn('a');
    expect(stats.totalCorrect, 7);
    expect(stats.childAge, 4);
    expect(rewards.totalCorrect, 7);
    expect(lives.lives, 2);
    expect(progress.boxOf('Kedi'), 3);
  });

  test(
    'sunucuya ulaşılamazsa senkron açılmaz, buluttaki veri ezilmez',
    () async {
      me = () => http.Response('', 503);
      await sync.onSignedIn('a');
      stats.recordAnswer(correct: true, difficulty: 0);
      lives.loseLife();
      await settle();
      expect(puts, isEmpty);
    },
  );

  test(
    'hesap silinince cihazdaki verisi de silinir ve senkron kapanır',
    () async {
      await sync.onSignedIn('a');
      await play(3);
      stats.changePin('9876');
      await sync.onAccountDeleted();

      expect(stats.totalCorrect, 0);
      expect(stats.hasPin, isFalse);
      expect(rewards.totalCorrect, 0);
      expect(lives.lives, LivesService.maxLives);

      puts.clear();
      stats.recordAnswer(correct: true, difficulty: 0);
      await settle();
      expect(puts, isEmpty);
    },
  );

  test('hesap değişince cihaz tercihi (ASR motoru) korunur', () async {
    await sync.onSignedIn('a');
    stats.setAsrEngine('platform');
    sync.onSignedOut();
    await sync.onSignedIn('b');
    expect(stats.asrEngine, 'platform');
  });

  http.Response cloud(int totalCorrect) => http.Response(
    jsonEncode({
      'stats': {'totalCorrect': totalCorrect, 'totalWrong': 0, 'childAge': 4},
      'rewards': {
        'totalCorrect': totalCorrect,
        'earnedIds': [],
        'puzzlePieces': {},
      },
      'lives': 5,
      'wordProgress': {},
    }),
    200,
  );

  test('internet gelince yeniden bağlanır; çevrimdışı oynanan yerel veri '
      'buluta yazılır, buluttaki eski veri üstüne yazılmaz', () async {
    me = () => http.Response('', 503);
    await sync.onSignedIn('a');
    await play(3); // internetsiz oyun
    expect(sync.hasUnsyncedChanges, isTrue);
    expect(puts, isEmpty);

    me = () => cloud(1); // buluttaki eski kayıt
    await Future<void>.delayed(const Duration(milliseconds: 120));
    expect(stats.totalCorrect, 3, reason: 'yerel ilerleme korunur');
    expect(sentStats().last['totalCorrect'], 3);
    expect(sync.hasUnsyncedChanges, isFalse);
  });

  test(
    'çevrimdışı değişiklik yoksa internet gelince buluttaki veri yüklenir',
    () async {
      me = () => http.Response('', 503);
      await sync.onSignedIn('a');
      me = () => cloud(7);
      await Future<void>.delayed(const Duration(milliseconds: 120));
      expect(stats.totalCorrect, 7);
      expect(puts, isEmpty);
    },
  );

  test('gönderilemeyen kayıt cihazda işaretlenir; sonraki açılışta bulut '
      'yerel ilerlemeyi ezmez, yerel veri gönderilir', () async {
    await sync.onSignedIn('a'); // bulutta veri yok, senkron açık
    putStatus = 503;
    await play(2);
    await settle();
    expect(sync.hasUnsyncedChanges, isTrue);

    // Uygulama kapandı; yeniden açılışta sunucu çalışıyor ama eski veriyle.
    sync.dispose();
    putStatus = 204;
    puts.clear();
    me = () => cloud(0);
    sync = makeSync(makeApi());
    await sync.init();
    await sync.onSignedIn('a');
    await Future<void>.delayed(const Duration(milliseconds: 60));
    expect(stats.totalCorrect, 2);
    expect(sentStats().last['totalCorrect'], 2);
    expect(sync.hasUnsyncedChanges, isFalse);
  });

  test(
    'hesap değişince eski hesabın bekleyen kaydı yeni hesaba gitmez',
    () async {
      await sync.onSignedIn('a');
      putStatus = 503;
      await play(4);
      await settle();
      putStatus = 204;
      puts.clear();
      await sync.onSignedIn('b');
      await Future<void>.delayed(const Duration(milliseconds: 60));
      expect(sentStats().where((s) => s['totalCorrect'] == 4), isEmpty);
      expect(stats.totalCorrect, 0);
    },
  );
}
