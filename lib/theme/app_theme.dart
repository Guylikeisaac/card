import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// SyncUp colour tokens — strictly black & white.
class SC {
  static const bg = Color(0xFF050506);
  static const surface = Color(0xFF0B0B0D);
  static const field = Color(0xFF121214);
  static const fieldHi = Color(0xFF1F1F22);
  static const chip = Color(0xFF1C1C1F);
  static const border = Color(0xFF26262A);
  static const borderHi = Color(0xFF9A9AA0);
  static const text = Color(0xFFF5F5F5);
  static const textDim = Color(0xFF9A9AA0);
  static const textFaint = Color(0xFF5E5E64);
  static const disabledBtn = Color(0xFFBDBDBD);
}

/// SyncUp text styles.
class ST {
  static TextStyle get h1 => GoogleFonts.inter(
        fontSize: 28,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.9,
        height: 1.12,
        color: SC.text,
      );
  static TextStyle get sub =>
      GoogleFonts.inter(fontSize: 14.5, height: 1.45, color: SC.textDim);
  static TextStyle get body => GoogleFonts.inter(
      fontSize: 15.5, fontWeight: FontWeight.w500, color: SC.text);
  static TextStyle get label => GoogleFonts.inter(
      fontSize: 14, fontWeight: FontWeight.w600, color: SC.text);
  static TextStyle get small =>
      GoogleFonts.inter(fontSize: 13, color: SC.textDim, height: 1.4);
  static TextStyle get mono =>
      GoogleFonts.jetBrainsMono(fontSize: 12.5, color: SC.textDim);
}

ThemeData buildTheme() {
  final base = ThemeData.dark(useMaterial3: true);
  return base.copyWith(
    scaffoldBackgroundColor: SC.bg,
    colorScheme: const ColorScheme.dark(
      primary: Colors.white,
      onPrimary: Colors.black,
      secondary: Colors.white,
      onSecondary: Colors.black,
      surface: SC.field,
      onSurface: SC.text,
    ),
    textTheme: base.textTheme.apply(fontFamily: GoogleFonts.inter().fontFamily),
    textSelectionTheme: const TextSelectionThemeData(
      cursorColor: Colors.white,
      selectionColor: Colors.white24,
      selectionHandleColor: Colors.white,
    ),
    splashFactory: NoSplash.splashFactory,
    highlightColor: Colors.transparent,
    snackBarTheme: SnackBarThemeData(
      backgroundColor: SC.chip,
      behavior: SnackBarBehavior.floating,
      contentTextStyle: GoogleFonts.inter(color: SC.text, fontSize: 14),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: SC.border),
      ),
    ),
    datePickerTheme: DatePickerThemeData(
      backgroundColor: SC.field,
      headerBackgroundColor: SC.fieldHi,
      headerForegroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
  );
}
