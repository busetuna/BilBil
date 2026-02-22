import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math' as math;
import '../../../../core/theme/app_colors.dart';
import 'login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _bubbleController1;
  late AnimationController _bubbleController2;
  late AnimationController _bubbleController3;
  late AnimationController _dotController;
  late AnimationController _scaleController;

  @override
  void initState() {
    super.initState();

    // Bubble animations (farklı sürelerde)
    _bubbleController1 = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat(reverse: true);

    _bubbleController2 = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat(reverse: true);

    _bubbleController3 = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 7),
    )..repeat(reverse: true);

    // Loading dots animation
    _dotController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();

    // Logo scale animation
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..forward();

    // 5 saniye sonra login ekranına git
    Timer(const Duration(seconds: 10), () {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
            const LoginScreen(),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
              const begin = Offset(1.0, 0.0);
              const end = Offset.zero;
              const curve = Curves.easeInOutCubic;

              var tween = Tween(begin: begin, end: end)
                  .chain(CurveTween(curve: curve));
              var offsetAnimation = animation.drive(tween);

              var fadeAnimation = Tween<double>(begin: 0.0, end: 1.0)
                  .animate(CurvedAnimation(
                parent: animation,
                curve: const Interval(0.3, 1.0, curve: Curves.easeIn),
              ));

              return SlideTransition(
                position: offsetAnimation,
                child: FadeTransition(
                  opacity: fadeAnimation,
                  child: child,
                ),
              );
            },
            transitionDuration: const Duration(milliseconds: 800),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _bubbleController1.dispose();
    _bubbleController2.dispose();
    _bubbleController3.dispose();
    _dotController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Container(
        width: size.width,
        height: size.height,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.gradientStart,
              AppColors.gradientEnd,
            ],
          ),
        ),
        child: Stack(
          children: [
            // Background blur circles
            Positioned(
              top: -size.height * 0.1,
              left: -size.width * 0.1,
              child: Container(
                width: 384,
                height: 384,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary.withOpacity(0.1),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.05),
                      blurRadius: 100,
                      spreadRadius: 50,
                    ),
                  ],
                ),
              ),
            ),

            Positioned(
              bottom: -size.height * 0.15,
              right: -size.width * 0.1,
              child: Container(
                width: 320,
                height: 320,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.purple.withOpacity(0.05),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.purple.withOpacity(0.03),
                      blurRadius: 100,
                      spreadRadius: 50,
                    ),
                  ],
                ),
              ),
            ),

            // Floating bubbles
            _buildFloatingBubble(
              controller: _bubbleController1,
              top: size.height * 0.15,
              right: size.width * 0.1,
              size: 64,
              color: AppColors.bubblePink,
              opacity: 0.4,
            ),

            _buildFloatingBubble(
              controller: _bubbleController2,
              top: size.height * 0.3,
              left: size.width * 0.08,
              size: 96,
              color: AppColors.bubbleBlue,
              opacity: 0.3,
            ),

            _buildFloatingBubble(
              controller: _bubbleController3,
              bottom: size.height * 0.25,
              left: size.width * 0.15,
              size: 48,
              color: AppColors.bubbleYellow,
              opacity: 0.5,
            ),

            // Small pulse dot
            Positioned(
              top: size.height * 0.22,
              right: size.width * 0.25,
              child: _buildPulseDot(),
            ),

            // Main content
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Bilbil logo/character
                  ScaleTransition(
                    scale: CurvedAnimation(
                      parent: _scaleController,
                      curve: Curves.elasticOut,
                    ),
                    child: _buildBilbilLogo(),
                  ),

                  const SizedBox(height: 32),

                  // Title
                  const Text(
                    'Bilbil',
                    style: TextStyle(
                      fontSize: 64,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                      letterSpacing: 2,
                      shadows: [
                        Shadow(
                          color: Colors.white,
                          offset: Offset(0, 2),
                          blurRadius: 0,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Subtitle
                  const Text(
                    'MERHABA!',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textSecondary,
                      letterSpacing: 4,
                    ),
                  ),
                ],
              ),
            ),

            // Loading dots
            Positioned(
              bottom: 64,
              left: 0,
              right: 0,
              child: _buildLoadingDots(),
            ),
          ],
        ),
      ),
    );
  }

  // Floating bubble widget
  Widget _buildFloatingBubble({
    required AnimationController controller,
    double? top,
    double? bottom,
    double? left,
    double? right,
    required double size,
    required Color color,
    required double opacity,
  }) {
    return Positioned(
      top: top,
      bottom: bottom,
      left: left,
      right: right,
      child: AnimatedBuilder(
        animation: controller,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(
              0,
              math.sin(controller.value * 2 * math.pi) * 20,
            ),
            child: child,
          );
        },
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withOpacity(opacity),
            border: Border.all(
              color: Colors.white.withOpacity(0.4),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.2),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Pulse dot
  Widget _buildPulseDot() {
    return TweenAnimationBuilder(
      duration: const Duration(seconds: 2),
      tween: Tween<double>(begin: 0.5, end: 1.0),
      builder: (context, double value, child) {
        return Opacity(
          opacity: value,
          child: Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primary.withOpacity(0.2),
            ),
          ),
        );
      },
      onEnd: () {
        if (mounted) {
          setState(() {}); // Restart animation
        }
      },
    );
  }

  // Bilbil character/logo
  Widget _buildBilbilLogo() {
    return Container(
      width: 280,
      height: 280,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        boxShadow: [
          // Inner shadow effect (claymorphism)
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 30,
            spreadRadius: -10,
            offset: const Offset(0, 20),
          ),
          // Outer glow
          const BoxShadow(
            color: Colors.white,
            blurRadius: 20,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Stack(
        children: [
          // Main image
          Center(
            child: ClipOval(
              child: Container(
                width: 200,  // Boyutu artır
                height: 200, // Boyutu artır
                color: Colors.white,
                child: Image.asset(
                  'assets/images/giris_bilbil.png',
                  fit: BoxFit.cover,  // contain yerine cover kullan
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(
                      Icons.flutter_dash,
                      size: 120,
                      color: AppColors.primary,
                    );
                  },
                ),
              ),
            ),
          ),

          // Highlight (top-left shine)
          Positioned(
            top: 24,
            left: 32,
            child: Container(
              width: 64,
              height: 32,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(32),
                gradient: LinearGradient(
                  colors: [
                    Colors.white.withOpacity(0.4),
                    Colors.white.withOpacity(0.0),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Loading dots animation
  Widget _buildLoadingDots() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (index) {
        return AnimatedBuilder(
          animation: _dotController,
          builder: (context, child) {
            final delay = index * 0.2;
            final value = (_dotController.value - delay).clamp(0.0, 1.0);
            final offset = math.sin(value * math.pi) * 10;

            return Transform.translate(
              offset: Offset(0, -offset),
              child: child,
            );
          },
          child: Container(
            width: 16,
            height: 16,
            margin: const EdgeInsets.symmetric(horizontal: 6),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primary.withOpacity(0.8 - (index * 0.25)),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.3),
                  blurRadius: 8,
                  spreadRadius: 2,
                ),
              ],
            ),
          ),
        );
      }),
    );
  }
}