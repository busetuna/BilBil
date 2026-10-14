import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// Telefondaki bir sentetik ses (ör. "tr-tr-x-cfs-local").
@immutable
class TtsVoice {
  final String name;
  final String locale;
  const TtsVoice(this.name, this.locale);
}

/// Bilbil'in sesi: dil kurulumu, ses seçimi ve canlı/enerjik konuşma.
///
/// Varsayılan sentetik ses yavaş ve düz konuştuğu için ses tonu biraz
/// yükseltilir, övgüler hızlı ve ünlemli, kelimeler ise anlaşılır hızda
/// söylenir. Ebeveyn telefondaki Türkçe sesler arasından seçim yapabilir
/// (cihaz tercihi; hesapla senkronlanmaz).
class VoiceService extends ChangeNotifier {
  static const _boxName = 'voice_box';

  /// Övgü ve sohbet cümleleri (flutter_tts'te 0.5 normal hızdır).
  static const cheerfulRate = 0.52;

  /// Kelimenin tek başına, anlaşılır söylenişi (ipucu).
  static const wordRate = 0.36;

  static const minPitch = 1.0;
  static const maxPitch = 1.4;
  static const defaultPitch = 1.2;

  final FlutterTts _tts;
  final Random _rng;
  late Box _box;
  bool _prepared = false;
  bool _languageReady = false;
  List<TtsVoice> _voices = const [];

  VoiceService({FlutterTts? tts, Random? rng})
    : _tts = tts ?? FlutterTts(),
      _rng = rng ?? Random();

  Future<void> init() async {
    _box = await Hive.openBox(_boxName);
  }

  /// Telefondaki Türkçe sesler (prepare'den sonra dolu).
  List<TtsVoice> get voices => _voices;

  /// Ebeveynin seçtiği ses; null = telefonun varsayılan Türkçe sesi.
  String? get voiceName => _box.get('voice') as String?;

  double get pitch =>
      (_box.get('pitch', defaultValue: defaultPitch) as num).toDouble();

  /// Türkçe dili ve seçili sesi ayarlar. Türkçe ses paketi yoksa false.
  Future<bool> prepare() async {
    if (_prepared) return _languageReady;
    _prepared = true;
    _tts.setErrorHandler((msg) => debugPrint('TTS Error: $msg'));
    for (final v in const ['tr-TR', 'tr_TR', 'tr']) {
      final ok = await _tts.isLanguageAvailable(v);
      if (ok == true || ok == 1) {
        await _tts.setLanguage(v);
        _languageReady = true;
        break;
      }
    }
    _voices = await _loadTurkishVoices();
    await _applyVoice();
    await _tts.setVolume(1.0);
    await _tts.setPitch(pitch);
    notifyListeners();
    return _languageReady;
  }

  Future<List<TtsVoice>> _loadTurkishVoices() async {
    try {
      final raw = await _tts.getVoices;
      if (raw is! List) return const [];
      final voices = <TtsVoice>[
        for (final v in raw)
          if (v is Map && '${v['locale']}'.toLowerCase().startsWith('tr'))
            TtsVoice('${v['name']}', '${v['locale']}'),
      ]..sort((a, b) => a.name.compareTo(b.name));
      return voices;
    } catch (e) {
      debugPrint('VoiceService voices: $e');
      return const [];
    }
  }

  Future<void> _applyVoice() async {
    final name = voiceName;
    final voice = _voices.where((v) => v.name == name).firstOrNull;
    if (voice != null) {
      await _tts.setVoice({'name': voice.name, 'locale': voice.locale});
    }
  }

  Future<void> setVoice(String? name) async {
    if (name == null) {
      await _box.delete('voice');
    } else {
      await _box.put('voice', name);
    }
    await _applyVoice();
    notifyListeners();
  }

  Future<void> setPitch(double value) async {
    final p = value.clamp(minPitch, maxPitch).toDouble();
    await _box.put('pitch', p);
    await _tts.setPitch(p);
    notifyListeners();
  }

  Future<void> speak(String text, {double rate = cheerfulRate}) async {
    await _tts.setSpeechRate(rate);
    await _tts.speak(text);
  }

  Future<void> stop() => _tts.stop();

  /// Ayarlardaki "Dinle" butonu.
  Future<void> preview() async {
    await prepare();
    await _tts.stop();
    await speak('Merhaba! Ben Bilbil. Haydi birlikte öğrenelim!');
  }

  // ── Cümleler: her seferinde biraz farklı, coşkulu ───────────────────────────

  static const _cheers = [
    'Aferin!',
    'Harika!',
    'Süpersin!',
    'Bravo!',
    'Çok güzel!',
    'Yaşasın!',
    'Muhteşem!',
  ];
  static const _almost = ['Neredeyse!', 'Az kaldı!', 'Çok yaklaştın!'];

  String _pick(List<String> options) => options[_rng.nextInt(options.length)];

  /// Doğru cevap: "Harika! Bu bir kedi!" / "Bravo! Evet, kedi!"
  String praise(String word, {bool hinted = false}) {
    if (hinted) return '${_pick(_cheers)} Birlikte başardık: $word!';
    return _rng.nextBool()
        ? '${_pick(_cheers)} Bu bir $word!'
        : '${_pick(_cheers)} Evet, $word!';
  }

  /// Yanlış cevap: neşeli kalır, doğrusunu söyler.
  String tryAgain(String word) =>
      '${_pick(_almost)} Bu bir $word. Bir dahakine sen de söyle!';
}
