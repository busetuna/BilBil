
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

          // ASR metrikleri
          Text('ASR Performansı',
              style: GoogleFonts.fredoka(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary)),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  label: 'Ses Tanıma',
                  value: '%${(stats.asrAccuracy * 100).toStringAsFixed(1)}',
                  icon: Icons.mic_rounded,
                  color: const Color(0xFF5B9BFF),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  label: 'Ort. Yanıt',
                  value: '${(stats.avgLatencyMs / 1000).toStringAsFixed(1)}s',
                  icon: Icons.timer_rounded,
                  color: const Color(0xFFFF9800),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  label: 'ASR Deneme',
                  value: '${stats.totalAsrAttempts}',
                  icon: Icons.graphic_eq_rounded,
                  color: const Color(0xFF9C27B0),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  label: 'Hedef ≤500ms',
                  value: stats.avgLatencyMs <= 500 ? '✓' : '✗',
                  icon: Icons.speed_rounded,
                  color: stats.avgLatencyMs <= 500 || stats.totalAsrAttempts == 0
                      ? const Color(0xFF4CAF50)
                      : const Color(0xFFF44336),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // En çok zorlanan kategoriler
          const SizedBox(height: 24),
          Text('En Çok Zorlanan Kategoriler',
              style: GoogleFonts.fredoka(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary)),
          const SizedBox(height: 6),
          Text('Yanlış cevap oranına göre sıralı',
              style: GoogleFonts.poppins(
                  fontSize: 13, color: AppColors.textSecondary)),
          const SizedBox(height: 16),
          _CategoryBreakdown(stats: stats),
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

class _CategoryBreakdown extends StatelessWidget {
  final StatsService stats;
  const _CategoryBreakdown({required this.stats});

  static const _catNames = {
    'animals': 'Hayvanlar',
    'fruits_vegetables': 'Meyve-Sebze',
    'colors': 'Renkler',
    'shapes': 'Şekiller',
    'body_parts': 'Vücut Bölümleri',
    'clothes': 'Kıyafetler',
    'daily_objects': 'Günlük Eşyalar',
    'weather': 'Hava Durumu',
    'actions': 'Eylemler',
    'adjectives': 'Basit Sıfatlar',
  };

  @override
  Widget build(BuildContext context) {
    final totals = stats.categoryTotalCounts;
    final wrongs = stats.categoryWrongCounts;

    if (totals.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.05), blurRadius: 8)
          ],
        ),
        child: Center(
          child: Column(
            children: [
              const Icon(Icons.category_rounded,
                  size: 48, color: Color(0xFFD0D0D0)),
              const SizedBox(height: 10),
              Text('Henüz kategori verisi yok',
                  style: GoogleFonts.poppins(
                      fontSize: 13, color: AppColors.textSecondary)),
            ],
          ),
        ),
      );
    }

    // Sadece oynanmış kategorileri al, yanlış oranına göre sırala
    final entries = totals.entries.toList()
      ..sort((a, b) {
        final rateA = (wrongs[a.key] ?? 0) / a.value;
        final rateB = (wrongs[b.key] ?? 0) / b.value;
        return rateB.compareTo(rateA);
      });

    final maxWrong = entries
        .map((e) => wrongs[e.key] ?? 0)
        .fold(1, (a, b) => a > b ? a : b)
        .toDouble();

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
        children: entries.map((entry) {
          final name = _catNames[entry.key] ?? entry.key;
          final total = entry.value;
          final wrong = wrongs[entry.key] ?? 0;
          final correct = total - wrong;
          final wrongRate = total == 0 ? 0.0 : wrong / total;
          final barFill = maxWrong == 0 ? 0.0 : wrong / maxWrong;

          return Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(name,
                        style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary)),
                    Text(
                      '$correct✓  $wrong✗  (%${(wrongRate * 100).toStringAsFixed(0)} hata)',
                      style: GoogleFonts.poppins(
                          fontSize: 11, color: AppColors.textSecondary),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: barFill,
                    minHeight: 10,
                    backgroundColor: const Color(0xFFF5F5F5),
                    valueColor: AlwaysStoppedAnimation(
                      wrongRate > 0.6
                          ? const Color(0xFFF44336)
                          : wrongRate > 0.3
                              ? const Color(0xFFFFC107)
                              : const Color(0xFF4CAF50),
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
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
    final diffHistory = stats.difficultyHistory;
    final latHistory = stats.latencyHistory;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Zorluk grafiği ──────────────────────────────────────────────
          Text('Zorluk Seviyesi Değişimi',
              style: GoogleFonts.fredoka(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary)),
          const SizedBox(height: 6),
          Text('RL algoritmasının adaptasyonu',
              style: GoogleFonts.poppins(
                  fontSize: 13, color: AppColors.textSecondary)),
          const SizedBox(height: 16),
          if (diffHistory.isEmpty)
            _EmptyChart(message: 'Quiz oynadıkça grafik oluşur')
          else
            _DifficultyChart(history: diffHistory),
          const SizedBox(height: 8),
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

          // ── Yanıt süresi grafiği ────────────────────────────────────────
          const SizedBox(height: 32),
          Text('Yanıt Süresi Değişimi',
              style: GoogleFonts.fredoka(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary)),
          const SizedBox(height: 6),
          Text('Her cevapta geçen süre (saniye)',
              style: GoogleFonts.poppins(
                  fontSize: 13, color: AppColors.textSecondary)),
          const SizedBox(height: 16),
          if (latHistory.isEmpty)
            _EmptyChart(message: 'Sesli cevap verdikçe grafik oluşur')
          else
            _LatencyChart(history: latHistory),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _LegendDot(color: const Color(0xFF4CAF50), label: '≤0.5s (hedef)'),
              const SizedBox(width: 20),
              _LegendDot(color: const Color(0xFFFF9800), label: '>0.5s'),
            ],
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

class _EmptyChart extends StatelessWidget {
  final String message;
  const _EmptyChart({required this.message});

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 32),
          child: Column(
            children: [
              const Icon(Icons.auto_graph_rounded,
                  size: 56, color: Color(0xFFD0D0D0)),
              const SizedBox(height: 10),
              Text('Henüz veri yok',
                  style: GoogleFonts.poppins(
                      fontSize: 14, color: AppColors.textSecondary)),
              Text(message,
                  style: GoogleFonts.poppins(
                      fontSize: 12, color: AppColors.textSecondary)),
            ],
          ),
        ),
      );
}

class _DifficultyChart extends StatelessWidget {
  final List<int> history;
  const _DifficultyChart({required this.history});

  @override
  Widget build(BuildContext context) => Container(
        height: 220,
        padding: const EdgeInsets.fromLTRB(8, 16, 16, 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)
          ],
        ),
        child: LineChart(
          LineChartData(
            minY: -0.2,
            maxY: 2.2,
            gridData: FlGridData(
              show: true,
              horizontalInterval: 1,
              getDrawingHorizontalLine: (v) =>
                  FlLine(color: Colors.grey.withOpacity(0.15), strokeWidth: 1),
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
                            fontSize: 11, color: AppColors.textSecondary));
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
              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            borderData: FlBorderData(show: false),
            lineBarsData: [
              LineChartBarData(
                spots: history
                    .asMap()
                    .entries
                    .map((e) => FlSpot(e.key.toDouble(), e.value.toDouble()))
                    .toList(),
                isCurved: true,
                color: AppColors.primary,
                barWidth: 3,
                dotData: FlDotData(
                  show: history.length <= 30,
                  getDotPainter: (_, __, ___, ____) => FlDotCirclePainter(
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
      );
}

class _LatencyChart extends StatelessWidget {
  final List<int> history;
  const _LatencyChart({required this.history});

  @override
  Widget build(BuildContext context) {
    // ms → saniyeye çevir, 15 saniyede kes
    final spots = history
        .asMap()
        .entries
        .map((e) => FlSpot(e.key.toDouble(), (e.value / 1000).clamp(0.0, 15.0)))
        .toList();

    return Container(
      height: 220,
      padding: const EdgeInsets.fromLTRB(8, 16, 16, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)
        ],
      ),
      child: LineChart(
        LineChartData(
          minY: 0,
          maxY: 15,
          gridData: FlGridData(
            show: true,
            horizontalInterval: 5,
            getDrawingHorizontalLine: (v) =>
                FlLine(color: Colors.grey.withOpacity(0.15), strokeWidth: 1),
            drawVerticalLine: false,
          ),
          // hedef çizgisi: 0.5s
          extraLinesData: ExtraLinesData(
            horizontalLines: [
              HorizontalLine(
                y: 0.5,
                color: const Color(0xFF4CAF50).withOpacity(0.6),
                strokeWidth: 1.5,
                dashArray: [6, 4],
                label: HorizontalLineLabel(
                  show: true,
                  alignment: Alignment.topRight,
                  labelResolver: (_) => 'hedef',
                  style: GoogleFonts.poppins(
                      fontSize: 10, color: const Color(0xFF4CAF50)),
                ),
              ),
            ],
          ),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 5,
                reservedSize: 36,
                getTitlesWidget: (v, _) => Text(
                  '${v.toInt()}s',
                  style: GoogleFonts.poppins(
                      fontSize: 10, color: AppColors.textSecondary),
                ),
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
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: const Color(0xFFFF9800),
              barWidth: 3,
              dotData: FlDotData(
                show: history.length <= 30,
                getDotPainter: (spot, _, __, ___) => FlDotCirclePainter(
                  radius: 4,
                  color: spot.y <= 0.5
                      ? const Color(0xFF4CAF50)
                      : const Color(0xFFFF9800),
                  strokeWidth: 0,
                ),
              ),
              belowBarData: BarAreaData(
                show: true,
                color: const Color(0xFFFF9800).withOpacity(0.08),
              ),
            ),
          ],
        ),
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
              childAspectRatio: 0.75,
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
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(8, 10, 8, 4),
                        child: earned
                            ? Image.asset(
                                reward.imagePath,
                                fit: BoxFit.contain,
                                errorBuilder: (_, __, ___) => Text(
                                    reward.emoji,
                                    style: const TextStyle(fontSize: 36)),
                              )
                            : const Icon(Icons.lock_rounded,
                                size: 36, color: Color(0xFFD0D0D0)),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Text(
                        reward.title,
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: earned
                              ? AppColors.textPrimary
                              : AppColors.textSecondary,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        earned ? reward.badgeLabel : 'Kilitli',
                        style: GoogleFonts.poppins(
                            fontSize: 10, color: AppColors.textSecondary),
                      ),
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
                      fontSize: 13, color: AppColors.textSecondary),
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
                      fontSize: 11, color: AppColors.textSecondary),
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
                  'Yaşa göre içerik kategorileri ve maksimum zorluk seviyesi otomatik ayarlanır.',
                  style: GoogleFonts.poppins(
                      fontSize: 13, color: AppColors.textSecondary),
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
                  () {
                    switch (stats.childAge) {
                      case 2:
                        return '2 yaş: Yalnızca Kolay kategoriler (hayvanlar, renkler, şekiller).';
                      case 3:
                        return '3 yaş: Kolay + Orta kategoriler (+ meyve-sebze, vücut bölümleri, kıyafetler).';
                      default:
                        return '${stats.childAge} yaş: Tüm kategoriler ve zorluk seviyeleri açık.';
                    }
                  }(),
                  style: GoogleFonts.poppins(
                      fontSize: 11, color: AppColors.textSecondary),
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



