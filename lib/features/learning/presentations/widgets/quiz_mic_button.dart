import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class QuizMicButton extends StatelessWidget {
  final bool isListening;
  final bool sttAvailable;
  final VoidCallback? onTap;
  final AnimationController pulseController;

  const QuizMicButton({
    super.key,
    required this.isListening,
    required this.sttAvailable,
    required this.onTap,
    required this.pulseController,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: sttAvailable ? onTap : null,
      child: AnimatedBuilder(
        animation: pulseController,
        builder: (context, child) {
          final scale =
              isListening ? 1.0 + (pulseController.value * 0.15) : 1.0;
          return Transform.scale(scale: scale, child: child);
        },
        child: Container(
          width: 76,
          height: 76,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isListening ? AppColors.secondary : AppColors.primary,
            boxShadow: [
              BoxShadow(
                color: (isListening ? AppColors.secondary : AppColors.primary)
                    .withOpacity(0.45),
                blurRadius: 24,
                spreadRadius: 4,
              ),
            ],
          ),
          child: Icon(
            isListening ? Icons.mic_rounded : Icons.mic_none_rounded,
            color: Colors.white,
            size: 36,
          ),
        ),
      ),
    );
  }
}