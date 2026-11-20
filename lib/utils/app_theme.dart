import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  final bool isDark;

  const AppColors._({required this.isDark});

  factory AppColors.of(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return AppColors._(isDark: brightness == Brightness.dark);
  }

  Color get background => isDark ? Colors.black : Colors.white;
  Color get surface =>
      isDark ? const Color(0xFF121212) : const Color(0xFFF5F5F5);
  Color get foreground => isDark ? Colors.white : Colors.black;
  Color get onForeground => isDark ? Colors.black : Colors.white;
  Color get divider =>
      isDark ? const Color(0xFF1F1F1F) : const Color(0xFFE5E5E5);
  Color get cardBorderSubtle =>
      isDark ? const Color(0xFF262626) : const Color(0xFFD4D4D4);
  Color get border =>
      isDark ? const Color(0xFF333333) : const Color(0xFFCCCCCC);
  Color get badgeBorder =>
      isDark ? const Color(0xFF525252) : const Color(0xFFA3A3A3);
  Color get badgeText =>
      isDark ? const Color(0xFFD4D4D4) : const Color(0xFF404040);
  Color get mutedText =>
      isDark ? const Color(0xFF8C8C8C) : const Color(0xFF666666);
  Color get subtleText => const Color(0xFF737373);
  Color get inactiveTrack =>
      isDark ? const Color(0xFF1A1A1A) : const Color(0xFFE5E5E5);
}

class AppTheme {
  AppTheme._();

  static ThemeData dark() {
    final baseTheme = ThemeData.dark(useMaterial3: true);
    return baseTheme.copyWith(
      scaffoldBackgroundColor: Colors.black,
      colorScheme: const ColorScheme.dark(
        primary: Colors.white,
        onPrimary: Colors.black,
        secondary: Colors.white,
        onSecondary: Colors.black,
        surface: Colors.black,
        onSurface: Colors.white,
      ),
      textTheme: GoogleFonts.interTextTheme(baseTheme.textTheme).apply(
        bodyColor: Colors.white,
        displayColor: Colors.white,
      ),
      dividerColor: const Color(0xFF1F1F1F),
    );
  }

  static ThemeData light() {
    final baseTheme = ThemeData.light(useMaterial3: true);
    return baseTheme.copyWith(
      scaffoldBackgroundColor: Colors.white,
      colorScheme: const ColorScheme.light(
        primary: Colors.black,
        onPrimary: Colors.white,
        secondary: Colors.black,
        onSecondary: Colors.white,
        surface: Colors.white,
        onSurface: Colors.black,
      ),
      textTheme: GoogleFonts.interTextTheme(baseTheme.textTheme).apply(
        bodyColor: Colors.black,
        displayColor: Colors.black,
      ),
      dividerColor: const Color(0xFFE5E5E5),
    );
  }
}
