import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

export 'constants/app_physics.dart';
export 'themes/ambiance_colors.dart';
export 'themes/app_theme.dart';
export 'themes/theme_registry.dart';

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

  static const Color srStatusOnHold = Color(0xFFD6A24D);

  static const Color srStatusDropped = Color(0xFFC76464);



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



  
  static const Color rrStatusWatchlist = Color(0xFFB0512B);
  static const Color rrStatusSave = Color(0xFFA76A50);
  static const Color rrStatusWatching = Color(0xFF388E6C);
  static const Color rrStatusWatched = Color(0xFF566F86);
  static const Color rrStatusOnHold = Color(0xFFC5954F);
  static const Color rrStatusDropped = Color(0xFFB55D5D);

  static const Color rrGlow1 = Color(0xFFA76A50);
  static const Color rrGlow2 = Color(0xFFB0512B);

  static const LinearGradient rrPrimaryGradient = LinearGradient(

    colors: [rrAcc, rrAccGradientEnd],

    begin: Alignment.topLeft,

    end: Alignment.bottomRight,

  );

  

  // Violet Dusk Reference Variables

  static const Color vdBase = Color(0xFF1B0B22);

  static const Color vdCard = Color(0xFF502D55);

  static const Color vdInk = Color(0xFFF8F4E9);

  static const Color vdStatusWatchlist = Color(0xFF935073);

  static const Color vdStatusSave = Color(0xFFF6DBC0);

  static const Color vdStatusWatched = Color(0xFF7E9BB5);

  static const Color vdStatusOnHold = Color(0xFFD4B07B);

  static const Color vdStatusDropped = Color(0xFFC57B8A);

  static const Color vdGlow1 = Color(0xFF935073);

  static const Color vdGlow2 = Color(0xFFF6DBC0);

}


class AppThemes {
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

}

  TextTheme buildTextTheme(Color textColor) {

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

      titleLarge: AppThemes.safeGeist(

        fontSize: 15,

        fontWeight: FontWeight.w600,

        color: textColor,

      ),

      bodyLarge: AppThemes.safeGeist(

        fontSize: 14,

        fontWeight: FontWeight.w400,

        color: textColor,

      ),

      bodyMedium: AppThemes.safeGeist(

        fontSize: 13,

        fontWeight: FontWeight.w400,

        color: textColor,

      ),

      bodySmall: AppThemes.safeGeist(

        fontSize: 11,

        fontWeight: FontWeight.w400,

        color: textColor,

      ),

      labelLarge: AppThemes.safeGeist(

        fontSize: 12.5,

        fontWeight: FontWeight.w600,

        color: textColor,

      ),

    );

  }

