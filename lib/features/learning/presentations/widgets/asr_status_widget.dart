import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../services/asr/vosk_asr_service.dart';

class AsrDownloadIndicator extends StatelessWidget {
  final double progress;
  const AsrDownloadIndicator({super.key, required this.progress});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Ses modeli indiriliyor...',
            style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress > 0 ? progress : null,
              minHeight: 8,
              backgroundColor: AppColors.primary.withValues(alpha: 0.15),
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            progress > 0 ? '%${(progress * 100).toInt()}' : 'Bağlanıyor...',
            style: GoogleFonts.poppins(
                fontSize: 11, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class AsrErrorWidget extends StatelessWidget {
  final VoskAsrService vosk;
  const AsrErrorWidget({super.key, required this.vosk});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.error_outline, color: AppColors.error, size: 32),
        const SizedBox(height: 4),
        Text(
          'Model yüklenemedi',
          style: GoogleFonts.poppins(
              fontSize: 13,
              color: AppColors.error,
              fontWeight: FontWeight.w600),
        ),
        TextButton(
          onPressed: vosk.initialize,
          child: Text('Tekrar Dene',
              style: GoogleFonts.poppins(color: AppColors.primary)),
        ),
      ],
    );
  }
}