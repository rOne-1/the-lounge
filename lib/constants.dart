import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

enum AmbianceType {
  screeningRoom,
  readingRoom,
}

class AppColors {
  // Screening Room
  static const Color screeningRoomBase =
      Color(0xFF1C1917); // Near-black warm espresso
  static const Color screeningRoomSurface = Color(0xFF292524);
  static const Color screeningRoomAccent = Color(0xFFF3E5AB); // Champagne gold

  // The Reading Room
  static const Color readingRoomBase = Color(0xFFF5F5DC); // Parchment
  static const Color readingRoomSurface =
      Color(0xFFFAF9F6); // Lighter parchment
  static const Color readingRoomAccent = Color(0xFFB7410E); // Rust / Terracotta

  // Status Colors
  // Watchlist: Champagne gold / Rust
  static const Color statusWatchlistDark = Color(0xFFF3E5AB);
  static const Color statusWatchlistLight = Color(0xFFB7410E);
  // Save for later: Dusty rose / Copper-rose
  static const Color statusSaveForLaterDark = Color(0xFFDCAE96);
  static const Color statusSaveForLaterLight = Color(0xFFB87333);
  // Watched: Cool steel
  static const Color statusWatchedDark = Color(0xFFB0C4DE);
  static const Color statusWatchedLight = Color(0xFF778899);
}

class AppThemes {
  static ThemeData get screeningRoomTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.screeningRoomBase,
      primaryColor: AppColors.screeningRoomAccent,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.screeningRoomAccent,
        surface: AppColors.screeningRoomSurface,
        onPrimary: Colors.black,
        onSurface: Colors.white70,
      ),
      textTheme: _buildTextTheme(Colors.white),
    );
  }

  static ThemeData get readingRoomTheme {
    return ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.readingRoomBase,
      primaryColor: AppColors.readingRoomAccent,
      colorScheme: const ColorScheme.light(
        primary: AppColors.readingRoomAccent,
        surface: AppColors.readingRoomSurface,
        onPrimary: Colors.white,
        onSurface: Colors.black87,
      ),
      textTheme: _buildTextTheme(Colors.black),
    );
  }

  static TextTheme _buildTextTheme(Color textColor) {
    return TextTheme(
      displayLarge: GoogleFonts.bodoniModa(
        fontSize: 57,
        fontWeight: FontWeight.w400,
        color: textColor,
      ),
      displayMedium: GoogleFonts.bodoniModa(
        fontSize: 45,
        fontWeight: FontWeight.w400,
        color: textColor,
      ),
      displaySmall: GoogleFonts.bodoniModa(
        fontSize: 36,
        fontWeight: FontWeight.w400,
        color: textColor,
      ),
      headlineLarge: GoogleFonts.bodoniModa(
        fontSize: 32,
        fontWeight: FontWeight.w400,
        color: textColor,
      ),
      titleLarge: GoogleFonts.bodoniModa(
        fontSize: 22,
        fontWeight: FontWeight.w500,
        color: textColor,
      ),
      bodyLarge: _safeGeist(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: textColor,
      ),
      bodyMedium: _safeGeist(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: textColor,
      ),
      bodySmall: _safeGeist(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: textColor,
      ),
      labelLarge: _safeGeist(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: textColor,
      ),
    );
  }

  static TextStyle _safeGeist({
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
  }) {
    try {
      return GoogleFonts.getFont(
        'Geist',
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
      );
    } catch (_) {
      // Fallback if Geist is not supported
      return GoogleFonts.inter(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
      );
    }
  }
}
