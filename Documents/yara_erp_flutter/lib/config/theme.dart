import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// Liquid Glass Theme for Flutter
class AppTheme {
  // Colors
  static const Color primaryColor = Color(0xFF007AFF); // Apple Blue
  static const Color backgroundColor = Color(0xFF0F0C29); // Deep dark base
  static const Color surfaceColor = Color(0x0DFFFFFF); // 5% white
  static const Color borderColor = Color(0x1AFFFFFF); // 10% white
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0x99FFFFFF); // 60% white
  static const Color textMuted = Color(0x66FFFFFF); // 40% white
  
  // Gradients
  static const LinearGradient meshGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0x731D4ED8), // Blue 45%
      Color(0x40DB2777), // Pink 25%
      Color(0x738B5CF6), // Purple 45%
    ],
  );
  
  static const LinearGradient glassGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0x1A3B82F6), // Blue 10%
      Color(0x1A8B5CF6), // Purple 10%
    ],
  );
  
  // Glass panel decoration
  static BoxDecoration glassPanel({double borderRadius = 24}) {
    return BoxDecoration(
      color: surfaceColor,
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(color: borderColor, width: 1),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.1),
          blurRadius: 30,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }
  
  // Text styles
  static TextStyle get headingLarge => GoogleFonts.manrope(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    color: textPrimary,
  );
  
  static TextStyle get headingMedium => GoogleFonts.manrope(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: textPrimary,
  );
  
  static TextStyle get headingSmall => GoogleFonts.manrope(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: textPrimary,
  );
  
  static TextStyle get bodyMedium => GoogleFonts.manrope(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: textSecondary,
  );
  
  static TextStyle get bodySmall => GoogleFonts.manrope(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: textMuted,
  );
  
  static TextStyle get labelSmall => GoogleFonts.manrope(
    fontSize: 10,
    fontWeight: FontWeight.w600,
    color: textMuted,
    letterSpacing: 1.2,
  );
  
  // Theme data
  static ThemeData get darkTheme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: backgroundColor,
    primaryColor: primaryColor,
    colorScheme: const ColorScheme.dark(
      primary: primaryColor,
      surface: surfaceColor,
      onSurface: textPrimary,
    ),
    textTheme: TextTheme(
      headlineLarge: headingLarge,
      headlineMedium: headingMedium,
      headlineSmall: headingSmall,
      bodyMedium: bodyMedium,
      bodySmall: bodySmall,
      labelSmall: labelSmall,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      titleTextStyle: headingSmall,
    ),
  );
}
