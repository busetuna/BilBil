import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../services/lives/lives_service.dart';

class QuizTopBar extends StatelessWidget {
  final int difficulty;
  final String difficultyLabel;
  final int stars;
  final int currentIndex;
  final int totalItems;
  final VoidCallback onBack;

  const QuizTopBar({
    super.key,
    required this.difficulty,
    required this.difficultyLabel,
    required this.stars,
    required this.currentIndex,
    required this.totalItems,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    const diffColors = [
      Color(0xFF4CAF50),
      Color(0xFFFFC107),
      Color(0xFFF44336),
    ];
    final diffColor = diffColors[difficulty];
    final starsShown = stars % 5 == 0 && stars > 0 ? 5 : stars % 5;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: onBack,
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withOpacity(0.08), blurRadius: 8)
                    ],
                  ),
                  child: Icon(Icons.arrow_back_ios_new_rounded,
                      size: 18, color: AppColors.textPrimary),
                ),
              ),
              const Spacer(),
              Row(
                children: List.generate(
                  5,
                  (i) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: Icon(
                      i < starsShown
                          ? Icons.star_rounded
                          : Icons.star_outline_rounded,
                      size: 28,
                      color: i < starsShown
                          ? const Color(0xFFFFC107)
                          : const Color(0xFFD0D0D0),
                    ),
                  ),
                ),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.08), blurRadius: 8)
                  ],
                ),
                child: Text(
                  '${currentIndex + 1}/$totalItems',
                  style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: diffColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: diffColor.withOpacity(0.4)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.auto_graph_rounded, size: 13, color: diffColor),
                    const SizedBox(width: 4),
                    Text(
                      'Seviye: $difficultyLabel',
                      style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: diffColor),
                    ),
                  ],
                ),
              ),
              Consumer<LivesService>(
                builder: (_, lives, __) => Row(
                  children: List.generate(
                    LivesService.maxLives,
                    (i) => Padding(
                      padding: const EdgeInsets.only(left: 3),
                      child: Icon(
                        Icons.favorite_rounded,
                        size: 18,
                        color: i < lives.lives
                            ? const Color(0xFFFF4F6D)
                            : Colors.grey[300],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}