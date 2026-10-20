import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:app/services/api/api_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  final requests = <http.Request>[];

  ApiService api(
    Future<http.Response> Function(http.Request) handler, {
    String baseUrl = 'https://api.test',
    String? token = 'tok',
  }) {
    return ApiService(
      baseUrl: baseUrl,
      getToken: () async => token,
      client: MockClient((req) {
        requests.add(req);
        return handler(req);
      }),
    );
  }

  setUp(requests.clear);

  test('adres verilmemişse hiç istek atmaz', () async {
    final svc = api((_) async => http.Response('{}', 200), baseUrl: '');
    expect(svc.isConfigured, isFalse);
    expect(await svc.loadUserData(), isNull);
    expect(requests, isEmpty);
  });

  test('oturum yoksa (token yok) istek atmaz', () async {
    final svc = api((_) async => http.Response('{}', 200), token: null);
    expect(await svc.loadUserData(), isNull);
    expect(requests, isEmpty);
  });

  test('loadUserData: token başlığı, 200 → veri, 404 → null', () async {
    var status = 200;
    final svc = api(
      (_) async =>
          http.Response(jsonEncode({'lives': 3, 'stats': null}), status),
    );

    expect(await svc.loadUserData(), {'lives': 3, 'stats': null});
    expect(requests.single.url.toString(), 'https://api.test/v1/me');
    expect(requests.single.headers['Authorization'], 'Bearer tok');

    status = 404;
    expect(await svc.loadUserData(), isNull);
  });

  test('loadUserData: ağ hatasında null döner, uygulamayı düşürmez', () async {
    final svc = api((_) async => throw http.ClientException('offline'));
    expect(await svc.loadUserData(), isNull);
  });

  test('createUserProfile tarihi UTC olarak gönderir', () async {
    final svc = api((_) async => http.Response('', 204));
    await svc.createUserProfile(
      name: 'Ada',
      email: 'ada@example.com',
      userType: 'UserType.parent',
      createdAt: DateTime.utc(2026, 10, 13, 12),
    );
    final req = requests.single;
    expect(req.method, 'PUT');
    expect(req.url.path, '/v1/me/profile');
    expect(jsonDecode(req.body)['createdAt'], '2026-10-13T12:00:00.000Z');
  });

  test(
    'deleteUserData: 204 → true, sunucu hatası ya da ağ hatası → false',
    () async {
      var status = 204;
      final svc = api((_) async => http.Response('', status));
      expect(await svc.deleteUserData(), isTrue);
      expect(requests.single.method, 'DELETE');
      expect(requests.single.url.path, '/v1/me');
      expect(requests.single.headers['Authorization'], 'Bearer tok');

      status = 500;
      expect(await svc.deleteUserData(), isFalse);

      final offline = api((_) async => throw http.ClientException('offline'));
      expect(await offline.deleteUserData(), isFalse);
    },
  );

  test('silmeden önce bekleyen kayıt atılır, yoldaki beklenir', () async {
    final gate = Completer<void>();
    final svc = api((req) async {
      if (req.method == 'PUT' && requests.length == 1) await gate.future;
      return http.Response('', 204);
    });

    svc.saveStats({'v': 1}); // yola çıkar, kapıda bekler
    await Future<void>.delayed(Duration.zero);
    svc.saveStats({'v': 2}); // kuyrukta bekler
    final deleting = svc.deleteUserData();
    await Future<void>.delayed(Duration.zero);
    expect(
      requests.map((r) => r.method),
      ['PUT'],
      reason: 'yoldaki kayıt bitmeden DELETE gitmemeli',
    );

    gate.complete();
    expect(await deleting, isTrue);
    expect(
      requests.map((r) => r.method),
      ['PUT', 'DELETE'],
      reason: 'kuyruktaki {v: 2} silmeden sonra satırı geri yaratmamalı',
    );
  });

  test('art arda kayıtlar sırayla gider, aradakiler atlanır', () async {
    final gate = Completer<void>();
    final svc = api((req) async {
      if (requests.length == 1) await gate.future;
      return http.Response('', 204);
    });

    svc.saveStats({'v': 1});
    await Future<void>.delayed(Duration.zero); // ilk istek yola çıksın
    svc.saveStats({'v': 2});
    svc.saveStats({'v': 3});
    svc.saveLives(4); // farklı kaynak, beklemez

    gate.complete();
    await Future<void>.delayed(const Duration(milliseconds: 50));

    final stats = requests
        .where((r) => r.url.path == '/v1/me/stats')
        .map((r) => jsonDecode(r.body)['v'])
        .toList();
    expect(stats, [1, 3]);
    expect(requests.where((r) => r.url.path == '/v1/me/lives'), hasLength(1));
  });

  ApiService retrying(
    Future<http.Response> Function(http.Request) handler, {
    Duration delay = const Duration(milliseconds: 2),
  }) => ApiService(
    baseUrl: 'https://api.test',
    getToken: () async => 'tok',
    retryDelays: [delay],
    client: MockClient((req) {
      requests.add(req);
      return handler(req);
    }),
  );

  test('ağ hatasında kayıt yeniden denenir; gidince işaret kalkar', () async {
    final seen = <bool>[];
    final svc = retrying((req) async {
      if (requests.length <= 2) throw const SocketException('internet yok');
      return http.Response('', 204);
    });
    svc.unsynced.addListener(() => seen.add(svc.unsynced.value));
    svc.saveStats({'v': 1});
    await svc.whenIdle();
    expect(requests, hasLength(3));
    expect(seen.first, isTrue);
    expect(svc.unsynced.value, isFalse);
  });

  test(
    'sunucu hatası (5xx) yeniden denenir, geçersiz veri (4xx) denenmez',
    () async {
      var calls = 0;
      final svc = retrying(
        (req) async => http.Response('', ++calls == 1 ? 503 : 204),
      );
      svc.saveLives(3);
      await svc.whenIdle();
      expect(requests, hasLength(2));

      requests.clear();
      final bad = retrying((req) async => http.Response('invalid', 400));
      bad.saveLives(9);
      await bad.whenIdle();
      expect(requests, hasLength(1));
      expect(bad.unsynced.value, isFalse);
    },
  );

  test(
    'yeniden denemeyi beklerken gelen yeni kayıt eskisinin yerini alır',
    () async {
      final svc = retrying((req) async {
        if (requests.length == 1) throw const SocketException('internet yok');
        return http.Response('', 204);
      }, delay: const Duration(milliseconds: 30));
      svc.saveStats({'v': 1});
      await Future<void>.delayed(const Duration(milliseconds: 5));
      svc.saveStats({'v': 2});
      await svc.whenIdle();
      expect(requests.map((r) => jsonDecode(r.body)['v']), [1, 2]);
    },
  );

  test('bekleyenler atılınca yeniden deneme durur', () async {
    final svc = retrying(
      (req) async => throw const SocketException('yok'),
      delay: const Duration(hours: 1),
    );
    svc.saveStats({'v': 1});
    await Future<void>.delayed(const Duration(milliseconds: 5));
    expect(svc.unsynced.value, isTrue);
    svc.discardPending();
    await svc.whenIdle(); // bir saat beklemez
    expect(requests, hasLength(1));
    expect(svc.unsynced.value, isFalse);
  });

  test('kalıcı hata yeniden denenmez, bağlantı hatası denenir', () async {
    expect(ApiService.isTransient(const SocketException('yok')), isTrue);
    expect(ApiService.isTransient(TimeoutException('geç')), isTrue);
    expect(ApiService.isTransient(http.ClientException('koptu')), isTrue);
    expect(ApiService.isTransient(ArgumentError('bozuk')), isFalse);
    expect(ApiService.isTransient(const FormatException('bozuk')), isFalse);

    final svc = retrying((req) async => throw ArgumentError('bozuk'));
    svc.saveLives(2);
    await svc.whenIdle();
    expect(requests, hasLength(1));
    expect(svc.unsynced.value, isFalse);
  });
}
