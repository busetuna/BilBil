import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../data/models/quiz_category.dart';
import '../../../../data/models/quiz_item.dart';
import '../../../../services/rewards/reward_service.dart';
import '../../../../services/rl_agent/rl_agent.dart';
import '../../../../services/stats/stats_service.dart';
import '../../../../services/lives/lives_service.dart';
import '../../../../services/ads/ad_service.dart';
import '../../../../services/asr/quiz_grammar.dart';
import '../../../../services/learning/learning_scheduler.dart';
import '../../../../services/learning/word_progress_service.dart';
import '../../../../services/sound/sound_service.dart';
import '../../../../services/tts/voice_service.dart';
import '../../../../services/asr/vosk_asr_service.dart';
import '../../../../services/asr/whisper_asr_service.dart';
import 'rest_screen.dart';
import 'answer_checker.dart';
import 'reward_celebration_dialog.dart';
import 'quiz_dialogs.dart';
import '../widgets/quiz_top_bar.dart';
import '../widgets/quiz_image_card.dart';
import '../widgets/quiz_word_reveal.dart';
import '../widgets/quiz_mic_button.dart';
import '../widgets/asr_status_widget.dart';

class QuizScreen extends StatefulWidget {
  /// Ana ekranda seçilen kategori; null = karışık (tüm kategoriler).
  final QuizCategory? category;

  const QuizScreen({super.key, this.category});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> with TickerProviderStateMixin {
  // ── Soru havuzları ──────────────────────────────────────────────────────────
  late Map<int, List<QuizItem>> _pools;
  int _activeDifficulty = 0;
  int _currentIndex = 0;
  int _stars = 0;

  // Ekrandaki soru, cevap ve geri bildirim boyunca sabit kalır. RL ajanının
  // yeni zorluğu ancak sıradaki soruda uygulanır; önceden havuz anında
  // değişiyor, resim cevap sırasında kayıyor ve eski sıra numarası kısa
  // "zor" havuzunu aşınca RangeError ile çöküyordu.
  List<QuizItem> get _items => _pools[_activeDifficulty]!;
  late QuizItem _currentItem;

  // ── Servisler ───────────────────────────────────────────────────────────────
  late VoiceService _voice;
  late SoundService _sound;
  late VoskAsrService _vosk;
  late WhisperAsrService _whisper;
  late RLAgent _rlAgent;
  late RewardService _rewardService;
  late StatsService _statsService;
  late LivesService _livesService;
  bool _servicesInitialized = false;

  // ── ASR durumu ──────────────────────────────────────────────────────────────
  bool _isListening = false;
  String _recognizedWord = '';
  bool _hasSpoken = false;
  bool _isCorrect = false;
  DateTime? _questionStartTime;
  // RL için tereddüt süresi: mikrofon açılışından ilk duyulan söze kadar.
  DateTime? _listenStartedAt;
  DateTime? _speechStartedAt;
  Timer? _silenceTimer;
  bool _finishing = false;

  // Hiçbir şey duyulmadığında çocuk cezalandırılmaz, tekrar denemesi istenir.
  static const _maxNotHeard = 2;
  int _notHeardCount = 0;
  bool _notHeard = false;

  // "Bilbil söylesin" ipucu bu soruda kullanıldı mı? İpucuyla verilen doğru
  // cevap övülür ama kelime "biliniyor" sayılmaz (bkz. _handleFinalResult).
  bool _hintUsed = false;

  // ── Animasyonlar ────────────────────────────────────────────────────────────
  late AnimationController _micPulseController;
  late AnimationController _cardController;
  late Animation<double> _cardAnimation;
  late AnimationController _wordRevealController;
  late Animation<double> _wordRevealAnimation;

  // ── Yaşam döngüsü ───────────────────────────────────────────────────────────

  // Aralıklı tekrar: zorlanılan kelimeler havuzda öne çıkar (bkz.
  // LearningScheduler), bilinemeyen soru birkaç soru sonra yeniden gelir.
  late WordProgressService _progress;
  final _reviews = ReviewQueue<QuizItem>();
  final _rng = Random();
  int _questionNumber = 0;

  List<QuizItem> _buildPool(int diff) => LearningScheduler.order(
    widget.category?.itemsAt(diff) ?? QuizData.byDifficulty(diff),
    (item) => LearningScheduler.weightOf(_progress.boxOf(item.word)),
    _rng,
  );

  @override
  void initState() {
    super.initState();

    _micPulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _cardController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _cardAnimation = CurvedAnimation(
      parent: _cardController,
      curve: Curves.easeOutBack,
    );

    _wordRevealController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _wordRevealAnimation = CurvedAnimation(
      parent: _wordRevealController,
      curve: Curves.elasticOut,
    );

    _cardController.forward();
    _startQuestion();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _rewardService = Provider.of<RewardService>(context, listen: false);
    _statsService = Provider.of<StatsService>(context, listen: false);
    _livesService = Provider.of<LivesService>(context, listen: false);
    _voice = Provider.of<VoiceService>(context, listen: false);
    _sound = Provider.of<SoundService>(context, listen: false);
    _progress = Provider.of<WordProgressService>(context, listen: false);
    _vosk = Provider.of<VoskAsrService>(context, listen: false);
    _whisper = Provider.of<WhisperAsrService>(context, listen: false);
    // Quiz bitişi reklamı çıkışta hazır olsun.
    Provider.of<AdService>(context, listen: false).preloadInterstitial();
    if (!_servicesInitialized) {
      _servicesInitialized = true;
      // Kategoride kelimesi olmayan seviyeye çıkılmaz (bkz. maxDifficulty).
      final maxDiff = min(
        _statsService.maxDifficultyForAge,
        widget.category?.maxDifficulty ?? 2,
      );
      final startDiff = _statsService.startingDifficulty.clamp(0, maxDiff);
      // Önceki quiz'lerde öğrenilenler ve kalınan seviyeyle başlar.
      _rlAgent = RLAgent(
        epsilon: 0.2,
        initialDifficulty: startDiff,
        maxDifficulty: maxDiff,
        saved: _statsService.rlAgentState,
      );
      _pools = {for (var i = 0; i <= maxDiff; i++) i: _buildPool(i)};
      _activeDifficulty = _rlAgent.currentDifficulty;
      _currentItem = _items[0];
      _initTts(); // _rlAgent'a ihtiyaç duyar
      _sound.startMusic(); // ebeveyn açtıysa
      if (_statsService.asrEngine == 'platform') {
        _whisper.initialize();
      } else {
        _vosk.initialize();
      }
    }
  }

  @override
  void dispose() {
    _voice.stop();
    _sound.stopMusic();
    _silenceTimer?.cancel();
    if (_isListening) _stopAsr();
    _micPulseController.dispose();
    _cardController.dispose();
    _wordRevealController.dispose();
    super.dispose();
  }

  // ── TTS ─────────────────────────────────────────────────────────────────────

  Future<void> _initTts() async {
    final ok = await _voice.prepare();
    if (!ok) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) showTtsSetupDialog(context);
      });
    }
  }

  /// Bilbil'in cümle başı: "Bu bir kedi", "Bu renk kırmızı", "Çocuk koşuyor".
  String get _lead => QuizCategory.leadFor(_currentItem);

  /// Övgü ve geri bildirim: canlı tonda, zorluğa göre biraz hızlanır.
  Future<void> _speak(String text) async {
    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted) _voice.speak(text, rate: _rlAgent.config.ttsRate);
  }

  /// Bilbil kelimeyi yavaşça söyler. [together]: 2–3 yaşta duyulmayınca
  /// "Hadi birlikte söyleyelim". Mikrofon açıkken söylemez (kendi sesi
  /// cevap sanılmasın). "Duyamadım" kararı dinleme bitirilirken verildiği
  /// için _finishing'e bakılmaz; o anda kayıt zaten durmuştur.
  Future<void> _giveHint({bool together = false}) async {
    if (_isListening || _hasSpoken) return;
    setState(() => _hintUsed = true);
    final word = _currentItem.word;
    await _voice.stop();
    await _voice.speak(
      together
          ? VoiceService.together(word, lead: _lead)
          : VoiceService.hint(word, lead: _lead),
      rate: VoiceService.wordRate,
    );
  }

  // ── ASR (Vosk on-device) ────────────────────────────────────────────────────

  bool get _asrIsReady =>
      _statsService.asrEngine == 'platform' ? _whisper.isReady : _vosk.isReady;

  void _stopAsr() {
    if (_statsService.asrEngine == 'platform') {
      _whisper.stopListening();
    } else {
      _vosk.stopListening();
    }
  }

  void _startAsr({
    required void Function(String) onPartial,
    required void Function(List<String>) onFinal,
    required void Function() onSpeech,
  }) {
    if (_statsService.asrEngine == 'platform') {
      _whisper.startListening(onPartial: onPartial, onFinal: onFinal);
    } else {
      _vosk.startListening(
        onPartial: onPartial,
        onFinal: onFinal,
        onSpeech: onSpeech,
        grammar: QuizGrammar.forWord(_currentItem.word),
      );
    }
  }

  /// Dinlemeyi bitirir; o ana kadar duyulan tahminleri döner (en iyisi önce).
  Future<List<String>> _finishAsr() async {
    final partial = [if (_recognizedWord.trim().isNotEmpty) _recognizedWord];
    if (_statsService.asrEngine == 'platform') {
      _whisper.stopListening();
      return partial;
    }
    final candidates = await _vosk.finishListening();
    return candidates.isNotEmpty ? candidates : partial;
  }

  /// Küçük çocuklar söze daha geç başlar.
  Duration get _silenceTimeout =>
      Duration(seconds: _statsService.childAge <= 3 ? 8 : 6);

  Future<void> _startListening() async {
    // _hasSpoken: soru cevaplandı, sıradakine geçiliyor. Bu sırada dinlemek
    // aynı soruyu ikinci kez cevaplatıp yıldız/ödülü iki kez sayıyordu.
    if (_isListening || _finishing || _hasSpoken || !_asrIsReady) return;

    final perm = await Permission.microphone.status;
    if (perm.isPermanentlyDenied) {
      if (mounted) showMicPermissionDialog(context, permanent: true);
      return;
    }
    if (!perm.isGranted) {
      final result = await Permission.microphone.request();
      if (!result.isGranted) {
        if (mounted) {
          showMicPermissionDialog(
            context,
            permanent: result.isPermanentlyDenied,
          );
        }
        return;
      }
    }
    if (!mounted || _isListening || _hasSpoken) return;

    // Bilbil konuşurken mikrofon açılırsa kendi sesi cevap sanılmasın;
    // müzik de dinleme boyunca susar (cevap bitince _listeningDone sürdürür).
    await _voice.stop();
    await _sound.suspendMusic('mic');
    if (!mounted) return;

    setState(() {
      _isListening = true;
      _recognizedWord = '';
      _hasSpoken = false;
      _notHeard = false;
    });
    _micPulseController.repeat(reverse: true);
    _resetSilenceTimer();
    _listenStartedAt = DateTime.now();
    _speechStartedAt = null;

    _startAsr(
      onPartial: (text) {
        if (!mounted || !_isListening) return;
        _speechStartedAt ??= DateTime.now();
        setState(() => _recognizedWord = text);
        _resetSilenceTimer();
      },
      onFinal: (candidates) {
        if (!mounted || _hasSpoken || !_isListening) return;
        _silenceTimer?.cancel();
        if (candidates.every((c) => c.trim().isEmpty)) {
          _stopAsr();
          _micPulseController.stop();
          setState(() => _isListening = false);
          _handleNotHeard();
        } else {
          _handleFinalResult(candidates);
        }
      },
      onSpeech: () {
        if (mounted && _isListening) _resetSilenceTimer();
      },
    );
  }

  void _resetSilenceTimer() {
    _silenceTimer?.cancel();
    _silenceTimer = Timer(_silenceTimeout, _finishListening);
  }

  /// Süre dolunca ya da mikrofona tekrar dokununca: duyulanı değerlendir.
  /// Önceden duyulan kısmi metin atılıyor, cevap "yanlış" sayılıyordu.
  Future<void> _finishListening() async {
    if (!mounted || !_isListening || _hasSpoken || _finishing) return;
    _finishing = true;
    _silenceTimer?.cancel();
    _micPulseController.stop();
    setState(() => _isListening = false);
    try {
      final candidates = await _finishAsr();
      if (!mounted || _hasSpoken) return;
      if (candidates.every((c) => c.trim().isEmpty)) {
        _handleNotHeard();
      } else {
        _handleFinalResult(candidates);
      }
    } finally {
      _finishing = false;
    }
  }

  /// Dinleme bitti (cevap ya da "duyamadım"): müzik sürebilir.
  void _listeningDone() => _sound.resumeMusic('mic');

  void _handleFinalResult(List<String> candidates) {
    _stopAsr();
    _micPulseController.stop();
    _listeningDone();

    final expected = _currentItem.word;
    // Tahminlerden biri tutarsa doğru; ekranda tutan (yoksa en iyi) tahmin.
    // Resmin diğer doğru adları da kabul (ör. Kupa için "Bardak").
    final answers = _currentItem.answers;
    final match = candidates.where(
      (c) => answers.any((a) => AnswerChecker.check(c, a)),
    );
    final correct = match.isNotEmpty;
    final recognized = correct ? match.first : candidates.first;
    final latencyMs = _questionStartTime != null
        ? DateTime.now().difference(_questionStartTime!).inMilliseconds
        : 5000;

    _statsService.recordAsrResult(isMatch: correct, latencyMs: latencyMs);
    _statsService.recordCategoryAnswer(
      category: _currentItem.category,
      correct: correct,
    );
    _progress.record(_currentItem.word, correct: correct, hinted: _hintUsed);
    if (!correct) _reviews.scheduleAfterMiss(_currentItem, _questionNumber);
    _updateRlAgent(correct, _hesitationSec());

    setState(() {
      _isListening = false;
      _hasSpoken = true;
      _isCorrect = correct;
      _recognizedWord = recognized;
      if (correct) _stars++;
    });

    _wordRevealController
      ..reset()
      ..forward();

    // Efekt hemen, Bilbil'in sözü yarım saniye sonra (bkz. _speak).
    if (correct) {
      _sound.play(SoundEffect.correct);
      _speak(_voice.praise(expected, hinted: _hintUsed, lead: _lead));
      _rewardService.addCorrect().then((newRewards) {
        if (mounted && newRewards.isNotEmpty) {
          Future.delayed(const Duration(milliseconds: 800), () {
            if (!mounted) return;
            _sound.play(SoundEffect.reward);
            showRewardCelebration(context, newRewards.first);
          });
        }
      });
    } else {
      _sound.play(SoundEffect.wrong);
      _speak(_voice.tryAgain(expected, lead: _lead));
    }

    _scheduleNextOrRest();
  }

  void _toggleListening() {
    if (_isListening) {
      _finishListening();
    } else {
      _startListening();
    }
  }

  // ── Quiz akışı ───────────────────────────────────────────────────────────────

  void _startQuestion() {
    _questionStartTime = DateTime.now();
  }

  /// Mikrofon açıldıktan çocuk konuşmaya başlayana kadar geçen süre. Söz
  /// hiç ara sonuç vermeden geldiyse (kısa kelime) cevabın geldiği an.
  double _hesitationSec() {
    final start = _listenStartedAt;
    if (start == null) return 5.0;
    final end = _speechStartedAt ?? DateTime.now();
    return end.difference(start).inMilliseconds / 1000.0;
  }

  /// Ajanın öğrendikleri her quiz'de saklanır. Kategori quiz'i ise
  /// çocuğun kaldığı seviyeyi değiştirmez: seviyesi kategoriye göre
  /// kısıtlı olabilir (ör. Şekiller'de yalnızca Kolay), Zor'daki çocuk
  /// sonraki karışık quiz'e Kolay'dan başlamasın.
  Map<String, dynamic> _rlStateToSave() {
    final state = _rlAgent.toJson();
    if (widget.category == null) return state;
    final level = _statsService.rlAgentState?['level'];
    return level == null
        ? (state..remove('level'))
        : {...state, 'level': level};
  }

  void _updateRlAgent(bool correct, double responseTimeSec) {
    final diff = _rlAgent.currentDifficulty;
    _rlAgent.processAnswer(
      isCorrect: correct,
      responseTimeSec: responseTimeSec,
      hintUsed: _hintUsed,
      itemDifficulty: _currentItem.difficulty,
    );
    _statsService.recordAnswer(
      correct: correct,
      difficulty: diff,
      rlState: _rlStateToSave(),
    );
    // Yeni zorluk _nextItem'da uygulanır; ekrandaki soru burada değişmez.
    if (!correct) _livesService.loseLife();
    _answeredThisSession++;
  }

  // Quiz bitişi reklamı yalnızca yeterince oynandıysa (bkz. AdPacing).
  int _answeredThisSession = 0;
  bool _leaving = false;

  /// Çocuk quiz'den kendi isteğiyle çıkıyor (geri butonu ya da geri tuşu):
  /// sıklık kuralları izin verirse ana sayfaya dönerken geçiş reklamı çıkar.
  /// Canlar bitip moladan çıkılırken reklam gösterilmez.
  void _leaveQuiz() {
    if (_leaving) return;
    _leaving = true;
    _sound.stopMusic(); // reklamdan önce
    final ads = context.read<AdService>();
    Navigator.pop(context);
    ads.showQuizEndAd(answersThisSession: _answeredThisSession);
  }

  /// Hiçbir şey duyulmadı. Bu çocuğun hatası değil (sessiz kaldı, mikrofon
  /// alamadı ya da tanıma kaçırdı): can, istatistik ve RL etkilenmez.
  void _handleNotHeard() {
    _listeningDone();
    if (!mounted || _hasSpoken) return;
    _notHeardCount++;
    if (_notHeardCount < _maxNotHeard) {
      setState(() {
        _notHeard = true;
        _recognizedWord = '';
      });
      if (_statsService.childAge <= 3) {
        _giveHint(together: true); // küçükler için: kelimeyi birlikte söyle
      } else {
        _speak(VoiceService.notHeard);
      }
      return; // aynı soru; çocuk mikrofona tekrar dokunur
    }

    // Yine duyulmadı: kelimeyi göster ve cezasız sıradakine geç.
    setState(() {
      _hasSpoken = true;
      _isCorrect = false;
      _recognizedWord = '';
      _notHeard = false;
    });
    _wordRevealController
      ..reset()
      ..forward();
    _speak(VoiceService.skip(_currentItem.word, lead: _lead));
    _scheduleNextOrRest();
  }

  void _scheduleNextOrRest() {
    if (_livesService.lives == 0) {
      Future.delayed(const Duration(seconds: 2), () async {
        if (!mounted) return;
        _sound.suspendMusic('rest'); // molada müzik yok (reklam da var)
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const RestScreen()),
        );
        _sound.resumeMusic('rest');
        if (!mounted) return;
        // Mola bitmeden geri dönüldüyse 0 canla oynanmasın.
        if (_livesService.hasLives) {
          _nextItem();
        } else {
          Navigator.pop(context);
        }
      });
    } else {
      Future.delayed(const Duration(seconds: 3), _nextItem);
    }
  }

  void _nextItem() {
    if (!mounted) return;
    _questionNumber++;
    final currentDiff = _rlAgent.currentDifficulty;
    if (currentDiff != _activeDifficulty) {
      _activeDifficulty = currentDiff; // yeni zorluğun havuzu, baştan
      _currentIndex = -1;
    }

    // Vakti gelen tekrar sorusu varsa önce o; havuzdaki sıra beklemede kalır.
    var next = _reviews.takeDue(_questionNumber, exclude: _currentItem);
    if (next == null) {
      if (_currentIndex >= _items.length - 1) {
        // Havuz bitti: güncel ilerlemeyle yeniden ağırlıklı sırala.
        _pools[_activeDifficulty] = _buildPool(_activeDifficulty);
        _currentIndex = -1;
      }
      _currentIndex++;
      next = _items[_currentIndex];
    }

    setState(() {
      _currentItem = next!;
      _recognizedWord = '';
      _hasSpoken = false;
      _isCorrect = false;
      _notHeard = false;
      _notHeardCount = 0;
      _hintUsed = false;
    });
    _cardController
      ..reset()
      ..forward();
    _wordRevealController.reset();
    _startQuestion();
  }

  // ── Build ────────────────────────────────────────────────────────────────────

  /// Mikrofon ortada kalsın diye sağda ipucu butonu kadar boşluk bırakılır.
  Widget _micWithHint(Widget mic) {
    final enabled = !_isListening && !_hasSpoken;
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Opacity(
          opacity: enabled ? 1 : 0.35,
          child: GestureDetector(
            key: const Key('hint-button'),
            onTap: enabled ? _giveHint : null,
            child: SizedBox(
              width: 72,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFFFFF3C4),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.lightbulb_rounded,
                      color: Color(0xFFFFA000),
                      size: 28,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Bilbil söylesin',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        mic,
        const SizedBox(width: 16 + 72),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_items.isEmpty) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return PopScope(
      canPop: false, // Android geri tuşu da _leaveQuiz'den geçsin
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _leaveQuiz();
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Column(
            children: [
              QuizTopBar(
                difficulty: _activeDifficulty,
                difficultyLabel: RLAgent.configs[_activeDifficulty].label,
                categoryName: widget.category?.name,
                stars: _stars,
                currentIndex: max(_currentIndex, 0),
                totalItems: _items.length,
                onBack: _leaveQuiz,
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: ScaleTransition(
                    scale: _cardAnimation,
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: AppColors.card,
                        borderRadius: BorderRadius.circular(32),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.06),
                            blurRadius: 20,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      // Kısa ekranlarda (küçük telefon, yatay mod) içerik
                      // taşmak yerine orantılı küçülür.
                      child: Center(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const SizedBox(height: 24),
                              QuizImageCard(imagePath: _currentItem.imagePath),
                              const SizedBox(height: 28),
                              QuizWordReveal(
                                hasSpoken: _hasSpoken,
                                recognizedWord: _recognizedWord,
                                correctWord: _currentItem.word,
                                isListening: _isListening,
                                isCorrect: _isCorrect,
                                revealAnimation: _wordRevealAnimation,
                              ),
                              const SizedBox(height: 28),
                              Consumer2<VoskAsrService, WhisperAsrService>(
                                builder: (context, vosk, whisper, _) {
                                  final usePlatform =
                                      _statsService.asrEngine == 'platform';
                                  if (usePlatform) {
                                    return _micWithHint(
                                      QuizMicButton(
                                        isListening: _isListening,
                                        sttAvailable: whisper.isReady,
                                        onTap: _toggleListening,
                                        pulseController: _micPulseController,
                                      ),
                                    );
                                  }
                                  if (vosk.isDownloading) {
                                    // FittedBox içinde genişlik sınırsız; çubuğa ver.
                                    return SizedBox(
                                      width: 260,
                                      child: AsrDownloadIndicator(
                                        progress: vosk.downloadProgress,
                                      ),
                                    );
                                  }
                                  if (vosk.status == AsrModelStatus.error) {
                                    return AsrErrorWidget(vosk: vosk);
                                  }
                                  return _micWithHint(
                                    QuizMicButton(
                                      isListening: _isListening,
                                      sttAvailable: vosk.isReady,
                                      onTap: _toggleListening,
                                      pulseController: _micPulseController,
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(height: 12),
                              Text(
                                _isListening
                                    ? 'Dinliyorum...'
                                    : _notHeard
                                    ? 'Seni duyamadım, tekrar dokun'
                                    : 'Dokun ve Söyle',
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 24),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
