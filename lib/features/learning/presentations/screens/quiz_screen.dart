import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../data/models/quiz_item.dart';
import '../../../../services/rewards/reward_service.dart';
import '../../../../services/rl_agent/rl_agent.dart';
import '../../../../services/stats/stats_service.dart';
import '../../../../services/lives/lives_service.dart';
import 'rest_screen.dart';
import 'answer_checker.dart';
import 'reward_celebration_dialog.dart';

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
  final SpeechToText _stt = SpeechToText();
  late RLAgent _rlAgent;
  late RewardService _rewardService;
  late StatsService _statsService;
  late LivesService _livesService;
  bool _servicesInitialized = false;

  // ── STT durumu ──────────────────────────────────────────────────────────────
  bool _isListening = false;
  bool _sttAvailable = false;
  String _recognizedWord = '';
  bool _hasSpoken = false;
  bool _isCorrect = false;
  DateTime? _questionStartTime;

  // ── Animasyonlar ────────────────────────────────────────────────────────────
  late AnimationController _micPulseController;
  late AnimationController _cardController;
  late Animation<double> _cardAnimation;
  late AnimationController _wordRevealController;
  late Animation<double> _wordRevealAnimation;

  // ── Yaşam döngüsü ───────────────────────────────────────────────────────────

  List<QuizItem> _buildPool(int diff) => RLAgent.configs[diff].categories
      .expand((c) => QuizData.byCategory(c))
      .toList()
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
    _initStt();
    _startQuestion();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _rewardService = Provider.of<RewardService>(context, listen: false);
    _statsService = Provider.of<StatsService>(context, listen: false);
    _livesService = Provider.of<LivesService>(context, listen: false);
    if (!_servicesInitialized) {
      _servicesInitialized = true;
      _rlAgent = RLAgent(
        epsilon: 0.2,
        initialDifficulty: _statsService.startingDifficulty,
      );
      _activeDifficulty = _statsService.startingDifficulty;
    }
  }

  @override
  void dispose() {
    _tts.stop();
    _stt.stop();
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
        if (mounted) _showTtsSetupDialog();
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

  void _showTtsSetupDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Sesli Okuma Kapalı',
            style: GoogleFonts.fredoka(fontSize: 20, fontWeight: FontWeight.bold)),
        content: Text(
          'Türkçe ses paketi yüklü değil.\n\n'
          '📱 Şu adımları izle:\n'
          '1. Telefon Ayarları\'nı aç\n'
          '2. "Erişilebilirlik" seç\n'
          '3. "Metin Okuma" veya "TTS" seç\n'
          '4. "Türkçe" dil paketini indir\n'
          '5. Uygulamaya geri dön',
          style: GoogleFonts.poppins(fontSize: 13, height: 1.6),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Tamam',
                style: GoogleFonts.poppins(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: Text('Ayarları Aç',
                style: GoogleFonts.poppins(
                    color: Colors.white, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  // ── STT ─────────────────────────────────────────────────────────────────────

  Future<void> _initStt() async {
    final status = await Permission.microphone.request();
    if (status.isPermanentlyDenied) {
      setState(() => _sttAvailable = false);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _showMicPermissionDialog(permanent: true);
      });
      return;
    }
    if (status.isDenied) {
      setState(() => _sttAvailable = false);
      return;
    }
    _sttAvailable =
        await _stt.initialize(onError: _onSttError, onStatus: _onSttStatus);
    setState(() {});
  }

  void _onSttStatus(String s) {
    if ((s == 'done' || s == 'notListening') && mounted) {
      _micPulseController.stop();
      final wasListening = _isListening;
      if (_isListening) setState(() => _isListening = false);
      if (wasListening && !_hasSpoken) _handleNoAnswer();
    }
  }

  void _onSttError(SpeechRecognitionError error) {
    if (!mounted) return;
    _micPulseController.stop();
    setState(() => _isListening = false);
    if (error.permanent) {
      Permission.microphone.status.then((perm) {
        if (!perm.isGranted && mounted) {
          setState(() => _sttAvailable = false);
          _showMicPermissionDialog(permanent: perm.isPermanentlyDenied);
        }
      });
    }
  }

  void _showMicPermissionDialog({required bool permanent}) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Mikrofon İzni Gerekli',
            style: GoogleFonts.fredoka(fontSize: 20, fontWeight: FontWeight.bold)),
        content: Text(
          permanent
              ? 'Mikrofon izni kalıcı olarak reddedildi.\n'
                  'Uygulama ayarlarından "Mikrofon" iznini açmanız gerekiyor.'
              : 'Sesli cevap verebilmek için mikrofon iznine ihtiyaç var.',
          style: GoogleFonts.poppins(fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Tamam',
                style: GoogleFonts.poppins(color: AppColors.textSecondary)),
          ),
          if (permanent)
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                openAppSettings();
              },
              style:
                  ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              child: Text('Ayarları Aç',
                  style: GoogleFonts.poppins(
                      color: Colors.white, fontWeight: FontWeight.w600)),
            ),
        ],
      ),
    );
  }

  Future<void> _startListening() async {
    if (_isListening) return;

    final perm = await Permission.microphone.status;
    if (perm.isPermanentlyDenied) {
      _showMicPermissionDialog(permanent: true);
      return;
    }
    if (!perm.isGranted) {
      final result = await Permission.microphone.request();
      if (!result.isGranted) return;
    }

    if (!_sttAvailable) {
      _sttAvailable =
          await _stt.initialize(onError: _onSttError, onStatus: _onSttStatus);
      if (mounted) setState(() {});
      if (!_sttAvailable) return;
    }

    setState(() {
      _isListening = true;
      _recognizedWord = '';
      _hasSpoken = false;
    });
    _micPulseController.repeat(reverse: true);

    await _stt.listen(
      onResult: _onSttResult,
      localeId: 'tr_TR',
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 4),
      listenOptions: SpeechListenOptions(cancelOnError: false),
    );
  }

  void _onSttResult(SpeechRecognitionResult result) {
    setState(() => _recognizedWord = result.recognizedWords);
    if (!result.finalResult || _recognizedWord.isEmpty) return;

    _stt.stop();
    _micPulseController.stop();

    final expected = _currentItem.word;
    final correct = AnswerChecker.check(_recognizedWord, expected);
    final responseTimeSec = _questionStartTime != null
        ? DateTime.now().difference(_questionStartTime!).inMilliseconds / 1000.0
        : 5.0;

    _updateRlAgent(correct, responseTimeSec);

    setState(() {
      _isListening = false;
      _hasSpoken = true;
      _isCorrect = correct;
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

  Future<void> _toggleListening() async {
    if (_isListening) {
      await _stt.stop();
      _micPulseController.stop();
      setState(() => _isListening = false);
    } else {
      await _startListening();
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
      backgroundColor: const Color(0xFFF0F4FF),
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: ScaleTransition(
                  scale: _cardAnimation,
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFFDE7),
                      borderRadius: BorderRadius.circular(32),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.06),
                          blurRadius: 20,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildImageCard(),
                        const SizedBox(height: 28),
                        _buildWordReveal(),
                        const SizedBox(height: 28),
                        _buildMicButton(),
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

  Widget _buildTopBar() {
    final diffColors = [
      const Color(0xFF4CAF50),
      const Color(0xFFFFC107),
      const Color(0xFFF44336),
    ];
    final diffColor = diffColors[_rlAgent.currentDifficulty];
    final starsShown = _stars % 5 == 0 && _stars > 0 ? 5 : _stars % 5;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withOpacity(0.08), blurRadius: 8)
                    ],
                  ),
                  child: Icon(Icons.arrow_back_ios_new_rounded,
                      size: 18, color: AppColors.textPrimary),
                ),
              ),
              const Spacer(),
              Row(
                children: List.generate(
                  5,
                  (i) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: Icon(
                      i < starsShown
                          ? Icons.star_rounded
                          : Icons.star_outline_rounded,
                      size: 28,
                      color: i < starsShown
                          ? const Color(0xFFFFC107)
                          : const Color(0xFFD0D0D0),
                    ),
                  ),
                ),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.08), blurRadius: 8)
                  ],
                ),
                child: Text(
                  '${_currentIndex + 1}/${_items.length}',
                  style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: diffColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: diffColor.withOpacity(0.4)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.auto_graph_rounded, size: 13, color: diffColor),
                    const SizedBox(width: 4),
                    Text(
                      'Seviye: ${_rlAgent.config.label}',
                      style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: diffColor),
                    ),
                  ],
                ),
              ),
              Consumer<LivesService>(
                builder: (_, lives, __) => Row(
                  children: List.generate(
                    LivesService.maxLives,
                    (i) => Padding(
                      padding: const EdgeInsets.only(left: 3),
                      child: Icon(
                        Icons.favorite_rounded,
                        size: 18,
                        color: i < lives.lives
                            ? const Color(0xFFFF4F6D)
                            : Colors.grey[300],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildImageCard() {
    return Container(
      width: 260,
      height: 220,
      margin: const EdgeInsets.only(top: 28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.07),
              blurRadius: 16,
              offset: const Offset(0, 4))
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Image.asset(
          _currentItem.imagePath,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => Center(
            child: Icon(Icons.image_not_supported_outlined,
                size: 60, color: Colors.grey[300]),
          ),
        ),
      ),
    );
  }

  Widget _buildWordReveal() {
    // Sessiz kaldı
    if (_hasSpoken && _recognizedWord.isEmpty) {
      return ScaleTransition(
        scale: _wordRevealAnimation,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3E0),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: const Color(0xFFFF9800).withOpacity(0.6), width: 2),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('🤫', style: TextStyle(fontSize: 24)),
                  const SizedBox(width: 8),
                  Text(
                    _currentItem.word,
                    style: GoogleFonts.fredoka(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFFFF9800)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            Text('Tekrar deneyelim!',
                style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: const Color(0xFFFF9800),
                    fontWeight: FontWeight.w600)),
          ],
        ),
      );
    }

    final feedbackColor =
        _isCorrect ? const Color(0xFF4CAF50) : const Color(0xFFF44336);
    final feedbackIcon = _isCorrect ? '✅' : '❌';

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 400),
      child: _hasSpoken && _recognizedWord.isNotEmpty
          ? ScaleTransition(
              key: ValueKey(_recognizedWord),
              scale: _wordRevealAnimation,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 32, vertical: 12),
                    decoration: BoxDecoration(
                      color: feedbackColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: feedbackColor.withOpacity(0.5), width: 2),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(feedbackIcon,
                            style: const TextStyle(fontSize: 24)),
                        const SizedBox(width: 8),
                        Text(
                          _recognizedWord,
                          style: GoogleFonts.fredoka(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: feedbackColor),
                        ),
                      ],
                    ),
                  ),
                  if (!_isCorrect) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Doğrusu: ${_currentItem.word}',
                      style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: const Color(0xFF4CAF50),
                          fontWeight: FontWeight.w600),
                    ),
                  ],
                ],
              ),
            )
          : SizedBox(
              height: 60,
              child: Center(
                child: Text(
                  _isListening ? '🎤 ...' : '❓',
                  style: const TextStyle(fontSize: 32),
                ),
              ),
            ),
    );
  }

  Widget _buildMicButton() {
    return GestureDetector(
      onTap: _sttAvailable ? _toggleListening : null,
      child: AnimatedBuilder(
        animation: _micPulseController,
        builder: (context, child) {
          final scale =
              _isListening ? 1.0 + (_micPulseController.value * 0.15) : 1.0;
          return Transform.scale(scale: scale, child: child);
        },
        child: Container(
          width: 76,
          height: 76,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _isListening ? AppColors.secondary : const Color(0xFF5B9BFF),
            boxShadow: [
              BoxShadow(
                color: (_isListening
                        ? AppColors.secondary
                        : const Color(0xFF5B9BFF))
                    .withOpacity(0.45),
                blurRadius: 24,
                spreadRadius: 4,
              ),
            ],
          ),
          child: Icon(
            _isListening ? Icons.mic_rounded : Icons.mic_none_rounded,
            color: Colors.white,
            size: 36,
          ),
        ),
      ),
    );
  }
}