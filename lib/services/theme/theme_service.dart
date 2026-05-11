import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../core/theme/app_colors.dart';
import 'app_theme.dart';

class ThemeService extends ChangeNotifier {
  static const _boxName = 'theme_box';
  static const _themeKey = 'theme_id';

  late Box _box;
  AppTheme _current = AppTheme.lavender;

  AppTheme get current => _current;

  Future<void> init() async {
    _box = await Hive.openBox(_boxName);
    final savedId = _box.get(_themeKey, defaultValue: 'lavender') as String;
    _current = AppTheme.all.firstWhere(
      (t) => t.id == savedId,
      orElse: () => AppTheme.lavender,
    );
    _applyToAppColors(_current);
  }

  Future<void> setTheme(AppTheme theme) async {
    if (_current.id == theme.id) return;
    _current = theme;
    _applyToAppColors(theme);
    await _box.put(_themeKey, theme.id);
    notifyListeners();
  }

  void _applyToAppColors(AppTheme t) {
    AppColors.primary = t.primary;
    AppColors.primaryLight = t.primaryLight;
    AppColors.accent = t.accent;
    AppColors.background = t.background;
    AppColors.card = t.card;
  }
}