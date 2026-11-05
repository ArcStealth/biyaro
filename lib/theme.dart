import 'package:flutter/material.dart';

class BColors {
  static const bg = Color(0xFF000000);
  static const card = Color(0xFF1C1C20);
  static const accent = Color(0xFF4FC3BD);
  static const muted = Color(0xFF9A9AA5);
  static const amber = Color(0xFFE8A84C);
  static const red = Color(0xFFE5484D);
}

ThemeData biyaroTheme() {
  final base = ThemeData.dark(useMaterial3: true);
  return base.copyWith(
    scaffoldBackgroundColor: BColors.bg,
    colorScheme: const ColorScheme.dark(
      primary: BColors.accent,
      onPrimary: Colors.black,
      secondary: BColors.amber,
      surface: BColors.card,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: BColors.card,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
    ),
    navigationBarTheme: const NavigationBarThemeData(
      backgroundColor: BColors.card,
      indicatorColor: Color(0x334FC3BD),
    ),
  );
}
