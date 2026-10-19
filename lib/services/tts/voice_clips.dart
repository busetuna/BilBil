import 'dart:async';
import 'dart:convert';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../sound/sound_service.dart';

/// Bilbil'in önceden seslendirilmiş konuşmaları (tool/generate_voice.py).
///
/// Telefonun sentetik sesi çok robotik bulundu; cümleler bilgisayarda EMA
/// Lightning ile bir kere üretilip uygulamaya gömüldü. Bir cümle, kayıtlı
/// parçalarından birleştirilir: "Harika! Bu bir kedi!" = "Harika!" +
/// "Bu bir kedi!". Parçalardan biri bile yoksa null döner ve cümle
/// telefonun sesiyle söylenir.
class VoiceClips {
  static const manifestAsset = 'assets/voice/manifest.json';

  final Map<String, String> _clips; // anahtar -> assets/voice/ altındaki yol

  const VoiceClips(this._clips);

  static const empty = VoiceClips({});

  /// CC BY 4.0 kaynak gösterimi (ayarlarda ve lisans listesinde görünür).
  static const credit =
      "Bilbil'in sesi: pocket-tts-tr (kaanhgunay, CC BY 4.0), Kyutai Pocket "
      'TTS temelli; Türkçe veri: Turkish TTS Audiobooks (Serdar I. Çağlar). '
      'Ses örneği: EMA Lightning (Canberk Aslan, Apache 2.0). Yapay zekâ sesidir.';

  static Future<VoiceClips> load([AssetBundle? bundle]) async {
    try {
      final raw = await (bundle ?? rootBundle).loadString(manifestAsset);
      final clips = (jsonDecode(raw) as Map)['clips'] as Map;
      return VoiceClips(clips.cast<String, String>());
    } catch (e) {
      debugPrint('VoiceClips: $e'); // kayıt yoksa telefonun sesi
      return empty;
    }
  }

  bool get isEmpty => _clips.isEmpty;

  /// generate_voice.py'deki key() ile aynı: Türkçe küçük harf, tek boşluk,
  /// sondaki noktalama atılır ("Bu bir elma." ile "Bu bir elma!" aynı kayıt).
  static String key(String text) => text
      .replaceAll('İ', 'i')
      .replaceAll('I', 'ı')
      .toLowerCase()
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim()
      .replaceAll(RegExp(r'[.!?,:;]+$'), '')
      .trim();

  // Cümle sonu (. ! ? : ,) ardından boşlukta böl; "Bu bir... kedi" bölünmez.
  static final _boundary = RegExp(r'(?<=[^.][.!?:,])\s+');

  /// Sırayla çalınacak kayıtlar (AssetSource yolları), ya da null.
  List<String>? assetsFor(String text) {
    if (_clips.isEmpty) return null;
    final whole = _clips[key(text)];
    if (whole != null) return ['voice/$whole'];
    final parts = text.trim().split(_boundary);
    final out = <String>[];
    var i = 0;
    while (i < parts.length) {
      String? hit;
      var j = parts.length;
      for (; j > i; j--) {
        hit = _clips[key(parts.sublist(i, j).join(' '))];
        if (hit != null) break;
      }
      if (hit == null) return null;
      out.add('voice/$hit');
      i = j;
    }
    return out;
  }
}

/// Kayıtları sırayla çalar; testlerde sahtesi kullanılır.
abstract class ClipPlayer {
  /// [text] söylenen cümle; [assets] sırayla çalınacak parçalar. Bitince
  /// (ya da [stop] ile kesilince) tamamlanır.
  Future<void> play(String text, List<String> assets);
  Future<void> stop();
}

class AudioplayersClipPlayer implements ClipPlayer {
  AudioPlayer? _player;
  Completer<void>? _stopped;

  @override
  Future<void> play(String text, List<String> assets) async {
    await stop(); // önceki cümle yarıda kalsın
    final stopped = _stopped = Completer<void>();
    final p = _player ??= await _create();
    for (final asset in assets) {
      if (stopped.isCompleted) return;
      final done = p.onPlayerComplete.first;
      await p.play(AssetSource(asset));
      // Kesilirse onPlayerComplete gelmeyebilir; takılıp kalmasın.
      await Future.any([
        done,
        stopped.future,
        Future<void>.delayed(const Duration(seconds: 8)),
      ]);
    }
  }

  static Future<AudioPlayer> _create() async {
    final p = AudioPlayer();
    await p.setAudioContext(AudioplayersBackend.audioContext);
    await p.setPlayerMode(PlayerMode.mediaPlayer);
    await p.setReleaseMode(ReleaseMode.stop);
    return p;
  }

  @override
  Future<void> stop() async {
    final s = _stopped;
    if (s != null && !s.isCompleted) s.complete();
    await _player?.stop();
  }
}
