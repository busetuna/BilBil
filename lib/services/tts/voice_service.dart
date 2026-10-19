import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'voice_clips.dart';

/// Telefondaki bir sentetik ses (ör. "tr-tr-x-cfs-local").
@immutable
class TtsVoice {
  final String name;
  final String locale;
  const TtsVoice(this.name, this.locale);
}

/// Bilbil'in sesi.
///
/// Varsayılan: önceden seslendirilmiş neşeli kayıtlar (bkz. [VoiceClips],
/// tool/generate_voice.py). Telefonun sentetik sesi çok robotik bulundu;
/// artık yalnızca kaydı olmayan bir cümlede ya da ebeveyn ayarlardan
/// telefonun sesini seçerse kullanılır. Tercihler cihazdadır (hesapla
/// senkronlanmaz).
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
  final ClipPlayer _clipPlayer;
  final VoiceClips? _injectedClips;
  final Random _rng;
  late Box _box;
  VoiceClips _clips = VoiceClips.empty;
  bool _prepared = false;
  bool _languageReady = false;
  List<TtsVoice> _voices = const [];

  VoiceService({
    FlutterTts? tts,
    ClipPlayer? clipPlayer,
    VoiceClips? clips,
    Random? rng,
  }) : _tts = tts ?? FlutterTts(),
       _clipPlayer = clipPlayer ?? AudioplayersClipPlayer(),
       _injectedClips = clips,
       _rng = rng ?? Random();

  Future<void> init() async {
    _box = await Hive.openBox(_boxName);
    _clips = _injectedClips ?? await VoiceClips.load();
  }

  /// Kayıtlı ses var mı (uygulamayla gelir; testlerde boş olabilir).
  bool get hasRecordedVoice => !_clips.isEmpty;

  /// Bilbil'in kayıtlı sesi mi, telefonun sesi mi (ebeveyn seçer).
  bool get useRecorded =>
      hasRecordedVoice && (_box.get('recorded', defaultValue: true) as bool);

  Future<void> setUseRecorded(bool on) async {
    await _box.put('recorded', on);
    notifyListeners();
  }

  /// Telefondaki Türkçe sesler (prepare'den sonra dolu).
  List<TtsVoice> get voices => _voices;

  /// Ebeveynin seçtiği telefon sesi; null = telefonun varsayılan Türkçe sesi.
  String? get voiceName => _box.get('voice') as String?;

  double get pitch =>
      (_box.get('pitch', defaultValue: defaultPitch) as num).toDouble();

  /// Telefonun sesini (yedek) hazırlar. Konuşabiliyorsa true: kayıtlı ses
  /// varken Türkçe ses paketi olmasa da Bilbil konuşur.
  Future<bool> prepare() async {
    if (!_prepared) {
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
    }
    return _languageReady || useRecorded;
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

  /// Telefonun seslerinden birini seçer (kayıtlı ses kapanır).
  Future<void> setVoice(String? name) async {
    if (name == null) {
      await _box.delete('voice');
    } else {
      await _box.put('voice', name);
    }
    await _box.put('recorded', false);
    await _applyVoice();
    notifyListeners();
  }

  Future<void> setPitch(double value) async {
    final p = value.clamp(minPitch, maxPitch).toDouble();
    await _box.put('pitch', p);
    await _tts.setPitch(p);
    notifyListeners();
  }

  /// [rate] yalnızca telefonun sesi için; kayıtlar kendi hızlarındadır.
  Future<void> speak(String text, {double rate = cheerfulRate}) async {
    final assets = useRecorded ? _clips.assetsFor(text) : null;
    if (assets != null) {
      await _tts.stop();
      await _clipPlayer.play(text, assets);
      return;
    }
    await _clipPlayer.stop();
    await _tts.setSpeechRate(rate);
    await _tts.speak(text);
  }

  Future<void> stop() async {
    await _clipPlayer.stop();
    await _tts.stop();
  }

  /// Ayarlardaki "Dinle" butonu.
  Future<void> preview() async {
    await prepare();
    await stop();
    await speak(greeting);
  }

  // ── Cümleler ───────────────────────────────────────────────────────────────
  // Her biri kayıtlı parçalardan kurulur (tool/generate_voice.py aynı
  // listeleri üretir; voice_service_test her cümlenin kaydı olduğunu
  // denetler). Kelime tek başına kaydedilmez: kısa tek kelimelik kayıtlar
  // güvenilmezdi, "Evet, kedi!" yerine hep "Bu bir kedi!" denir.

  static const cheers = [
    'Aferin!',
    'Harika!',
    'Süpersin!',
    'Bravo!',
    'Çok güzel!',
    'Yaşasın!',
    'Muhteşem!',
  ];
  static const almost = ['Neredeyse!', 'Az kaldı!', 'Çok yaklaştın!'];

  static const greeting = 'Merhaba! Ben Bilbil. Haydi birlikte öğrenelim!';
  static const notHeard = 'Seni duyamadım! Bir daha söyler misin?';

  String _pick(List<String> options) => options[_rng.nextInt(options.length)];

  /// Doğru cevap: "Harika! Bu bir kedi!". [lead] kategoriye göre cümle
  /// başı: "Bu renk kırmızı", "Çocuk koşuyor".
  String praise(String word, {bool hinted = false, String lead = 'Bu bir'}) =>
      praiseWith(_pick(cheers), word, hinted: hinted, lead: lead);

  static String praiseWith(
    String cheer,
    String word, {
    bool hinted = false,
    String lead = 'Bu bir',
  }) =>
      hinted ? '$cheer Birlikte başardık! $lead $word!' : '$cheer $lead $word!';

  /// Yanlış cevap: neşeli kalır, doğrusunu söyler.
  String tryAgain(String word, {String lead = 'Bu bir'}) =>
      tryAgainWith(_pick(almost), word, lead: lead);

  static String tryAgainWith(
    String almost,
    String word, {
    String lead = 'Bu bir',
  }) => '$almost $lead $word. Bir dahakine sen de söyle!';

  /// "Bilbil söylesin" ipucu: kelime yavaş ve vurgulu.
  static String hint(String word, {String lead = 'Bu bir'}) =>
      '$lead... $word!';

  /// 2–3 yaşta duyulmayınca: birlikte söyleme.
  static String together(String word, {String lead = 'Bu bir'}) =>
      'Hadi birlikte söyleyelim! $lead $word!';

  /// İki kez duyulmayınca kelime söylenip geçilir.
  static String skip(String word, {String lead = 'Bu bir'}) =>
      '$lead $word! Hadi sıradakine geçelim!';
}
