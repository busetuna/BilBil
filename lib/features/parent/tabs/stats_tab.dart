import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../services/learning/word_progress_service.dart';
import '../../../services/stats/stats_service.dart';

class StatsTab extends StatelessWidget {
  const StatsTab({super.key});

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
          Text(
            'Genel Performans',
            style: GoogleFonts.fredoka(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
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

          // Not: "latency" alanları ses tanıma gecikmesi değil, sorunun
          // gösterilmesinden cevaba kadar geçen süredir. Doğruluk oranı da
          // yukarıdaki başarı oranının aynısı olduğu için ayrıca gösterilmez.
          Text(
            'Sesli Cevaplar',
            style: GoogleFonts.fredoka(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  label: 'Sesli Cevap',
                  value: '${stats.totalAsrAttempts}',
                  icon: Icons.mic_rounded,
                  color: const Color(0xFF5B9BFF),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  label: 'Ort. Cevap Süresi',
                  value: '${(stats.avgLatencyMs / 1000).toStringAsFixed(1)}s',
                  icon: Icons.timer_rounded,
                  color: const Color(0xFFFF9800),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          Text(
            'Zorlandığı Kelimeler',
            style: GoogleFonts.fredoka(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Bu kelimeler quiz\'de daha sık tekrar ediliyor',
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          const _StrugglingWords(),

          const SizedBox(height: 24),
          Text(
            'En Çok Zorlanan Kategoriler',
            style: GoogleFonts.fredoka(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Yanlış cevap oranına göre sıralı',
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          _CategoryBreakdown(stats: stats),
          const SizedBox(height: 24),

          Text(
            'Başarı Çubuğu',
            style: GoogleFonts.fredoka(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8),
              ],
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Doğru',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    Text(
                      '%$rate',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF4CAF50),
                      ),
                    ),
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

/// Yanlış yapılıp henüz oturmamış kelimeler (aralıklı tekrar kutusu 0–1).
class _StrugglingWords extends StatelessWidget {
  const _StrugglingWords();

  @override
  Widget build(BuildContext context) {
    final words = context.watch<WordProgressService>().struggling();
    final deco = BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8),
      ],
    );
    if (words.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: deco,
        child: Text(
          'Henüz zorlandığı bir kelime yok 🎉',
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
            fontSize: 13,
            color: AppColors.textSecondary,
          ),
        ),
      );
    }
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: deco,
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final w in words)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3E0),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${w.word} · ${w.wrong} yanlış',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFFE65100),
                ),
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
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8),
          ],
        ),
        child: Center(
          child: Column(
            children: [
              const Icon(
                Icons.category_rounded,
                size: 48,
                color: Color(0xFFD0D0D0),
              ),
              const SizedBox(height: 10),
              Text(
                'Henüz kategori verisi yok',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      );
    }

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
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8),
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
                    Text(
                      name,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      '$correct✓  $wrong✗  (%${(wrongRate * 100).toStringAsFixed(0)} hata)',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
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
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.fredoka(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
