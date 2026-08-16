import 'package:flutter/material.dart';
import 'app_theme.dart';
import 'ambiance_colors.dart';
import 'typography.dart';

const Color _acBase = Color(0xFF1A2A21); // Deep Pine Dark
const Color _acCard = Color(0xFF2F483A); // Deep Pine Main
const Color _acCard2 = Color(0xFF4A6B58); // Deep Pine Light
const Color _acLineRgba = Color.fromRGBO(245, 243, 233, 0.16); // Frost/Snow with opacity
const Color _acInk = Color(0xFFF5F3E9); // Snow / Inverse Text
const Color _acSub = Color.fromRGBO(245, 243, 233, 0.55);
const Color _acAcc = Color(0xFFB85C38); // Ember / Hearth Warmth
const Color _acPh = Color.fromRGBO(245, 243, 233, 0.07);
const Color _acPill = Color.fromRGBO(245, 243, 233, 0.08);


const Color _acGlow1 = Color(0xFFB85C38);
const Color _acGlow2 = Color(0xFFE24E1B);

const Color _acStarRating = Color(0xFFE0A94A);
const Color _acSurfaceHighlight = Color.fromRGBO(245, 243, 233, 0.08);
const Color _acNavBarBg = Color.fromRGBO(26, 42, 33, 0.75);
const Color _acScrim = Color.fromRGBO(0, 0, 0, 0.85);
const Color _acDanger = Color(0xFFB33F2E);
const Color _acSuccess = Color(0xFF5E8F6F);

BoxDecoration alpineChaletBackground() {
  return const BoxDecoration(
    color: _acBase,
    gradient: RadialGradient(
      center: Alignment(0, -1.16),
      radius: 1.2,
      colors: [
        Color(0xFF2F483A),
        _acBase,
      ],
      stops: [0.0, 0.6],
    ),
  );
}

final AmbianceColors acAmbianceColors = AmbianceColors(
  base: _acBase,
  card: _acCard,
  card2: _acCard2,
  lineRgba: _acLineRgba,
  ink: _acInk,
  sub: _acSub,
  acc: _acAcc,
  ph: _acPh,
  pill: _acPill,
  starRating: _acStarRating,
  surfaceHighlight: _acSurfaceHighlight,
  navBarBg: _acNavBarBg,
  scrim: _acScrim,
  danger: _acDanger,
  success: _acSuccess,
  glow1: _acGlow1,
  glow2: _acGlow2,
  background: alpineChaletBackground(),
  primaryButtonDecoration: BoxDecoration(
    color: _acAcc,
    borderRadius: BorderRadius.circular(999),
  ),
  isDark: true,
);

final AppTheme alpineChaletTheme = AppTheme(
  id: 'alpine_chalet',
  displayName: 'Alpine',
  description: 'Cozy, relaxed, and warm. Deep pine and slate accented by hearth fire hues.',
  colors: acAmbianceColors,
  isDark: true,
  themeData: ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: _acBase,
    primaryColor: _acAcc,
    colorScheme: const ColorScheme.dark(
      primary: _acAcc,
      surface: _acBase,
      onPrimary: Color(0xFFF5F3E9),
      onSurface: _acInk,
      surfaceContainerHighest: _acCard,
      outline: _acLineRgba,
    ),
    dividerColor: _acLineRgba,
    textTheme: buildTextTheme(_acInk),
    extensions: [acAmbianceColors],
  ),
);