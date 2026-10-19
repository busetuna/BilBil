// Quiz akışı: gerçek QuizScreen, sahte ses motoru.
//
// Mikrofon ve Vosk yerine FakeVosk testin "söylediği" metni iletir; TTS ve
// izin eklentileri sahte kanallarla cevaplanır, Hive kutuları bellektedir.
import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:app/data/models/quiz_category.dart';
import 'package:app/data/models/quiz_item.dart';
import 'package:app/domain/entities/user.dart';
import 'package:app/domain/repositories/auth_repository.dart';
import 'package:app/domain/usecases/login_usecase.dart';
import 'package:app/domain/usecases/logout_usecase.dart';
import 'package:app/domain/usecases/register_usecase.dart';
import 'package:app/features/learning/presentations/providers/auth_provider.dart';
import 'package:app/features/debug/sound_lab_screen.dart';
import 'package:app/features/learning/presentations/screens/home_screen.dart';
import 'package:app/features/learning/presentations/screens/login_screen.dart';
import 'package:app/features/learning/presentations/screens/quiz_screen.dart';
import 'package:app/features/parent/tabs/settings_tab.dart';
import 'package:app/features/learning/presentations/screens/rest_screen.dart';
import 'package:app/features/learning/presentations/widgets/quiz_image_card.dart';
import 'package:app/features/learning/presentations/widgets/quiz_mic_button.dart';
import 'package:app/features/learning/presentations/widgets/quiz_word_reveal.dart';
import 'package:app/services/ads/ad_service.dart';
import 'package:app/services/asr/vosk_asr_service.dart';
import 'package:app/services/asr/whisper_asr_service.dart';
import 'package:app/services/learning/learning_scheduler.dart';
import 'package:app/services/learning/word_progress_service.dart';
import 'package:app/services/lives/lives_service.dart';
import 'package:app/services/rewards/reward_service.dart';
import 'package:app/services/stats/stats_service.dart';
import 'package:app/services/theme/theme_service.dart';
import 'package:app/services/sound/sound_service.dart';
import 'package:app/services/tts/voice_clips.dart';
import 'package:app/services/tts/voice_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
// ignore: implementation_imports
import 'package:google_fonts/src/google_fonts_base.dart' as google_fonts;
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';

/// Ana ekran için: oturum açmış kullanıcı yok, hiçbir çağrı yapılmaz.
class FakeAuthRepository implements AuthRepository {
  @override
  Future<User?> getCurrentUser() async => null;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeVosk extends VoskAsrService {
  void Function(String)? onPartial;
  void Function(List<String>)? onFinal;
  int starts = 0;
  List<String> finishCandidates = const [];
  List<String>? lastGrammar;

  @override
  bool get isReady => true;
  @override
  AsrModelStatus get status => AsrModelStatus.ready;
  @override
  bool get isDownloading => false;
  @override
  Future<void> initialize() async {}

  @override
  void startListening({
    required void Function(String partial) onPartial,
    required void Function(List<String> candidates) onFinal,
    void Function()? onSpeech,
    List<String>? grammar,
  }) {
    starts++;
    lastGrammar = grammar;
    this.onPartial = onPartial;
    this.onFinal = onFinal;
  }

  @override
  void stopListening() {}

  @override
  Future<List<String>> finishListening() async => finishCandidates;
}

/// Reklam SDK'sı yerine: testin belirlediği sonucu döner.
/// Bilbil'in kayıtlı sesini çalmaz; söylenen cümleyi listeye yazar.
class FakeClipPlayer implements ClipPlayer {
  final List<String> spoken;
  final assets = <List<String>>[];
  FakeClipPlayer(this.spoken);

  @override
  Future<void> play(String text, List<String> parts) async {
    spoken.add(text);
    assets.add(parts);
  }

  @override
  Future<void> stop() async {}
}

/// Çalınan efektleri ve müzik olaylarını sırayla kaydeder.
class FakeSound implements SoundBackend {
  final calls = <String>[];
  List<String> get effects => [
    for (final c in calls)
      if (c.startsWith('effect:')) c.split('/').last.split('.').first,
  ];
  List<String> get music =>
      calls.where((c) => !c.startsWith('effect:')).toList();

  @override
  Future<void> playEffect(String asset) async => calls.add('effect:$asset');
  @override
  Future<void> startLoop(String asset, double volume) async =>
      calls.add('start');
  @override
  Future<void> pauseLoop() async => calls.add('pause');
  @override
  Future<void> resumeLoop() async => calls.add('resume');
  @override
  Future<void> stopLoop() async => calls.add('stop');
}

class FakeAds extends AdService {
  RewardedResult next = RewardedResult.earned;
  int shows = 0;

  @override
  bool get isSupported => true;
  @override
  Future<void> init() async {}
  @override
  void preload() {}
  @override
  Future<RewardedResult> showRewarded() async {
    shows++;
    return next;
  }

  /// Quiz bitişi reklamı istekleri (o oturumdaki cevap sayısıyla).
  final quizEndRequests = <int>[];
  @override
  void preloadInterstitial() {}
  @override
  Future<bool> showQuizEndAd({required int answersThisSession}) async {
    quizEndRequests.add(answersThisSession);
    return true;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late DateTime now;
  late StatsService stats;
  late RewardService rewards;
  late LivesService lives;
  late WordProgressService progress;
  late VoiceService voice;
  late FakeClipPlayer clipPlayer;
  late FakeSound soundBackend;
  late SoundService sound;
  late FakeVosk vosk;
  late FakeAds ads;
  // Bilbil'in söyledikleri (sahte TTS kanalına gelen speak çağrıları).
  final spoken = <String>[];

  setUpAll(() {
    // Fontlar internetten istenir; testte istek hiç cevaplanmaz (hata da
    // fırlatılmaz), metinler varsayılan fontla çizilir.
    google_fonts.httpClient = MockClient(
      (_) => Completer<http.Response>().future,
    );
  });

  setUp(() async {
    Hive.init(Directory.systemTemp.createTempSync('bilbil_quiz_test').path);
    for (final box in [
      'stats',
      'rewards_box',
      'lives_box',
      'word_progress',
      'voice_box',
      'theme_box',
      'sound_box',
    ]) {
      await Hive.openBox(box, bytes: Uint8List(0)); // bellekte
    }
    now = DateTime(2026, 10, 13, 12);
    stats = StatsService();
    await stats.init();
    rewards = RewardService();
    await rewards.init();
    lives = LivesService(clock: () => now);
    await lives.init();
    progress = WordProgressService();
    await progress.init();
    clipPlayer = FakeClipPlayer(spoken);
    voice = VoiceService(clipPlayer: clipPlayer);
    await voice.init();
    soundBackend = FakeSound();
    sound = SoundService(backend: soundBackend);
    await sound.init();
    vosk = FakeVosk();
    ads = FakeAds();

    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    spoken.clear();
    messenger.setMockMethodCallHandler(const MethodChannel('flutter_tts'), (
      call,
    ) async {
      if (call.method == 'speak') spoken.add(call.arguments as String);
      return 1;
    });
    messenger.setMockMethodCallHandler(
      const MethodChannel('flutter.baseflow.com/permissions/methods'),
      (call) async => call.method == 'checkPermissionStatus' ? 1 : null,
    );
  });

  tearDown(() => Hive.close());

  Future<void> pumpApp(WidgetTester tester, Widget home) async {
    final auth = FakeAuthRepository();
    final theme = ThemeService();
    await theme.init();
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthProvider>(
            create: (_) => AuthProvider(
              loginUseCase: LoginUseCase(auth),
              registerUseCase: RegisterUseCase(auth),
              logoutUseCase: LogoutUseCase(auth),
              authRepository: auth,
              onSignedIn: (_) async {},
              onSignedOut: () async {},
              onAccountDeleted: () async {},
            ),
          ),
          ChangeNotifierProvider<ThemeService>.value(value: theme),
          ChangeNotifierProvider<StatsService>.value(value: stats),
          ChangeNotifierProvider<RewardService>.value(value: rewards),
          ChangeNotifierProvider<LivesService>.value(value: lives),
          ChangeNotifierProvider<WordProgressService>.value(value: progress),
          ChangeNotifierProvider<VoiceService>.value(value: voice),
          ChangeNotifierProvider<SoundService>.value(value: sound),
          ChangeNotifierProvider<VoskAsrService>.value(value: vosk),
          ChangeNotifierProvider<AdService>.value(value: ads),
          ChangeNotifierProvider<WhisperAsrService>.value(
            value: WhisperAsrService(),
          ),
        ],
        child: MaterialApp(home: home),
      ),
    );
  }

  Future<void> openQuiz(WidgetTester tester, {QuizCategory? category}) async {
    await pumpApp(
      tester,
      Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: ElevatedButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => QuizScreen(category: category),
                ),
              ),
              child: const Text('Başla'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Başla'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
  }

  QuizWordReveal reveal(WidgetTester t) =>
      t.widget(find.byType(QuizWordReveal));
  String imageOf(WidgetTester t) =>
      t.widget<QuizImageCard>(find.byType(QuizImageCard)).imagePath;

  Future<void> settle(WidgetTester t) async {
    for (var i = 0; i < 6; i++) {
      await t.pump();
    }
  }

  Future<void> tapMic(WidgetTester t) async {
    await t.tap(find.byType(QuizMicButton));
    await settle(t); // izin kontrolü + TTS durdurma
  }

  Future<void> say(WidgetTester t, String text) async {
    await tapMic(t);
    vosk.onFinal!([text]);
    await t.pump();
  }

  Future<void> nextQuestion(WidgetTester t) async {
    await t.pump(const Duration(seconds: 3));
    await t.pump(const Duration(milliseconds: 600));
  }

  Future<void> waitSilence(WidgetTester t) async {
    await t.pump(const Duration(seconds: 9)); // 3 yaş: 8 sn sessizlik
    await settle(t);
  }

  Future<void> reachRestScreen(WidgetTester t) async {
    for (var i = 0; i < LivesService.maxLives; i++) {
      await say(t, 'qqqq');
      if (i < LivesService.maxLives - 1) await nextQuestion(t);
    }
    await t.pump(const Duration(seconds: 2));
    await t.pump(const Duration(milliseconds: 600));
  }

  Future<void> finish(WidgetTester t) async {
    // Bekleyen zamanlayıcılar (konuşma, sıradaki soru) bitsin, ağaç kapansın.
    await t.pump(const Duration(seconds: 10));
    await t.pumpWidget(const SizedBox());
    await t.pump(const Duration(seconds: 1));
  }

  testWidgets(
    'doğru cevap: istatistik artar, can düşmez, sıradaki soruya geçilir',
    (tester) async {
      await openQuiz(tester);
      await say(tester, reveal(tester).correctWord);

      expect(reveal(tester).hasSpoken, isTrue);
      expect(reveal(tester).isCorrect, isTrue);
      expect(stats.totalCorrect, 1);
      expect(lives.lives, LivesService.maxLives);

      await nextQuestion(tester);
      expect(reveal(tester).hasSpoken, isFalse);
      await finish(tester);
    },
  );

  testWidgets('yanlış cevap bir can düşürür', (tester) async {
    await openQuiz(tester);
    await say(tester, 'qqqq');

    expect(reveal(tester).isCorrect, isFalse);
    expect(stats.totalWrong, 1);
    expect(lives.lives, LivesService.maxLives - 1);
    await finish(tester);
  });

  testWidgets(
    'bilinemeyen soru 3 soru sonra tekrar gelir ve zorlandığı kelimelere girer',
    (tester) async {
      await openQuiz(tester);
      final missedImage = imageOf(tester);
      final missedWord = reveal(tester).correctWord;
      await say(tester, 'qqqq');
      expect(progress.boxOf(missedWord), 0);
      expect(progress.struggling().map((s) => s.word), contains(missedWord));

      final seen = <String>[];
      for (var i = 0; i < ReviewQueue.delay; i++) {
        await nextQuestion(tester);
        seen.add(imageOf(tester));
        await say(tester, reveal(tester).correctWord);
      }
      expect(seen.take(ReviewQueue.delay - 1), isNot(contains(missedImage)));
      expect(seen.last, missedImage, reason: '3. soruda tekrar');
      await finish(tester);
    },
  );

  testWidgets(
    'ipucu: Bilbil kelimeyi söyler; ipucuyla doğru cevap kutuyu yükseltmez',
    (tester) async {
      await openQuiz(tester);
      final word = reveal(tester).correctWord;
      progress
        ..record(word, correct: true)
        ..record(word, correct: true);
      expect(progress.boxOf(word), 1);

      await tester.tap(find.byKey(const Key('hint-button')));
      await settle(tester);
      expect(spoken.last, contains(word));

      await say(tester, word);
      expect(
        reveal(tester).isCorrect,
        isTrue,
        reason: 'övülür, yıldız kazanır',
      );
      expect(stats.totalCorrect, 1);
      expect(progress.boxOf(word), 1, reason: 'ipucuyla doğru: kutu yükselmez');
      await finish(tester);
    },
  );

  testWidgets('ipucusuz doğru cevap kutuyu yükseltir', (tester) async {
    await openQuiz(tester);
    final word = reveal(tester).correctWord;
    progress
      ..record(word, correct: true)
      ..record(word, correct: true);
    await say(tester, word);
    expect(progress.boxOf(word), 2);
    await finish(tester);
  });

  testWidgets('2–3 yaşta duyulmazsa Bilbil "birlikte söyleyelim" der', (
    tester,
  ) async {
    await openQuiz(tester); // varsayılan yaş 3
    await tapMic(tester);
    await waitSilence(tester);
    expect(
      spoken.last,
      allOf(contains('birlikte'), contains(reveal(tester).correctWord)),
    );
    expect(lives.lives, LivesService.maxLives);
    await finish(tester);
  });

  testWidgets(
    '4–5 yaşta duyulmazsa kelime söylenmez, tekrar denemesi istenir',
    (tester) async {
      stats.setChildAge(5);
      await openQuiz(tester);
      await tapMic(tester);
      await waitSilence(tester);
      await tester.pump(const Duration(seconds: 1)); // konuşma 500 ms gecikmeli
      expect(spoken.last, contains('duyamadım'));
      expect(spoken.last, isNot(contains(reveal(tester).correctWord)));
      await finish(tester);
    },
  );

  testWidgets('mikrofon dinlerken ipucu kapalı', (tester) async {
    await openQuiz(tester);
    await tapMic(tester);
    final before = spoken.length;
    await tester.tap(find.byKey(const Key('hint-button')));
    await settle(tester);
    expect(spoken.length, before);
    await finish(tester);
  });

  testWidgets('alternatif tahminlerden biri tutarsa doğru sayılır', (
    tester,
  ) async {
    await openQuiz(tester);
    await tapMic(tester);
    vosk.onFinal!(['qqqq', reveal(tester).correctWord]);
    await tester.pump();

    expect(reveal(tester).isCorrect, isTrue);
    expect(
      reveal(tester).recognizedWord,
      reveal(tester).correctWord,
      reason: 'ekranda tutan tahmin gösterilir',
    );
    expect(lives.lives, LivesService.maxLives);
    await finish(tester);
  });

  testWidgets('Vosk her soruda kapalı sözlükle dinler (kelime sözlükteyse)', (
    tester,
  ) async {
    await openQuiz(tester);
    await tapMic(tester);
    final word = reveal(tester).correctWord;
    final grammar = vosk.lastGrammar;
    if (grammar != null) {
      expect(grammar.last, '[unk]');
      expect(grammar.length, greaterThan(100), reason: 'tüm quiz kelimeleri');
    } else {
      // Vosk'un yazamadığı kelime: açık sözlük.
      expect([
        'kaplumbağa',
        'zürafa',
        'zebra',
        'kirpi',
        'penguen',
        'papağan',
        'civciv',
        'kanepe',
        'fincan',
        'marul',
        'salyangoz',
        'abajur',
        'bej',
        'böğürtlen',
        'kapüşonlu',
        'klozet',
        'küvet',
        'rakun',
        'yusufçuk',
        'nar bülbülü',
      ], contains(word.toLowerCase()));
    }
    await finish(tester);
  });

  testWidgets(
    'hiçbir şey duyulmazsa can düşmez; ikinci kez de duyulmazsa cezasız geçilir',
    (tester) async {
      await openQuiz(tester);

      await tapMic(tester);
      await waitSilence(tester);
      expect(find.text('Seni duyamadım, tekrar dokun'), findsOneWidget);
      expect(reveal(tester).hasSpoken, isFalse, reason: 'aynı soru sürer');
      expect(lives.lives, LivesService.maxLives);
      expect(stats.totalAnswers, 0);

      await tapMic(tester);
      await waitSilence(tester);
      expect(reveal(tester).hasSpoken, isTrue, reason: 'kelime gösterilir');
      expect(lives.lives, LivesService.maxLives);
      expect(stats.totalAnswers, 0);

      await nextQuestion(tester);
      expect(reveal(tester).hasSpoken, isFalse);
      await finish(tester);
    },
  );

  testWidgets(
    'süre dolunca son duyulan kısmi metin cevap olarak değerlendirilir',
    (tester) async {
      await openQuiz(tester);
      await tapMic(tester);
      vosk.onPartial!(reveal(tester).correctWord);
      await waitSilence(tester);

      expect(stats.totalCorrect, 1);
      expect(lives.lives, LivesService.maxLives);
      await finish(tester);
    },
  );

  testWidgets(
    'cevaptan sonra mikrofona dokunmak aynı soruyu ikinci kez saydırmaz',
    (tester) async {
      await openQuiz(tester);
      await say(tester, reveal(tester).correctWord);
      final starts = vosk.starts;

      await tapMic(tester);
      expect(
        vosk.starts,
        starts,
        reason: 'geri bildirim sırasında dinleme açılmaz',
      );
      expect(stats.totalCorrect, 1);
      await finish(tester);
    },
  );

  testWidgets(
    'canlar bitince mola; mola bitmeden geri dönülürse quiz kapanır',
    (tester) async {
      await openQuiz(tester);
      await reachRestScreen(tester);

      expect(lives.lives, 0);
      expect(find.byType(RestScreen), findsOneWidget);
      expect(
        find.text('Devam Et'),
        findsNothing,
        reason: 'mola sürerken kapalı',
      );
      expect(find.text('Reklam izle, canları doldur'), findsOneWidget);

      await tester.binding.handlePopRoute(); // Android geri tuşu
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));
      expect(find.byType(QuizScreen), findsNothing);
      expect(find.text('Başla'), findsOneWidget);
      expect(
        ads.quizEndRequests,
        isEmpty,
        reason: 'canlar bitip moladan çıkarken reklam yok',
      );
      await finish(tester);
    },
  );

  testWidgets(
    'quiz geri butonuyla bitince bitiş reklamı cevap sayısıyla istenir',
    (tester) async {
      await openQuiz(tester);
      for (var i = 0; i < 5; i++) {
        await say(tester, reveal(tester).correctWord);
        await nextQuestion(tester);
      }
      await tester.tap(find.byIcon(Icons.arrow_back_ios_new_rounded));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      expect(find.byType(QuizScreen), findsNothing);
      expect(ads.quizEndRequests, [5]);
      await finish(tester);
    },
  );

  testWidgets('Android geri tuşu da aynı çıkış akışından geçer', (
    tester,
  ) async {
    await openQuiz(tester);
    await say(tester, reveal(tester).correctWord);
    await nextQuestion(tester);

    await tester.binding.handlePopRoute();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.byType(QuizScreen), findsNothing);
    expect(
      ads.quizEndRequests,
      [1],
      reason: 'reklamı gösterip göstermemeye AdPacing karar verir',
    );
    await finish(tester);
  });

  testWidgets('mola dolunca canlar dolar ve quiz kaldığı yerden sürer', (
    tester,
  ) async {
    await openQuiz(tester);
    await reachRestScreen(tester);

    now = now.add(LivesService.restDuration + const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
    await tester.tap(find.text('Devam Et'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.byType(RestScreen), findsNothing);
    expect(find.byType(QuizScreen), findsOneWidget);
    expect(lives.lives, LivesService.maxLives);
    expect(reveal(tester).hasSpoken, isFalse, reason: 'yeni soru');
    await finish(tester);
  });

  testWidgets(
    'mola ekranında reklam sonuna kadar izlenirse canlar dolar, quiz sürer',
    (tester) async {
      await openQuiz(tester);
      await reachRestScreen(tester);

      ads.next = RewardedResult.earned;
      await tester.tap(find.text('Reklam izle, canları doldur'));
      await settle(tester);
      await tester.pump(const Duration(milliseconds: 600));

      expect(ads.shows, 1);
      expect(lives.lives, LivesService.maxLives);
      expect(find.byType(RestScreen), findsNothing);
      expect(find.byType(QuizScreen), findsOneWidget);
      await finish(tester);
    },
  );

  testWidgets('reklam yarıda kapatılırsa ya da hiç yoksa mola sürer', (
    tester,
  ) async {
    await openQuiz(tester);
    await reachRestScreen(tester);

    final messages = {
      RewardedResult.skipped: 'Reklam bitmeden kapandı, mola sürüyor',
      RewardedResult.unavailable: 'Şu an reklam yok, biraz sonra tekrar dene',
    };
    var shows = 0;
    for (final MapEntry(key: result, value: message) in messages.entries) {
      ads.next = result;
      final button = find.text('Reklam izle, canları doldur');
      await tester.ensureVisible(button);
      await tester.pump();
      await tester.tap(button);
      await settle(tester);

      expect(ads.shows, ++shows, reason: 'reklam gerçekten açıldı ($result)');
      expect(find.text(message), findsOneWidget, reason: '$result');
      expect(lives.lives, 0, reason: '$result');
      expect(find.byType(RestScreen), findsOneWidget, reason: '$result');
    }
    await finish(tester);
  });

  testWidgets(
    'zorluk değişse de soru cevap boyunca sabit kalır; uzun oturumda çökmez',
    (tester) async {
      stats.setChildAge(5); // tüm zorluklar açık; "zor" havuzu 37 soru
      await openQuiz(tester);

      for (var i = 0; i < 45; i++) {
        final collect = find.text('KOLEKSİYONA EKLE'); // ödül kutlaması
        if (collect.evaluate().isNotEmpty) {
          await tester.tap(collect);
          await tester.pump(const Duration(milliseconds: 600));
        }
        final word = reveal(tester).correctWord;
        final image = imageOf(tester);

        await say(tester, word);
        await tester.pump(const Duration(milliseconds: 1500));
        expect(reveal(tester).correctWord, word, reason: 'soru $i');
        expect(imageOf(tester), image, reason: 'soru $i');

        await nextQuestion(tester);
      }
      expect(stats.totalCorrect, 45);
      expect(lives.lives, LivesService.maxLives);
      await finish(tester);
    },
  );

  QuizCategory category(String id) =>
      QuizCategory.all.firstWhere((c) => c.id == id);

  testWidgets("kategori quiz'i yalnızca o kategoriden sorar, kelimesi olmayan "
      "seviyeye çıkmaz", (tester) async {
    stats.setChildAge(5); // yaş Zor'a izin verir; Şekiller'de yalnızca Kolay
    final shapes = category('shapes');
    final images = {for (final i in shapes.items) i.imagePath};
    await openQuiz(tester, category: shapes);
    expect(find.text('Şekiller · Kolay'), findsOneWidget);

    for (var i = 0; i < 12; i++) {
      final collect = find.text('KOLEKSİYONA EKLE'); // ödül kutlaması
      if (collect.evaluate().isNotEmpty) {
        await tester.tap(collect);
        await tester.pump(const Duration(milliseconds: 600));
      }
      expect(images, contains(imageOf(tester)), reason: 'soru $i');
      await say(tester, reveal(tester).correctWord);
      await nextQuestion(tester);
    }
    expect(find.text('Şekiller · Kolay'), findsOneWidget);
    expect(stats.totalCorrect, 12);
    await finish(tester);
  });

  testWidgets(
    "kategori quiz'i çocuğun kaldığı seviyeyi değiştirmez, öğrendiklerini "
    "yine saklar",
    (tester) async {
      stats.setChildAge(5);
      stats.recordAnswer(
        correct: true,
        difficulty: 2,
        rlState: {
          'q': List.filled(3, [0.0, 0.0, 0.0]),
          'n': List.filled(3, [0, 0, 0]),
          'level': 2,
        },
      );
      await openQuiz(tester, category: category('shapes'));
      for (var i = 0; i < 4; i++) {
        await say(tester, reveal(tester).correctWord);
        await nextQuestion(tester);
      }
      final rl = stats.rlAgentState!;
      expect(rl['level'], 2);
      expect(
        (rl['n'] as List).expand((r) => r as List).any((n) => n > 0),
        isTrue,
      );
      await finish(tester);
    },
  );

  for (final size in [const Size(360, 640), const Size(800, 600)]) {
    testWidgets(
      'ana ekran ${size.width.toInt()}x${size.height.toInt()}: taşma yok; '
      'kategori kartı o kategoride quiz açar',
      (tester) async {
        await tester.binding.setSurfaceSize(size);
        addTearDown(() => tester.binding.setSurfaceSize(null));
        await pumpApp(tester, const HomeScreen());
        await tester.pump();
        expect(find.text('Ya da bir konu seç'), findsOneWidget);

        await tester.tap(find.byKey(const Key('category-animals')));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 600));
        final quiz = tester.widget<QuizScreen>(find.byType(QuizScreen));
        expect(quiz.category?.id, 'animals');
        expect(find.text('Hayvanlar · Kolay'), findsOneWidget);
        await finish(tester);
      },
    );
  }

  testWidgets('büyük buton karışık quiz açar', (tester) async {
    await pumpApp(tester, const HomeScreen());
    await tester.pump();
    await tester.tap(find.byKey(const Key('quiz-start')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    expect(tester.widget<QuizScreen>(find.byType(QuizScreen)).category, isNull);
    expect(find.text('Seviye: Kolay'), findsOneWidget);
    await finish(tester);
  });

  testWidgets(
    'ayarlar: yaş yazısı doğru, yaş sınırının üstündeki seviye seçilemez',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 3000));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      stats.setChildAge(2);
      await pumpApp(tester, const Scaffold(body: SettingsTab()));
      await tester.pump();
      int words(int maxDiff) =>
          QuizData.all.where((i) => i.difficulty <= maxDiff).length;
      expect(
        find.text('2 yaş: Kolay kelimeler (${words(0)} kelime).'),
        findsOneWidget,
      );
      final segments = tester
          .widget<SegmentedButton<int>>(
            find.byWidgetPredicate(
              (w) => w is SegmentedButton<int> && w.segments.length == 3,
            ),
          )
          .segments;
      expect(segments.map((s) => s.enabled), [true, false, false]);

      stats.setChildAge(5);
      await tester.pump();
      expect(
        find.text(
          '5 yaş: Kolay, Orta ve Zor kelimeler '
          '(${QuizData.all.length} kelime).',
        ),
        findsOneWidget,
      );
      await finish(tester);
    },
  );

  testWidgets('doğruda neşeli, yanlışta yumuşak ses efekti çalar', (
    tester,
  ) async {
    await openQuiz(tester);
    await say(tester, reveal(tester).correctWord);
    expect(soundBackend.effects, ['correct']);
    await nextQuestion(tester);
    await say(tester, 'qqqq');
    expect(soundBackend.effects, ['correct', 'wrong']);
    await finish(tester);
  });

  testWidgets('ebeveyn kapattıysa efekt çalmaz; müzik varsayılan kapalı', (
    tester,
  ) async {
    await sound.setEffectsOn(false);
    await openQuiz(tester);
    await say(tester, reveal(tester).correctWord);
    expect(soundBackend.calls, isEmpty);
    await finish(tester);
  });

  testWidgets(
    'müzik: quiz\'de çalar, mikrofon dinlerken susar, çıkınca durur',
    (tester) async {
      await sound.setMusicOn(true);
      await openQuiz(tester);
      expect(soundBackend.music, ['start']);

      await tapMic(tester);
      expect(soundBackend.music, ['start', 'pause'], reason: 'mikrofon açık');
      vosk.onFinal!([reveal(tester).correctWord]);
      await tester.pump();
      expect(soundBackend.music, ['start', 'pause', 'resume']);

      await nextQuestion(tester);
      await tester.tap(find.byIcon(Icons.arrow_back_ios_new_rounded));
      await tester.pump();
      expect(soundBackend.music.last, 'stop');
      await finish(tester);
    },
  );

  testWidgets('molada müzik susar, mola bitip quiz sürünce devam eder', (
    tester,
  ) async {
    await sound.setMusicOn(true);
    await openQuiz(tester);
    await reachRestScreen(tester);
    expect(find.byType(RestScreen), findsOneWidget);
    expect(soundBackend.music.last, 'pause');

    now = now.add(LivesService.restDuration + const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
    await tester.tap(find.text('Devam Et'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.byType(QuizScreen), findsOneWidget);
    expect(soundBackend.music.last, 'resume');
    await finish(tester);
  });

  testWidgets(
    "ses laboratuvarı: girişte Bilbil'e uzun basınca açılır, butonlar çalar; "
    'çıkınca ebeveynin müzik ayarı geri döner',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 1400));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await pumpApp(tester, const LoginScreen());
      await tester.pump();
      await tester.longPress(find.byKey(const Key('sound-lab-entry')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));
      expect(find.byType(SoundLabScreen), findsOneWidget);

      await tester.tap(find.text('Doğru'));
      await tester.pump();
      expect(soundBackend.effects, ['correct']);
      await tester.tap(find.text('Duyamadım'));
      await settle(tester);
      expect(spoken.last, 'Seni duyamadım! Bir daha söyler misin?');

      expect(sound.musicOn, isFalse);
      await tester.tap(find.text('Müziği çal'));
      await settle(tester);
      expect(soundBackend.music, ['start']);
      await tester.pageBack();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));
      expect(soundBackend.music.last, 'stop');
      expect(
        sound.musicOn,
        isFalse,
        reason: 'laboratuvar ayarı kalıcı değiştirmez',
      );
      await finish(tester);
    },
  );

  testWidgets('Bilbil kayıtlı sesiyle konuşur (telefonun sesi değil)', (
    tester,
  ) async {
    await openQuiz(tester);
    final word = reveal(tester).correctWord;
    await say(tester, word);
    await tester.pump(const Duration(milliseconds: 600)); // övgü 0.5 sn sonra
    expect(spoken.last, contains(word));
    expect(clipPlayer.assets.last, isNotEmpty);
    expect(clipPlayer.assets.last, everyElement(startsWith('voice/clips/')));
    await finish(tester);
  });
}
