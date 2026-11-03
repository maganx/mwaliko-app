import 'package:flutter/material.dart';

class MwalikoColors {
  static const maroon = Color(0xFF7A1F3D);
  static const gold = Color(0xFFD4AF37);
  static const cream = Color(0xFFFFF8F0);
  static const ink = Color(0xFF2A1A20);
}

ThemeData buildTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: MwalikoColors.maroon,
    primary: MwalikoColors.maroon,
    secondary: MwalikoColors.gold,
    surface: MwalikoColors.cream,
  );
  return ThemeData(
    colorScheme: scheme,
    useMaterial3: true,
    fontFamily: 'Poppins',
    scaffoldBackgroundColor: MwalikoColors.cream,
    appBarTheme: const AppBarTheme(
      backgroundColor: MwalikoColors.cream,
      foregroundColor: MwalikoColors.ink,
      centerTitle: false,
      elevation: 0,
      titleTextStyle: TextStyle(
        fontFamily: 'PlayfairDisplay',
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: MwalikoColors.ink,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.brown.shade100),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
        textStyle: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, fontSize: 16),
      ),
    ),
    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: Colors.brown.shade50),
      ),
    ),
  );
}
