// lib/features/learning/presentations/screens/quiz_screen.dart

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../data/models/quiz_item.dart';
import '../../../../services/rewards/reward_service.dart';
import '../../../../services/rl_agent/rl_agent.dart';
import 'package:permission_handler/permission_handler.dart';

class QuizScreen extends StatefulWidget {
  final String category;
  const QuizScreen({super.key, this.category = 'animals'});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> with TickerProviderStateMixin {
  late List<QuizItem> _items;
  int _currentIndex = 0;
  int _stars = 0;

  final FlutterTts _tts = FlutterTts();
  final SpeechToText _stt = SpeechToText();

  bool _isListening = false;
  bool _sttAvailable = false;
  String _recognizedWord = '';
  bool _hasSpoken = false;
  bool _isCorrect = false;
  bool _showHint = false;
  late RewardService _rewardService;
  final RLAgent _rlAgent = RLAgent(epsilon: 0.2);
  DateTime? _questionStartTime;

  late AnimationController _micPulseController;
  late AnimationController _cardController;
  late Animation<double> _cardAnimation;
  late AnimationController _wordRevealController;
  late Animation<double> _wordRevealAnimation;

  @override
  void initState() {
    super.initState();
    _items = List.from(QuizData.byCategory(widget.category))..shuffle(Random());

    _micPulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _cardController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _cardAnimation = CurvedAnimation(parent: _cardController, curve: Curves.easeOutBack);

    _wordRevealController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _wordRevealAnimation = CurvedAnimation(parent: _wordRevealController, curve: Curves.elasticOut);

    _cardController.forward();
    _initTts();
    _initStt();
    _startQuestion();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _rewardService = Provider.of<RewardService>(context, listen: false);
  }

  void _showRewardCelebration(Reward reward) {
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black54,
      builder: (dialogContext) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 28, vertical: 60),
        child: _RewardCelebrationCard(
          reward: reward,
          onCollect: () => Navigator.pop(dialogContext),
        ),
      ),
    );
  }

  Future<void> _initTts() async {
    await _tts.setLanguage('tr-TR');
    await _tts.setSpeechRate(_rlAgent.config.ttsRate);
    await _tts.setVolume(1.0);
  }

  void _startQuestion() {
    _questionStartTime = DateTime.now();
    _showHint = false;

    // Kolay modda belirli süre sonra ipucu göster
    if (_rlAgent.config.showHintAfterDelay) {
      Future.delayed(Duration(seconds: _rlAgent.config.hintDelaySeconds), () {
        if (mounted && !_hasSpoken) {
          setState(() => _showHint = true);
        }
      });
    }
  }

  Future<void> _initStt() async {
    final status = await Permission.microphone.request();

    if (status.isPermanentlyDenied) {
      // Kullanıcı "bir daha sorma" dedi → ayarlara gönder
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

    _sttAvailable = await _stt.initialize(
      onError: (error) {
        debugPrint('STT Error: $error');
        // permanent: true → dinlemeyi durdur ve kullanıcıyı bilgilendir
        if (error.permanent && mounted) {
          _micPulseController.stop();
          setState(() {
            _isListening = false;
            _sttAvailable = false;
          });
          _showMicPermissionDialog(permanent: true);
        }
      },
      onStatus: (s) {
        debugPrint('STT Status: $s');
        // 'done' veya 'notListening' gelirse animasyonu durdur
        if ((s == 'done' || s == 'notListening') && mounted) {
          _micPulseController.stop();
          if (_isListening) setState(() => _isListening = false);
        }
      },
    );
    setState(() {});
  }

  void _showMicPermissionDialog({required bool permanent}) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Mikrofon İzni Gerekli',
          style: GoogleFonts.fredoka(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        content: Text(
          permanent
              ? 'Mikrofon izni kalıcı olarak reddedildi.\nUygulama ayarlarından "Mikrofon" iznini açmanız gerekiyor.'
              : 'Sesli cevap verebilmek için mikrofon iznine ihtiyaç var.',
          style: GoogleFonts.poppins(fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Tamam', style: GoogleFonts.poppins(color: AppColors.textSecondary)),
          ),
          if (permanent)
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                openAppSettings();
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              child: Text('Ayarları Aç',
                  style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600)),
            ),
        ],
      ),
    );
  }

  bool _checkAnswer(String recognized, String expected) {
    String normalize(String s) => s
        .trim()
        .toLowerCase()
        .replaceAll('İ', 'i')
        .replaceAll('I', 'ı')
        .replaceAll('Ğ', 'ğ')
        .replaceAll('Ü', 'ü')
        .replaceAll('Ş', 'ş')
        .replaceAll('Ö', 'ö')
        .replaceAll('Ç', 'ç');
    final r = normalize(recognized);
    final e = normalize(expected);
    return r == e || r.contains(e) || e.contains(r);
  }

  Future<void> _toggleListening() async {
    if (_isListening) {
      await _stt.stop();
      _micPulseController.stop();
      setState(() => _isListening = false);
    } else {
      // Her basışta izni tekrar kontrol et
      final permStatus = await Permission.microphone.status;
      if (permStatus.isPermanentlyDenied) {
        _showMicPermissionDialog(permanent: true);
        return;
      }
      if (!permStatus.isGranted) {
        final result = await Permission.microphone.request();
        if (!result.isGranted) return;
        // İzin yeni verildiyse STT'yi yeniden başlat
        _sttAvailable = await _stt.initialize(
          onError: (error) {
            if (error.permanent && mounted) {
              _micPulseController.stop();
              setState(() { _isListening = false; _sttAvailable = false; });
              _showMicPermissionDialog(permanent: true);
            }
          },
          onStatus: (s) {
            if ((s == 'done' || s == 'notListening') && mounted) {
              _micPulseController.stop();
              if (_isListening) setState(() => _isListening = false);
            }
          },
        );
        if (!_sttAvailable) return;
      }

      setState(() {
        _isListening = true;
        _recognizedWord = '';
        _hasSpoken = false;
      });
      _micPulseController.repeat(reverse: true);

      await _stt.listen(
        onResult: (result) {
          setState(() {
            _recognizedWord = result.recognizedWords;
          });

          if (result.finalResult && _recognizedWord.isNotEmpty) {
            _stt.stop();
            _micPulseController.stop();

            final expectedWord = _items[_currentIndex].word;
            final correct = _checkAnswer(_recognizedWord, expectedWord);

            // Yanıt süresini hesapla
            final responseTimeSec = _questionStartTime != null
                ? DateTime.now().difference(_questionStartTime!).inMilliseconds / 1000.0
                : 5.0;

            // RL ajanını güncelle → yeni zorluk belirle
            _rlAgent.processAnswer(
              isCorrect: correct,
              responseTimeSec: responseTimeSec,
            );

            // TTS hızını yeni zorluğa göre güncelle
            _tts.setSpeechRate(_rlAgent.config.ttsRate);

            setState(() {
              _isListening = false;
              _hasSpoken = true;
              _isCorrect = correct;
              _showHint = false;
              if (correct) _stars = min(_stars + 1, 5);
            });

            _wordRevealController.reset();
            _wordRevealController.forward();

            if (correct) {
              _tts.speak('Aferin! Bu bir $expectedWord!');
              _rewardService.addCorrect().then((newRewards) {
                if (mounted && newRewards.isNotEmpty) {
                  Future.delayed(const Duration(milliseconds: 800), () {
                    if (mounted) _showRewardCelebration(newRewards.first);
                  });
                }
              });
            } else {
              _tts.speak('Neredeyse! Bu bir $expectedWord. Tekrar deneyelim!');
            }

            Future.delayed(const Duration(seconds: 3), _nextItem);
          }
        },
        localeId: 'tr_TR',
      );
    }
  }

  void _nextItem() {
    if (!mounted) return;
    if (_currentIndex < _items.length - 1) {
      setState(() {
        _currentIndex++;
        _recognizedWord = '';
        _hasSpoken = false;
        _isCorrect = false;
        _showHint = false;
      });
      _cardController.reset();
      _cardController.forward();
      _wordRevealController.reset();
      _startQuestion();
    } else {
      _showFinishDialog();
    }
  }

  void _showFinishDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🎉', style: TextStyle(fontSize: 64)),
            const SizedBox(height: 12),
            Text('Tebrikler!',
                style: GoogleFonts.fredoka(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.primary)),
            const SizedBox(height: 8),
            Text('Tüm resimleri tamamladın!',
                style: GoogleFonts.poppins(fontSize: 14, color: AppColors.textSecondary),
                textAlign: TextAlign.center),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () { Navigator.pop(context); Navigator.pop(context); },
            child: Text('Ana Sayfaya Dön',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _items.shuffle(Random());
                _currentIndex = 0;
                _stars = 0; // yeni oyunda sıfırla
                _recognizedWord = '';
                _hasSpoken = false;
                _isCorrect = false;
              });
              _cardController.reset();
              _cardController.forward();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text('Tekrar Oyna',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: Colors.white)),
          ),
        ],
      ),
    );
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

  @override
  Widget build(BuildContext context) {
    if (_items.isEmpty) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    final item = _items[_currentIndex];

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
                        BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 20, offset: const Offset(0, 6)),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Resim kartı
                        _buildImageCard(item),

                        // İpucu (kolay modda, gecikmeli gösterilir)
                        if (_showHint && !_hasSpoken)
                          Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                              decoration: BoxDecoration(
                                color: const Color(0xFF4CAF50).withOpacity(0.12),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: const Color(0xFF4CAF50).withOpacity(0.4)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.lightbulb_outline, size: 16, color: Color(0xFF4CAF50)),
                                  const SizedBox(width: 6),
                                  Text(
                                    item.word,
                                    style: GoogleFonts.fredoka(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFF4CAF50),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                        const SizedBox(height: 28),

                        // Tanınan kelime (çocuk söylediğinde belirir)
                        _buildWordReveal(),

                        const SizedBox(height: 28),

                        // Mikrofon butonu
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
    final difficultyColors = [
      const Color(0xFF4CAF50),
      const Color(0xFFFFC107),
      const Color(0xFFF44336),
    ];
    final diffColor = difficultyColors[_rlAgent.currentDifficulty];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 8)],
                  ),
                  child: Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: AppColors.textPrimary),
                ),
              ),
              const Spacer(),
              // Yıldızlar
              Row(
                children: List.generate(5, (i) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: Icon(
                    i < _stars ? Icons.star_rounded : Icons.star_outline_rounded,
                    size: 28,
                    color: i < _stars ? const Color(0xFFFFC107) : const Color(0xFFD0D0D0),
                  ),
                )),
              ),
              const Spacer(),
              // İlerleme sayacı
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 8)],
                ),
                child: Text(
                  '${_currentIndex + 1}/${_items.length}',
                  style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          // RL zorluk göstergesi
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
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
                        color: diffColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildImageCard(QuizItem item) {
    return Container(
      width: 260,
      height: 220,
      margin: const EdgeInsets.only(top: 28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.07), blurRadius: 16, offset: const Offset(0, 4))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Image.asset(
          item.imagePath,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => Center(
            child: Icon(Icons.image_not_supported_outlined, size: 60, color: Colors.grey[300]),
          ),
        ),
      ),
    );
  }

  Widget _buildWordReveal() {
    final feedbackColor = _isCorrect ? const Color(0xFF4CAF50) : const Color(0xFFF44336);
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
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              decoration: BoxDecoration(
                color: feedbackColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: feedbackColor.withOpacity(0.5), width: 2),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(feedbackIcon, style: const TextStyle(fontSize: 24)),
                  const SizedBox(width: 8),
                  Text(
                    _recognizedWord,
                    style: GoogleFonts.fredoka(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: feedbackColor,
                    ),
                  ),
                ],
              ),
            ),
            if (!_isCorrect) ...[
              const SizedBox(height: 8),
              Text(
                'Doğrusu: ${_items[_currentIndex].word}',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: const Color(0xFF4CAF50),
                  fontWeight: FontWeight.w600,
                ),
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
          final scale = _isListening ? 1.0 + (_micPulseController.value * 0.15) : 1.0;
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
                color: (_isListening ? AppColors.secondary : const Color(0xFF5B9BFF)).withOpacity(0.45),
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

// ─── Rozet Kutlama Kartı ───────────────────────────────────────────────────

class _RewardCelebrationCard extends StatefulWidget {
  final Reward reward;
  final VoidCallback onCollect;

  const _RewardCelebrationCard({required this.reward, required this.onCollect});

  @override
  State<_RewardCelebrationCard> createState() => _RewardCelebrationCardState();
}

class _RewardCelebrationCardState extends State<_RewardCelebrationCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _bounceController;
  late Animation<double> _bounceAnim;

  @override
  void initState() {
    super.initState();
    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _bounceAnim = CurvedAnimation(parent: _bounceController, curve: Curves.elasticOut);
    _bounceController.forward();
  }

  @override
  void dispose() {
    _bounceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _bounceAnim,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFD6EFFA),
          borderRadius: BorderRadius.circular(32),
        ),
        child: Stack(
          children: [
            _buildConfetti(),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Kapat butonu
                  Align(
                    alignment: Alignment.topRight,
                    child: GestureDetector(
                      onTap: widget.onCollect,
                      child: Container(
                        width: 32, height: 32,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.75),
                        ),
                        child: const Icon(Icons.close, size: 18, color: Colors.grey),
                      ),
                    ),
                  ),
                  const SizedBox(height: 2),
                  // "Harika!"
                  Text(
                    'Harika!',
                    style: GoogleFonts.fredoka(
                      fontSize: 34,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1565C0),
                    ),
                  ),
                  // "Yeni Ödül!"
                  Text(
                    'Yeni Ödül!',
                    style: GoogleFonts.fredoka(
                      fontSize: 34,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFFFF6B35),
                    ),
                  ),
                  const SizedBox(height: 22),
                  // Güneş ışını + rozet
                  _buildBadgeCircle(),
                  const SizedBox(height: 20),
                  // Açıklama
                  Text(
                    widget.reward.description,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFFFF6B35),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 22),
                  // Koleksiyona Ekle butonu
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: widget.onCollect,
                      icon: const Icon(Icons.add_circle_outline, color: Colors.white, size: 20),
                      label: Text(
                        'KOLEKSİYONA EKLE',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: Colors.white,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF43C659),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBadgeCircle() {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Güneş ışını arka planı
        SizedBox(
          width: 190,
          height: 190,
          child: CustomPaint(painter: _SunburstPainter()),
        ),
        // Beyaz daire + hayvan resmi
        Container(
          width: 148,
          height: 148,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.10),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipOval(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Image.asset(
                widget.reward.imagePath,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => Text(
                  widget.reward.emoji,
                  style: const TextStyle(fontSize: 60),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
        ),
        // Rozet etiketi (altta)
        Positioned(
          bottom: 12,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.10),
                  blurRadius: 6,
                ),
              ],
            ),
            child: Text(
              widget.reward.badgeLabel,
              style: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: const Color(0xFFFF6B35),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildConfetti() {
    const dots = [
      _ConfettiDot(left: 18, top: 50, color: Color(0xFFFF6B35), size: 11),
      _ConfettiDot(left: 36, top: 100, color: Color(0xFF43C659), size: 8),
      _ConfettiDot(left: 14, top: 160, color: Color(0xFF1565C0), size: 9),
      _ConfettiDot(right: 18, top: 50, color: Color(0xFF9C27B0), size: 10),
      _ConfettiDot(right: 36, top: 110, color: Color(0xFFFFC107), size: 13),
      _ConfettiDot(right: 14, top: 170, color: Color(0xFFE91E63), size: 8),
      _ConfettiDot(left: 60, top: 28, color: Color(0xFFFFC107), size: 7),
      _ConfettiDot(right: 60, top: 28, color: Color(0xFF43C659), size: 7),
    ];

    return Positioned.fill(
      child: Stack(
        children: dots
            .map((d) => Positioned(
                  left: d.left,
                  right: d.right,
                  top: d.top,
                  bottom: d.bottom,
                  child: Container(
                    width: d.size,
                    height: d.size,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: d.color,
                    ),
                  ),
                ))
            .toList(),
      ),
    );
  }
}

class _ConfettiDot {
  final double? left, right, top, bottom;
  final Color color;
  final double size;

  const _ConfettiDot({
    this.left,
    this.right,
    this.top,
    this.bottom,
    required this.color,
    required this.size,
  });
}

class _SunburstPainter extends CustomPainter {
  const _SunburstPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    const totalRays = 16;
    const twoPi = 3.14159265358979 * 2;
    const sweepAngle = twoPi / totalRays;

    for (int i = 0; i < totalRays; i++) {
      final startAngle = i * sweepAngle;
      final paint = Paint()
        ..color = i.isEven ? const Color(0xFFFFF9C4) : const Color(0xFFFFF176)
        ..style = PaintingStyle.fill;

      final path = Path()
        ..moveTo(center.dx, center.dy)
        ..arcTo(
          Rect.fromCircle(center: center, radius: radius),
          startAngle,
          sweepAngle,
          false,
        )
        ..close();

      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(_SunburstPainter _) => false;
}