import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';

class QuizWordReveal extends StatelessWidget {
  final bool hasSpoken;
  final String recognizedWord;
  final String correctWord;
  final bool isListening;
  final bool isCorrect;
  final Animation<double> revealAnimation;

  const QuizWordReveal({
    super.key,
    required this.hasSpoken,
    required this.recognizedWord,
    required this.correctWord,
    required this.isListening,
    required this.isCorrect,
    required this.revealAnimation,
  });

  @override
  Widget build(BuildContext context) {
    if (hasSpoken && recognizedWord.isEmpty) {
      return ScaleTransition(
        scale: revealAnimation,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3E0),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: const Color(0xFFFF9800).withOpacity(0.6), width: 2),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('🤫', style: TextStyle(fontSize: 24)),
                  const SizedBox(width: 8),
                  Text(
                    correctWord,
                    style: GoogleFonts.fredoka(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFFFF9800)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            Text('Tekrar deneyelim!',
                style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: const Color(0xFFFF9800),
                    fontWeight: FontWeight.w600)),
          ],
        ),
      );
    }

    final feedbackColor =
        isCorrect ? const Color(0xFF4CAF50) : const Color(0xFFF44336);
    final feedbackIcon = isCorrect ? '✅' : '❌';

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 400),
      child: hasSpoken && recognizedWord.isNotEmpty
          ? ScaleTransition(
              key: ValueKey(recognizedWord),
              scale: revealAnimation,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 32, vertical: 12),
                    decoration: BoxDecoration(
                      color: feedbackColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: feedbackColor.withOpacity(0.5), width: 2),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(feedbackIcon,
                            style: const TextStyle(fontSize: 24)),
                        const SizedBox(width: 8),
                        Text(
                          recognizedWord,
                          style: GoogleFonts.fredoka(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: feedbackColor),
                        ),
                      ],
                    ),
                  ),
                  if (!isCorrect) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Doğrusu: $correctWord',
                      style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: const Color(0xFF4CAF50),
                          fontWeight: FontWeight.w600),
                    ),
                  ],
                ],
              ),
            )
          : SizedBox(
              height: 60,
              child: Center(
                child: Text(
                  isListening ? '🎤 ' : '❓',
                  style: const TextStyle(fontSize: 32),
                ),
              ),
            ),
    );
  }
}