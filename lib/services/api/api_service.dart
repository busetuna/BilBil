import 'dart:async';
import 'dart:convert';

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
  static const _defaultBaseUrl = String.fromEnvironment('API_BASE_URL',
      defaultValue: 'https://api-production-9c46.up.railway.app');
  static const _timeout = Duration(seconds: 10);

  final http.Client _client;
  final String _baseUrl;
  final Future<String?> Function() _getToken;

  ApiService({
    http.Client? client,
    String? baseUrl,
    Future<String?> Function()? getToken,
  })  : _client = client ?? http.Client(),
        _baseUrl = baseUrl ?? _defaultBaseUrl,
        _getToken = getToken ??
            (() async => fb.FirebaseAuth.instance.currentUser?.getIdToken());

  bool get isConfigured => _baseUrl.isNotEmpty;

  // Aynı kaynağa giden kayıtlar sırayla gönderilir; biri yoldayken gelen
  // yeni kayıt bekleyenin yerini alır, böylece eski veri yeniyi ezemez.
  final Map<String, Object> _pending = {};
  final Set<String> _sending = {};

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

  void _enqueue(String path, Object body) {
    _pending[path] = body;
    if (_sending.add(path)) _drain(path);
  }

  Future<void> _drain(String path) async {
    try {
      while (_pending.containsKey(path)) {
        final body = _pending.remove(path)!;
        try {
          final res = await _request('PUT', path, body);
          if (res != null && res.statusCode >= 400) {
            debugPrint('ApiService $path: HTTP ${res.statusCode} ${res.body}');
          }
        } catch (e) {
          debugPrint('ApiService $path: $e');
        }
      }
    } finally {
      _sending.remove(path);
    }
  }

  Future<http.Response?> _request(String method, String path,
      [Object? body]) async {
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
