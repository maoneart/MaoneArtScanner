import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// SHADCN UI DESIGN TOKENS (Zinc Dark Theme)
class AppTheme {
  // Background & Surface Colors (Zinc Spectrum)
  static const Color bgDark = Color(0xFF09090B); // Pure Zinc Dark
  static const Color bgCard = Color(0xFF121215); // Card Surface
  static const Color bgSurface = Color(0xFF18181B); // Inset & Element Background
  static const Color bgMuted = Color(0xFF27272A); // Muted Input & Chips

  // Borders & Dividers
  static const Color border = Color(0xFF27272A); // Standard 1px solid border
  static const Color borderHover = Color(0xFF3F3F46); // Active / Hover border
  static const Color borderLight = Color(0xFF52525B); // Accent border

  // Text Colors
  static const Color textMain = Color(0xFFFAFAFA); // High Contrast White
  static const Color textMuted = Color(0xFFA1A1AA); // Secondary Label
  static const Color textDim = Color(0xFF71717A); // Subtext / Metadata

  // Accents & Status Colors
  static const Color accentCyan = Color(0xFF38BDF8); // Cyan Accent
  static const Color accentCyanDark = Color(0xFF0284C7);
  static const Color accentEmerald = Color(0xFF10B981); // Success
  static const Color accentPurple = Color(0xFFA855F7); // OCR / Magic
  static const Color accentAmber = Color(0xFFF59E0B); // Warning / Notes
  static const Color accentRose = Color(0xFFEF4444); // Danger / Destructive

  // Linear Gradients (Subtle & Monochromatic, Anti-Slop)
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF38BDF8), Color(0xFF0284C7)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient emeraldGradient = LinearGradient(
    colors: [Color(0xFF10B981), Color(0xFF059669)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient purpleGradient = LinearGradient(
    colors: [Color(0xFFA855F7), Color(0xFF7E22CE)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient scanLaserGradient = LinearGradient(
    colors: [
      Colors.transparent,
      Color(0x2038BDF8),
      Color(0xFF38BDF8),
      Color(0x2038BDF8),
      Colors.transparent,
    ],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  // Typography & ThemeData
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: bgDark,
      primaryColor: accentCyan,
      canvasColor: bgDark,
      cardColor: bgCard,
      dividerColor: border,
      colorScheme: const ColorScheme.dark(
        primary: accentCyan,
        secondary: accentEmerald,
        surface: bgCard,
        error: accentRose,
        onPrimary: Color(0xFF09090B),
        onSecondary: Colors.white,
        onSurface: textMain,
      ),
      textTheme: TextTheme(
        displayLarge: GoogleFonts.plusJakartaSans(
          color: textMain,
          fontWeight: FontWeight.w800,
          fontSize: 30,
          letterSpacing: -0.8,
        ),
        headlineMedium: GoogleFonts.plusJakartaSans(
          color: textMain,
          fontWeight: FontWeight.w700,
          fontSize: 22,
          letterSpacing: -0.5,
        ),
        titleLarge: GoogleFonts.plusJakartaSans(
          color: textMain,
          fontWeight: FontWeight.w600,
          fontSize: 17,
          letterSpacing: -0.3,
        ),
        titleMedium: GoogleFonts.plusJakartaSans(
          color: textMain,
          fontWeight: FontWeight.w600,
          fontSize: 15,
        ),
        bodyLarge: GoogleFonts.plusJakartaSans(
          color: textMain,
          fontSize: 14,
        ),
        bodyMedium: GoogleFonts.plusJakartaSans(
          color: textMuted,
          fontSize: 13,
        ),
        bodySmall: GoogleFonts.plusJakartaSans(
          color: textDim,
          fontSize: 11,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: textMain,
          foregroundColor: const Color(0xFF09090B),
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          textStyle: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: textMain,
          side: const BorderSide(color: border, width: 1),
          backgroundColor: bgSurface,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          textStyle: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: bgDark,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: textMain, size: 20),
      ),
    );
  }
}
