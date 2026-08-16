import 'package:flutter/material.dart';
import 'app_theme.dart';
import 'ambiance_colors.dart';
import 'typography.dart';

const Color _ccBase = Color(0xFF1E1A17); // Dark Chocolate
const Color _ccCard = Color(0xFF452F23); // Espresso Martini 
const Color _ccCard2 = Color(0xFF7B5A44); // Mocha Latte
const Color _ccLineRgba = Color.fromRGBO(203, 182, 154, 0.16); // Crème Brulee with opacity
const Color _ccInk = Color(0xFFCBB69A); // Crème Brulee
const Color _ccSub = Color.fromRGBO(203, 182, 154, 0.55);
const Color _ccAcc = Color(0xFFD4A373); // Rich caramel accent for interactive elements
const Color _ccPh = Color.fromRGBO(203, 182, 154, 0.07);
const Color _ccPill = Color.fromRGBO(203, 182, 154, 0.08);


const Color _ccGlow1 = Color(0xFFCBB69A);
const Color _ccGlow2 = Color(0xFF7B5A44);

const Color _ccStarRating = Color(0xFFE8B04B);
const Color _ccSurfaceHighlight = Color.fromRGBO(255, 244, 230, 0.08);
const Color _ccNavBarBg = Color.fromRGBO(30, 26, 23, 0.75);
const Color _ccScrim = Color.fromRGBO(0, 0, 0, 0.85);
const Color _ccDanger = Color(0xFFC1272D);
const Color _ccSuccess = Color(0xFF6FA98C);

BoxDecoration cafeCalmBackground() {
  return const BoxDecoration(
    color: _ccBase,
    gradient: RadialGradient(
      center: Alignment(0, -1.16),
      radius: 1.2,
      colors: [
        Color(0xFF452F23), // Espresso Martini center
        _ccBase,           // Fading out to Dark Chocolate
      ],
      stops: [0.0, 0.6],
    ),
  );
}

final AmbianceColors ccAmbianceColors = AmbianceColors(
  base: _ccBase,
  card: _ccCard,
  card2: _ccCard2,
  lineRgba: _ccLineRgba,
  ink: _ccInk,
  sub: _ccSub,
  acc: _ccAcc,
  ph: _ccPh,
  pill: _ccPill,
  starRating: _ccStarRating,
  surfaceHighlight: _ccSurfaceHighlight,
  navBarBg: _ccNavBarBg,
  scrim: _ccScrim,
  danger: _ccDanger,
  success: _ccSuccess,
  glow1: _ccGlow1,
  glow2: _ccGlow2,
  background: cafeCalmBackground(),
  primaryButtonDecoration: BoxDecoration(
    color: _ccAcc,
    borderRadius: BorderRadius.circular(999),
  ),
  isDark: true,
);

final AppTheme cafeCalmTheme = AppTheme(
  id: 'cafe_calm',
  displayName: 'Café Calm',
  description: 'A rich, dark aesthetic inspired by a warm morning coffee routine.',
  colors: ccAmbianceColors,
  isDark: true,
  themeData: ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: _ccBase,
    primaryColor: _ccAcc,
    colorScheme: const ColorScheme.dark(
      primary: _ccAcc,
      surface: _ccBase,
      onPrimary: Color(0xFF1E1A17),
      onSurface: _ccInk,
      surfaceContainerHighest: _ccCard,
      outline: _ccLineRgba,
    ),
    dividerColor: _ccLineRgba,
    textTheme: buildTextTheme(_ccInk),
    extensions: [ccAmbianceColors],
  ),
);