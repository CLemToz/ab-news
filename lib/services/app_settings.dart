import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppSettings extends ChangeNotifier {
  AppSettings._();
  static final AppSettings I = AppSettings._();

  double fontScale = 1.0;               // 0.85 – 1.4 (UI below clamps)
  ThemeMode themeMode = ThemeMode.system;

  Future<void> load() async {
    final sp = await SharedPreferences.getInstance();
    fontScale = sp.getDouble('fontScale') ?? 1.0;
    final mode = sp.getString('themeMode') ?? 'system';
    themeMode = _modeFromString(mode);
    notifyListeners();
  }

  Future<void> setFontScale(double v) async {
    fontScale = v.clamp(0.85, 1.4);
    final sp = await SharedPreferences.getInstance();
    await sp.setDouble('fontScale', fontScale);
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode m) async {
    themeMode = m;
    final sp = await SharedPreferences.getInstance();
    await sp.setString('themeMode', _modeToString(m));
    notifyListeners();
  }

  // helpers
  String _modeToString(ThemeMode m) =>
      m == ThemeMode.dark ? 'dark' : m == ThemeMode.light ? 'light' : 'system';
  ThemeMode _modeFromString(String s) =>
      s == 'dark' ? ThemeMode.dark : s == 'light' ? ThemeMode.light : ThemeMode.system;
}
