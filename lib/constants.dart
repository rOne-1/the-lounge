import 'package:flutter/material.dart';
import 'themes/typography.dart';

export 'constants/app_physics.dart';
export 'constants/app_status_colors.dart';
export 'constants/app_rating_colors.dart';
export 'themes/ambiance_colors.dart';
export 'themes/app_theme.dart';
export 'themes/theme_registry.dart';
export 'themes/typography.dart';
export 'widgets/signature_motif.dart';

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

  /// Resolves display/headline typography from the active theme's [TextTheme],
  /// applying optional overrides (fontSize, fontWeight, fontStyle, color, height, letterSpacing).
  static TextStyle display(
    BuildContext context, {
    double? fontSize,
    FontWeight? fontWeight,
    FontStyle? fontStyle,
    Color? color,
    double? height,
    double? letterSpacing,
  }) {
    final base = Theme.of(context).textTheme.headlineMedium ?? const TextStyle();
    return base.copyWith(
      fontSize: fontSize,
      fontWeight: fontWeight,
      fontStyle: fontStyle,
      color: color,
      height: height,
      letterSpacing: letterSpacing,
    );
  }
}
