import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../services/lives/lives_service.dart';

class RestScreen extends StatefulWidget {
  const RestScreen({super.key});

  @override
  State<RestScreen> createState() => _RestScreenState();
}

class _RestScreenState extends State<RestScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;

  late AnimationController _zzzCtrl;

  late AnimationController _heartCtrl;
  late Animation<double> _heartAnim;

  @override
  void initState() {
    super.initState();

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);
    _pulseAnim = Tween(begin: 0.93, end: 1.07).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );

    _zzzCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat();

    _heartCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _heartAnim = CurvedAnimation(parent: _heartCtrl, curve: Curves.elasticOut);
    _heartCtrl.forward();
  }

  void _continuePressed() {
    context.read<LivesService>().refillLives();
    Navigator.pop(context);
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _zzzCtrl.dispose();
    _heartCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 28),
            _buildHearts(),
            const SizedBox(height: 36),
            _buildSleepAnimation(),
            const SizedBox(height: 28),
            _buildTexts(),
            const Spacer(),
            _buildContinueButton(),
            const SizedBox(height: 36),
          ],
        ),
      ),
    );
  }

  Widget _buildHearts() {
    return ScaleTransition(
      scale: _heartAnim,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(
          LivesService.maxLives,
          (i) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Icon(
              Icons.favorite_rounded,
              size: 34,
              color: Colors.grey[300],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSleepAnimation() {
    return SizedBox(
      width: 220,
      height: 220,
      child: Stack(
        alignment: Alignment.center,
        children: [
          ..._buildGlowCircles(),
          ScaleTransition(
            scale: _pulseAnim,
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [AppColors.primaryLight, AppColors.primary],
                  radius: 0.8,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.4),
                    blurRadius: 30,
                    spreadRadius: 8,
                  ),
                ],
              ),
              child: const Center(
                child: Text('😴', style: TextStyle(fontSize: 72)),
              ),
            ),
          ),
          Positioned(
            top: 20,
            right: 30,
            child: _buildZzz(),
          ),
          Positioned(
              top: 30,
              left: 20,
              child: _buildStar(size: 18, delay: 0.0)),
          Positioned(
              bottom: 40,
              right: 15,
              child: _buildStar(size: 14, delay: 0.3)),
          Positioned(
              bottom: 25,
              left: 35,
              child: _buildStar(size: 10, delay: 0.6)),
        ],
      ),
    );
  }

  List<Widget> _buildGlowCircles() {
    return [
      Container(
        width: 200,
        height: 200,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.primary.withOpacity(0.08),
        ),
      ),
      Container(
        width: 175,
        height: 175,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.primary.withOpacity(0.10),
        ),
      ),
    ];
  }

  Widget _buildZzz() {
    return AnimatedBuilder(
      animation: _zzzCtrl,
      builder: (_, __) {
        final t = _zzzCtrl.value;
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _zzzLetter('Z', t, delay: 0.0, baseSize: 22),
            _zzzLetter('Z', t, delay: 0.2, baseSize: 17),
            _zzzLetter('Z', t, delay: 0.4, baseSize: 13),
          ],
        );
      },
    );
  }

  Widget _zzzLetter(String letter, double t,
      {required double delay, required double baseSize}) {
    final phase = ((t - delay) % 1.0 + 1.0) % 1.0;
    final opacity = (1.0 - phase).clamp(0.0, 1.0);
    final dy = -20.0 * phase;

    return Transform.translate(
      offset: Offset(0, dy),
      child: Opacity(
        opacity: opacity,
        child: Text(
          letter,
          style: GoogleFonts.fredoka(
            fontSize: baseSize,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildStar({required double size, required double delay}) {
    return AnimatedBuilder(
      animation: _pulseCtrl,
      builder: (_, __) {
        final t = (_pulseCtrl.value - delay).abs();
        final opacity = (0.4 + 0.6 * (1 - t)).clamp(0.0, 1.0);
        return Opacity(
          opacity: opacity,
          child: Icon(Icons.star_rounded, size: size, color: Colors.white),
        );
      },
    );
  }

  Widget _buildTexts() {
    return Column(
      children: [
        Text(
          'Dinlenme Zamanı!',
          style: GoogleFonts.fredoka(
            fontSize: 30,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Canların bitti 💔',
          style: GoogleFonts.poppins(
            fontSize: 15,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Biraz dinlen ve tekrar dene!',
          style: GoogleFonts.poppins(
            fontSize: 13,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildContinueButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: GestureDetector(
              onTap: _continuePressed,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 18),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.primaryLight, AppColors.primary],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.45),
                      blurRadius: 20,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.play_arrow_rounded,
                        color: Colors.white, size: 26),
                    const SizedBox(width: 10),
                    Text(
                      'Devam Et',
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.favorite_rounded,
                  size: 14, color: AppColors.primary),
              const SizedBox(width: 4),
              Text(
                '5 can geri gelir',
                style: GoogleFonts.poppins(
                    fontSize: 11, color: AppColors.textSecondary),
              ),
            ],
          ),
        ],
      ),
    );
  }
}