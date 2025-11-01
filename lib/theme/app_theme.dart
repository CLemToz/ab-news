import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'brand.dart';

class AppTheme {
  static ThemeData get lightTheme {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: Brand.blue,
        brightness: Brightness.light,
      ).copyWith(
        primary: Brand.blue,
        secondary: Brand.red,
        tertiary: Brand.red,
      ),
    );

    return base.copyWith(
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black, // Changed to black for light theme
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.dark, // Ensures dark icons on status bar
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: Brand.red,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: Brand.blue),
      ),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: Brand.blue.withOpacity(.08),
        labelStyle: const TextStyle(fontWeight: FontWeight.w600),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  static ThemeData get darkTheme {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: Brand.blue,
        brightness: Brightness.dark,
      ).copyWith(
        primary: Brand.blue,
        secondary: Brand.red,
        tertiary: Brand.red,
        surface: Colors.black,
        background: Colors.black,
      ),
    );

    return base.copyWith(
      scaffoldBackgroundColor: Colors.black,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.light, // Ensures light icons on status bar
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: Brand.red,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: Brand.blue),
      ),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: Brand.blue.withOpacity(.2),
        labelStyle: const TextStyle(fontWeight: FontWeight.w600, color: Colors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}
