import 'package:flutter/material.dart';
import 'themes/typography.dart';

export 'constants/app_physics.dart';
export 'constants/app_status_colors.dart';
export 'themes/ambiance_colors.dart';
export 'themes/app_theme.dart';
export 'themes/theme_registry.dart';
export 'themes/typography.dart';

class AppThemes {
  static TextStyle safeGeist({
    double? fontSize,
    FontWeight? fontWeight,
    FontStyle? fontStyle,
    Color? color,
    Color? backgroundColor,
    double? letterSpacing,
    double? height,
    TextStyle? textStyle,
  }) {
    return safeGeistStyle(
      fontSize: fontSize,
      fontWeight: fontWeight,
      fontStyle: fontStyle,
      color: color,
      backgroundColor: backgroundColor,
      letterSpacing: letterSpacing,
      height: height,
      textStyle: textStyle,
    );
  }
}
