import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../services/rewards/reward_service.dart';
import '../../../services/stats/stats_service.dart';

class ParentPanelScreen extends StatefulWidget {
  const ParentPanelScreen({super.key});

  @override
  State<ParentPanelScreen> createState() => _ParentPanelScreenState();
}

class _ParentPanelScreenState extends State<ParentPanelScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        leading: BackButton(color: Colors.white),
        title: Text('Ebeveyn Paneli',
            style: GoogleFonts.fredoka(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white)),
        centerTitle: true,
        bottom: TabBar(
          controller: _tab,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          labelStyle:
              GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600),
          tabs: const [
            Tab(icon: Icon(Icons.bar_chart_rounded), text: 'İstatistik'),
            Tab(icon: Icon(Icons.auto_graph_rounded), text: 'Grafik'),
            Tab(icon: Icon(Icons.emoji_events_rounded), text: 'Ödüller'),
            Tab(icon: Icon(Icons.settings_rounded), text: 'Ayarlar'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tab,
        children: const [
          _StatsTab(),
          _ChartTab(),
          _RewardsTab(),
          _SettingsTab(),
        ],
      ),
    );
  }
}

// ── İstatistik Sekmesi ─────────────────────────────────────────────────────

class _StatsTab extends StatelessWidget {
  const _StatsTab();

  @override
  Widget build(BuildContext context) {
    final stats = context.watch<StatsService>();
    final total = stats.totalAnswers;
    final rate = (stats.successRate * 100).toStringAsFixed(1);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Genel Performans',
              style: GoogleFonts.fredoka(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary)),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  label: 'Doğru',
                  value: '${stats.totalCorrect}',
                  icon: Icons.check_circle_rounded,
                  color: const Color(0xFF4CAF50),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  label: 'Yanlış',
                  value: '${stats.totalWrong}',
                  icon: Icons.cancel_rounded,
                  color: const Color(0xFFF44336),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  label: 'Toplam Cevap',
                  value: '$total',
                  icon: Icons.quiz_rounded,
                  color: const Color(0xFF5B9BFF),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  label: 'Başarı Oranı',
                  value: '%$rate',
                  icon: Icons.percent_rounded,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Başarı çubuğu
          Text('Başarı Çubuğu',
              style: GoogleFonts.fredoka(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.05), blurRadius: 8)
              ],
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Doğru',
                        style: GoogleFonts.poppins(
                            fontSize: 13, color: AppColors.textSecondary)),
                    Text('%$rate',
                        style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF4CAF50))),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: stats.successRate.clamp(0.0, 1.0),
                    minHeight: 14,
                    backgroundColor: const Color(0xFFFFEBEE),
                    valueColor: const AlwaysStoppedAnimation(Color(0xFF4CAF50)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(value,
              style: GoogleFonts.fredoka(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary)),
          Text(label,
              style: GoogleFonts.poppins(
                  fontSize: 12, color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}

// ── RL Grafik Sekmesi ──────────────────────────────────────────────────────

class _ChartTab extends StatelessWidget {
  const _ChartTab();

  @override
  Widget build(BuildContext context) {
    final stats = context.watch<StatsService>();
    final history = stats.difficultyHistory;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Zorluk Seviyesi Değişimi',
              style: GoogleFonts.fredoka(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary)),
          const SizedBox(height: 6),
          Text('RL algoritmasının adaptasyonu',
              style: GoogleFonts.poppins(
                  fontSize: 13, color: AppColors.textSecondary)),
          const SizedBox(height: 20),
          if (history.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(40),
                child: Column(
                  children: [
                    const Icon(Icons.auto_graph_rounded,
                        size: 64, color: Color(0xFFD0D0D0)),
                    const SizedBox(height: 12),
                    Text('Henüz veri yok',
                        style: GoogleFonts.poppins(
                            fontSize: 14, color: AppColors.textSecondary)),
                    Text('Quiz oynadıkça grafik oluşur',
                        style: GoogleFonts.poppins(
                            fontSize: 12, color: AppColors.textSecondary)),
                  ],
                ),
              ),
            )
          else
            Container(
              height: 260,
              padding: const EdgeInsets.fromLTRB(8, 16, 16, 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.05), blurRadius: 10)
                ],
              ),
              child: LineChart(
                LineChartData(
                  minY: -0.2,
                  maxY: 2.2,
                  gridData: FlGridData(
                    show: true,
                    horizontalInterval: 1,
                    getDrawingHorizontalLine: (v) => FlLine(
                      color: Colors.grey.withOpacity(0.15),
                      strokeWidth: 1,
                    ),
                    drawVerticalLine: false,
                  ),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 1,
                        reservedSize: 52,
                        getTitlesWidget: (v, _) {
                          const labels = ['Kolay', 'Orta', 'Zor'];
                          final i = v.toInt();
                          if (i < 0 || i > 2) return const SizedBox();
                          return Text(labels[i],
                              style: GoogleFonts.poppins(
                                  fontSize: 11,
                                  color: AppColors.textSecondary));
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: (history.length / 5).ceilToDouble().clamp(1, double.infinity),
                        getTitlesWidget: (v, _) => Text(
                          '${v.toInt() + 1}',
                          style: GoogleFonts.poppins(
                              fontSize: 10, color: AppColors.textSecondary),
                        ),
                      ),
                    ),
                    topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: history
                          .asMap()
                          .entries
                          .map((e) =>
                              FlSpot(e.key.toDouble(), e.value.toDouble()))
                          .toList(),
                      isCurved: true,
                      color: AppColors.primary,
                      barWidth: 3,
                      dotData: FlDotData(
                        show: history.length <= 30,
                        getDotPainter: (_, __, ___, ____) =>
                            FlDotCirclePainter(
                          radius: 4,
                          color: AppColors.primary,
                          strokeWidth: 0,
                        ),
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        color: AppColors.primary.withOpacity(0.10),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 20),
          // Renk açıklaması
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _LegendDot(color: const Color(0xFF4CAF50), label: 'Kolay'),
              const SizedBox(width: 20),
              _LegendDot(color: const Color(0xFFFFC107), label: 'Orta'),
              const SizedBox(width: 20),
              _LegendDot(color: const Color(0xFFF44336), label: 'Zor'),
            ],
          ),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Container(
              width: 12,
              height: 12,
              decoration:
                  BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 6),
          Text(label,
              style: GoogleFonts.poppins(
                  fontSize: 12, color: AppColors.textSecondary)),
        ],
      );
}

// ── Ödüller Sekmesi ────────────────────────────────────────────────────────

class _RewardsTab extends StatelessWidget {
  const _RewardsTab();

  @override
  Widget build(BuildContext context) {
    final rewardSvc = context.watch<RewardService>();
    final all = RewardService.allRewards;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Kazanılan Ödüller',
              style: GoogleFonts.fredoka(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary)),
          const SizedBox(height: 6),
          Text(
            '${all.where((r) => rewardSvc.isEarned(r.id)).length}/${all.length} rozet kazanıldı',
            style: GoogleFonts.poppins(
                fontSize: 13, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 20),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.85,
            ),
            itemCount: all.length,
            itemBuilder: (_, i) {
              final reward = all[i];
              final earned = rewardSvc.isEarned(reward.id);
              return Container(
                decoration: BoxDecoration(
                  color: earned ? reward.color.withOpacity(0.12) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: earned
                        ? reward.color.withOpacity(0.4)
                        : Colors.grey.withOpacity(0.2),
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    earned
                        ? Image.asset(reward.imagePath,
                            width: 48,
                            height: 48,
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) =>
                                Text(reward.emoji,
                                    style: const TextStyle(fontSize: 36)))
                        : const Icon(Icons.lock_rounded,
                            size: 36, color: Color(0xFFD0D0D0)),
                    const SizedBox(height: 6),
                    Text(
                      reward.title,
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: earned
                            ? AppColors.textPrimary
                            : AppColors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    Text(
                      earned ? reward.badgeLabel : 'Kilitli',
                      style: GoogleFonts.poppins(
                          fontSize: 10, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

// ── Ayarlar Sekmesi ────────────────────────────────────────────────────────

class _SettingsTab extends StatefulWidget {
  const _SettingsTab();

  @override
  State<_SettingsTab> createState() => _SettingsTabState();
}

class _SettingsTabState extends State<_SettingsTab> {
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
        title: Text('İstatistikleri Sıfırla',
            style: GoogleFonts.fredoka(
                fontSize: 20, fontWeight: FontWeight.bold)),
        content: Text(
          'Tüm istatistikler ve grafik verileri silinecek. Bu işlem geri alınamaz.',
          style: GoogleFonts.poppins(fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('İptal',
                style: GoogleFonts.poppins(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              stats.resetStats();
              _showSnack('İstatistikler sıfırlandı');
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF44336)),
            child: Text('Sıfırla',
                style: GoogleFonts.poppins(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final stats = context.watch<StatsService>();
    const diffLabels = ['Kolay', 'Orta', 'Zor'];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
                  'Quiz başlarken hangi zorluktan başlansın?',
                  style: GoogleFonts.poppins(
                      fontSize: 13, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 12),
                SegmentedButton<int>(
                  segments: List.generate(
                    3,
                    (i) => ButtonSegment(
                      value: i,
                      label: Text(diffLabels[i],
                          style: GoogleFonts.poppins(fontSize: 13)),
                    ),
                  ),
                  selected: {stats.startingDifficulty},
                  onSelectionChanged: (s) =>
                      stats.setStartingDifficulty(s.first),
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
                        borderRadius: BorderRadius.circular(12)),
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
                        borderRadius: BorderRadius.circular(12)),
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
                          borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Text('PIN Güncelle',
                        style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // İstatistikleri sıfırla
          _SectionHeader('Tehlikeli Bölge'),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _confirmReset(stats),
              icon: const Icon(Icons.delete_outline_rounded,
                  color: Color(0xFFF44336)),
              label: Text('İstatistikleri Sıfırla',
                  style: GoogleFonts.poppins(
                      color: const Color(0xFFF44336),
                      fontWeight: FontWeight.w600)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFFF44336)),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  BoxDecoration _cardDeco() => BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)
        ],
      );
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
            color: AppColors.textPrimary),
      );
}