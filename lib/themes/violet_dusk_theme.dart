import 'package:flutter/material.dart';
import 'app_theme.dart';
import 'ambiance_colors.dart';
import 'typography.dart';

const Color _vdBase = Color(0xFF1B0B22);
const Color _vdCard = Color(0xFF502D55);
const Color _vdInk = Color(0xFFF8F4E9);
const Color _vdStatusWatchlist = Color(0xFF935073);
const Color _vdStatusSave = Color(0xFFF6DBC0);
const Color _vdStatusWatched = Color(0xFF7E9BB5);
const Color _vdStatusOnHold = Color(0xFFD4B07B);
const Color _vdStatusDropped = Color(0xFFC57B8A);
const Color _vdGlow1 = Color(0xFF935073);
const Color _vdGlow2 = Color(0xFFF6DBC0);
const Color _vdStatusWatching = Color(0xFF62A87C);
const Color _vdStatusSkip = Color(0xFF7D6E85);
const Color _vdStarRating = Color(0xFFE8B04B);
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
  card2: _vdCard,
  lineRgba: const Color.fromRGBO(248, 244, 233, 0.16),
  ink: _vdInk,
  sub: const Color.fromRGBO(248, 244, 233, 0.55),
  acc: _vdStatusWatchlist,
  ph: const Color.fromRGBO(248, 244, 233, 0.07),
  pill: const Color.fromRGBO(248, 244, 233, 0.08),
  statusWatchlist: _vdStatusWatchlist,
  statusSave: _vdStatusSave,
  statusWatching: _vdStatusWatching,
  statusWatched: _vdStatusWatched,
  statusOnHold: _vdStatusOnHold,
  statusDropped: _vdStatusDropped,
  statusSkip: _vdStatusSkip,
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
    color: _vdStatusWatchlist,
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
    primaryColor: _vdStatusWatchlist,
    colorScheme: const ColorScheme.dark(
      primary: _vdStatusWatchlist,
      surface: _vdBase,
      onPrimary: Color(0xFF1A140C),
      onSurface: _vdInk,
      surfaceContainerHighest: _vdCard,
      outline: Color.fromRGBO(248, 244, 233, 0.16),
    ),
    dividerColor: const Color.fromRGBO(248, 244, 233, 0.16),
    textTheme: buildTextTheme(_vdInk),
    extensions: [vdAmbianceColors],
  ),
);
