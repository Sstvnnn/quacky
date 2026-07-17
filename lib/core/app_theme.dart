import 'package:flutter/material.dart';

class QColors {
  static const cream = Color(0xFFFFF6E0);
  static const creamDeep = Color(0xFFFBE9BE);
  static const yellow = Color(0xFFF6C445);
  static const orange = Color(0xFFF79A1F);
  static const orangeDark = Color(0xFFC2710D);
  static const red = Color(0xFFCE2029);
  static const redDark = Color(0xFF8E1116);
  static const green = Color(0xFF3FA34D);
  static const brown = Color(0xFF5B3A1E);
  static const brownSoft = Color(0xFF8A6440);
  static const sleepBlue = Color(0xFFBFE3F2);
  static const nightIndigo = Color(0xFF1B2A3A);
}

ThemeData buildQuackyTheme() {
  final base = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: QColors.yellow,
      primary: QColors.orange,
      secondary: QColors.yellow,
      error: QColors.red,
      surface: QColors.cream,
    ),
    scaffoldBackgroundColor: QColors.cream,
  );

  return base.copyWith(
    textTheme: base.textTheme.apply(
      bodyColor: QColors.brown,
      displayColor: QColors.brown,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: QColors.cream,
      foregroundColor: QColors.brown,
      elevation: 0,
      centerTitle: true,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: QColors.orange,
        foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(56),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        textStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
        elevation: 3,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: QColors.brown,
        minimumSize: const Size.fromHeight(52),
        side: const BorderSide(color: QColors.brownSoft, width: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: QColors.creamDeep, width: 2),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: QColors.creamDeep, width: 2),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: QColors.orange, width: 2.5),
      ),
      labelStyle: const TextStyle(color: QColors.brownSoft),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: QColors.brown,
      contentTextStyle: const TextStyle(color: Colors.white, fontSize: 15),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
  );
}
