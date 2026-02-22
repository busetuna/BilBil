import 'package:flutter/material.dart';

class AppColors {
  // Ana Renkler
  static const Color primary = Color(0xFF6C63FF);
  static const Color secondary = Color(0xFFFF6B9D);
  static const Color accent = Color(0xFFFFC857);

  // Gradient Renkler
  static const Color gradientStart = Color(0xFFE8F5FF);
  static const Color gradientEnd = Color(0xFFFFE8F0);

  // Bubble Renkler
  static const Color bubblePink = Color(0xFFFFB6C1);
  static const Color bubbleBlue = Color(0xFF87CEEB);
  static const Color bubbleYellow = Color(0xFFFFE082);
  static const Color bubblePurple = Color(0xFFDDA0DD);
  static const Color bubbleGreen = Color(0xFFA8E6CF);

  // Metin Renkler
  static const Color textPrimary = Color(0xFF2D3142);
  static const Color textSecondary = Color(0xFF9E9E9E);
  static const Color textLight = Color(0xFFB0B0B0);

  // Arka Plan Renkler
  static const Color background = Color(0xFFFAFAFA);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF5F5F5);

  // Başarı/Uyarı Renkler
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFFA726);
  static const Color error = Color(0xFFEF5350);
  static const Color info = Color(0xFF42A5F5);

  // Özel Renkler - Bilbil Teması
  static const Color bilbilBlue = Color(0xFF64B5F6);
  static const Color bilbilPink = Color(0xFFFFB6C1);
  static const Color bilbilYellow = Color(0xFFFFD54F);
  static const Color bilbilGreen = Color(0xFF81C784);
  static const Color bilbilPurple = Color(0xFFBA68C8);

  // Overlay Renkler
  static const Color overlay = Color(0x66000000);
  static const Color overlayLight = Color(0x33000000);

  // Border Renkler
  static const Color border = Color(0xFFE0E0E0);
  static const Color borderLight = Color(0xFFF0F0F0);

  // Gölge Renkler
  static Color shadowLight = Colors.black.withOpacity(0.08);
  static Color shadowMedium = Colors.black.withOpacity(0.15);
  static Color shadowDark = Colors.black.withOpacity(0.25);

  // Kategori Renkler (Kelime kategorileri için)
  static const Map<String, Color> categoryColors = {
    'animals': Color(0xFFFFB6C1),      // Pembe
    'actions': Color(0xFF87CEEB),      // Açık Mavi
    'adjectives': Color(0xFFFFE082),   // Sarı
    'body_parts': Color(0xFFA8E6CF),   // Mint Yeşili
    'clothes': Color(0xFFDDA0DD),      // Mor
    'colors': Color(0xFFFFD54F),       // Turuncu-Sarı
    'daily_objects': Color(0xFF81C784), // Yeşil
    'fruits_vegetables': Color(0xFFFF8A65), // Turuncu
    'shapes': Color(0xFF64B5F6),       // Mavi
    'weather': Color(0xFFFFB74D),      // Koyu Sarı
  };

  // Difficulty Level Colors
  static const Map<String, Color> difficultyColors = {
    'easy': Color(0xFF81C784),
    'medium': Color(0xFFFFD54F),
    'hard': Color(0xFFEF5350),
  };
}