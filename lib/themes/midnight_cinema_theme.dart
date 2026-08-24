import 'package:flutter/material.dart';
import '../constants.dart';

BoxDecoration midnightCinemaBackground() {
  return const BoxDecoration(
    color: Color(0xFF0A1128),
    gradient: RadialGradient(
      center: Alignment(0, -1.16),
      radius: 1.2,
      colors: [
        Color(0xFF15224D),
        Color(0xFF0A1128),
      ],
      stops: [0.0, 0.6],
    ),
  );
}

final AmbianceColors mcAmbianceColors = AmbianceColors(
  base: const Color(0xFF0A1128),
  card: const Color(0xFF101F42),
  card2: const Color(0xFF1C2E5C),
  lineRgba: const Color.fromRGBO(148, 163, 184, 0.16),
  ink: const Color(0xFFE2E8F0),
  sub: const Color(0xFF94A3B8),
  acc: const Color(0xFF00B4D8),
  ph: const Color.fromRGBO(148, 163, 184, 0.07),
  pill: const Color.fromRGBO(148, 163, 184, 0.08),
  starRating: const Color(0xFFFF4FD8),
  surfaceHighlight: const Color.fromRGBO(226, 232, 240, 0.09),
  navBarBg: const Color.fromRGBO(10, 17, 40, 0.72),
  scrim: const Color.fromRGBO(0, 0, 0, 0.85),
  danger: const Color(0xFFE5383B),
  success: const Color(0xFF06D6A0),
  glow1: const Color(0xFF0096C7),
  glow2: const Color(0xFFD6409F),
  background: midnightCinemaBackground(),
  primaryButtonDecoration: BoxDecoration(
    color: const Color(0xFF00B4D8),
    borderRadius: BorderRadius.circular(999),
  ),
  grainOpacity: 0.035,
  grainTint: const Color.fromRGBO(0, 180, 216, 0.18),
  isDark: true,
);

final AppTheme midnightCinemaTheme = AppTheme(
  id: 'midnight_cinema',
  displayName: 'Midnight Cinema',
  description: 'Deep blue hues with vibrant neon accents.',
  colors: mcAmbianceColors,
  isDark: true,
  themeData: ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: const Color(0xFF0A1128),
    primaryColor: const Color(0xFF00B4D8),
    colorScheme: const ColorScheme.dark(
      primary: Color(0xFF00B4D8),
      surface: Color(0xFF0A1128),
      onPrimary: Color(0xFF000000),
      onSurface: Color(0xFFE2E8F0),
      surfaceContainerHighest: Color(0xFF101F42),
      outline: Color.fromRGBO(148, 163, 184, 0.16),
    ),
    dividerColor: const Color.fromRGBO(148, 163, 184, 0.16),
    textTheme: buildTextTheme(const Color(0xFFE2E8F0)),
    extensions: [mcAmbianceColors],
  ),
);
