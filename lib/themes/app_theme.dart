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

  /// THEME-DEPTH-4: Bespoke signature decorative motif builder for this theme.
  final WidgetBuilder? signatureMotif;

  const AppTheme({
    required this.id,
    required this.displayName,
    required this.description,
    required this.colors,
    required this.themeData,
    required this.isDark,
    this.signatureMotif,
  });
}





