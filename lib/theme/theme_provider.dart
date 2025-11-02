import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ValueNotifier<ThemeMode> {
  ThemeProvider(ThemeMode initial) : super(initial);

  static const _key = 'themeMode';

  static Future<ThemeProvider> create() async {
    final prefs = await SharedPreferences.getInstance();
    final themeModeString = prefs.getString(_key);
    final themeMode = ThemeMode.values.firstWhere(
      (e) => e.toString() == themeModeString,
      orElse: () => ThemeMode.system,
    );
    return ThemeProvider(themeMode);
  }

  void setThemeMode(ThemeMode themeMode) async {
    if (value == themeMode) return;
    value = themeMode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, themeMode.toString());
  }
}
