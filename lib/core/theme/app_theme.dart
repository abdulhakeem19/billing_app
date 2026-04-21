import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color primaryColor = Color(0xFF6C63FF);
  static const Color secondaryColor = Color(0xFF03DAC6);
  static const Color backgroundColor = Color(0xFFF2F2F7);
  static const Color surfaceColor = Colors.white;
  static const Color errorColor = Color(0xFFFF3B30);
  static const Color successColor = Color(0xFF34C759);
  static const Color textPrimary = Color(0xFF1C1C1E);
  static const Color textSecondary = Color(0xFF8E8E93);
  static const Color dividerColor = Color(0xFFE5E5EA);

  static final TextTheme textTheme =
      GoogleFonts.ibmPlexSansTextTheme().copyWith(
    bodyLarge: GoogleFonts.ibmPlexSans(
      fontSize: 15,
      fontWeight: FontWeight.w400,
      color: textPrimary,
    ),
    bodyMedium: GoogleFonts.ibmPlexSans(
      fontSize: 14,
      fontWeight: FontWeight.w400,
      color: textPrimary,
    ),
    titleLarge: GoogleFonts.ibmPlexSans(
      fontSize: 18,
      fontWeight: FontWeight.w700,
      color: textPrimary,
    ),
    titleMedium: GoogleFonts.ibmPlexSans(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      color: textPrimary,
    ),
    labelLarge: GoogleFonts.ibmPlexSans(
      fontSize: 15,
      fontWeight: FontWeight.w600,
      color: Colors.white,
    ),
  );

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: primaryColor,
      scaffoldBackgroundColor: backgroundColor,
      dividerColor: dividerColor,
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Colors.transparent,
      ),
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        primary: primaryColor,
        secondary: secondaryColor,
        surface: surfaceColor,
        error: errorColor,
      ),
      textTheme: textTheme.apply(
        bodyColor: textPrimary,
        displayColor: textPrimary,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: textTheme.titleLarge,
        iconTheme: const IconThemeData(color: textPrimary),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        color: surfaceColor,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        hintStyle: const TextStyle(
            color: textSecondary,
            fontWeight: FontWeight.normal,
            fontSize: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: dividerColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: dividerColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryColor, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: errorColor, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: errorColor, width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          padding:
              const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
          textStyle: textTheme.labelLarge,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryColor,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8)),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: backgroundColor,
        selectedColor: primaryColor.withValues(alpha: 0.12),
        labelStyle: const TextStyle(fontSize: 13),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        side: BorderSide.none,
      ),
    );
  }

  /// Shared card decoration used throughout the app.
  static BoxDecoration cardDecoration({
    Color? color,
    double radius = 14,
    bool withBorder = false,
  }) =>
      BoxDecoration(
        color: color ?? surfaceColor,
        borderRadius: BorderRadius.circular(radius),
        border: withBorder
            ? Border.all(color: dividerColor)
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      );
}
