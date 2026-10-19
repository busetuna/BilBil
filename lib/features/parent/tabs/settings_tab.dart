import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/app_links.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/quiz_item.dart';
import '../../../services/stats/stats_service.dart';
import '../../learning/presentations/providers/auth_provider.dart';
import '../../learning/presentations/screens/login_screen.dart';
import '../widgets/password_confirm_dialog.dart';
import '../widgets/sound_settings.dart';

class SettingsTab extends StatefulWidget {
  const SettingsTab({super.key});

  @override
  State<SettingsTab> createState() => _SettingsTabState();
}

class _SettingsTabState extends State<SettingsTab> {
  final _pinController = TextEditingController();
  final _pinConfirmController = TextEditingController();

  @override
  void dispose() {
    _pinController.dispose();
    _pinConfirmController.dispose();
    super.dispose();
  }

  void _changePin(StatsService stats) {
    final newPin = _pinController.text.trim();
    final confirm = _pinConfirmController.text.trim();
    if (newPin.length != 4 || !RegExp(r'^\d{4}$').hasMatch(newPin)) {
      _showSnack('PIN 4 haneli rakam olmalı');
      return;
    }
    if (newPin != confirm) {
      _showSnack('PIN\'ler eşleşmiyor');
      return;
    }
    stats.changePin(newPin);
    _pinController.clear();
    _pinConfirmController.clear();
    _showSnack('PIN güncellendi ✓');
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: GoogleFonts.poppins()),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _confirmReset(StatsService stats) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'İstatistikleri Sıfırla',
          style: GoogleFonts.fredoka(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Tüm istatistikler ve grafik verileri silinecek. Bu işlem geri alınamaz.',
          style: GoogleFonts.poppins(fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'İptal',
              style: GoogleFonts.poppins(color: AppColors.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              stats.resetStats();
              _showSnack('İstatistikler sıfırlandı');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF44336),
            ),
            child: Text(
              'Sıfırla',
              style: GoogleFonts.poppins(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  /// Giriş ekranına döner ve geri tuşuyla oturumsuz ekranlara dönülmesini
  /// engeller. (Kök route giriş akışında değiştirildiği için oturum
  /// değişikliğini dinleyen bir kök widget'a güvenilemez.)
  static void _goToLogin(NavigatorState navigator) {
    navigator.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  Future<void> _openPrivacyPolicy() async {
    final opened = await launchUrl(
      Uri.parse(AppLinks.privacy),
      mode: LaunchMode.externalApplication,
    );
    if (!opened && mounted)
      _showSnack('Tarayıcı açılamadı: ${AppLinks.privacy}');
  }

  Future<void> _logout() async {
    final navigator = Navigator.of(context);
    await context.read<AuthProvider>().logout();
    _goToLogin(navigator);
  }

  Future<void> _deleteAccount() async {
    final auth = context.read<AuthProvider>();
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final deleted = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => PasswordConfirmDialog(
        title: 'Hesabımı Sil',
        message:
            'Hesabın ve tüm verilerin (istatistikler, ödüller, ayarlar) '
            'kalıcı olarak silinecek. Bu işlem geri alınamaz.\n\n'
            'Onaylamak için hesap şifreni gir.',
        confirmLabel: 'Kalıcı Olarak Sil',
        destructive: true,
        onConfirm: (password) async => await auth.deleteAccount(password)
            ? null
            : auth.errorMessage ?? 'Hesap silinemedi',
      ),
    );
    if (deleted != true) return;
    _goToLogin(navigator);
    messenger.showSnackBar(
      SnackBar(
        content: Text('Hesabın silindi', style: GoogleFonts.poppins()),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  BoxDecoration _cardDeco() => BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(16),
    boxShadow: [
      BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8),
    ],
  );

  @override
  Widget build(BuildContext context) {
    final stats = context.watch<StatsService>();
    const diffLabels = ['Kolay', 'Orta', 'Zor'];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Bilbil'in sesi
          _SectionHeader('Bilbil\'in Sesi'),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: _cardDeco(),
            child: const VoiceSettings(),
          ),

          const SizedBox(height: 24),

          // Ses efektleri ve müzik
          _SectionHeader('Sesler'),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 4),
            decoration: _cardDeco(),
            // Anahtarların dokunma efekti beyaz kartın üstünde görünsün.
            child: const Material(
              type: MaterialType.transparency,
              child: SoundSettings(),
            ),
          ),

          const SizedBox(height: 24),

          // ASR motor seçimi
          _SectionHeader('Ses Tanıma Motoru'),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: _cardDeco(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hangi ses tanıma motoru kullanılsın?',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 12),
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(
                      value: 'vosk',
                      label: Text('Vosk'),
                      icon: Icon(Icons.cloud_off_rounded, size: 15),
                    ),
                    ButtonSegment(
                      value: 'platform',
                      label: Text('Platform ASR'),
                      icon: Icon(Icons.mic_rounded, size: 15),
                    ),
                  ],
                  selected: {stats.asrEngine},
                  onSelectionChanged: (s) => stats.setAsrEngine(s.first),
                  style: ButtonStyle(
                    backgroundColor: WidgetStateProperty.resolveWith((states) {
                      if (states.contains(WidgetState.selected)) {
                        return AppColors.primary;
                      }
                      return Colors.white;
                    }),
                    foregroundColor: WidgetStateProperty.resolveWith((states) {
                      if (states.contains(WidgetState.selected)) {
                        return Colors.white;
                      }
                      return AppColors.textPrimary;
                    }),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  stats.asrEngine == 'vosk'
                      ? 'Vosk: Tamamen çevrimdışı, Türkçe model indirir (~50 MB).'
                      : 'Platform ASR: Cihazın yerleşik ses tanımasını kullanır.',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Çocuğun yaşı
          _SectionHeader('Çocuğun Yaşı'),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: _cardDeco(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Yaş, en yüksek zorluk seviyesini belirler. Tüm konular her yaşta açık; zorluk çocuğun cevaplarına göre kendiliğinden ayarlanır.',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 12),
                SegmentedButton<int>(
                  segments: const [
                    ButtonSegment(value: 2, label: Text('2 yaş')),
                    ButtonSegment(value: 3, label: Text('3 yaş')),
                    ButtonSegment(value: 4, label: Text('4 yaş')),
                    ButtonSegment(value: 5, label: Text('5 yaş')),
                  ],
                  selected: {stats.childAge},
                  onSelectionChanged: (s) => stats.setChildAge(s.first),
                  style: ButtonStyle(
                    backgroundColor: WidgetStateProperty.resolveWith((states) {
                      if (states.contains(WidgetState.selected)) {
                        return AppColors.primary;
                      }
                      return Colors.white;
                    }),
                    foregroundColor: WidgetStateProperty.resolveWith((states) {
                      if (states.contains(WidgetState.selected)) {
                        return Colors.white;
                      }
                      return AppColors.textPrimary;
                    }),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  _ageSummary(stats.childAge, stats.maxDifficultyForAge),
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Başlangıç zorluğu
          _SectionHeader('Başlangıç Zorluğu'),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: _cardDeco(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'İlk quiz bu seviyeden başlar. Sonra Bilbil seviyeyi çocuğun '
                  'cevaplarına göre ayarlar ve kaldığı yeri hatırlar. Burayı '
                  'değiştirirsen bir sonraki quiz yine buradan başlar.',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 12),
                SegmentedButton<int>(
                  segments: List.generate(
                    3,
                    (i) => ButtonSegment(
                      value: i,
                      // Yaş sınırının üstü seçilemez (quiz zaten kırpıyordu).
                      enabled: i <= stats.maxDifficultyForAge,
                      label: Text(
                        diffLabels[i],
                        style: GoogleFonts.poppins(fontSize: 13),
                      ),
                    ),
                  ),
                  selected: {
                    stats.startingDifficulty.clamp(
                      0,
                      stats.maxDifficultyForAge,
                    ),
                  },
                  onSelectionChanged: (s) =>
                      stats.setStartingDifficulty(s.first),
                  style: ButtonStyle(
                    backgroundColor: WidgetStateProperty.resolveWith((states) {
                      if (states.contains(WidgetState.selected)) {
                        return AppColors.primary;
                      }
                      if (states.contains(WidgetState.disabled)) {
                        return const Color(0xFFF2F2F2);
                      }
                      return Colors.white;
                    }),
                    foregroundColor: WidgetStateProperty.resolveWith((states) {
                      if (states.contains(WidgetState.selected)) {
                        return Colors.white;
                      }
                      if (states.contains(WidgetState.disabled)) {
                        return AppColors.textSecondary.withValues(alpha: 0.5);
                      }
                      return AppColors.textPrimary;
                    }),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // PIN değiştir
          _SectionHeader('PIN Değiştir'),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: _cardDeco(),
            child: Column(
              children: [
                TextField(
                  controller: _pinController,
                  keyboardType: TextInputType.number,
                  maxLength: 4,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'Yeni PIN (4 hane)',
                    labelStyle: GoogleFonts.poppins(fontSize: 13),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    counterText: '',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _pinConfirmController,
                  keyboardType: TextInputType.number,
                  maxLength: 4,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'PIN Tekrar',
                    labelStyle: GoogleFonts.poppins(fontSize: 13),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    counterText: '',
                  ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => _changePin(stats),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Text(
                      'PIN Güncelle',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Hesap
          _SectionHeader('Hesap'),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: _cardDeco(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.watch<AuthProvider>().currentUser?.email ?? '',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _logout,
                    icon: Icon(Icons.logout_rounded, color: AppColors.primary),
                    label: Text(
                      'Çıkış Yap',
                      style: GoogleFonts.poppins(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: AppColors.primary),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Center(
                  child: TextButton.icon(
                    onPressed: _openPrivacyPolicy,
                    icon: Icon(
                      Icons.privacy_tip_outlined,
                      size: 18,
                      color: AppColors.textSecondary,
                    ),
                    label: Text(
                      'Gizlilik Politikası',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // İstatistikleri sıfırla / hesabı sil
          _SectionHeader('Tehlikeli Bölge'),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _confirmReset(stats),
              icon: const Icon(
                Icons.delete_outline_rounded,
                color: Color(0xFFF44336),
              ),
              label: Text(
                'İstatistikleri Sıfırla',
                style: GoogleFonts.poppins(
                  color: const Color(0xFFF44336),
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFFF44336)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _deleteAccount,
              icon: const Icon(
                Icons.person_remove_rounded,
                color: Colors.white,
              ),
              label: Text(
                'Hesabımı Sil',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF44336),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) => Text(
    title,
    style: GoogleFonts.fredoka(
      fontSize: 18,
      fontWeight: FontWeight.bold,
      color: AppColors.textPrimary,
    ),
  );
}

/// Ayarlardaki yaş açıklaması: hangi seviyeler açık, kaç kelime.
String _ageSummary(int age, int maxDifficulty) {
  const levels = ['Kolay', 'Kolay ve Orta', 'Kolay, Orta ve Zor'];
  final words = QuizData.all.where((i) => i.difficulty <= maxDifficulty).length;
  return '$age yaş: ${levels[maxDifficulty]} kelimeler ($words kelime).';
}
