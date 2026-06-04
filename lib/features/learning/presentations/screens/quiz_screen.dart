import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../data/models/quiz_item.dart';
import '../../../../services/rewards/reward_service.dart';
import '../../../../services/rl_agent/rl_agent.dart';
import '../../../../services/stats/stats_service.dart';
import '../../../../services/lives/lives_service.dart';
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
  const QuizScreen({super.key});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> with TickerProviderStateMixin {
  // ── Soru havuzları ──────────────────────────────────────────────────────────
  late Map<int, List<QuizItem>> _pools;
  int _activeDifficulty = 0;
  int _currentIndex = 0;
  int _stars = 0;

  List<QuizItem> get _items => _pools[_rlAgent.currentDifficulty]!;
  QuizItem get _currentItem => _items[_currentIndex];

  // ── Servisler ───────────────────────────────────────────────────────────────
  final FlutterTts _tts = FlutterTts();
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
  Timer? _silenceTimer;

  // ── Animasyonlar ────────────────────────────────────────────────────────────
  late AnimationController _micPulseController;
  late AnimationController _cardController;
  late Animation<double> _cardAnimation;
  late AnimationController _wordRevealController;
  late Animation<double> _wordRevealAnimation;

  // ── Yaşam döngüsü ───────────────────────────────────────────────────────────

  List<QuizItem> _buildPool(int diff) => QuizData.byDifficulty(diff)
    ..shuffle(Random());

  @override
  void initState() {
    super.initState();
    _pools = {for (var i = 0; i < RLAgent.configs.length; i++) i: _buildPool(i)};

    _micPulseController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900));

    _cardController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _cardAnimation =
        CurvedAnimation(parent: _cardController, curve: Curves.easeOutBack);

    _wordRevealController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _wordRevealAnimation =
        CurvedAnimation(parent: _wordRevealController, curve: Curves.elasticOut);

    _cardController.forward();
    _initTts();
    _startQuestion();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _rewardService = Provider.of<RewardService>(context, listen: false);
    _statsService = Provider.of<StatsService>(context, listen: false);
    _livesService = Provider.of<LivesService>(context, listen: false);
    _vosk = Provider.of<VoskAsrService>(context, listen: false);
    _whisper = Provider.of<WhisperAsrService>(context, listen: false);
    if (!_servicesInitialized) {
      _servicesInitialized = true;
      final maxDiff = _statsService.maxDifficultyForAge;
      final startDiff = _statsService.startingDifficulty.clamp(0, maxDiff);
      _rlAgent = RLAgent(
        epsilon: 0.2,
        initialDifficulty: startDiff,
        maxDifficulty: maxDiff,
      );
      _activeDifficulty = startDiff;
      if (_statsService.asrEngine == 'platform') {
        _whisper.initialize();
      } else {
        _vosk.initialize();
      }
    }
  }

  @override
  void dispose() {
    _tts.stop();
    _silenceTimer?.cancel();
    if (_isListening) _stopAsr();
    _micPulseController.dispose();
    _cardController.dispose();
    _wordRevealController.dispose();
    super.dispose();
  }

  // ── TTS ─────────────────────────────────────────────────────────────────────

  Future<void> _initTts() async {
    _tts.setErrorHandler((msg) => debugPrint('TTS Error: $msg'));
    const variants = ['tr-TR', 'tr_TR', 'tr'];
    bool langSet = false;
    for (final v in variants) {
      final ok = await _tts.isLanguageAvailable(v);
      if (ok == true || ok == 1) {
        await _tts.setLanguage(v);
        langSet = true;
        break;
      }
    }
    if (!langSet) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) showTtsSetupDialog(context);
      });
    }
    await _tts.setSpeechRate(_rlAgent.config.ttsRate);
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.0);
  }

  Future<void> _speak(String text) async {
    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted) _tts.speak(text);
  }

  // ── ASR (Vosk on-device) ────────────────────────────────────────────────────


  bool get _asrIsReady => _statsService.asrEngine == 'platform'
      ? _whisper.isReady
      : _vosk.isReady;

  void _stopAsr() {
    if (_statsService.asrEngine == 'platform') {
      _whisper.stopListening();
    } else {
      _vosk.stopListening();
    }
  }

  void _startAsr({
    required void Function(String) onPartial,
    required void Function(String) onFinal,
  }) {
    if (_statsService.asrEngine == 'platform') {
      _whisper.startListening(onPartial: onPartial, onFinal: onFinal);
    } else {
      _vosk.startListening(onPartial: onPartial, onFinal: onFinal);
    }
  }

  Future<void> _startListening() async {
    if (_isListening || !_asrIsReady) return;

    final perm = await Permission.microphone.status;
    if (perm.isPermanentlyDenied) {
      if (mounted) showMicPermissionDialog(context, permanent: true);
      return;
    }
    if (!perm.isGranted) {
      final result = await Permission.microphone.request();
      if (!result.isGranted) return;
    }

    setState(() {
      _isListening = true;
      _recognizedWord = '';
      _hasSpoken = false;
    });
    _micPulseController.repeat(reverse: true);
    _resetSilenceTimer();

    _startAsr(
      onPartial: (text) {
        if (!mounted) return;
        setState(() => _recognizedWord = text);
        _resetSilenceTimer();
      },
      onFinal: (text) {
        if (!mounted || _hasSpoken) return;
        _silenceTimer?.cancel();
        _handleFinalResult(text);
      },
    );
  }

  void _resetSilenceTimer() {
    _silenceTimer?.cancel();
    _silenceTimer = Timer(const Duration(seconds: 5), () {
      if (!mounted || !_isListening || _hasSpoken) return;
      _stopAsr();
      _micPulseController.stop();
      setState(() => _isListening = false);
      _handleNoAnswer();
    });
  }

  void _handleFinalResult(String recognized) {
    _stopAsr();
    _micPulseController.stop();

    final expected = _currentItem.word;
    final correct = AnswerChecker.check(recognized, expected);
    final latencyMs = _questionStartTime != null
        ? DateTime.now().difference(_questionStartTime!).inMilliseconds
        : 5000;

    _statsService.recordAsrResult(isMatch: correct, latencyMs: latencyMs);
    _statsService.recordCategoryAnswer(category: _currentItem.category, correct: correct);
    _updateRlAgent(correct, latencyMs / 1000.0);

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

    if (correct) {
      _speak('Aferin! Bu bir $expected!');
      _rewardService.addCorrect().then((newRewards) {
        if (mounted && newRewards.isNotEmpty) {
          Future.delayed(const Duration(milliseconds: 800), () {
            if (mounted) showRewardCelebration(context, newRewards.first);
          });
        }
      });
    } else {
      _speak('Neredeyse! Bu bir $expected. Tekrar deneyelim!');
    }

    _scheduleNextOrRest();
  }

  void _toggleListening() {
    if (_isListening) {
      _silenceTimer?.cancel();
      _stopAsr();
      _micPulseController.stop();
      setState(() => _isListening = false);
    } else {
      _startListening();
    }
  }

  // ── Quiz akışı ───────────────────────────────────────────────────────────────

  void _startQuestion() {
    _questionStartTime = DateTime.now();
  }

  void _updateRlAgent(bool correct, double responseTimeSec) {
    final diff = _rlAgent.currentDifficulty;
    _rlAgent.processAnswer(isCorrect: correct, responseTimeSec: responseTimeSec);
    _statsService.recordAnswer(correct: correct, difficulty: diff);
    _tts.setSpeechRate(_rlAgent.config.ttsRate);
    if (_rlAgent.currentDifficulty != diff) {
      _activeDifficulty = _rlAgent.currentDifficulty;
    }
    if (!correct) _livesService.loseLife();
  }

  void _handleNoAnswer() {
    if (!mounted || _hasSpoken) return;
    final expected = _currentItem.word;
    final responseTimeSec = _questionStartTime != null
        ? DateTime.now().difference(_questionStartTime!).inMilliseconds / 1000.0
        : 30.0;

    _statsService.recordCategoryAnswer(category: _currentItem.category, correct: false);
    _updateRlAgent(false, responseTimeSec);

    setState(() {
      _hasSpoken = true;
      _isCorrect = false;
      _recognizedWord = '';
    });
    _wordRevealController
      ..reset()
      ..forward();
    _speak('Bu bir $expected. Tekrar deneyelim!');
    _scheduleNextOrRest();
  }

  void _scheduleNextOrRest() {
    if (_livesService.lives == 0) {
      Future.delayed(const Duration(seconds: 2), () {
        if (!mounted) return;
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const RestScreen()),
        ).then((_) {
          if (mounted) _nextItem();
        });
      });
    } else {
      Future.delayed(const Duration(seconds: 3), _nextItem);
    }
  }

  void _nextItem() {
    if (!mounted) return;
    final currentDiff = _rlAgent.currentDifficulty;
    int nextIndex;

    if (currentDiff != _activeDifficulty) {
      _activeDifficulty = currentDiff;
      nextIndex = 0;
    } else if (_currentIndex < _items.length - 1) {
      nextIndex = _currentIndex + 1;
    } else {
      _pools[currentDiff]!.shuffle(Random());
      nextIndex = 0;
    }

    setState(() {
      _currentIndex = nextIndex;
      _recognizedWord = '';
      _hasSpoken = false;
      _isCorrect = false;
    });
    _cardController
      ..reset()
      ..forward();
    _wordRevealController.reset();
    _startQuestion();
  }

  // ── Build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_items.isEmpty) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            QuizTopBar(
              difficulty: _rlAgent.currentDifficulty,
              difficultyLabel: _rlAgent.config.label,
              stars: _stars,
              currentIndex: _currentIndex,
              totalItems: _items.length,
              onBack: () => Navigator.pop(context),
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
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
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
                              return QuizMicButton(
                                isListening: _isListening,
                                sttAvailable: whisper.isReady,
                                onTap: _toggleListening,
                                pulseController: _micPulseController,
                              );
                            }
                            if (vosk.isDownloading) {
                              return AsrDownloadIndicator(
                                  progress: vosk.downloadProgress);
                            }
                            if (vosk.status == AsrModelStatus.error) {
                              return AsrErrorWidget(vosk: vosk);
                            }
                            return QuizMicButton(
                              isListening: _isListening,
                              sttAvailable: vosk.isReady,
                              onTap: _toggleListening,
                              pulseController: _micPulseController,
                            );
                          },
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _isListening ? 'Dinliyorum...' : 'Dokun ve Söyle',
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
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}