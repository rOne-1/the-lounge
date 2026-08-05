import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

export 'constants/app_physics.dart';

enum AmbianceType {
  screeningRoom,
  readingRoom,
}

class AppColors {
  // Screening Room CSS Variables
  static const Color srBase = Color(0xFF171310);
  static const Color srCard = Color(0xFF241B15);
  static const Color srCard2 = Color(0xFF2C2018);
  static const Color srLineRgba = Color.fromRGBO(201, 168, 106, 0.16);
  static const Color srInk = Color(0xFFEFE6D8);
  static const Color srSub = Color.fromRGBO(239, 230, 216, 0.55);
  static const Color srAcc = Color(0xFFCBA86A);
  static const Color srPh = Color.fromRGBO(239, 230, 216, 0.07);
  static const Color srPill = Color.fromRGBO(239, 230, 216, 0.08);

  static const Color srStatusWatchlist = Color(0xFFCBA86A);
  static const Color srStatusSave = Color(0xFFD69784);
  static const Color srStatusWatching = Color(0xFF62A87C);
  static const Color srStatusWatched = Color(0xFF7E9BB5);

  static const Color srGlow1 = Color(0xFFCBA86A);
  static const Color srGlow2 = Color(0xFFD69784);

  // Reading Room CSS Variables
  static const Color rrBase = Color(0xFFEFE6D5);
  static const Color rrCard = Color(0xFFF6EFE1);
  static const Color rrCard2 = Color(0xFFF2E9D8);
  static const Color rrLineRgba = Color.fromRGBO(160, 74, 42, 0.16);
  static const Color rrInk = Color(0xFF2C2016);
  static const Color rrSub = Color(0xFF5C4C3D);
  static const Color rrAcc = Color(0xFFB0512B);
  static const Color rrAccGradientEnd = Color(0xFF8F3E1E);
  static const Color rrPh = Color.fromRGBO(44, 32, 22, 0.07);
  static const Color rrPill = Color.fromRGBO(44, 32, 22, 0.06);

  static const LinearGradient rrPrimaryGradient = LinearGradient(
    colors: [rrAcc, rrAccGradientEnd],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static BoxDecoration primaryButtonDecoration({
    required bool isDark,
    double borderRadius = 999,
  }) {
    if (isDark) {
      return BoxDecoration(
        color: srAcc,
        borderRadius: BorderRadius.circular(borderRadius),
      );
    }
    return BoxDecoration(
      gradient: rrPrimaryGradient,
      borderRadius: BorderRadius.circular(borderRadius),
    );
  }

  static const Color rrStatusWatchlist = Color(0xFFB0512B);
  static const Color rrStatusSave = Color(0xFFA76A50);
  static const Color rrStatusWatching = Color(0xFF388E6C);
  static const Color rrStatusWatched = Color(0xFF566F86);

  static const Color rrGlow1 = Color(0xFFA76A50);
  static const Color rrGlow2 = Color(0xFFB0512B);
}

class AppThemes {
  static ThemeData get screeningRoomTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.srBase,
      primaryColor: AppColors.srAcc,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.srAcc,
        surface: AppColors.srBase,
        onPrimary: Color(0xFF1A140C),
        onSurface: AppColors.srInk,
        surfaceContainerHighest: AppColors.srCard,
        outline: AppColors.srLineRgba,
      ),
      dividerColor: AppColors.srLineRgba,
      textTheme: _buildTextTheme(AppColors.srInk),
    );
  }

  static ThemeData get readingRoomTheme {
    return ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.rrBase,
      primaryColor: AppColors.rrAcc,
      colorScheme: const ColorScheme.light(
        primary: AppColors.rrAcc,
        surface: AppColors.rrBase,
        onPrimary: Colors.white,
        onSurface: AppColors.rrInk,
        surfaceContainerHighest: AppColors.rrCard,
        outline: AppColors.rrLineRgba,
      ),
      dividerColor: AppColors.rrLineRgba,
      textTheme: _buildTextTheme(AppColors.rrInk),
    );
  }

  static TextTheme _buildTextTheme(Color textColor) {
    return TextTheme(
      displayLarge: GoogleFonts.bodoniModa(
        fontSize: 52,
        fontWeight: FontWeight.w600,
        fontStyle: FontStyle.italic,
        color: textColor,
        height: 1.02,
      ),
      displayMedium: GoogleFonts.bodoniModa(
        fontSize: 30,
        fontWeight: FontWeight.w600,
        fontStyle: FontStyle.italic,
        color: textColor,
        height: 1.05,
      ),
      displaySmall: GoogleFonts.bodoniModa(
        fontSize: 27,
        fontWeight: FontWeight.w600,
        fontStyle: FontStyle.italic,
        color: textColor,
        height: 1.02,
      ),
      headlineLarge: GoogleFonts.bodoniModa(
        fontSize: 21,
        fontWeight: FontWeight.w600,
        fontStyle: FontStyle.italic,
        color: textColor,
      ),
      titleLarge: safeGeist(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: textColor,
      ),
      bodyLarge: safeGeist(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: textColor,
      ),
      bodyMedium: safeGeist(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        color: textColor,
      ),
      bodySmall: safeGeist(
        fontSize: 11,
        fontWeight: FontWeight.w400,
        color: textColor,
      ),
      labelLarge: safeGeist(
        fontSize: 12.5,
        fontWeight: FontWeight.w600,
        color: textColor,
      ),
    );
  }

  static TextStyle safeGeist({
    double? fontSize,
    FontWeight? fontWeight,
    FontStyle? fontStyle,
    Color? color,
    Color? backgroundColor,
    double? letterSpacing,
    double? height,
    TextStyle? textStyle,
  }) {
    try {
      return GoogleFonts.getFont(
        'Geist',
        fontSize: fontSize,
        fontWeight: fontWeight,
        fontStyle: fontStyle,
        color: color,
        backgroundColor: backgroundColor,
        letterSpacing: letterSpacing,
        height: height,
        textStyle: textStyle,
      );
    } catch (_) {
      return GoogleFonts.inter(
        fontSize: fontSize,
        fontWeight: fontWeight,
        fontStyle: fontStyle,
        color: color,
        backgroundColor: backgroundColor,
        letterSpacing: letterSpacing,
        height: height,
        textStyle: textStyle,
      );
    }
  }

  static BoxDecoration screeningRoomBackground() {
    return const BoxDecoration(
      color: AppColors.srBase,
      gradient: RadialGradient(
        center: Alignment(0, -1.16),
        radius: 1.2,
        colors: [
          Color(0xFF241812),
          AppColors.srBase,
        ],
        stops: [0.0, 0.6],
      ),
    );
  }

  static BoxDecoration readingRoomBackground() {
    return const BoxDecoration(
      color: AppColors.rrBase,
      gradient: RadialGradient(
        center: Alignment(0, -1.16),
        radius: 1.2,
        colors: [
          Color(0xFFE8DCC8),
          AppColors.rrBase,
        ],
        stops: [0.0, 0.6],
      ),
    );
  }
}
