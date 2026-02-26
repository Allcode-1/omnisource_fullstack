import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const primary = Color(0xFF5AA9FF);
  static const secondary = Color(0xFF19C2B4);
  static const authBackground = Color(0xFF121212);
  static const appBackground = Color(0xFF0B1220);
  static const surface = Color(0xFF16213A);
  static const surfaceAlt = Color(0xFF1D2A47);
  static const line = Color(0xFF2B3959);

  static ThemeData get authTheme => _buildTheme(
    scaffoldColor: authBackground,
    inputFill: const Color(0xFF171717),
  );

  static ThemeData get mainTheme =>
      _buildTheme(scaffoldColor: Colors.transparent, inputFill: surface);

  static BoxDecoration get mainBackgroundDecoration => const BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF0A1120), Color(0xFF111A2E), Color(0xFF081222)],
      stops: [0.0, 0.55, 1.0],
    ),
  );

  static ThemeData _buildTheme({
    required Color scaffoldColor,
    required Color inputFill,
  }) {
    final base = ThemeData.dark();
    final colorScheme = const ColorScheme.dark(
      primary: primary,
      secondary: secondary,
      surface: surface,
      error: Color(0xFFFF6B6B),
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: Colors.white,
    );

    final textTheme = GoogleFonts.plusJakartaSansTextTheme(base.textTheme)
        .copyWith(
          displayMedium: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
          headlineSmall: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w800,
            letterSpacing: -0.2,
          ),
          titleLarge: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
          titleMedium: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
          bodyLarge: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w500,
            color: Colors.white.withValues(alpha: 0.95),
          ),
          bodyMedium: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w500,
            color: Colors.white.withValues(alpha: 0.86),
          ),
          labelLarge: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w700,
            letterSpacing: 0.1,
          ),
        );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      primaryColor: primary,
      scaffoldBackgroundColor: scaffoldColor,
      cardColor: surface,
      dividerColor: line,
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge?.copyWith(fontSize: 24),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: inputFill,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
        hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.45)),
        helperStyle: const TextStyle(fontSize: 10),
        errorStyle: const TextStyle(fontSize: 10, color: Color(0xFFFF6B6B)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: line),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: primary, width: 1.3),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 0,
          minimumSize: const Size(0, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: textTheme.labelLarge?.copyWith(fontSize: 14),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.white,
          side: BorderSide(color: Colors.white.withValues(alpha: 0.16)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          textStyle: textTheme.labelLarge?.copyWith(fontSize: 13),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: surface,
        selectedColor: primary.withValues(alpha: 0.2),
        labelStyle: textTheme.bodySmall ?? const TextStyle(color: Colors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: surfaceAlt,
        contentTextStyle: textTheme.bodyMedium?.copyWith(color: Colors.white),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: Colors.white.withValues(alpha: 0.9),
        textColor: Colors.white,
        tileColor: surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
      ),
      dividerTheme: DividerThemeData(
        color: Colors.white.withValues(alpha: 0.08),
        thickness: 1,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(color: primary),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: CupertinoPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.windows: CupertinoPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.linux: CupertinoPageTransitionsBuilder(),
        },
      ),
    );
  }
}
