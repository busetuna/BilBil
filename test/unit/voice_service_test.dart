import 'dart:io';
import 'dart:math';

import 'package:app/services/tts/voice_service.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory dir;
  late VoiceService voice;
  final calls = <MethodCall>[];

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('bilbil_voice_test');
    Hive.init(dir.path);
    calls.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(const MethodChannel('flutter_tts'), (
          call,
        ) async {
          calls.add(call);
          if (call.method == 'getVoices') {
            return [
              {'name': 'en-us-x-sfg-local', 'locale': 'en-US'},
              {'name': 'tr-tr-x-mfm-network', 'locale': 'tr-TR'},
              {'name': 'tr-tr-x-cfs-local', 'locale': 'tr-TR'},
            ];
          }
          return 1;
        });
    voice = VoiceService(rng: Random(1));
    await voice.init();
  });

  tearDown(() async {
    await Hive.deleteFromDisk();
    await dir.delete(recursive: true);
  });

  Iterable<MethodCall> named(String m) => calls.where((c) => c.method == m);

  test(
    'yalnızca Türkçe sesler listelenir; ton canlı varsayılanla ayarlanır',
    () async {
      expect(await voice.prepare(), isTrue);
      expect(voice.voices.map((v) => v.name), [
        'tr-tr-x-cfs-local',
        'tr-tr-x-mfm-network',
      ]);
      expect(named('setLanguage').single.arguments, 'tr-TR');
      expect(named('setPitch').last.arguments, VoiceService.defaultPitch);
      expect(named('setVoice'), isEmpty, reason: 'otomatik: telefonun sesi');
    },
  );

  test('seçilen ses ve ton saklanır, yeniden açılışta uygulanır', () async {
    await voice.prepare();
    await voice.setVoice('tr-tr-x-mfm-network');
    await voice.setPitch(1.3);

    calls.clear();
    final reopened = VoiceService();
    await reopened.init();
    await reopened.prepare();
    expect(named('setVoice').single.arguments, {
      'name': 'tr-tr-x-mfm-network',
      'locale': 'tr-TR',
    });
    expect(named('setPitch').last.arguments, 1.3);
  });

  test('ton sınırların dışına çıkmaz', () async {
    await voice.setPitch(9);
    expect(voice.pitch, VoiceService.maxPitch);
    await voice.setPitch(0);
    expect(voice.pitch, VoiceService.minPitch);
  });

  test('övgüler değişir, hep ünlemli ve kelimeyi söyler', () {
    final texts = {for (var i = 0; i < 40; i++) voice.praise('Kedi')};
    expect(texts.length, greaterThan(5), reason: 'tek düze değil');
    for (final t in texts) {
      expect(t, contains('Kedi'));
      expect(t, contains('!'));
    }
    expect(voice.praise('Kedi', hinted: true), contains('Birlikte'));
    expect(voice.tryAgain('Kedi'), contains('Kedi'));
  });

  test('konuşma hızı her cümlede ayarlanır', () async {
    await voice.speak('Merhaba', rate: VoiceService.wordRate);
    expect(named('setSpeechRate').last.arguments, VoiceService.wordRate);
    expect(named('speak').last.arguments, 'Merhaba');
  });
}
