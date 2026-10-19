import 'dart:io';
import 'dart:math';

import 'dart:convert';

import 'package:app/data/models/quiz_category.dart';
import 'package:app/data/models/quiz_item.dart';
import 'package:app/services/tts/voice_clips.dart';
import 'package:app/services/tts/voice_service.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

/// Çalınan kayıtları sırayla saklar.
class FakeClipPlayer implements ClipPlayer {
  final played = <List<String>>[];
  int stops = 0;

  @override
  Future<void> play(String text, List<String> assets) async =>
      played.add(assets);

  @override
  Future<void> stop() async => stops++;
}

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
    expect(voice.tryAgain('Kedi'), contains('Bu bir Kedi'));
    expect(
      voice.tryAgain('Kırmızı', lead: 'Bu renk'),
      contains('Bu renk Kırmızı'),
    );
    final colorPraise = {
      for (var i = 0; i < 40; i++) voice.praise('Kırmızı', lead: 'Bu renk'),
    };
    expect(colorPraise.any((t) => t.contains('Bu bir')), isFalse);
  });

  test('konuşma hızı her cümlede ayarlanır', () async {
    await voice.speak('Merhaba', rate: VoiceService.wordRate);
    expect(named('setSpeechRate').last.arguments, VoiceService.wordRate);
    expect(named('speak').last.arguments, 'Merhaba');
  });

  group('kayıtlı ses', () {
    const clips = VoiceClips({
      'harika': 'clips/harika.mp3',
      'bu bir kedi': 'clips/bu_bir_kedi.mp3',
      'bu bir... kedi': 'clips/ipucu_bu_bir_kedi.mp3',
      'bir dahakine sen de söyle': 'clips/bir_dahakine.mp3',
      'neredeyse': 'clips/neredeyse.mp3',
    });
    late FakeClipPlayer player;
    late VoiceService recorded;

    setUp(() async {
      player = FakeClipPlayer();
      recorded = VoiceService(clipPlayer: player, clips: clips, rng: Random(1));
      await recorded.init();
    });

    test('cümle kayıtlı parçalardan çalınır, telefonun sesi susar', () async {
      await recorded.speak('Harika! Bu bir Kedi!');
      expect(player.played.single, [
        'voice/clips/harika.mp3',
        'voice/clips/bu_bir_kedi.mp3',
      ]);
      expect(named('speak'), isEmpty);
      await recorded.speak(
        'Neredeyse! Bu bir Kedi. Bir dahakine sen de söyle!',
      );
      expect(
        player.played.last,
        hasLength(3),
        reason: 'nokta da ünlemle aynı kayıt',
      );
    });

    test('ipucu kendi kaydıyla ("..." bölünmez)', () async {
      await recorded.speak(VoiceService.hint('Kedi'));
      expect(player.played.single, ['voice/clips/ipucu_bu_bir_kedi.mp3']);
    });

    test('kaydı olmayan cümle telefonun sesiyle söylenir', () async {
      await recorded.speak('Bravo! Bu bir Kedi!');
      expect(player.played, isEmpty);
      expect(named('speak').single.arguments, 'Bravo! Bu bir Kedi!');
    });

    test(
      'ebeveyn telefonun sesini seçince kayıtlar çalmaz; geri dönülebilir',
      () async {
        await recorded.setVoice(null);
        expect(recorded.useRecorded, isFalse);
        await recorded.speak('Harika! Bu bir Kedi!');
        expect(player.played, isEmpty);
        await recorded.setUseRecorded(true);
        await recorded.speak('Harika! Bu bir Kedi!');
        expect(player.played, hasLength(1));
      },
    );

    test(
      'Türkçe ses paketi olmasa da kayıtlı sesle konuşur (kurulum penceresi çıkmaz)',
      () async {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(const MethodChannel('flutter_tts'), (
              call,
            ) async {
              if (call.method == 'isLanguageAvailable') return 0;
              if (call.method == 'getVoices') return [];
              return 1;
            });
        expect(await recorded.prepare(), isTrue);
      },
    );
  });

  test(
    "Bilbil'in söyleyebileceği her cümlenin kaydı var (generate_voice.py)",
    () {
      final manifest =
          jsonDecode(File('assets/voice/manifest.json').readAsStringSync())
              as Map;
      final map = (manifest['clips'] as Map).cast<String, String>();
      for (final path in map.values) {
        expect(File('assets/voice/$path').existsSync(), isTrue, reason: path);
      }
      final clips = VoiceClips(map);
      final missing = <String>{};
      void check(String text) {
        if (clips.assetsFor(text) == null) missing.add(text);
      }

      check(VoiceService.greeting);
      check(VoiceService.notHeard);
      for (final item in QuizData.all) {
        final lead = QuizCategory.leadFor(item);
        final w = item.word;
        for (final c in VoiceService.cheers) {
          check(VoiceService.praiseWith(c, w, lead: lead));
          check(VoiceService.praiseWith(c, w, lead: lead, hinted: true));
        }
        for (final a in VoiceService.almost) {
          check(VoiceService.tryAgainWith(a, w, lead: lead));
        }
        check(VoiceService.hint(w, lead: lead));
        check(VoiceService.together(w, lead: lead));
        check(VoiceService.skip(w, lead: lead));
      }
      expect(
        missing,
        isEmpty,
        reason: 'tool/generate_voice.py ile kayıtları yeniden üret',
      );
    },
  );
}
