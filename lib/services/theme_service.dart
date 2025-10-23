import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A service that stores and retrieves user theme settings.
///
/// This class uses [SharedPreferences] to persist the theme settings locally
/// and [ChangeNotifier] to notify listeners of theme changes.
class ThemeService with ChangeNotifier {
  final SharedPreferences _prefs;
  static const String _themeKey = 'theme_mode';

  ThemeMode _themeMode = ThemeMode.system;

  ThemeService(this._prefs) {
    _loadTheme();
  }

  /// The current theme mode.
  ThemeMode get themeMode => _themeMode;

  /// Loads the user's preferred theme from [SharedPreferences].
  ///
  /// If no preference is found, it defaults to [ThemeMode.system].
  void _loadTheme() {
    final themeIndex = _prefs.getInt(_themeKey);
    if (themeIndex != null && themeIndex >= 0 && themeIndex < ThemeMode.values.length) {
      _themeMode = ThemeMode.values[themeIndex];
    } else {
      _themeMode = ThemeMode.system; // Default value
    }
    notifyListeners();
  }

  /// Persists the user's preferred theme to [SharedPreferences].
  Future<void> setTheme(ThemeMode themeMode) async {
    if (_themeMode == themeMode) return; // No change

    _themeMode = themeMode;
    await _prefs.setInt(_themeKey, themeMode.index);
    notifyListeners(); // Notify listeners to rebuild widgets
  }
}
