import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../services/stats/stats_service.dart';
import '../../learning/presentations/providers/auth_provider.dart';
import '../widgets/password_confirm_dialog.dart';
import 'parent_panel_screen.dart';

/// verify: PIN sorulur. create/confirm: henüz PIN yoksa (ilk kez ya da
/// "PIN'imi unuttum" sonrası) ebeveyne yeni PIN iki kez girdirilir.
enum _PinMode { verify, create, confirm }

class ParentPinScreen extends StatefulWidget {
  const ParentPinScreen({super.key});

  @override
  State<ParentPinScreen> createState() => _ParentPinScreenState();
}

class _ParentPinScreenState extends State<ParentPinScreen>
    with SingleTickerProviderStateMixin {
  String _entered = '';
  String _firstPin = '';
  String? _error;
  late _PinMode _mode;
  Timer? _lockTicker;
  late AnimationController _shakeController;
  late Animation<double> _shakeAnim;

  StatsService get _stats => context.read<StatsService>();

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
    _mode = _stats.hasPin ? _PinMode.verify : _PinMode.create;
    _startLockTicker();
  }

  @override
  void dispose() {
    _lockTicker?.cancel();
    _shakeController.dispose();
    super.dispose();
  }

  bool get _locked =>
      _mode == _PinMode.verify && _stats.pinLockRemaining != null;

  /// Kilitliyken geri sayımı her saniye günceller.
  void _startLockTicker() {
    _lockTicker?.cancel();
    if (_stats.pinLockRemaining == null) return;
    _lockTicker = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      if (_stats.pinLockRemaining == null) {
        t.cancel();
        _error = null;
      }
      setState(() {});
    });
  }

  void _onDigit(String digit) {
    if (_locked || _entered.length >= 4) return;
    setState(() => _entered += digit);
    if (_entered.length == 4) _submit();
  }

  void _onDelete() {
    if (_entered.isEmpty) return;
    setState(() => _entered = _entered.substring(0, _entered.length - 1));
  }

  void _submit() {
    switch (_mode) {
      case _PinMode.verify:
        _verify();
      case _PinMode.create:
        setState(() {
          _firstPin = _entered;
          _entered = '';
          _error = null;
          _mode = _PinMode.confirm;
        });
      case _PinMode.confirm:
        if (_entered == _firstPin) {
          _stats.changePin(_entered);
          _openPanel();
        } else {
          _firstPin = '';
          _mode = _PinMode.create;
          _fail('PIN\'ler eşleşmedi, baştan belirle');
        }
    }
  }

  void _verify() {
    if (_stats.verifyPin(_entered)) {
      _openPanel();
      return;
    }
    if (_stats.pinLockRemaining != null) {
      _fail(null);
      _startLockTicker();
    } else {
      _fail('Yanlış PIN · ${_stats.pinAttemptsLeft} deneme hakkın kaldı');
    }
  }

  void _fail(String? message) {
    setState(() => _error = message);
    _shakeController.forward(from: 0);
    Future.delayed(const Duration(milliseconds: 450), () {
      if (mounted) setState(() => _entered = '');
    });
  }

  void _openPanel() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const ParentPanelScreen()),
    );
  }

  Future<void> _forgotPin() async {
    final auth = context.read<AuthProvider>();
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => PasswordConfirmDialog(
        title: 'PIN\'imi Unuttum',
        message: 'PIN\'i sıfırlamak için hesap şifreni gir. '
            'Sonra yeni bir PIN belirleyeceksin.',
        confirmLabel: 'Sıfırla',
        onConfirm: (password) async => await auth.reauthenticate(password)
            ? null
            : auth.errorMessage ?? 'Şifre doğrulanamadı',
      ),
    );
    if (ok != true || !mounted) return;
    _stats.clearPin();
    _lockTicker?.cancel();
    setState(() {
      _mode = _PinMode.create;
      _entered = '';
      _firstPin = '';
      _error = null;
    });
  }

  String get _title => switch (_mode) {
        _PinMode.verify => 'PIN Kodunu Gir',
        _PinMode.create => 'PIN Belirle',
        _PinMode.confirm => 'PIN\'i Tekrar Gir',
      };

  String get _subtitle {
    final left = _locked ? _stats.pinLockRemaining : null;
    if (left != null) {
      return 'Çok fazla yanlış deneme. ${left.inSeconds + 1} sn sonra tekrar dene';
    }
    if (_error != null) return _error!;
    return switch (_mode) {
      _PinMode.verify => 'Ebeveyn paneline erişmek için PIN gerekli',
      _PinMode.create => 'Ebeveyn paneli için 4 haneli bir PIN seç',
      _PinMode.confirm => 'Doğrulamak için aynı PIN\'i tekrar gir',
    };
  }

  @override
  Widget build(BuildContext context) {
    final warn = _locked || _error != null;
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
          Icon(_locked ? Icons.lock_clock_rounded : Icons.lock_outline_rounded,
              size: 64, color: AppColors.primary),
          const SizedBox(height: 16),
          Text(_title,
              style: GoogleFonts.fredoka(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary)),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(_subtitle,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: warn ? const Color(0xFFF44336) : AppColors.textSecondary)),
          ),
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
                    color: filled ? AppColors.primary : Colors.white,
                    border: Border.all(color: AppColors.primary, width: 2),
                  ),
                );
              }),
            ),
          ),

          const SizedBox(height: 48),

          // Numpad
          Opacity(
            opacity: _locked ? 0.4 : 1,
            child: Padding(
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
          ),

          if (_mode == _PinMode.verify) ...[
            const SizedBox(height: 24),
            TextButton(
              onPressed: _forgotPin,
              child: Text('PIN\'imi unuttum',
                  style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary)),
            ),
          ],
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
                  color: Colors.black.withValues(alpha: 0.08), blurRadius: 8)
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
                  color: Colors.black.withValues(alpha: 0.08), blurRadius: 8)
            ],
          ),
          child: Center(
            child: Icon(Icons.backspace_outlined,
                size: 24, color: AppColors.primary),
          ),
        ),
      );
}
