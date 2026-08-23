import 'package:flutter/material.dart';
import 'app_theme.dart';
import 'ambiance_colors.dart';
import 'typography.dart';

const Color _tsBase = Color(0xFF1F161A); // Darkened Voodoo
const Color _tsCard = Color(0xFF45303E); // Voodoo
const Color _tsCard2 = Color(0xFF6A4048); // Vineyard Wine
const Color _tsLineRgba = Color.fromRGBO(243, 230, 224, 0.16);
const Color _tsInk = Color(0xFFF3E6E0);
const Color _tsSub = Color.fromRGBO(243, 230, 224, 0.55);
const Color _tsAcc = Color(0xFFBB8B7A); // Tuscany
const Color _tsOnPrimary = Color(0xFF1F161A);
const Color _tsPh = Color.fromRGBO(243, 230, 224, 0.07);
const Color _tsPill = Color.fromRGBO(243, 230, 224, 0.08);

const Color _tsGlow1 = Color(0xFF966D69); // Clay Ridge
const Color _tsGlow2 = Color(0xFF434252); // Flintstone Blue

const Color _tsStarRating = Color(0xFFE3A458);
const Color _tsSurfaceHighlight = Color.fromRGBO(243, 230, 224, 0.08);
const Color _tsNavBarBg = Color.fromRGBO(31, 22, 26, 0.75);
const Color _tsScrim = Color.fromRGBO(0, 0, 0, 0.85);
const Color _tsDanger = Color(0xFFC1443D);
const Color _tsSuccess = Color(0xFF6B9A6E);

BoxDecoration tuscanyBackground() {
  return const BoxDecoration(
    color: _tsBase,
    gradient: RadialGradient(
      center: Alignment(0, -1.16),
      radius: 1.2,
      colors: [
        Color(0xFF3A2830),
        _tsBase,
      ],
      stops: [0.0, 0.6],
    ),
  );
}

final AmbianceColors tsAmbianceColors = AmbianceColors(
  base: _tsBase,
  card: _tsCard,
  card2: _tsCard2,
  lineRgba: _tsLineRgba,
  ink: _tsInk,
  sub: _tsSub,
  acc: _tsAcc,
  ph: _tsPh,
  pill: _tsPill,
  starRating: _tsStarRating,
  surfaceHighlight: _tsSurfaceHighlight,
  navBarBg: _tsNavBarBg,
  scrim: _tsScrim,
  danger: _tsDanger,
  success: _tsSuccess,
  glow1: _tsGlow1,
  glow2: _tsGlow2,
  background: tuscanyBackground(),
  primaryButtonDecoration: BoxDecoration(
    color: _tsAcc,
    borderRadius: BorderRadius.circular(999),
  ),
  isDark: true,
);

final AppTheme tuscanyTheme = AppTheme(
  id: 'tuscany',
  displayName: 'Tuscany',
  description: 'Sun-baked terracotta and aged wine, cooled by dusk slate.',
  colors: tsAmbianceColors,
  isDark: true,
  themeData: ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: _tsBase,
    primaryColor: _tsAcc,
    colorScheme: const ColorScheme.dark(
      primary: _tsAcc,
      surface: _tsBase,
      onPrimary: _tsOnPrimary,
      onSurface: _tsInk,
      surfaceContainerHighest: _tsCard,
      outline: _tsLineRgba,
    ),
    dividerColor: _tsLineRgba,
    textTheme: buildTextTheme(_tsInk),
    extensions: [tsAmbianceColors],
  ),
);
