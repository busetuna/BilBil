import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../services/stats/stats_service.dart';

class ChartTab extends StatelessWidget {
  const ChartTab({super.key});

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