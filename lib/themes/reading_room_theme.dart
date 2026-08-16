import 'package:flutter/material.dart';
import 'app_theme.dart';
import 'ambiance_colors.dart';
import 'typography.dart';

const Color _rrBase = Color(0xFFEFE6D5);
const Color _rrCard = Color(0xFFF6EFE1);
const Color _rrCard2 = Color(0xFFF2E9D8);
const Color _rrLineRgba = Color.fromRGBO(160, 74, 42, 0.16);
const Color _rrInk = Color(0xFF2C2016);
const Color _rrSub = Color(0xFF5C4C3D);
const Color _rrAcc = Color(0xFFB0512B);
const Color _rrAccGradientEnd = Color(0xFF8F3E1E);
const Color _rrPh = Color.fromRGBO(44, 32, 22, 0.07);
const Color _rrPill = Color.fromRGBO(44, 32, 22, 0.06);

const Color _rrStatusWatchlist = Color(0xFFB0512B);
const Color _rrStatusSave = Color(0xFFA76A50);
const Color _rrStatusWatching = Color(0xFF388E6C);
const Color _rrStatusWatched = Color(0xFF566F86);
const Color _rrStatusOnHold = Color(0xFFC5954F);
const Color _rrStatusDropped = Color(0xFFB55D5D);

const Color _rrGlow1 = Color(0xFFA76A50);
const Color _rrGlow2 = Color(0xFFB0512B);

const Color _rrStatusSkip = Color(0xFF9C8E7A);
const Color _rrStarRating = Color(0xFFC98A2C);
const Color _rrSurfaceHighlight = Color.fromRGBO(255, 255, 255, 0.55);
const Color _rrNavBarBg = Color.fromRGBO(246, 239, 225, 0.78);
const Color _rrScrim = Color.fromRGBO(0, 0, 0, 0.72);
const Color _rrDanger = Color(0xFFB3413B);
const Color _rrSuccess = Color(0xFF2F7A57);

const LinearGradient _rrPrimaryGradient = LinearGradient(
  colors: [_rrAcc, _rrAccGradientEnd],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);

BoxDecoration readingRoomBackground() {
  return const BoxDecoration(
    color: _rrBase,
    gradient: RadialGradient(
      center: Alignment(0, -1.16),
      radius: 1.2,
      colors: [
        Color(0xFFE8DCC8),
        _rrBase,
      ],
      stops: [0.0, 0.6],
    ),
  );
}

final AmbianceColors rrAmbianceColors = AmbianceColors(
  base: _rrBase,
  card: _rrCard,
  card2: _rrCard2,
  lineRgba: _rrLineRgba,
  ink: _rrInk,
  sub: _rrSub,
  acc: _rrAcc,
  ph: _rrPh,
  pill: _rrPill,
  statusWatchlist: _rrStatusWatchlist,
  statusSave: _rrStatusSave,
  statusWatching: _rrStatusWatching,
  statusWatched: _rrStatusWatched,
  statusOnHold: _rrStatusOnHold,
  statusDropped: _rrStatusDropped,
  statusSkip: _rrStatusSkip,
  starRating: _rrStarRating,
  surfaceHighlight: _rrSurfaceHighlight,
  navBarBg: _rrNavBarBg,
  scrim: _rrScrim,
  danger: _rrDanger,
  success: _rrSuccess,
  glow1: _rrGlow1,
  glow2: _rrGlow2,
  background: readingRoomBackground(),
  primaryButtonDecoration: BoxDecoration(
    gradient: _rrPrimaryGradient,
    borderRadius: BorderRadius.circular(999),
  ),
  isDark: false,
);

final AppTheme readingRoomTheme = AppTheme(
  id: 'reading_room',
  displayName: 'Reading Room',
  description: 'Bright light theme for reading.',
  colors: rrAmbianceColors,
  isDark: false,
  themeData: ThemeData(
    brightness: Brightness.light,
    scaffoldBackgroundColor: _rrBase,
    primaryColor: _rrAcc,
    colorScheme: const ColorScheme.light(
      primary: _rrAcc,
      surface: _rrBase,
      onPrimary: Colors.white,
      onSurface: _rrInk,
      surfaceContainerHighest: _rrCard,
      outline: _rrLineRgba,
    ),
    dividerColor: _rrLineRgba,
    textTheme: buildTextTheme(_rrInk),
    extensions: [rrAmbianceColors],
  ),
);
