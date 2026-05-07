import 'package:flutter/material.dart';

class GistagColors {
  const GistagColors._();

  /// Figma token: primary-400 (#FF4A3D)
  static const primary = Color(0xFFFF4A3D);
  static const primaryDark = Color(0xFFD92D27);
  /// Figma token: primary-200 (#FFCBC4)
  static const primarySoft = Color(0xFFFFCBC4);
  static const background = Color(0xFFFFF7F6);
  static const surface = Colors.white;
  static const text = Color(0xFF222222);
  static const mutedText = Color(0xFF767676);
  /// Figma token: neutral-border (#EBE5E5)
  static const border = Color(0xFFEBE5E5);
  static const disabled = primarySoft;
  static const xp = Color(0xFFFFB020);
  static const success = Color(0xFF1BAA6F);
}

ThemeData buildGistagTheme() {
  final colorScheme = ColorScheme.fromSeed(
    seedColor: GistagColors.primary,
    primary: GistagColors.primary,
    surface: GistagColors.surface,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: GistagColors.background,
    fontFamily: 'Pretendard',
    textTheme: const TextTheme(
      headlineLarge: TextStyle(
        color: GistagColors.text,
        fontSize: 30,
        fontWeight: FontWeight.w700,
        height: 1.15,
      ),
      headlineMedium: TextStyle(
        color: GistagColors.text,
        fontSize: 24,
        fontWeight: FontWeight.w700,
      ),
      titleLarge: TextStyle(
        color: GistagColors.text,
        fontSize: 20,
        fontWeight: FontWeight.w700,
      ),
      titleMedium: TextStyle(
        color: GistagColors.text,
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
      bodyLarge: TextStyle(color: GistagColors.text, fontSize: 16, height: 1.4),
      bodyMedium: TextStyle(
        color: GistagColors.mutedText,
        fontSize: 14,
        height: 1.4,
      ),
      labelLarge: TextStyle(
        color: Colors.white,
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: GistagColors.primary,
        disabledBackgroundColor: GistagColors.disabled,
        foregroundColor: Colors.white,
        disabledForegroundColor: Colors.white,
        elevation: 0,
        minimumSize: const Size.fromHeight(56),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),
  );
}
