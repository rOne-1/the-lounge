import 'package:flutter/material.dart';

import 'package:google_fonts/google_fonts.dart';



export 'constants/app_physics.dart';



enum AmbianceType {

  screeningRoom,

  readingRoom,

  violetDusk,

}



class AmbianceColors extends ThemeExtension<AmbianceColors> {

  final Color base;

  final Color card;

  final Color card2;

  final Color lineRgba;

  final Color ink;

  final Color sub;

  final Color acc;

  final Color ph;

  final Color pill;

  final Color statusWatchlist;

  final Color statusSave;

  final Color statusWatching;

  final Color statusWatched;

  final Color statusOnHold;

  final Color statusDropped;

  final Color glow1;

  final Color glow2;

  final BoxDecoration background;

  final BoxDecoration primaryButtonDecoration;

  final bool isDark;



  const AmbianceColors({

    required this.base,

    required this.card,

    required this.card2,

    required this.lineRgba,

    required this.ink,

    required this.sub,

    required this.acc,

    required this.ph,

    required this.pill,

    required this.statusWatchlist,

    required this.statusSave,

    required this.statusWatching,

    required this.statusWatched,

    required this.statusOnHold,

    required this.statusDropped,

    required this.glow1,

    required this.glow2,

    required this.background,

    required this.primaryButtonDecoration,

    required this.isDark,

  });



  @override

  ThemeExtension<AmbianceColors> copyWith({

    Color? base,

    Color? card,

    Color? card2,

    Color? lineRgba,

    Color? ink,

    Color? sub,

    Color? acc,

    Color? ph,

    Color? pill,

    Color? statusWatchlist,

    Color? statusSave,

    Color? statusWatching,

    Color? statusWatched,

    Color? statusOnHold,

    Color? statusDropped,

    Color? glow1,

    Color? glow2,

    BoxDecoration? background,

    BoxDecoration? primaryButtonDecoration,

    bool? isDark,

  }) {

    return AmbianceColors(

      base: base ?? this.base,

      card: card ?? this.card,

      card2: card2 ?? this.card2,

      lineRgba: lineRgba ?? this.lineRgba,

      ink: ink ?? this.ink,

      sub: sub ?? this.sub,

      acc: acc ?? this.acc,

      ph: ph ?? this.ph,

      pill: pill ?? this.pill,

      statusWatchlist: statusWatchlist ?? this.statusWatchlist,

      statusSave: statusSave ?? this.statusSave,

      statusWatching: statusWatching ?? this.statusWatching,

      statusWatched: statusWatched ?? this.statusWatched,

      statusOnHold: statusOnHold ?? this.statusOnHold,

      statusDropped: statusDropped ?? this.statusDropped,

      glow1: glow1 ?? this.glow1,

      glow2: glow2 ?? this.glow2,

      background: background ?? this.background,

      primaryButtonDecoration: primaryButtonDecoration ?? this.primaryButtonDecoration,

      isDark: isDark ?? this.isDark,

    );

  }



  @override

  ThemeExtension<AmbianceColors> lerp(ThemeExtension<AmbianceColors>? other, double t) {

    if (other is! AmbianceColors) return this;

    return AmbianceColors(

      base: Color.lerp(base, other.base, t)!,

      card: Color.lerp(card, other.card, t)!,

      card2: Color.lerp(card2, other.card2, t)!,

      lineRgba: Color.lerp(lineRgba, other.lineRgba, t)!,

      ink: Color.lerp(ink, other.ink, t)!,

      sub: Color.lerp(sub, other.sub, t)!,

      acc: Color.lerp(acc, other.acc, t)!,

      ph: Color.lerp(ph, other.ph, t)!,

      pill: Color.lerp(pill, other.pill, t)!,

      statusWatchlist: Color.lerp(statusWatchlist, other.statusWatchlist, t)!,

      statusSave: Color.lerp(statusSave, other.statusSave, t)!,

      statusWatching: Color.lerp(statusWatching, other.statusWatching, t)!,

      statusWatched: Color.lerp(statusWatched, other.statusWatched, t)!,

      statusOnHold: Color.lerp(statusOnHold, other.statusOnHold, t)!,

      statusDropped: Color.lerp(statusDropped, other.statusDropped, t)!,

      glow1: Color.lerp(glow1, other.glow1, t)!,

      glow2: Color.lerp(glow2, other.glow2, t)!,

      background: BoxDecoration.lerp(background, other.background, t)!,

      primaryButtonDecoration: BoxDecoration.lerp(primaryButtonDecoration, other.primaryButtonDecoration, t)!,

      isDark: t < 0.5 ? isDark : other.isDark,

    );

  }

}



extension AmbianceThemeExtension on BuildContext {

  AmbianceColors get ambianceColors => Theme.of(this).extension<AmbianceColors>() ?? AppThemes.srAmbianceColors;

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



  static BoxDecoration violetDuskBackground() {

    return const BoxDecoration(

      color: AppColors.vdBase,

      gradient: RadialGradient(

        center: Alignment(0, -1.16),

        radius: 1.2,

        colors: [

          Color(0xFF3B1A46),

          AppColors.vdBase,

        ],

        stops: [0.0, 0.6],

      ),

    );

  }



  static final AmbianceColors srAmbianceColors = AmbianceColors(

    base: AppColors.srBase,

    card: AppColors.srCard,

    card2: AppColors.srCard2,

    lineRgba: AppColors.srLineRgba,

    ink: AppColors.srInk,

    sub: AppColors.srSub,

    acc: AppColors.srAcc,

    ph: AppColors.srPh,

    pill: AppColors.srPill,

    statusWatchlist: AppColors.srStatusWatchlist,

    statusSave: AppColors.srStatusSave,

    statusWatching: AppColors.srStatusWatching,

    statusWatched: AppColors.srStatusWatched,

    statusOnHold: AppColors.srStatusOnHold,

    statusDropped: AppColors.srStatusDropped,

    glow1: AppColors.srGlow1,

    glow2: AppColors.srGlow2,

    background: screeningRoomBackground(),

    primaryButtonDecoration: BoxDecoration(

      color: AppColors.srAcc,

      borderRadius: BorderRadius.circular(999),

    ),

    isDark: true,

  );



  static final AmbianceColors rrAmbianceColors = AmbianceColors(

    base: AppColors.rrBase,

    card: AppColors.rrCard,

    card2: AppColors.rrCard2,

    lineRgba: AppColors.rrLineRgba,

    ink: AppColors.rrInk,

    sub: AppColors.rrSub,

    acc: AppColors.rrAcc,

    ph: AppColors.rrPh,

    pill: AppColors.rrPill,

    statusWatchlist: AppColors.rrStatusWatchlist,

    statusSave: AppColors.rrStatusSave,

    statusWatching: AppColors.rrStatusWatching,

    statusWatched: AppColors.rrStatusWatched,

    statusOnHold: AppColors.rrStatusOnHold,

    statusDropped: AppColors.rrStatusDropped,

    glow1: AppColors.rrGlow1,

    glow2: AppColors.rrGlow2,

    background: readingRoomBackground(),

    primaryButtonDecoration: BoxDecoration(

      gradient: AppColors.rrPrimaryGradient,

      borderRadius: BorderRadius.circular(999),

    ),

    isDark: false,

  );



  static final AmbianceColors vdAmbianceColors = AmbianceColors(

    base: AppColors.vdBase,

    card: AppColors.vdCard,

    card2: AppColors.vdCard, // reuse card

    lineRgba: const Color.fromRGBO(248, 244, 233, 0.16),

    ink: AppColors.vdInk,

    sub: const Color.fromRGBO(248, 244, 233, 0.55),

    acc: AppColors.vdStatusWatchlist,

    ph: const Color.fromRGBO(248, 244, 233, 0.07),

    pill: const Color.fromRGBO(248, 244, 233, 0.08),

    statusWatchlist: AppColors.vdStatusWatchlist,

    statusSave: AppColors.vdStatusSave,

    statusWatching: AppColors.srStatusWatching, // fallback

    statusWatched: AppColors.vdStatusWatched,

    statusOnHold: AppColors.vdStatusOnHold,

    statusDropped: AppColors.vdStatusDropped,

    glow1: AppColors.vdGlow1,

    glow2: AppColors.vdGlow2,

    background: violetDuskBackground(),

    primaryButtonDecoration: BoxDecoration(

      color: AppColors.vdStatusWatchlist,

      borderRadius: BorderRadius.circular(999),

    ),

    isDark: true,

  );



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

      extensions: [srAmbianceColors],

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

      extensions: [rrAmbianceColors],

    );

  }



  static ThemeData get violetDuskTheme {

    return ThemeData(

      brightness: Brightness.dark,

      scaffoldBackgroundColor: AppColors.vdBase,

      primaryColor: AppColors.vdStatusWatchlist,

      colorScheme: const ColorScheme.dark(

        primary: AppColors.vdStatusWatchlist,

        surface: AppColors.vdBase,

        onPrimary: Color(0xFF1A140C),

        onSurface: AppColors.vdInk,

        surfaceContainerHighest: AppColors.vdCard,

        outline: Color.fromRGBO(248, 244, 233, 0.16),

      ),

      dividerColor: const Color.fromRGBO(248, 244, 233, 0.16),

      textTheme: _buildTextTheme(AppColors.vdInk),

      extensions: [vdAmbianceColors],

    );

  }



  static ThemeData theme(AmbianceType type) {

    switch (type) {

      case AmbianceType.screeningRoom:

        return screeningRoomTheme;

      case AmbianceType.readingRoom:

        return readingRoomTheme;

      case AmbianceType.violetDusk:

        return violetDuskTheme;

    }

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

}

