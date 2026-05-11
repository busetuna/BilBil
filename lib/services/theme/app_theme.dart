import 'package:flutter/material.dart';

class AppTheme {
  final String id;
  final String name;
  final String emoji;
  final Color background;
  final Color primary;
  final Color primaryLight;
  final Color accent;
  final Color card;

  const AppTheme({
    required this.id,
    required this.name,
    required this.emoji,
    required this.background,
    required this.primary,
    required this.primaryLight,
    required this.accent,
    required this.card,
  });

  static const lavender = AppTheme(
    id: 'lavender',
    name: 'Lavanta',
    emoji: '💜',
    background: Color(0xFFF5F0FF),
    primary: Color(0xFF7C4DFF),
    primaryLight: Color(0xFFB8B0FF),
    accent: Color(0xFFB39DDB),
    card: Color(0xFFEDE7F6),
  );

  static const cotton = AppTheme(
    id: 'cotton',
    name: 'Pembe',
    emoji: '🩷',
    background: Color(0xFFFFF0F5),
    primary: Color(0xFFFF6B9D),
    primaryLight: Color(0xFFFFB3D1),
    accent: Color(0xFFFFB3D1),
    card: Color(0xFFFFE4EF),
  );

  static const sunny = AppTheme(
    id: 'sunny',
    name: 'Güneşli',
    emoji: '🧡',
    background: Color(0xFFFFF8F0),
    primary: Color(0xFFFF8C42),
    primaryLight: Color(0xFFFFCC80),
    accent: Color(0xFFFFB347),
    card: Color(0xFFFFF0E0),
  );

  static const mint = AppTheme(
    id: 'mint',
    name: 'Nane',
    emoji: '💚',
    background: Color(0xFFF0FFF8),
    primary: Color(0xFF4CAF82),
    primaryLight: Color(0xFF80CBC4),
    accent: Color(0xFF80CBC4),
    card: Color(0xFFE0F7F0),
  );

  static const List<AppTheme> all = [lavender, cotton, sunny, mint];
}