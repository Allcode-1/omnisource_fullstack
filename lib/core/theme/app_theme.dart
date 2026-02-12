import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const primaryBlue = Color(0xFF0984E3);
  static const backgroundBlack = Color(0xFF121212);

  static ThemeData get darkTheme {
    final baseDarkTheme = ThemeData.dark();

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: primaryBlue,
      scaffoldBackgroundColor: backgroundBlack,

      textTheme: GoogleFonts.interTextTheme(baseDarkTheme.textTheme).copyWith(
        bodyLarge: GoogleFonts.inter(fontWeight: FontWeight.w400),
        bodyMedium: GoogleFonts.inter(fontWeight: FontWeight.w400),
        titleLarge: GoogleFonts.inter(fontWeight: FontWeight.w600),
      ),

      inputDecorationTheme: const InputDecorationTheme(
        filled: true,
        fillColor: backgroundBlack,
        isDense: true,
        contentPadding: EdgeInsets.symmetric(vertical: 12),
        helperStyle: TextStyle(fontSize: 10),
        errorStyle: TextStyle(fontSize: 10, color: Colors.redAccent),
        errorMaxLines: 1,
        enabledBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.white24),
        ),
        focusedBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.white70),
        ),
        errorBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.redAccent),
        ),
        focusedErrorBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.redAccent, width: 1.5),
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blueAccent,
          foregroundColor: Colors.white,
          elevation: 0,
          minimumSize: const Size(0, 54),
          padding: const EdgeInsets.symmetric(horizontal: 24),
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
      ),

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
