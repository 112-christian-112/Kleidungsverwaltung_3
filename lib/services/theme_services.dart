// services/theme_service.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum ThemeOption {
  system,
  light,
  dark,
  blue,
  green,
  orange
}

class ThemeService extends ChangeNotifier {
  static const String _themeKey = 'selected_theme';
  late SharedPreferences _prefs;
  ThemeOption _currentTheme = ThemeOption.system;

  ThemeOption get currentTheme => _currentTheme;

  // Singleton-Pattern
  static final ThemeService _instance = ThemeService._internal();

  factory ThemeService() {
    return _instance;
  }

  ThemeService._internal();

  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    final savedTheme = _prefs.getInt(_themeKey);
    if (savedTheme != null) {
      _currentTheme = ThemeOption.values[savedTheme];
    }
    notifyListeners();
  }

  Future<void> setTheme(ThemeOption theme) async {
    _currentTheme = theme;
    await _prefs.setInt(_themeKey, theme.index);
    notifyListeners();
  }

  ThemeMode getThemeMode() {
    switch (_currentTheme) {
      case ThemeOption.light:
        return ThemeMode.light;
      case ThemeOption.dark:
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  ThemeData getLightTheme() {
    switch (_currentTheme) {
      case ThemeOption.blue:
        return _createTheme(Colors.blue, Brightness.light);
      case ThemeOption.green:
        return _createTheme(Colors.green, Brightness.light);
      case ThemeOption.orange:
        return _createTheme(Colors.orange, Brightness.light);
      default:
        return _createTheme(Colors.blue, Brightness.light);
    }
  }

  ThemeData getDarkTheme() {
    switch (_currentTheme) {
      case ThemeOption.blue:
        return _createTheme(Colors.blue, Brightness.dark);
      case ThemeOption.green:
        return _createTheme(Colors.green, Brightness.dark);
      case ThemeOption.orange:
        return _createTheme(Colors.orange, Brightness.dark);
      default:
        return _createTheme(Colors.blue, Brightness.dark);
    }
  }

  ThemeData _createTheme(Color primaryColor, Brightness brightness) {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        brightness: brightness,
      ),
      useMaterial3: true,
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 2,
      ),
    );
  }

  String getThemeName(ThemeOption theme) {
    switch (theme) {
      case ThemeOption.system:
        return 'Systemstandard';
      case ThemeOption.light:
        return 'Hell';
      case ThemeOption.dark:
        return 'Dunkel';
      case ThemeOption.blue:
        return 'Blau';
      case ThemeOption.green:
        return 'Grün';
      case ThemeOption.orange:
        return 'Orange';
    }
  }
}
