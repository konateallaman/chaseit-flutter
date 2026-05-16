import 'package:flutter/material.dart';

class AppColors {
  // Brand
  static const Color accent = Color(0xFFE84C1E);
  static const Color accent2 = Color(0xFFFF6B3D);
  static const Color accentBg = Color(0xFFFFF0EB);

  // Backgrounds
  static const Color bg = Color(0xFFF7F4EF);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surface2 = Color(0xFFF0ECE5);

  // Ink
  static const Color ink = Color(0xFF1A1612);
  static const Color ink2 = Color(0xFF2D2820);
  static const Color muted = Color(0xFF8A8070);
  static const Color muted2 = Color(0xFFC4BDB0);

  // Status
  static const Color green = Color(0xFF1A6B3C);
  static const Color greenBg = Color(0xFFE8F5EE);
  static const Color yellow = Color(0xFFB87C00);
  static const Color yellowBg = Color(0xFFFFF8E6);
  static const Color blue = Color(0xFF1A4FA0);
  static const Color blueBg = Color(0xFFE8F0FB);

  // Border
  static const Color border = Color(0x1A1A1612);
  static const Color border2 = Color(0x2E1A1612);

  // Sidebar
  static const Color sidebarBg = Color(0xFF1A1612);
}

class AppTheme {
  static ThemeData get theme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.bg,
      colorScheme: const ColorScheme.light(
        primary: AppColors.accent,
        secondary: AppColors.green,
        surface: AppColors.surface,
        error: AppColors.accent,
      ),
      fontFamily: 'Syne',
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.ink,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontFamily: 'Syne',
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: AppColors.ink,
          letterSpacing: -0.3,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accent,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: const TextStyle(fontFamily: 'Syne', fontWeight: FontWeight.w600, fontSize: 13),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.bg,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.border2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: AppColors.border2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.accent, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        labelStyle: const TextStyle(fontFamily: 'Syne', fontSize: 12, color: AppColors.muted),
        hintStyle: const TextStyle(fontFamily: 'Syne', fontSize: 13, color: AppColors.muted2),
      ),
    );
  }
}
