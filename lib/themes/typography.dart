import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

TextStyle safeGeistStyle({
  double? fontSize,
  FontWeight? fontWeight,
  FontStyle? fontStyle,
  Color? color,
  Color? backgroundColor,
  double? letterSpacing,
  double? height,
  TextStyle? textStyle,
}) {
  try {
    return GoogleFonts.getFont(
      'Geist',
      fontSize: fontSize,
      fontWeight: fontWeight,
      fontStyle: fontStyle,
      color: color,
      backgroundColor: backgroundColor,
      letterSpacing: letterSpacing,
      height: height,
      textStyle: textStyle,
    );
  } catch (_) {
    return GoogleFonts.inter(
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

TextTheme buildTextTheme(Color textColor) {
  return TextTheme(
    displayLarge: GoogleFonts.bodoniModa(
      fontSize: 52,
      fontWeight: FontWeight.w600,
      fontStyle: FontStyle.italic,
      color: textColor,
      height: 1.02,
    ),
    displayMedium: GoogleFonts.bodoniModa(
      fontSize: 30,
      fontWeight: FontWeight.w600,
      fontStyle: FontStyle.italic,
      color: textColor,
      height: 1.05,
    ),
    displaySmall: GoogleFonts.bodoniModa(
      fontSize: 27,
      fontWeight: FontWeight.w600,
      fontStyle: FontStyle.italic,
      color: textColor,
      height: 1.02,
    ),
    headlineLarge: GoogleFonts.bodoniModa(
      fontSize: 21,
      fontWeight: FontWeight.w600,
      fontStyle: FontStyle.italic,
      color: textColor,
    ),
    titleLarge: safeGeistStyle(
      fontSize: 15,
      fontWeight: FontWeight.w600,
      color: textColor,
    ),
    bodyLarge: safeGeistStyle(
      fontSize: 14,
      fontWeight: FontWeight.w400,
      color: textColor,
    ),
    bodyMedium: safeGeistStyle(
      fontSize: 13,
      fontWeight: FontWeight.w400,
      color: textColor,
    ),
    bodySmall: safeGeistStyle(
      fontSize: 11,
      fontWeight: FontWeight.w400,
      color: textColor,
    ),
    labelLarge: safeGeistStyle(
      fontSize: 12.5,
      fontWeight: FontWeight.w600,
      color: textColor,
    ),
  );
}
