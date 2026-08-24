import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_theme.dart';
import 'ambiance_colors.dart';
import 'shadow_tokens.dart';
import 'typography.dart';

const Color _srBase = Color(0xFF171310);
const Color _srCard = Color(0xFF241B15);
const Color _srCard2 = Color(0xFF2C2018);
const Color _srLineRgba = Color.fromRGBO(201, 168, 106, 0.16);
const Color _srInk = Color(0xFFEFE6D8);
const Color _srSub = Color.fromRGBO(239, 230, 216, 0.55);
const Color _srAcc = Color(0xFFCBA86A);
const Color _srPh = Color.fromRGBO(239, 230, 216, 0.07);
const Color _srPill = Color.fromRGBO(239, 230, 216, 0.08);


const Color _srGlow1 = Color(0xFFCBA86A);
const Color _srGlow2 = Color(0xFFD69784);

const Color _srStarRating = Color(0xFFE3B23C);
const Color _srSurfaceHighlight = Color.fromRGBO(255, 244, 230, 0.08);
const Color _srNavBarBg = Color.fromRGBO(23, 19, 16, 0.72);
const Color _srScrim = Color.fromRGBO(0, 0, 0, 0.85);
const Color _srDanger = Color(0xFFD9534F);
const Color _srSuccess = Color(0xFF4C9A6A);

const double _srGrainOpacity = 0.055;
const Color _srGrainTint = Color.fromRGBO(203, 168, 106, 0.30);

final ThemeShadows _srShadows = buildThemeShadows(accent: _srAcc, isDark: true);

BoxDecoration screeningRoomBackground() {
  return const BoxDecoration(
    color: _srBase,
    gradient: RadialGradient(
      center: Alignment(0, -1.16),
      radius: 1.2,
      colors: [
        Color(0xFF241812),
        _srBase,
      ],
      stops: [0.0, 0.6],
    ),
  );
}

final AmbianceColors srAmbianceColors = AmbianceColors(
  base: _srBase,
  card: _srCard,
  card2: _srCard2,
  lineRgba: _srLineRgba,
  ink: _srInk,
  sub: _srSub,
  acc: _srAcc,
  ph: _srPh,
  pill: _srPill,
  starRating: _srStarRating,
  surfaceHighlight: _srSurfaceHighlight,
  navBarBg: _srNavBarBg,
  scrim: _srScrim,
  danger: _srDanger,
  success: _srSuccess,
  glow1: _srGlow1,
  glow2: _srGlow2,
  background: screeningRoomBackground(),
  primaryButtonDecoration: BoxDecoration(
    color: _srAcc,
    borderRadius: BorderRadius.circular(999),
  ),
  grainOpacity: _srGrainOpacity,
  grainTint: _srGrainTint,
  cardShadow: _srShadows.cardShadow,
  ambientGlowShadow: _srShadows.ambientGlowShadow,
  dialogShadow: _srShadows.dialogShadow,
  isDark: true,
);

final AppTheme screeningRoomTheme = AppTheme(
  id: 'screening_room',
  displayName: 'Screening Room',
  description: 'Classic dark theme with warm golden accents.',
  colors: srAmbianceColors,
  isDark: true,
  themeData: ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: _srBase,
    primaryColor: _srAcc,
    colorScheme: const ColorScheme.dark(
      primary: _srAcc,
      surface: _srBase,
      onPrimary: Color(0xFF1A140C),
      onSurface: _srInk,
      surfaceContainerHighest: _srCard,
      outline: _srLineRgba,
    ),
    dividerColor: _srLineRgba,
    textTheme: buildTextTheme(
      textColor: _srInk,
      displayFont: GoogleFonts.fraunces,
      italicDisplay: true,
    ),
    extensions: [srAmbianceColors],
  ),
);
