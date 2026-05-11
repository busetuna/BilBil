import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../services/stats/stats_service.dart';
import 'parent_panel_screen.dart';

class ParentPinScreen extends StatefulWidget {
  const ParentPinScreen({super.key});

  @override
  State<ParentPinScreen> createState() => _ParentPinScreenState();
}

class _ParentPinScreenState extends State<ParentPinScreen>
    with SingleTickerProviderStateMixin {
  String _entered = '';
  bool _shake = false;
  late AnimationController _shakeController;
  late Animation<double> _shakeAnim;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _shakeAnim = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: -10.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -10.0, end: 10.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 10.0, end: -10.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -10.0, end: 0.0), weight: 1),
    ]).animate(_shakeController);
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  void _onDigit(String digit) {
    if (_entered.length >= 4) return;
    setState(() => _entered += digit);
    if (_entered.length == 4) _verify();
  }

  void _onDelete() {
    if (_entered.isEmpty) return;
    setState(() => _entered = _entered.substring(0, _entered.length - 1));
  }

  void _verify() {
    final stats = context.read<StatsService>();
    if (stats.verifyPin(_entered)) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const ParentPanelScreen()),
      );
    } else {
      _shakeController.forward(from: 0);
      Future.delayed(const Duration(milliseconds: 450), () {
        if (mounted) setState(() => _entered = '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: BackButton(color: AppColors.textPrimary),
        title: Text('Ebeveyn Paneli',
            style: GoogleFonts.fredoka(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary)),
        centerTitle: true,
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.lock_outline_rounded, size: 64, color: AppColors.primary),
          const SizedBox(height: 16),
          Text('PIN Kodunu Gir',
              style: GoogleFonts.fredoka(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary)),
          const SizedBox(height: 8),
          Text('Ebeveyn paneline erişmek için PIN gerekli',
              style: GoogleFonts.poppins(
                  fontSize: 13, color: AppColors.textSecondary)),
          const SizedBox(height: 40),

          // PIN noktaları
          AnimatedBuilder(
            animation: _shakeAnim,
            builder: (_, child) =>
                Transform.translate(offset: Offset(_shakeAnim.value, 0), child: child),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(4, (i) {
                final filled = i < _entered.length;
                return Container(
                  width: 18,
                  height: 18,
                  margin: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: filled
                        ? AppColors.primary
                        : Colors.white,
                    border: Border.all(
                      color: AppColors.primary,
                      width: 2,
                    ),
                  ),
                );
              }),
            ),
          ),

          const SizedBox(height: 48),

          // Numpad
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 60),
            child: Column(
              children: [
                _buildRow(['1', '2', '3']),
                const SizedBox(height: 16),
                _buildRow(['4', '5', '6']),
                const SizedBox(height: 16),
                _buildRow(['7', '8', '9']),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    const SizedBox(width: 72),
                    _numKey('0'),
                    _deleteKey(),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRow(List<String> digits) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: digits.map(_numKey).toList(),
      );

  Widget _numKey(String digit) => GestureDetector(
        onTap: () => _onDigit(digit),
        child: Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.08), blurRadius: 8)
            ],
          ),
          child: Center(
            child: Text(digit,
                style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary)),
          ),
        ),
      );

  Widget _deleteKey() => GestureDetector(
        onTap: _onDelete,
        child: Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.08), blurRadius: 8)
            ],
          ),
          child: Center(
            child: Icon(Icons.backspace_outlined,
                size: 24, color: AppColors.primary),
          ),
        ),
      );
}