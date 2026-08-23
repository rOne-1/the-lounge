import 'package:flutter/material.dart';
import 'app_theme.dart';
import 'ambiance_colors.dart';
import 'typography.dart';

const Color _rvBase = Color(0xFFEAF4F2); // Pale seafoam
const Color _rvCard = Color(0xFFF7FCFB); // Near-white mint
const Color _rvCard2 = Color(0xFFF7E4DE); // Pale peach-pink
const Color _rvLineRgba = Color.fromRGBO(18, 50, 56, 0.16);
const Color _rvInk = Color(0xFF123238); // Deep navy-teal
const Color _rvSub = Color.fromRGBO(18, 50, 56, 0.55);
const Color _rvAcc = Color(0xFFDD6A50); // Coral
const Color _rvAccGradientEnd = Color(0xFFE8899E); // Blush pink
const Color _rvOnPrimary = Color(0xFF0B1E21);
const Color _rvPh = Color.fromRGBO(18, 50, 56, 0.07);
const Color _rvPill = Color.fromRGBO(18, 50, 56, 0.06);

const Color _rvGlow1 = Color(0xFF3F9C94); // Teal
const Color _rvGlow2 = Color(0xFFE8899E); // Blush pink

const Color _rvStarRating = Color(0xFFE0A93E);
const Color _rvSurfaceHighlight = Color.fromRGBO(255, 255, 255, 0.6);
const Color _rvNavBarBg = Color.fromRGBO(247, 252, 251, 0.78);
const Color _rvScrim = Color.fromRGBO(0, 0, 0, 0.72);
const Color _rvDanger = Color(0xFFC23B4A);
const Color _rvSuccess = Color(0xFF4C9A5C);

const LinearGradient _rvPrimaryGradient = LinearGradient(
  colors: [_rvAcc, _rvAccGradientEnd],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);

BoxDecoration rivieraBackground() {
  return const BoxDecoration(
    color: _rvBase,
    gradient: RadialGradient(
      center: Alignment(0, -1.16),
      radius: 1.2,
      colors: [
        Color(0xFFD3EDE7),
        _rvBase,
      ],
      stops: [0.0, 0.6],
    ),
  );
}

final AmbianceColors rvAmbianceColors = AmbianceColors(
  base: _rvBase,
  card: _rvCard,
  card2: _rvCard2,
  lineRgba: _rvLineRgba,
  ink: _rvInk,
  sub: _rvSub,
  acc: _rvAcc,
  ph: _rvPh,
  pill: _rvPill,
  starRating: _rvStarRating,
  surfaceHighlight: _rvSurfaceHighlight,
  navBarBg: _rvNavBarBg,
  scrim: _rvScrim,
  danger: _rvDanger,
  success: _rvSuccess,
  glow1: _rvGlow1,
  glow2: _rvGlow2,
  background: rivieraBackground(),
  primaryButtonDecoration: BoxDecoration(
    gradient: _rvPrimaryGradient,
    borderRadius: BorderRadius.circular(999),
  ),
  isDark: false,
);

final AppTheme rivieraTheme = AppTheme(
  id: 'riviera',
  displayName: 'Riviera',
  description: 'A fresh coastal palette of teal, coral, and blush pink for daylight viewing.',
  colors: rvAmbianceColors,
  isDark: false,
  themeData: ThemeData(
    brightness: Brightness.light,
    scaffoldBackgroundColor: _rvBase,
    primaryColor: _rvAcc,
    colorScheme: const ColorScheme.light(
      primary: _rvAcc,
      surface: _rvBase,
      onPrimary: _rvOnPrimary,
      onSurface: _rvInk,
      surfaceContainerHighest: _rvCard,
      outline: _rvLineRgba,
    ),
    dividerColor: _rvLineRgba,
    textTheme: buildTextTheme(_rvInk),
    extensions: [rvAmbianceColors],
  ),
);
