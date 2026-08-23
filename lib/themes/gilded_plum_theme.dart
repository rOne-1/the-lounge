import 'package:flutter/material.dart';
import 'app_theme.dart';
import 'ambiance_colors.dart';
import 'typography.dart';

const Color _gpBase = Color(0xFF130A0D); // Ebony
const Color _gpCard = Color(0xFF3F242A); // Tamarind
const Color _gpCard2 = Color(0xFF523344); // Italian Plum
const Color _gpLineRgba = Color.fromRGBO(240, 230, 214, 0.16);
const Color _gpInk = Color(0xFFF0E6D6);
const Color _gpSub = Color.fromRGBO(240, 230, 214, 0.55);
const Color _gpAcc = Color(0xFFA67542); // Hearth Gold
const Color _gpAccGradientEnd = Color(0xFFD19E7C); // Sonora Sahde
const Color _gpOnPrimary = Color(0xFF130A0D);
const Color _gpPh = Color.fromRGBO(240, 230, 214, 0.07);
const Color _gpPill = Color.fromRGBO(240, 230, 214, 0.08);

const Color _gpGlow1 = Color(0xFFD19E7C); // Sonora Sahde
const Color _gpGlow2 = Color(0xFFD4D8A2); // Frappe

const Color _gpStarRating = Color(0xFFD9A94D);
const Color _gpSurfaceHighlight = Color.fromRGBO(240, 230, 214, 0.08);
const Color _gpNavBarBg = Color.fromRGBO(19, 10, 13, 0.75);
const Color _gpScrim = Color.fromRGBO(0, 0, 0, 0.85);
const Color _gpDanger = Color(0xFFA6373A);
const Color _gpSuccess = Color(0xFF8FA06B);

const LinearGradient _gpPrimaryGradient = LinearGradient(
  colors: [_gpAcc, _gpAccGradientEnd],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);

BoxDecoration gildedPlumBackground() {
  return const BoxDecoration(
    color: _gpBase,
    gradient: RadialGradient(
      center: Alignment(0, -1.16),
      radius: 1.2,
      colors: [
        _gpCard2,
        _gpBase,
      ],
      stops: [0.0, 0.6],
    ),
  );
}

final AmbianceColors gpAmbianceColors = AmbianceColors(
  base: _gpBase,
  card: _gpCard,
  card2: _gpCard2,
  lineRgba: _gpLineRgba,
  ink: _gpInk,
  sub: _gpSub,
  acc: _gpAcc,
  ph: _gpPh,
  pill: _gpPill,
  starRating: _gpStarRating,
  surfaceHighlight: _gpSurfaceHighlight,
  navBarBg: _gpNavBarBg,
  scrim: _gpScrim,
  danger: _gpDanger,
  success: _gpSuccess,
  glow1: _gpGlow1,
  glow2: _gpGlow2,
  background: gildedPlumBackground(),
  primaryButtonDecoration: BoxDecoration(
    gradient: _gpPrimaryGradient,
    borderRadius: BorderRadius.circular(999),
  ),
  isDark: true,
);

final AppTheme gildedPlumTheme = AppTheme(
  id: 'gilded_plum',
  displayName: 'Gilded Plum',
  description: 'Jewel-toned plum deepened to black, warmed by bronze and gold.',
  colors: gpAmbianceColors,
  isDark: true,
  themeData: ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: _gpBase,
    primaryColor: _gpAcc,
    colorScheme: const ColorScheme.dark(
      primary: _gpAcc,
      surface: _gpBase,
      onPrimary: _gpOnPrimary,
      onSurface: _gpInk,
      surfaceContainerHighest: _gpCard,
      outline: _gpLineRgba,
    ),
    dividerColor: _gpLineRgba,
    textTheme: buildTextTheme(_gpInk),
    extensions: [gpAmbianceColors],
  ),
);
