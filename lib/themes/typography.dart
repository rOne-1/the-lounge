import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

typedef FontBuilder = TextStyle Function({
  TextStyle? textStyle,
  Color? color,
  Color? backgroundColor,
  double? fontSize,
  FontWeight? fontWeight,
  FontStyle? fontStyle,
  double? letterSpacing,
  double? wordSpacing,
  TextBaseline? textBaseline,
  double? height,
  Locale? locale,
  Paint? foreground,
  Paint? background,
  List<Shadow>? shadows,
  List<FontFeature>? fontFeatures,
  TextDecoration? decoration,
  Color? decorationColor,
  TextDecorationStyle? decorationStyle,
  double? decorationThickness,
});

TextStyle safeGeistStyle({
  TextStyle? textStyle,
  Color? color,
  Color? backgroundColor,
  double? fontSize,
  FontWeight? fontWeight,
  FontStyle? fontStyle,
  double? letterSpacing,
  double? wordSpacing,
  TextBaseline? textBaseline,
  double? height,
  Locale? locale,
  Paint? foreground,
  Paint? background,
  List<Shadow>? shadows,
  List<FontFeature>? fontFeatures,
  TextDecoration? decoration,
  Color? decorationColor,
  TextDecorationStyle? decorationStyle,
  double? decorationThickness,
}) {
  try {
    return GoogleFonts.getFont(
      'Geist',
      textStyle: textStyle,
      color: color,
      backgroundColor: backgroundColor,
      fontSize: fontSize,
      fontWeight: fontWeight,
      fontStyle: fontStyle,
      letterSpacing: letterSpacing,
      wordSpacing: wordSpacing,
      textBaseline: textBaseline,
      height: height,
      locale: locale,
      foreground: foreground,
      background: background,
      shadows: shadows,
      fontFeatures: fontFeatures,
      decoration: decoration,
      decorationColor: decorationColor,
      decorationStyle: decorationStyle,
      decorationThickness: decorationThickness,
    );
  } catch (_) {
    return GoogleFonts.inter(
      textStyle: textStyle,
      color: color,
      backgroundColor: backgroundColor,
      fontSize: fontSize,
      fontWeight: fontWeight,
      fontStyle: fontStyle,
      letterSpacing: letterSpacing,
      wordSpacing: wordSpacing,
      textBaseline: textBaseline,
      height: height,
      locale: locale,
      foreground: foreground,
      background: background,
      shadows: shadows,
      fontFeatures: fontFeatures,
      decoration: decoration,
      decorationColor: decorationColor,
      decorationStyle: decorationStyle,
      decorationThickness: decorationThickness,
    );
  }
}

/// THEME-DEPTH-1: Builds a standard Flutter [TextTheme] adhering strictly to
/// standard typography hierarchy contracts while rendering each theme's
/// distinctive typographical personality (e.g. Fraunces italic for Screening Room,
/// Bricolage Grotesque for Midnight Cinema, Cormorant Garamond for Orchid Bloom,
/// Playfair Display for Violet Dusk, Lora for Tuscany).
TextTheme buildTextTheme({
  required Color textColor,
  required FontBuilder displayFont,
  FontBuilder? bodyFont,
  bool italicDisplay = false,
}) {
  final body = bodyFont ?? safeGeistStyle;
  final displayStyle = italicDisplay ? FontStyle.italic : FontStyle.normal;

  return TextTheme(
    displayLarge: displayFont(
      fontSize: 52,
      fontWeight: FontWeight.w600,
      fontStyle: displayStyle,
      color: textColor,
      height: 1.02,
    ),
    displayMedium: displayFont(
      fontSize: 30,
      fontWeight: FontWeight.w600,
      fontStyle: displayStyle,
      color: textColor,
      height: 1.05,
    ),
    displaySmall: displayFont(
      fontSize: 27,
      fontWeight: FontWeight.w600,
      fontStyle: displayStyle,
      color: textColor,
      height: 1.02,
    ),
    headlineLarge: displayFont(
      fontSize: 21,
      fontWeight: FontWeight.w600,
      fontStyle: displayStyle,
      color: textColor,
    ),
    headlineMedium: displayFont(
      fontSize: 18,
      fontWeight: FontWeight.w600,
      fontStyle: displayStyle,
      color: textColor,
    ),
    headlineSmall: displayFont(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      fontStyle: displayStyle,
      color: textColor,
    ),
    titleLarge: body(
      fontSize: 15,
      fontWeight: FontWeight.w600,
      color: textColor,
    ),
    titleMedium: body(
      fontSize: 14,
      fontWeight: FontWeight.w600,
      color: textColor,
    ),
    titleSmall: body(
      fontSize: 13,
      fontWeight: FontWeight.w600,
      color: textColor,
    ),
    bodyLarge: body(
      fontSize: 14,
      fontWeight: FontWeight.w400,
      color: textColor,
    ),
    bodyMedium: body(
      fontSize: 13,
      fontWeight: FontWeight.w400,
      color: textColor,
    ),
    bodySmall: body(
      fontSize: 11,
      fontWeight: FontWeight.w400,
      color: textColor,
    ),
    labelLarge: body(
      fontSize: 12.5,
      fontWeight: FontWeight.w600,
      color: textColor,
    ),
    labelMedium: body(
      fontSize: 11.5,
      fontWeight: FontWeight.w600,
      color: textColor,
    ),
    labelSmall: body(
      fontSize: 10.5,
      fontWeight: FontWeight.w600,
      color: textColor,
    ),
  );
}
