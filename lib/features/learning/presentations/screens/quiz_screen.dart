// lib/features/learning/presentations/screens/quiz_screen.dart

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:speech_to_text/speech_to_text.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../data/models/quiz_item.dart';
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
  String _recognizedWord = '';   // Çocuğun söylediği kelime
  bool _hasSpoken = false;       // Çocuk bir şey söyledi mi?

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
  }

  Future<void> _initTts() async {
    await _tts.setLanguage('tr-TR');
    await _tts.setSpeechRate(0.4);
    await _tts.setVolume(1.0);
  }

  Future<void> _initStt() async {
    // Önce izin iste
    final status = await Permission.microphone.request();
    if (status.isGranted) {
      _sttAvailable = await _stt.initialize(
        onError: (error) => debugPrint('STT Error: $error'),
        onStatus: (status) => debugPrint('STT Status: $status'),
      );
    }
    setState(() {});
  }

  Future<void> _toggleListening() async {
    if (_isListening) {
      await _stt.stop();
      _micPulseController.stop();
      setState(() => _isListening = false);
    } else {
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
            setState(() {
              _isListening = false;
              _hasSpoken = true;
              _stars = min(_stars + 1, 5);
            });
            // Kelimeyi ekranda göster + TTS ile oku
            _wordRevealController.reset();
            _wordRevealController.forward();
            _tts.speak(_recognizedWord);

            // 3 saniye sonra sonraki resme geç
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
        _stars = 0;
      });
      _cardController.reset();
      _cardController.forward();
      _wordRevealController.reset();
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
                _stars = 0;
                _recognizedWord = '';
                _hasSpoken = false;
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
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
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 400),
      child: _hasSpoken && _recognizedWord.isNotEmpty
          ? ScaleTransition(
        key: ValueKey(_recognizedWord),
        scale: _wordRevealAnimation,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.12),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.primary.withOpacity(0.3), width: 2),
          ),
          child: Text(
            _recognizedWord,
            style: GoogleFonts.fredoka(
              fontSize: 36,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
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