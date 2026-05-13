import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../../core/theme/app_colors.dart';

void showTtsSetupDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (_) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text('Sesli Okuma Kapalı',
          style: GoogleFonts.fredoka(fontSize: 20, fontWeight: FontWeight.bold)),
      content: Text(
        'Türkçe ses paketi yüklü değil.\n\n'
        '📱 Şu adımları izle:\n'
        '1. Telefon Ayarları\'nı aç\n'
        '2. "Erişilebilirlik" seç\n'
        '3. "Metin Okuma" veya "TTS" seç\n'
        '4. "Türkçe" dil paketini indir\n'
        '5. Uygulamaya geri dön',
        style: GoogleFonts.poppins(fontSize: 13, height: 1.6),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Tamam',
              style: GoogleFonts.poppins(color: AppColors.textSecondary)),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context);
            openAppSettings();
          },
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
          child: Text('Ayarları Aç',
              style: GoogleFonts.poppins(
                  color: Colors.white, fontWeight: FontWeight.w600)),
        ),
      ],
    ),
  );
}

void showMicPermissionDialog(BuildContext context, {required bool permanent}) {
  showDialog(
    context: context,
    builder: (_) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text('Mikrofon İzni Gerekli',
          style: GoogleFonts.fredoka(fontSize: 20, fontWeight: FontWeight.bold)),
      content: Text(
        permanent
            ? 'Mikrofon izni kalıcı olarak reddedildi.\n'
                'Uygulama ayarlarından "Mikrofon" iznini açmanız gerekiyor.'
            : 'Sesli cevap verebilmek için mikrofon iznine ihtiyaç var.',
        style: GoogleFonts.poppins(fontSize: 13),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Tamam',
              style: GoogleFonts.poppins(color: AppColors.textSecondary)),
        ),
        if (permanent)
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: Text('Ayarları Aç',
                style: GoogleFonts.poppins(
                    color: Colors.white, fontWeight: FontWeight.w600)),
          ),
      ],
    ),
  );
}