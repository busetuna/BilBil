import 'package:app/features/learning/presentations/screens/register_screen.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../providers/auth_provider.dart';
import '../screens/forgot_password_screen.dart'; // En üste ekleyin
import 'main_navigation.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.3, 1.0, curve: Curves.easeOutCubic),
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Container(
        width: size.width,
        height: size.height,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.gradientStart,
              const Color(0xFFFFFDF5),
              AppColors.gradientEnd,
            ],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              // Dekoratif bulutlar ve yıldızlar
              _buildDecorativeElements(size),

              // Ana içerik
              Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Bilbil kuşu karakteri
                          _buildBirdCharacter(),

                          const SizedBox(height: 32),

                          // Başlık
                          Text(
                            'Merhaba!',
                            style: GoogleFonts.fredoka(
                              fontSize: 40,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),

                          const SizedBox(height: 8),

                          // Alt başlık
                          Text(
                            'Eğlenceye katılmaya hazır mısın?',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textSecondary,
                            ),
                          ),

                          const SizedBox(height: 40),

                          // Form alanları
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 400),
                            child: Column(
                              children: [
                                // E-posta
                                _buildEmailField(),

                                const SizedBox(height: 16),

                                // Şifre
                                _buildPasswordField(),

                                const SizedBox(height: 16),

                                // Şifremi unuttum
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => const ForgotPasswordScreen(),
                                        ),
                                      );
                                    },
                                    child: Text(
                                      'Şifremi unuttum?',
                                      style: GoogleFonts.poppins(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 24),

                                // Giriş yap butonu
                                _buildLoginButton(),

                                const SizedBox(height: 16),

                                // Kayıt ol butonu
                                _buildRegisterButton(),

                                const SizedBox(height: 32),

                                // Ebeveyn girişi
                                _buildParentLoginButton(),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDecorativeElements(Size size) {
    return Stack(
      children: [
        // Bulutlar
        Positioned(
          top: size.height * 0.05,
          left: -20,
          child: _buildCloud(80, AppColors.primary.withOpacity(0.1)),
        ),
        Positioned(
          top: size.height * 0.15,
          right: -30,
          child: _buildCloud(100, AppColors.secondary.withOpacity(0.1)),
        ),
        Positioned(
          bottom: size.height * 0.1,
          left: size.width * 0.1,
          child: _buildCloud(60, AppColors.primary.withOpacity(0.08)),
        ),

        // Yıldızlar
        Positioned(
          top: size.height * 0.12,
          right: size.width * 0.2,
          child: _buildStar(24, AppColors.accent.withOpacity(0.3)),
        ),
        Positioned(
          bottom: size.height * 0.2,
          right: size.width * 0.15,
          child: _buildStar(16, AppColors.accent.withOpacity(0.25)),
        ),
        Positioned(
          top: size.height * 0.25,
          left: size.width * 0.15,
          child: _buildStar(20, AppColors.accent.withOpacity(0.2)),
        ),
      ],
    );
  }

  Widget _buildCloud(double size, Color color) {
    return TweenAnimationBuilder(
      duration: const Duration(seconds: 6),
      tween: Tween<double>(begin: 0, end: 15),
      builder: (context, double value, child) {
        return Transform.translate(
          offset: Offset(0, value),
          child: Icon(
            Icons.cloud,
            size: size,
            color: color,
          ),
        );
      },
      onEnd: () {
        if (mounted) setState(() {});
      },
    );
  }

  Widget _buildStar(double size, Color color) {
    return Icon(
      Icons.star,
      size: size,
      color: color,
    );
  }

  Widget _buildBirdCharacter() {
    return TweenAnimationBuilder(
      duration: const Duration(seconds: 3),
      tween: Tween<double>(begin: 0, end: 10),
      builder: (context, double value, child) {
        return Transform.translate(
          offset: Offset(0, value),
          child: Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.2),
                  blurRadius: 30,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: ClipOval(
              child: Image.asset(
                'assets/images/bilbil1.png',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Icon(
                    Icons.flutter_dash,
                    size: 120,
                    color: AppColors.primary,
                  );
                },
              ),
            ),
          ),
        );
      },
      onEnd: () {
        if (mounted) setState(() {});
      },
    );
  }

  Widget _buildEmailField() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: _emailController,
        keyboardType: TextInputType.emailAddress,
        style: GoogleFonts.poppins(
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          hintText: 'E-posta',
          hintStyle: GoogleFonts.poppins(
            color: AppColors.textLight,
          ),
          prefixIcon: Icon(
            Icons.email_outlined,
            color: AppColors.primary.withOpacity(0.7),
            size: 24,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(20),
        ),
      ),
    );
  }

  Widget _buildPasswordField() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: _passwordController,
        obscureText: !_isPasswordVisible,
        style: GoogleFonts.poppins(
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          hintText: 'Şifre',
          hintStyle: GoogleFonts.poppins(
            color: AppColors.textLight,
          ),
          prefixIcon: Icon(
            Icons.lock_outline,
            color: AppColors.primary.withOpacity(0.7),
            size: 24,
          ),
          suffixIcon: IconButton(
            icon: Icon(
              _isPasswordVisible ? Icons.visibility_off : Icons.visibility,
              color: AppColors.primary.withOpacity(0.7),
              size: 24,
            ),
            onPressed: () {
              setState(() {
                _isPasswordVisible = !_isPasswordVisible;
              });
            },
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(20),
        ),
      ),
    );
  }

  Widget _buildLoginButton() {
    return SizedBox(
      width: double.infinity,
      height: 60,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handleLogin,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          shadowColor: AppColors.primary.withOpacity(0.4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: _isLoading
            ? const SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            color: Colors.white,
            strokeWidth: 2.5,
          ),
        )
            : Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Giriş Yap',
              style: GoogleFonts.quicksand(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.arrow_forward, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildRegisterButton() {
    return SizedBox(
      width: double.infinity,
      height: 60,
      child: ElevatedButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const RegisterScreen(),
            ),
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.secondary,
          foregroundColor: Colors.white,
          elevation: 0,
          shadowColor: AppColors.secondary.withOpacity(0.4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Kayıt Ol',
              style: GoogleFonts.quicksand(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.celebration_outlined, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildParentLoginButton() {
    return TextButton.icon(
      onPressed: () {
        // TODO: Ebeveyn girişi
      },
      icon: Icon(
        Icons.shield_outlined,
        color: AppColors.textSecondary,
        size: 20,
      ),
      label: Text(
        'EBEVEYN GİRİŞİ',
        style: GoogleFonts.poppins(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
          color: AppColors.textSecondary,
        ),
      ),
      style: TextButton.styleFrom(
        backgroundColor: Colors.white.withOpacity(0.5),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
      ),
    );
  }

  void _handleLogin() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    // Basit validasyon
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Lütfen tüm alanları doldurun',
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final success = await authProvider.login(
      _emailController.text.trim(),
      _passwordController.text,
    );

    if (mounted) {
      setState(() {
        _isLoading = false;
      });

      if (success) {
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
            const MainNavigation(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
            transitionDuration: const Duration(milliseconds: 400),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              authProvider.errorMessage ?? 'Giriş başarısız',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }
}