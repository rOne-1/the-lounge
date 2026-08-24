import 'package:flutter/material.dart';
import 'app_theme.dart';
import 'ambiance_colors.dart';
import 'typography.dart';

const Color _obBase = Color(0xFFF1EDF7); // Moon Pearl
const Color _obCard = Color(0xFFFBF9FD);
const Color _obCard2 = Color(0xFFEFE7F5);
const Color _obLineRgba = Color.fromRGBO(42, 18, 63, 0.16);
const Color _obInk = Color(0xFF2A123F); // Imperial Violet
const Color _obSub = Color.fromRGBO(42, 18, 63, 0.55);
const Color _obAcc = Color(0xFF4B1F6F); // Amethyst Noir
const Color _obAccGradientEnd = Color(0xFF2A123F); // Imperial Violet
const Color _obPh = Color.fromRGBO(42, 18, 63, 0.07);
const Color _obPill = Color.fromRGBO(42, 18, 63, 0.06);

const Color _obGlow1 = Color(0xFFC686DD); // Orchid Smoke
const Color _obGlow2 = Color(0xFF9C8CB9); // Dusted Lavender

const Color _obStarRating = Color(0xFFC9962E);
const Color _obSurfaceHighlight = Color.fromRGBO(255, 255, 255, 0.6);
const Color _obNavBarBg = Color.fromRGBO(251, 249, 253, 0.78);
const Color _obScrim = Color.fromRGBO(0, 0, 0, 0.72);
const Color _obDanger = Color(0xFFB23A5C);
const Color _obSuccess = Color(0xFF3F8F5F);

const double _obGrainOpacity = 0.02;
const Color _obGrainTint = Color.fromRGBO(75, 31, 111, 0.12);

const LinearGradient _obPrimaryGradient = LinearGradient(
  colors: [_obAcc, _obAccGradientEnd],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);

BoxDecoration orchidBloomBackground() {
  return const BoxDecoration(
    color: _obBase,
    gradient: RadialGradient(
      center: Alignment(0, -1.16),
      radius: 1.2,
      colors: [
        Color(0xFFE6D9F0),
        _obBase,
      ],
      stops: [0.0, 0.6],
    ),
  );
}

final AmbianceColors obAmbianceColors = AmbianceColors(
  base: _obBase,
  card: _obCard,
  card2: _obCard2,
  lineRgba: _obLineRgba,
  ink: _obInk,
  sub: _obSub,
  acc: _obAcc,
  ph: _obPh,
  pill: _obPill,
  starRating: _obStarRating,
  surfaceHighlight: _obSurfaceHighlight,
  navBarBg: _obNavBarBg,
  scrim: _obScrim,
  danger: _obDanger,
  success: _obSuccess,
  glow1: _obGlow1,
  glow2: _obGlow2,
  background: orchidBloomBackground(),
  primaryButtonDecoration: BoxDecoration(
    gradient: _obPrimaryGradient,
    borderRadius: BorderRadius.circular(999),
  ),
  grainOpacity: _obGrainOpacity,
  grainTint: _obGrainTint,
  isDark: false,
);

final AppTheme orchidBloomTheme = AppTheme(
  id: 'orchid_bloom',
  displayName: 'Orchid Bloom',
  description: 'Airy lavender and amethyst, for daylight viewing with a violet hush.',
  colors: obAmbianceColors,
  isDark: false,
  themeData: ThemeData(
    brightness: Brightness.light,
    scaffoldBackgroundColor: _obBase,
    primaryColor: _obAcc,
    colorScheme: const ColorScheme.light(
      primary: _obAcc,
      surface: _obBase,
      onPrimary: Colors.white,
      onSurface: _obInk,
      surfaceContainerHighest: _obCard,
      outline: _obLineRgba,
    ),
    dividerColor: _obLineRgba,
    textTheme: buildTextTheme(_obInk),
    extensions: [obAmbianceColors],
  ),
);
