import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// Quiz ses efektleri (tool/generate_sounds.py ile üretilir).
enum SoundEffect {
  correct('sounds/feedback/correct.wav'),
  wrong('sounds/feedback/wrong.wav'),
  reward('sounds/feedback/reward.wav');

  final String asset;
  const SoundEffect(this.asset);
}

/// Ses çalan katman; testlerde sahtesi kullanılır.
abstract class SoundBackend {
  Future<void> playEffect(String asset);
  Future<void> startLoop(String asset, double volume);
  Future<void> pauseLoop();
  Future<void> resumeLoop();
  Future<void> stopLoop();
}

class AudioplayersBackend implements SoundBackend {
  // Ses odağı istenmez: efekt ve müzik, Bilbil'in konuşmasını (TTS) ve
  // diğer uygulamaları durdurmaz, onlarla karışır. iOS'ta kategori
  // playAndRecord: mikrofon kaydıyla aynı oturumda çalışabilsin.
  static final audioContext = AudioContext(
    android: const AudioContextAndroid(
      contentType: AndroidContentType.sonification,
      usageType: AndroidUsageType.game,
      audioFocus: AndroidAudioFocus.none,
    ),
    iOS: AudioContextIOS(
      category: AVAudioSessionCategory.playAndRecord,
      options: const {
        AVAudioSessionOptions.mixWithOthers,
        AVAudioSessionOptions.defaultToSpeaker,
      },
    ),
  );

  AudioPlayer? _effects;
  AudioPlayer? _music;

  static Future<AudioPlayer> _create(PlayerMode mode) async {
    final p = AudioPlayer();
    await p.setAudioContext(audioContext);
    await p.setPlayerMode(mode);
    return p;
  }

  @override
  Future<void> playEffect(String asset) async {
    final p = _effects ??= await _create(PlayerMode.lowLatency);
    await p.stop();
    await p.play(AssetSource(asset));
  }

  @override
  Future<void> startLoop(String asset, double volume) async {
    final p = _music ??= await _create(PlayerMode.mediaPlayer);
    await p.setReleaseMode(ReleaseMode.loop);
    await p.play(AssetSource(asset), volume: volume);
  }

  @override
  Future<void> pauseLoop() async => _music?.pause();

  @override
  Future<void> resumeLoop() async => _music?.resume();

  @override
  Future<void> stopLoop() async => _music?.stop();
}

/// Ses efektleri ve arka plan müziği.
///
/// Müzik yalnızca quiz'de çalar; mikrofon dinlerken ([suspendMusic]) ve
/// uygulama arka plandayken durur. Önceden ses yoktu; mikrofon açıkken
/// çalan müzik ya da efekt, ses tanımaya cevap gibi karışırdı.
/// Tercihler cihazdadır (hesapla senkronlanmaz).
class SoundService extends ChangeNotifier with WidgetsBindingObserver {
  static const _boxName = 'sound_box';
  static const musicAsset = 'sounds/backgrounds/music_box.wav';

  /// Müzik, Bilbil'in sesinin altında kalsın.
  static const musicVolume = 0.08;

  final SoundBackend _backend;
  late Box _box;

  SoundService({SoundBackend? backend})
    : _backend = backend ?? AudioplayersBackend();

  Future<void> init() async {
    _box = await Hive.openBox(_boxName);
    WidgetsBinding.instance.addObserver(this);
  }

  bool get effectsOn => _box.get('effects', defaultValue: true) as bool;

  /// Varsayılan kapalı: ebeveyn isterse açar.
  bool get musicOn => _box.get('music', defaultValue: false) as bool;

  Future<void> setEffectsOn(bool on) async {
    await _box.put('effects', on);
    notifyListeners();
  }

  Future<void> setMusicOn(bool on) async {
    await _box.put('music', on);
    if (!on) {
      await _stopLoop();
    } else if (_musicWanted) {
      await _sync();
    }
    notifyListeners();
  }

  Future<void> play(SoundEffect effect) async {
    if (!effectsOn) return;
    try {
      await _backend.playEffect(effect.asset);
    } catch (e) {
      debugPrint('SoundService effect: $e'); // ses yoksa quiz sürer
    }
  }

  // ── Müzik ──────────────────────────────────────────────────────────────────
  // Quiz müziği ister (_musicWanted); mikrofon, mola ekranı ya da arka plan
  // geçici olarak susturur (_suspends). Çalıp çalmayacağına _sync karar verir.

  bool _musicWanted = false;
  final _suspends = <String>{};
  bool _backgrounded = false;
  bool _loopStarted = false;
  bool _playing = false;

  @visibleForTesting
  bool get musicPlaying => _playing;

  Future<void> startMusic() async {
    _musicWanted = true;
    await _sync();
  }

  Future<void> stopMusic() async {
    _musicWanted = false;
    _suspends.clear();
    await _stopLoop();
  }

  /// [reason]: "mic", "rest" gibi; her neden ayrı kaldırılır.
  Future<void> suspendMusic(String reason) async {
    _suspends.add(reason);
    await _sync();
  }

  Future<void> resumeMusic(String reason) async {
    _suspends.remove(reason);
    await _sync();
  }

  Future<void> _sync() async {
    final shouldPlay =
        musicOn && _musicWanted && _suspends.isEmpty && !_backgrounded;
    if (shouldPlay == _playing) return;
    _playing = shouldPlay;
    try {
      if (shouldPlay) {
        if (_loopStarted) {
          await _backend.resumeLoop();
        } else {
          _loopStarted = true;
          await _backend.startLoop(musicAsset, musicVolume);
        }
      } else {
        await _backend.pauseLoop();
      }
    } catch (e) {
      debugPrint('SoundService music: $e');
    }
  }

  Future<void> _stopLoop() async {
    _playing = false;
    if (!_loopStarted) return;
    _loopStarted = false;
    try {
      await _backend.stopLoop();
    } catch (e) {
      debugPrint('SoundService music: $e');
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _backgrounded = state != AppLifecycleState.resumed;
    _sync();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}
