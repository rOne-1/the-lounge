import 'package:flutter/material.dart';
import '../constants.dart';
import 'app_theme.dart';

BoxDecoration screeningRoomBackground() {
  return const BoxDecoration(
    color: AppColors.srBase,
    gradient: RadialGradient(
      center: Alignment(0, -1.16),
      radius: 1.2,
      colors: [
        Color(0xFF241812),
        AppColors.srBase,
      ],
      stops: [0.0, 0.6],
    ),
  );
}

final AmbianceColors srAmbianceColors = AmbianceColors(
  base: AppColors.srBase,
  card: AppColors.srCard,
  card2: AppColors.srCard2,
  lineRgba: AppColors.srLineRgba,
  ink: AppColors.srInk,
  sub: AppColors.srSub,
  acc: AppColors.srAcc,
  ph: AppColors.srPh,
  pill: AppColors.srPill,
  statusWatchlist: AppColors.srStatusWatchlist,
  statusSave: AppColors.srStatusSave,
  statusWatching: AppColors.srStatusWatching,
  statusWatched: AppColors.srStatusWatched,
  statusOnHold: AppColors.srStatusOnHold,
  statusDropped: AppColors.srStatusDropped,
  glow1: AppColors.srGlow1,
  glow2: AppColors.srGlow2,
  background: screeningRoomBackground(),
  primaryButtonDecoration: BoxDecoration(
    color: AppColors.srAcc,
    borderRadius: BorderRadius.circular(999),
  ),
  isDark: true,
);

final AppTheme screeningRoomTheme = AppTheme(
  id: 'screening_room',
  displayName: 'Screening Room',
  description: 'Classic dark theme with warm golden accents.',
  colors: srAmbianceColors,
  isDark: true,
  themeData: ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColors.srBase,
    primaryColor: AppColors.srAcc,
    colorScheme: const ColorScheme.dark(
      primary: AppColors.srAcc,
      surface: AppColors.srBase,
      onPrimary: Color(0xFF1A140C),
      onSurface: AppColors.srInk,
      surfaceContainerHighest: AppColors.srCard,
      outline: AppColors.srLineRgba,
    ),
    dividerColor: AppColors.srLineRgba,
    textTheme: buildTextTheme(AppColors.srInk),
    extensions: [srAmbianceColors],
  ),
);
