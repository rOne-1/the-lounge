import 'package:flutter/material.dart';
import 'app_theme.dart';
import 'ambiance_colors.dart';
import 'typography.dart';

const Color _vdBase = Color(0xFF1B0B22);
const Color _vdCard = Color(0xFF502D55);
const Color _vdCard2 = Color(0xFF5C3560);
const Color _vdInk = Color(0xFFF8F4E9);
const Color _vdGlow1 = Color(0xFFC2528F);
const Color _vdGlow2 = Color(0xFFF4D9E8);
const Color _vdStarRating = Color(0xFFF073B8);
const Color _vdSurfaceHighlight = Color.fromRGBO(248, 244, 233, 0.08);
const Color _vdNavBarBg = Color.fromRGBO(27, 11, 34, 0.75);
const Color _vdScrim = Color.fromRGBO(0, 0, 0, 0.85);
const Color _vdDanger = Color(0xFFD1495B);
const Color _vdSuccess = Color(0xFF3F9A78);

BoxDecoration violetDuskBackground() {
  return const BoxDecoration(
    color: _vdBase,
    gradient: RadialGradient(
      center: Alignment(0, -1.16),
      radius: 1.2,
      colors: [
        Color(0xFF3B1A46),
        _vdBase,
      ],
      stops: [0.0, 0.6],
    ),
  );
}

final AmbianceColors vdAmbianceColors = AmbianceColors(
  base: _vdBase,
  card: _vdCard,
  card2: _vdCard2,
  lineRgba: const Color.fromRGBO(248, 244, 233, 0.16),
  ink: _vdInk,
  sub: const Color.fromRGBO(248, 244, 233, 0.55),
  acc: _vdGlow1,
  ph: const Color.fromRGBO(248, 244, 233, 0.07),
  pill: const Color.fromRGBO(248, 244, 233, 0.08),
  starRating: _vdStarRating,
  surfaceHighlight: _vdSurfaceHighlight,
  navBarBg: _vdNavBarBg,
  scrim: _vdScrim,
  danger: _vdDanger,
  success: _vdSuccess,
  glow1: _vdGlow1,
  glow2: _vdGlow2,
  background: violetDuskBackground(),
  primaryButtonDecoration: BoxDecoration(
    color: _vdGlow1,
    borderRadius: BorderRadius.circular(999),
  ),
  isDark: true,
);

final AppTheme violetDuskTheme = AppTheme(
  id: 'violet_dusk',
  displayName: 'Violet Dusk',
  description: 'Deep purple tones for evening viewing.',
  colors: vdAmbianceColors,
  isDark: true,
  themeData: ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: _vdBase,
    primaryColor: _vdGlow1,
    colorScheme: const ColorScheme.dark(
      primary: _vdGlow1,
      surface: _vdBase,
      onPrimary: Color(0xFF2A0F22),
      onSurface: _vdInk,
      surfaceContainerHighest: _vdCard,
      outline: Color.fromRGBO(248, 244, 233, 0.16),
    ),
    dividerColor: const Color.fromRGBO(248, 244, 233, 0.16),
    textTheme: buildTextTheme(_vdInk),
    extensions: [vdAmbianceColors],
  ),
);
