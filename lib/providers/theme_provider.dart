import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';

/// Theme provider for managing light/dark mode
class ThemeProvider extends ChangeNotifier {
  static const String _themeKey = 'theme_mode';

  ThemeMode _themeMode = ThemeMode.system;
  bool _isDarkMode = false;

  ThemeMode get themeMode => _themeMode;
  bool get isDarkMode => _isDarkMode;

  ThemeProvider() {
    _loadTheme();
  }

  /// Load theme preference from storage
  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final themeIndex = prefs.getInt(_themeKey) ?? 0;

    switch (themeIndex) {
      case 0:
        _themeMode = ThemeMode.system;
        break;
      case 1:
        _themeMode = ThemeMode.light;
        break;
      case 2:
        _themeMode = ThemeMode.dark;
        break;
    }

    _updateDarkModeFlag();
    notifyListeners();
  }

  /// Save theme preference to storage
  Future<void> _saveTheme() async {
    final prefs = await SharedPreferences.getInstance();
    int themeIndex = 0;

    switch (_themeMode) {
      case ThemeMode.system:
        themeIndex = 0;
        break;
      case ThemeMode.light:
        themeIndex = 1;
        break;
      case ThemeMode.dark:
        themeIndex = 2;
        break;
    }

    await prefs.setInt(_themeKey, themeIndex);
  }

  /// Toggle between light and dark mode
  Future<void> toggleTheme() async {
    if (_themeMode == ThemeMode.light) {
      _themeMode = ThemeMode.dark;
    } else {
      _themeMode = ThemeMode.light;
    }

    _updateDarkModeFlag();
    await _saveTheme();
    notifyListeners();
  }

  /// Set specific theme mode
  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    _updateDarkModeFlag();
    await _saveTheme();
    notifyListeners();
  }

  /// Update dark mode flag based on current theme and system brightness
  void _updateDarkModeFlag() {
    if (_themeMode == ThemeMode.dark) {
      _isDarkMode = true;
    } else if (_themeMode == ThemeMode.light) {
      _isDarkMode = false;
    } else {
      // System mode - check system brightness
      final brightness =
          WidgetsBinding.instance.platformDispatcher.platformBrightness;
      _isDarkMode = brightness == Brightness.dark;
    }
  }
}

/// App theme definitions
class AppTheme {
  static const _primaryColor = Colors.indigo;
  static const _secondaryColor = Colors.indigoAccent;

  /// Light theme
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: _primaryColor,
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: Colors.white,
      appBarTheme: const AppBarTheme(
        backgroundColor: _primaryColor,
        foregroundColor: Colors.white,
        elevation: 1,
        centerTitle: false,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _primaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: _primaryColor, width: 2),
          borderRadius: BorderRadius.circular(8),
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
      ),
      cardTheme: CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      dividerColor: Colors.grey.shade300,
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
        headlineMedium: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          color: Colors.black87,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          color: Colors.black87,
        ),
      ),
    );
  }

  /// Dark theme
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: _primaryColor,
        brightness: Brightness.dark,
      ),
      scaffoldBackgroundColor: const Color(0xFF121212),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.grey.shade900,
        foregroundColor: Colors.white,
        elevation: 1,
        centerTitle: false,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _secondaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: _secondaryColor, width: 2),
          borderRadius: BorderRadius.circular(8),
        ),
        filled: true,
        fillColor: Colors.grey.shade800,
      ),
      cardTheme: CardThemeData(
        elevation: 2,
        color: Colors.grey.shade800,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      dividerColor: Colors.grey.shade700,
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        headlineMedium: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          color: Colors.white,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          color: Colors.white,
        ),
      ),
    );
  }
}

/// Theme toggle widget
class ThemeToggleButton extends StatelessWidget {
  const ThemeToggleButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return IconButton(
          icon: Icon(
            themeProvider.themeMode == ThemeMode.dark
                ? Icons.light_mode
                : Icons.dark_mode,
          ),
          onPressed: () {
            themeProvider.toggleTheme();
          },
        );
      },
    );
  }
}
