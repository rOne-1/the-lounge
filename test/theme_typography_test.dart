import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:the_lounge/themes/typography.dart';
import 'package:the_lounge/themes/screening_room_theme.dart';
import 'package:the_lounge/themes/midnight_cinema_theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('THEME-DEPTH-1: buildTextTheme contract compliance', () {
    test('buildTextTheme populates all 15 TextTheme styles with exact typography hierarchy', () {
      final textTheme = buildTextTheme(
        textColor: const Color(0xFFFFFFFF),
        displayFont: ({TextStyle? textStyle, Color? color, Color? backgroundColor, double? fontSize, FontWeight? fontWeight, FontStyle? fontStyle, double? letterSpacing, double? wordSpacing, TextBaseline? textBaseline, double? height, Locale? locale, Paint? foreground, Paint? background, List<Shadow>? shadows, List<FontFeature>? fontFeatures, TextDecoration? decoration, Color? decorationColor, TextDecorationStyle? decorationStyle, double? decorationThickness}) =>
            TextStyle(
              fontFamily: 'TestDisplayFont',
              fontSize: fontSize,
              fontWeight: fontWeight,
              fontStyle: fontStyle,
              color: color,
              height: height,
            ),
        bodyFont: ({TextStyle? textStyle, Color? color, Color? backgroundColor, double? fontSize, FontWeight? fontWeight, FontStyle? fontStyle, double? letterSpacing, double? wordSpacing, TextBaseline? textBaseline, double? height, Locale? locale, Paint? foreground, Paint? background, List<Shadow>? shadows, List<FontFeature>? fontFeatures, TextDecoration? decoration, Color? decorationColor, TextDecorationStyle? decorationStyle, double? decorationThickness}) =>
            TextStyle(
              fontFamily: 'TestBodyFont',
              fontSize: fontSize,
              fontWeight: fontWeight,
              fontStyle: fontStyle,
              color: color,
            ),
        italicDisplay: true,
      );

      expect(textTheme.displayLarge, isNotNull);
      expect(textTheme.displayLarge?.fontFamily, 'TestDisplayFont');
      expect(textTheme.displayLarge?.fontStyle, FontStyle.italic);
      expect(textTheme.displayLarge?.fontSize, 52);

      expect(textTheme.displayMedium?.fontFamily, 'TestDisplayFont');
      expect(textTheme.displayMedium?.fontStyle, FontStyle.italic);
      expect(textTheme.displayMedium?.fontSize, 30);

      expect(textTheme.displaySmall?.fontFamily, 'TestDisplayFont');
      expect(textTheme.displaySmall?.fontSize, 27);

      expect(textTheme.headlineLarge?.fontSize, 21);
      expect(textTheme.headlineMedium?.fontSize, 18);
      expect(textTheme.headlineSmall?.fontSize, 16);

      expect(textTheme.titleLarge?.fontFamily, 'TestBodyFont');
      expect(textTheme.titleLarge?.fontSize, 15);
      expect(textTheme.titleMedium?.fontSize, 14);
      expect(textTheme.titleSmall?.fontSize, 13);

      expect(textTheme.bodyLarge?.fontFamily, 'TestBodyFont');
      expect(textTheme.bodyLarge?.fontSize, 14);
      expect(textTheme.bodyMedium?.fontSize, 13);
      expect(textTheme.bodySmall?.fontSize, 11);

      expect(textTheme.labelLarge?.fontSize, 12.5);
      expect(textTheme.labelMedium?.fontSize, 11.5);
      expect(textTheme.labelSmall?.fontSize, 10.5);
    });
  });

  group('THEME-DEPTH-3: AmbianceColors.lerp overshoot immunity', () {
    test('AmbianceColors.lerp does not crash with negative or >1.0 t factors', () {
      final srColors = srAmbianceColors;
      final mcColors = mcAmbianceColors;

      // Test extreme spring overshoot bounds
      for (final t in [-0.5, -0.1, 0.0, 0.5, 1.0, 1.1, 1.5, 2.0]) {
        expect(() => srColors.lerp(mcColors, t), returnsNormally);
      }
    });
  });
}
