import 'package:flutter/material.dart';
import 'ambiance_colors.dart';
import '../constants.dart';


class AppTheme {
  final String id;
  final String displayName;
  final String description;
  final AmbianceColors colors;
  final ThemeData themeData;
  final bool isDark;

  const AppTheme({
    required this.id,
    required this.displayName,
    required this.description,
    required this.colors,
    required this.themeData,
    required this.isDark,
  });
}





