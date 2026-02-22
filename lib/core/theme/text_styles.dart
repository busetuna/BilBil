import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTextStyles {
  // ============ BAŞLIKLAR ============

  // Ana Başlık (Bilbil gibi)
  static TextStyle get displayLarge => GoogleFonts.fredoka(
    fontSize: 64,
    fontWeight: FontWeight.bold,
    color: AppColors.primary,
    letterSpacing: 2,
  );

  static TextStyle get displayMedium => GoogleFonts.fredoka(
    fontSize: 48,
    fontWeight: FontWeight.bold,
    color: AppColors.primary,
    letterSpacing: 1.5,
  );

  static TextStyle get displaySmall => GoogleFonts.fredoka(
    fontSize: 36,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    letterSpacing: 1,
  );

  // ============ BAŞLIKLAR (Headings) ============

  static TextStyle get headlineLarge => GoogleFonts.quicksand(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
  );

  static TextStyle get headlineMedium => GoogleFonts.quicksand(
    fontSize: 28,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  static TextStyle get headlineSmall => GoogleFonts.quicksand(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  // ============ ALT BAŞLIKLAR (Titles) ============

  static TextStyle get titleLarge => GoogleFonts.poppins(
    fontSize: 22,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  static TextStyle get titleMedium => GoogleFonts.poppins(
    fontSize: 18,
    fontWeight: FontWeight.w500,
    color: AppColors.textPrimary,
  );

  static TextStyle get titleSmall => GoogleFonts.poppins(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
  );

  // ============ GÖVDE METİNLERİ (Body) ============

  static TextStyle get bodyLarge => GoogleFonts.poppins(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    color: AppColors.textPrimary,
    height: 1.5,
  );

  static TextStyle get bodyMedium => GoogleFonts.poppins(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: AppColors.textPrimary,
    height: 1.5,
  );

  static TextStyle get bodySmall => GoogleFonts.poppins(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    color: AppColors.textSecondary,
    height: 1.4,
  );

  // ============ ETİKETLER (Labels) ============

  static TextStyle get labelLarge => GoogleFonts.poppins(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    letterSpacing: 0.5,
  );

  static TextStyle get labelMedium => GoogleFonts.poppins(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
    letterSpacing: 0.5,
  );

  static TextStyle get labelSmall => GoogleFonts.poppins(
    fontSize: 10,
    fontWeight: FontWeight.w500,
    color: AppColors.textLight,
    letterSpacing: 0.3,
  );

  // ============ ÖZEL STILLER ============

  // Merhaba gibi alt yazılar
  static TextStyle get subtitle => GoogleFonts.poppins(
    fontSize: 18,
    fontWeight: FontWeight.w300,
    color: AppColors.textSecondary,
    letterSpacing: 8,
  );

  // Buton metinleri
  static TextStyle get button => GoogleFonts.quicksand(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: Colors.white,
    letterSpacing: 1,
  );

  // Büyük buton metinleri
  static TextStyle get buttonLarge => GoogleFonts.quicksand(
    fontSize: 18,
    fontWeight: FontWeight.bold,
    color: Colors.white,
    letterSpacing: 1.5,
  );

  // Kartlardaki başlıklar
  static TextStyle get cardTitle => GoogleFonts.quicksand(
    fontSize: 20,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
  );

  // Kartlardaki açıklamalar
  static TextStyle get cardDescription => GoogleFonts.poppins(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: AppColors.textSecondary,
    height: 1.4,
  );

  // Oyun skorları
  static TextStyle get score => GoogleFonts.fredoka(
    fontSize: 48,
    fontWeight: FontWeight.bold,
    color: AppColors.primary,
  );

  // Kelime kartları (büyük kelimeler)
  static TextStyle get wordCard => GoogleFonts.fredoka(
    fontSize: 32,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  // Hata mesajları
  static TextStyle get error => GoogleFonts.poppins(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: AppColors.error,
  );

  // Başarı mesajları
  static TextStyle get success => GoogleFonts.poppins(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: AppColors.success,
  );

  // Bilgi mesajları
  static TextStyle get info => GoogleFonts.poppins(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: AppColors.info,
  );

  // İstatistik sayıları
  static TextStyle get statisticNumber => GoogleFonts.fredoka(
    fontSize: 36,
    fontWeight: FontWeight.bold,
    color: AppColors.primary,
  );

  // İstatistik etiketleri
  static TextStyle get statisticLabel => GoogleFonts.poppins(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    color: AppColors.textSecondary,
  );

  // Kategori etiketleri
  static TextStyle get categoryLabel => GoogleFonts.quicksand(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: Colors.white,
    letterSpacing: 0.5,
  );

  // Timer/Countdown
  static TextStyle get timer => GoogleFonts.fredoka(
    fontSize: 40,
    fontWeight: FontWeight.bold,
    color: AppColors.primary,
  );

  // ============ YARDIMCI FONKSIYONLAR ============

  // Renk değiştirme
  static TextStyle withColor(TextStyle style, Color color) {
    return style.copyWith(color: color);
  }

  // Boyut değiştirme
  static TextStyle withSize(TextStyle style, double fontSize) {
    return style.copyWith(fontSize: fontSize);
  }

  // Kalınlık değiştirme
  static TextStyle withWeight(TextStyle style, FontWeight weight) {
    return style.copyWith(fontWeight: weight);
  }

  // Gölge ekleme
  static TextStyle withShadow(TextStyle style, {
    Color? shadowColor,
    Offset offset = const Offset(0, 2),
    double blurRadius = 4,
  }) {
    return style.copyWith(
      shadows: [
        Shadow(
          color: shadowColor ?? AppColors.shadowLight,
          offset: offset,
          blurRadius: blurRadius,
        ),
      ],
    );
  }
}