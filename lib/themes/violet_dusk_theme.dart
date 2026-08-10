import 'package:flutter/material.dart';
import '../constants.dart';
import 'app_theme.dart';

BoxDecoration violetDuskBackground() {
  return const BoxDecoration(
    color: AppColors.vdBase,
    gradient: RadialGradient(
      center: Alignment(0, -1.16),
      radius: 1.2,
      colors: [
        Color(0xFF3B1A46),
        AppColors.vdBase,
      ],
      stops: [0.0, 0.6],
    ),
  );
}

final AmbianceColors vdAmbianceColors = AmbianceColors(
  base: AppColors.vdBase,
  card: AppColors.vdCard,
  card2: AppColors.vdCard,
  lineRgba: const Color.fromRGBO(248, 244, 233, 0.16),
  ink: AppColors.vdInk,
  sub: const Color.fromRGBO(248, 244, 233, 0.55),
  acc: AppColors.vdStatusWatchlist,
  ph: const Color.fromRGBO(248, 244, 233, 0.07),
  pill: const Color.fromRGBO(248, 244, 233, 0.08),
  statusWatchlist: AppColors.vdStatusWatchlist,
  statusSave: AppColors.vdStatusSave,
  statusWatching: AppColors.srStatusWatching,
  statusWatched: AppColors.vdStatusWatched,
  statusOnHold: AppColors.vdStatusOnHold,
  statusDropped: AppColors.vdStatusDropped,
  glow1: AppColors.vdGlow1,
  glow2: AppColors.vdGlow2,
  background: violetDuskBackground(),
  primaryButtonDecoration: BoxDecoration(
    color: AppColors.vdStatusWatchlist,
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
    scaffoldBackgroundColor: AppColors.vdBase,
    primaryColor: AppColors.vdStatusWatchlist,
    colorScheme: const ColorScheme.dark(
      primary: AppColors.vdStatusWatchlist,
      surface: AppColors.vdBase,
      onPrimary: Color(0xFF1A140C),
      onSurface: AppColors.vdInk,
      surfaceContainerHighest: AppColors.vdCard,
      outline: Color.fromRGBO(248, 244, 233, 0.16),
    ),
    dividerColor: const Color.fromRGBO(248, 244, 233, 0.16),
    textTheme: buildTextTheme(AppColors.vdInk),
    extensions: [vdAmbianceColors],
  ),
);
