import 'package:flutter/material.dart';
import '../constants.dart';
import 'app_theme.dart';

BoxDecoration readingRoomBackground() {
  return const BoxDecoration(
    color: AppColors.rrBase,
    gradient: RadialGradient(
      center: Alignment(0, -1.16),
      radius: 1.2,
      colors: [
        Color(0xFFE8DCC8),
        AppColors.rrBase,
      ],
      stops: [0.0, 0.6],
    ),
  );
}

final AmbianceColors rrAmbianceColors = AmbianceColors(
  base: AppColors.rrBase,
  card: AppColors.rrCard,
  card2: AppColors.rrCard2,
  lineRgba: AppColors.rrLineRgba,
  ink: AppColors.rrInk,
  sub: AppColors.rrSub,
  acc: AppColors.rrAcc,
  ph: AppColors.rrPh,
  pill: AppColors.rrPill,
  statusWatchlist: AppColors.rrStatusWatchlist,
  statusSave: AppColors.rrStatusSave,
  statusWatching: AppColors.rrStatusWatching,
  statusWatched: AppColors.rrStatusWatched,
  statusOnHold: AppColors.rrStatusOnHold,
  statusDropped: AppColors.rrStatusDropped,
  glow1: AppColors.rrGlow1,
  glow2: AppColors.rrGlow2,
  background: readingRoomBackground(),
  primaryButtonDecoration: BoxDecoration(
    gradient: AppColors.rrPrimaryGradient,
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
    scaffoldBackgroundColor: AppColors.rrBase,
    primaryColor: AppColors.rrAcc,
    colorScheme: const ColorScheme.light(
      primary: AppColors.rrAcc,
      surface: AppColors.rrBase,
      onPrimary: Colors.white,
      onSurface: AppColors.rrInk,
      surfaceContainerHighest: AppColors.rrCard,
      outline: AppColors.rrLineRgba,
    ),
    dividerColor: AppColors.rrLineRgba,
    textTheme: buildTextTheme(AppColors.rrInk),
    extensions: [rrAmbianceColors],
  ),
);
