import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../services/theme/app_theme.dart';
import '../../../../services/theme/theme_service.dart';
import '../providers/auth_provider.dart';
import 'quiz_screen.dart';
import '../../../parent/screens/parent_pin_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  bool _showThemePicker = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final userName = authProvider.currentUser?.name ?? 'Kullanıcı';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top bar
              _buildTopBar(userName),

              // Tema seçici paneli
              _buildThemePickerPanel(),

              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Decorative star (top left)
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Padding(
                          padding: const EdgeInsets.only(left: 16, bottom: 20),
                          child: Icon(
                            Icons.star,
                            size: 40,
                            color: AppColors.primary.withOpacity(0.15),
                          ),
                        ),
                      ),

                      // Big green quiz button
                      _buildQuizButton(),

                      const SizedBox(height: 32),

                      // Subtext
                      Text(
                        'Haydi oynamaya başla!',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Decorative shape (bottom right)
                      Align(
                        alignment: Alignment.centerRight,
                        child: Padding(
                          padding: const EdgeInsets.only(right: 16),
                          child: _buildFlowerShape(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar(String userName) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'MERHABA!',
              style: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Hoşgeldin $userName!',
              style: GoogleFonts.fredoka(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        Row(
          children: [
            // Tema seçici butonu
            GestureDetector(
              onTap: () => setState(() => _showThemePicker = !_showThemePicker),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _showThemePicker
                      ? AppColors.primary.withOpacity(0.12)
                      : Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: Icon(Icons.palette_rounded,
                    size: 20, color: AppColors.primary),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ParentPinScreen()),
              ),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: Icon(Icons.lock_outline_rounded,
                    size: 20, color: AppColors.primary),
              ),
            ),
            const SizedBox(width: 10),
            // Avatar
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                border: Border.all(
                  color: AppColors.primary.withOpacity(0.3),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.15),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: ClipOval(
                child: Image.asset(
                  'assets/images/bilbil1.png',
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Icon(
                    Icons.flutter_dash,
                    color: AppColors.primary,
                    size: 28,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildThemePickerPanel() {
    return AnimatedSize(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
      child: _showThemePicker
          ? _buildThemeSelector(context)
          : const SizedBox.shrink(),
    );
  }

  Widget _buildThemeSelector(BuildContext context) {
    final themeService = context.watch<ThemeService>();
    return Container(
      margin: const EdgeInsets.only(top: 8, bottom: 4),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.07),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Tema Seç',
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: AppTheme.all.map((theme) {
              final isSelected = themeService.current.id == theme.id;
              return GestureDetector(
                onTap: () {
                  themeService.setTheme(theme);
                  setState(() => _showThemePicker = false);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 10),
                  width: isSelected ? 44 : 36,
                  height: isSelected ? 44 : 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: theme.primary,
                    border: isSelected
                        ? Border.all(color: Colors.white, width: 3)
                        : null,
                    boxShadow: [
                      BoxShadow(
                        color: theme.primary.withOpacity(isSelected ? 0.5 : 0.2),
                        blurRadius: isSelected ? 14 : 6,
                        spreadRadius: isSelected ? 2 : 0,
                      ),
                    ],
                  ),
                  child: Center(
                    child: isSelected
                        ? const Icon(Icons.check_rounded,
                            color: Colors.white, size: 18)
                        : Text(theme.emoji,
                            style: const TextStyle(fontSize: 16)),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildQuizButton() {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const QuizScreen(),
          ),
        );
      },
      child: AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _pulseAnimation.value,
            child: child,
          );
        },
        child: Container(
          width: 240,
          height: 240,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.primaryLight,
                AppColors.primary,
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.4),
                blurRadius: 40,
                spreadRadius: 8,
                offset: const Offset(0, 10),
              ),
              BoxShadow(
                color: AppColors.primaryLight.withOpacity(0.2),
                blurRadius: 70,
                spreadRadius: 15,
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Play icon
              Container(
                width: 68,
                height: 68,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.3),
                ),
                child: const Icon(
                  Icons.play_arrow_rounded,
                  color: Colors.white,
                  size: 44,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'QUİZ BAŞLAT',
                style: GoogleFonts.fredoka(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFlowerShape() {
    return CustomPaint(
      size: const Size(50, 50),
      painter: _FlowerPainter(
        color: AppColors.secondary.withOpacity(0.15),
      ),
    );
  }
}

class _FlowerPainter extends CustomPainter {
  final Color color;
  _FlowerPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final center = Offset(size.width / 2, size.height / 2);
    final petalRadius = size.width / 3;
    final petalOffset = size.width / 4;

    for (int i = 0; i < 6; i++) {
      final angle = i * 3.14159 / 3;
      canvas.drawCircle(
        Offset(
          center.dx + petalOffset * cos(angle),
          center.dy + petalOffset * sin(angle),
        ),
        petalRadius,
        paint,
      );
    }
    canvas.drawCircle(center, petalRadius, paint);
  }

  double cos(double angle) => _cos(angle);
  double sin(double angle) => _sin(angle);

  double _cos(double x) {
    // Simple cos approximation
    x = x % (2 * 3.14159265);
    double result = 1;
    double term = 1;
    for (int i = 1; i <= 6; i++) {
      term *= -x * x / ((2 * i - 1) * (2 * i));
      result += term;
    }
    return result;
  }

  double _sin(double x) {
    x = x % (2 * 3.14159265);
    double result = x;
    double term = x;
    for (int i = 1; i <= 6; i++) {
      term *= -x * x / ((2 * i) * (2 * i + 1));
      result += term;
    }
    return result;
  }

  @override
  bool shouldRepaint(_FlowerPainter oldDelegate) => false;
}