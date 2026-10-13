// Quiz akışı: gerçek QuizScreen, sahte ses motoru.
//
// Mikrofon ve Vosk yerine FakeVosk testin "söylediği" metni iletir; TTS ve
// izin eklentileri sahte kanallarla cevaplanır, Hive kutuları bellektedir.
import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:app/features/learning/presentations/screens/quiz_screen.dart';
import 'package:app/features/learning/presentations/screens/rest_screen.dart';
import 'package:app/features/learning/presentations/widgets/quiz_image_card.dart';
import 'package:app/features/learning/presentations/widgets/quiz_mic_button.dart';
import 'package:app/features/learning/presentations/widgets/quiz_word_reveal.dart';
import 'package:app/services/asr/vosk_asr_service.dart';
import 'package:app/services/asr/whisper_asr_service.dart';
import 'package:app/services/lives/lives_service.dart';
import 'package:app/services/rewards/reward_service.dart';
import 'package:app/services/stats/stats_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
// ignore: implementation_imports
import 'package:google_fonts/src/google_fonts_base.dart' as google_fonts;
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';

class FakeVosk extends VoskAsrService {
  void Function(String)? onPartial;
  void Function(String)? onFinal;
  int starts = 0;
  String finishText = '';

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
    required void Function(String text) onFinal,
    void Function()? onSpeech,
  }) {
    starts++;
    this.onPartial = onPartial;
    this.onFinal = onFinal;
  }

  @override
  void stopListening() {}

  @override
  Future<String> finishListening() async => finishText;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late DateTime now;
  late StatsService stats;
  late RewardService rewards;
  late LivesService lives;
  late FakeVosk vosk;

  setUpAll(() {
    // Fontlar internetten istenir; testte istek hiç cevaplanmaz (hata da
    // fırlatılmaz), metinler varsayılan fontla çizilir.
    google_fonts.httpClient =
        MockClient((_) => Completer<http.Response>().future);
  });

  setUp(() async {
    Hive.init(Directory.systemTemp.createTempSync('bilbil_quiz_test').path);
    for (final box in ['stats', 'rewards_box', 'lives_box']) {
      await Hive.openBox(box, bytes: Uint8List(0)); // bellekte
    }
    now = DateTime(2026, 10, 13, 12);
    stats = StatsService();
    await stats.init();
    rewards = RewardService();
    await rewards.init();
    lives = LivesService(clock: () => now);
    await lives.init();
    vosk = FakeVosk();

    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(
        const MethodChannel('flutter_tts'), (_) async => 1);
    messenger.setMockMethodCallHandler(
        const MethodChannel('flutter.baseflow.com/permissions/methods'),
        (call) async => call.method == 'checkPermissionStatus' ? 1 : null);
  });

  tearDown(() => Hive.close());

  Future<void> openQuiz(WidgetTester tester) async {
    await tester.pumpWidget(MultiProvider(
      providers: [
        ChangeNotifierProvider<StatsService>.value(value: stats),
        ChangeNotifierProvider<RewardService>.value(value: rewards),
        ChangeNotifierProvider<LivesService>.value(value: lives),
        ChangeNotifierProvider<VoskAsrService>.value(value: vosk),
        ChangeNotifierProvider<WhisperAsrService>.value(
            value: WhisperAsrService()),
      ],
      child: MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const QuizScreen())),
                child: const Text('Başla'),
              ),
            ),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('Başla'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
  }

  QuizWordReveal reveal(WidgetTester t) => t.widget(find.byType(QuizWordReveal));
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
    vosk.onFinal!(text);
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

  testWidgets('doğru cevap: istatistik artar, can düşmez, sıradaki soruya geçilir',
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
  });

  testWidgets('yanlış cevap bir can düşürür', (tester) async {
    await openQuiz(tester);
    await say(tester, 'qqqq');

    expect(reveal(tester).isCorrect, isFalse);
    expect(stats.totalWrong, 1);
    expect(lives.lives, LivesService.maxLives - 1);
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
  });

  testWidgets('süre dolunca son duyulan kısmi metin cevap olarak değerlendirilir',
      (tester) async {
    await openQuiz(tester);
    await tapMic(tester);
    vosk.onPartial!(reveal(tester).correctWord);
    await waitSilence(tester);

    expect(stats.totalCorrect, 1);
    expect(lives.lives, LivesService.maxLives);
    await finish(tester);
  });

  testWidgets('cevaptan sonra mikrofona dokunmak aynı soruyu ikinci kez saydırmaz',
      (tester) async {
    await openQuiz(tester);
    await say(tester, reveal(tester).correctWord);
    final starts = vosk.starts;

    await tapMic(tester);
    expect(vosk.starts, starts, reason: 'geri bildirim sırasında dinleme açılmaz');
    expect(stats.totalCorrect, 1);
    await finish(tester);
  });

  testWidgets('canlar bitince mola; mola bitmeden geri dönülürse quiz kapanır',
      (tester) async {
    await openQuiz(tester);
    await reachRestScreen(tester);

    expect(lives.lives, 0);
    expect(find.byType(RestScreen), findsOneWidget);
    expect(find.text('Devam Et'), findsNothing, reason: 'mola sürerken kapalı');
    expect(find.text('Ebeveyn: molayı bitir'), findsOneWidget);

    await tester.binding.handlePopRoute(); // Android geri tuşu
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.byType(QuizScreen), findsNothing);
    expect(find.text('Başla'), findsOneWidget);
    await finish(tester);
  });

  testWidgets('mola dolunca canlar dolar ve quiz kaldığı yerden sürer',
      (tester) async {
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
  });
}
