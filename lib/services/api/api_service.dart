import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// [ApiService.fetchUserData] sonucu.
sealed class UserDataResult {
  const UserDataResult();
}

/// Sunucuda bu kullanıcının verisi var.
class UserDataFound extends UserDataResult {
  final Map<String, dynamic> data;
  const UserDataFound(this.data);
}

/// Sunucuya ulaşıldı ama kullanıcının henüz verisi yok (ilk giriş).
class UserDataMissing extends UserDataResult {
  const UserDataMissing();
}

/// Sunucuya ulaşılamadı ya da hata döndü: buluttaki veri bilinmiyor.
class UserDataUnavailable extends UserDataResult {
  const UserDataUnavailable();
}

/// Railway'deki Bilbil API'si (bkz. backend/).
///
/// Kimlik Firebase ID token'ı ile kanıtlanır; sunucu kullanıcıyı token'dan
/// bulduğu için uid gönderilmez. Varsayılan adres Railway'deki servistir;
/// yerel bir sunucuyla denemek için derlemede değiştirilebilir:
///   flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000
/// Adres boş verilirse bulut senkronu kapanır, uygulama yerel veriyle çalışır.
class ApiService {
  static const _defaultBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://api-production-9c46.up.railway.app',
  );
  static const _timeout = Duration(seconds: 10);

  final http.Client _client;
  final String _baseUrl;
  final Future<String?> Function() _getToken;

  /// Gönderilemeyen kaydın yeniden deneme aralıkları (sonuncusu tekrarlanır).
  static const defaultRetryDelays = [
    Duration(seconds: 5),
    Duration(seconds: 15),
    Duration(minutes: 1),
    Duration(minutes: 5),
  ];

  final List<Duration> _retryDelays;

  ApiService({
    http.Client? client,
    String? baseUrl,
    Future<String?> Function()? getToken,
    List<Duration> retryDelays = defaultRetryDelays,
  }) : _client = client ?? http.Client(),
       _baseUrl = baseUrl ?? _defaultBaseUrl,
       _retryDelays = retryDelays,
       _getToken =
           getToken ??
           (() async => fb.FirebaseAuth.instance.currentUser?.getIdToken());

  bool get isConfigured => _baseUrl.isNotEmpty;

  // Aynı kaynağa giden kayıtlar sırayla gönderilir; biri yoldayken gelen
  // yeni kayıt bekleyenin yerini alır, böylece eski veri yeniyi ezemez.
  final Map<String, Object> _pending = {};
  final Map<String, Future<void>> _sending = {};

  /// Gönderilemeyip yeniden denenmeyi bekleyen kayıt var mı. AccountSync
  /// bunu cihazda saklar: uygulama bu arada kapanırsa sonraki açılışta
  /// buluttaki eski veri yereldekinin üstüne yazılmaz.
  final unsynced = ValueNotifier<bool>(false);
  final Set<String> _failing = {};

  // Hesap değişince/silinince artar: yoldaki ya da beklemedeki eski kayıt
  // yeni hesaba gönderilmesin. Uyuyan yeniden denemeler _wake ile uyanır.
  int _generation = 0;
  Completer<void> _wake = Completer<void>();

  /// Kullanıcının bulut verisi; "veri yok" ile "ulaşılamadı" ayrı döner.
  Future<UserDataResult> fetchUserData() async {
    try {
      final res = await _request('GET', '/v1/me');
      if (res == null) return const UserDataUnavailable();
      if (res.statusCode == 404) return const UserDataMissing();
      if (res.statusCode != 200) {
        debugPrint('ApiService.fetchUserData: HTTP ${res.statusCode}');
        return const UserDataUnavailable();
      }
      return UserDataFound(jsonDecode(res.body) as Map<String, dynamic>);
    } catch (e) {
      debugPrint('ApiService.fetchUserData: $e');
      return const UserDataUnavailable();
    }
  }

  /// Kullanıcının bulut verisi; hiç verisi yoksa ya da ulaşılamazsa null.
  Future<Map<String, dynamic>?> loadUserData() async =>
      switch (await fetchUserData()) {
        UserDataFound(:final data) => data,
        _ => null,
      };

  Future<void> createUserProfile({
    required String name,
    required String email,
    required String userType,
    required DateTime createdAt,
  }) async {
    try {
      await _request('PUT', '/v1/me/profile', {
        'name': name,
        'email': email,
        'userType': userType,
        'createdAt': createdAt.toUtc().toIso8601String(),
      });
    } catch (e) {
      debugPrint('ApiService.createUserProfile: $e');
    }
  }

  void saveStats(Map<String, dynamic> data) => _enqueue('/v1/me/stats', data);

  void saveRewards(Map<String, dynamic> data) =>
      _enqueue('/v1/me/rewards', data);

  void saveLives(int lives) => _enqueue('/v1/me/lives', {'lives': lives});

  void saveWordProgress(Map<String, Map<String, Object>> words) =>
      _enqueue('/v1/me/progress', {'words': words});

  /// Kullanıcının sunucudaki tüm verisini siler (hesap silme). Başarılıysa
  /// true. Önce bekleyen kayıtlar atılır ve yoldakiler beklenir; yoksa
  /// silmeden sonra varan bir kayıt satırı yeniden oluştururdu.
  Future<bool> deleteUserData() async {
    discardPending();
    await Future.wait(_sending.values.toList());
    try {
      final res = await _request('DELETE', '/v1/me');
      return res != null && (res.statusCode == 204 || res.statusCode == 404);
    } catch (e) {
      debugPrint('ApiService.deleteUserData: $e');
      return false;
    }
  }

  void _enqueue(String path, Object body) {
    _pending[path] = body;
    _sending.putIfAbsent(path, () => _drain(path));
  }

  /// Bekleyen ve yeniden denenecek kayıtları atar (hesap değişimi/silme).
  void discardPending() {
    _generation++;
    _pending.clear();
    _failing.clear();
    unsynced.value = false;
    final wake = _wake;
    _wake = Completer<void>();
    wake.complete();
  }

  /// Yoldaki ve yeniden denenmeyi bekleyen gönderimler bitene kadar bekler.
  Future<void> whenIdle() async {
    while (_sending.isNotEmpty) {
      await Future.wait(_sending.values.toList());
    }
  }

  // Ağ hatası, zaman aşımı ya da sunucu hatasında kayıt artan aralıklarla
  // yeniden denenir; önceden sessizce düşüyordu ve bulut, bir sonraki
  // değişikliğe kadar (belki hiç) güncellenmiyordu. Bu arada gelen daha yeni
  // kayıt eskisinin yerini alır.
  Future<void> _drain(String path) async {
    var attempt = 0;
    try {
      while (_pending.containsKey(path)) {
        final generation = _generation;
        final body = _pending.remove(path)!;
        final retry = await _send(path, body);
        if (generation != _generation) return; // atıldı
        _setFailing(path, retry);
        if (!retry) {
          attempt = 0;
          continue;
        }
        _pending.putIfAbsent(path, () => body);
        final delay = _retryDelays[min(attempt++, _retryDelays.length - 1)];
        await Future.any([Future<void>.delayed(delay), _wake.future]);
      }
    } finally {
      _sending.remove(path);
    }
  }

  /// true: yeniden denenmeli. Geçersiz veri (4xx) yeniden denenmez:
  /// tekrar göndermek düzeltmez.
  Future<bool> _send(String path, Object body) async {
    try {
      final res = await _request('PUT', path, body);
      if (res == null) return false; // adres ya da oturum yok
      if (res.statusCode >= 500 || res.statusCode == 429) {
        debugPrint(
          'ApiService $path: HTTP ${res.statusCode}, yeniden denenecek',
        );
        return true;
      }
      if (res.statusCode >= 400) {
        debugPrint('ApiService $path: HTTP ${res.statusCode} ${res.body}');
      }
      return false;
    } catch (e) {
      final retry = isTransient(e);
      debugPrint('ApiService $path: $e${retry ? ', yeniden denenecek' : ''}');
      return retry;
    }
  }

  /// Bağlantıdan kaynaklanan, sonra düzelebilecek hata mı? Kalıcı hatalar
  /// (kodlama, programlama hatası) yeniden denenmez; sonsuza dek denenirdi.
  @visibleForTesting
  static bool isTransient(Object e) =>
      e is TimeoutException ||
      e is http.ClientException || // SocketException'ı da sarar
      e is IOException ||
      (e is fb.FirebaseException && e.code == 'network-request-failed');

  void _setFailing(String path, bool failing) {
    failing ? _failing.add(path) : _failing.remove(path);
    unsynced.value = _failing.isNotEmpty;
  }

  Future<http.Response?> _request(
    String method,
    String path, [
    Object? body,
  ]) async {
    if (!isConfigured) return null;
    final token = await _getToken();
    if (token == null) return null;

    final req = http.Request(method, Uri.parse('$_baseUrl$path'))
      ..headers['Authorization'] = 'Bearer $token';
    if (body != null) {
      req.headers['Content-Type'] = 'application/json';
      req.body = jsonEncode(body);
    }
    final streamed = await _client.send(req).timeout(_timeout);
    return http.Response.fromStream(streamed);
  }
}
