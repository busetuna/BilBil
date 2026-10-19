import 'dart:io';

import 'package:app/services/sound/sound_service.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

/// Çalınanları kaydeder; isterse hata fırlatır (ses yoksa quiz sürmeli).
class FakeSoundBackend implements SoundBackend {
  final calls = <String>[];
  bool fail = false;

  void _log(String c) {
    if (fail) throw Exception('ses yok');
    calls.add(c);
  }

  @override
  Future<void> playEffect(String asset) async => _log('effect:$asset');
  @override
  Future<void> startLoop(String asset, double volume) async => _log('start');
  @override
  Future<void> pauseLoop() async => _log('pause');
  @override
  Future<void> resumeLoop() async => _log('resume');
  @override
  Future<void> stopLoop() async => _log('stop');
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory dir;
  late FakeSoundBackend backend;
  late SoundService sound;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('bilbil_sound_test');
    Hive.init(dir.path);
    backend = FakeSoundBackend();
    sound = SoundService(backend: backend);
    await sound.init();
  });

  tearDown(() async {
    sound.dispose();
    await Hive.deleteFromDisk();
    await dir.delete(recursive: true);
  });

  test('efektler varsayılan açık; kapatılınca çalmaz', () async {
    await sound.play(SoundEffect.correct);
    expect(backend.calls, ['effect:${SoundEffect.correct.asset}']);
    await sound.setEffectsOn(false);
    await sound.play(SoundEffect.wrong);
    expect(backend.calls, hasLength(1));
  });

  test('müzik varsayılan kapalı; açılınca quiz sürüyorsa başlar', () async {
    await sound.startMusic();
    expect(backend.calls, isEmpty);
    await sound.setMusicOn(true);
    expect(backend.calls, ['start']);
    await sound.setMusicOn(false);
    expect(backend.calls, ['start', 'stop']);
  });

  test('mikrofon ve mola müziği susturur; ikisi de bitince sürer', () async {
    await sound.setMusicOn(true);
    await sound.startMusic();
    await sound.suspendMusic('mic');
    await sound.suspendMusic('rest');
    await sound.resumeMusic('mic');
    expect(sound.musicPlaying, isFalse, reason: 'mola sürüyor');
    await sound.resumeMusic('rest');
    expect(backend.calls, ['start', 'pause', 'resume']);
  });

  test('uygulama arka plana geçince müzik durur, dönünce sürer', () async {
    await sound.setMusicOn(true);
    await sound.startMusic();
    sound.didChangeAppLifecycleState(AppLifecycleState.paused);
    await Future<void>.delayed(Duration.zero);
    expect(sound.musicPlaying, isFalse);
    sound.didChangeAppLifecycleState(AppLifecycleState.resumed);
    await Future<void>.delayed(Duration.zero);
    expect(backend.calls, ['start', 'pause', 'resume']);
  });

  test('quiz bitince durur; yeni quiz baştan başlatır', () async {
    await sound.setMusicOn(true);
    await sound.startMusic();
    await sound.stopMusic();
    await sound.resumeMusic('mic'); // geç gelen çağrı müziği açmaz
    expect(sound.musicPlaying, isFalse);
    await sound.startMusic();
    expect(backend.calls, ['start', 'stop', 'start']);
  });

  test('ses çalınamazsa hata quiz\'e taşmaz', () async {
    backend.fail = true;
    await sound.setMusicOn(true);
    await expectLater(sound.play(SoundEffect.reward), completes);
    await expectLater(sound.startMusic(), completes);
  });
}
