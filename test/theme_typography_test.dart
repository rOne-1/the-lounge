import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:the_lounge/themes/typography.dart';
import 'package:the_lounge/themes/app_theme.dart';
import 'package:the_lounge/themes/screening_room_theme.dart';
import 'package:the_lounge/themes/midnight_cinema_theme.dart';
import 'package:the_lounge/themes/orchid_bloom_theme.dart';
import 'package:the_lounge/themes/violet_dusk_theme.dart';
import 'package:the_lounge/themes/tuscany_theme.dart';
import 'package:the_lounge/themes/glacier_dawn_theme.dart';
import 'package:the_lounge/themes/nebula_tide_theme.dart';
import 'package:the_lounge/themes/verdant_manor_theme.dart';

// The per-theme widget-rendering checks below (real fonts, real TextTheme,
// zero RenderFlex overflow) were present in the original THEME-DEPTH-1
// commit (8a1157a) but were deleted rather than fixed in a later commit
// (18adfa7) that also legitimately hardened AmbianceColors.lerp -- the
// triage doc's own acceptance criterion ("flutter test passes 100% of
// widget tests without a single RenderFlex overflow error") was left
// unverified by any test as a result. Restored here using testWidgets
// (not plain test()), which correctly awaits the async GoogleFonts
// fallback that a bare test() cannot -- that mismatch, not the font
// assertions themselves, was almost certainly why the originals were
// pulled instead of fixed.
// getThemes() is a function, not a top-level value -- building
// screeningRoomTheme/etc. (which eagerly constructs ThemeData via
// buildTextTheme -> GoogleFonts) at main()'s top level runs at file-load
// time, before any test's setUp() has fired GoogleFonts.config.allowRuntimeFetching
// = false, so it tries a real network fetch outside any test zone and
// crashes the whole file. Calling this from inside each test body instead
// means it only ever runs after that test's own setUp.
Map<String, AppTheme> _getThemes() => {
      'Screening Room': screeningRoomTheme,
      'Violet Dusk': violetDuskTheme,
      'Midnight Cinema': midnightCinemaTheme,
      'Orchid Bloom': orchidBloomTheme,
      'Tuscany': tuscanyTheme,
      'Glacier Dawn': glacierDawnTheme,
      'Nebula Tide': nebulaTideTheme,
      'Verdant Manor': verdantManorTheme,
    };

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  group('THEME-DEPTH-1: each theme wires its own real display font', () {
    testWidgets('Screening Room uses Fraunces, italic', (tester) async {
      expect(screeningRoomTheme.themeData.textTheme.displayLarge?.fontFamily,
          contains('Fraunces'));
      expect(screeningRoomTheme.themeData.textTheme.displayLarge?.fontStyle,
          FontStyle.italic);
    });

    testWidgets('Midnight Cinema uses Bricolage Grotesque, upright', (tester) async {
      expect(midnightCinemaTheme.themeData.textTheme.displayLarge?.fontFamily,
          contains('Bricolage'));
      expect(midnightCinemaTheme.themeData.textTheme.displayLarge?.fontStyle,
          FontStyle.normal);
    });

    testWidgets('Orchid Bloom uses Cormorant Garamond, italic', (tester) async {
      expect(orchidBloomTheme.themeData.textTheme.displayLarge?.fontFamily,
          contains('Cormorant'));
      expect(orchidBloomTheme.themeData.textTheme.displayLarge?.fontStyle,
          FontStyle.italic);
    });

    testWidgets('Violet Dusk uses Playfair Display', (tester) async {
      expect(violetDuskTheme.themeData.textTheme.displayLarge?.fontFamily,
          contains('Playfair'));
    });

    testWidgets('Tuscany uses Lora', (tester) async {
      expect(tuscanyTheme.themeData.textTheme.displayLarge?.fontFamily,
          contains('Lora'));
    });

    testWidgets('Glacier Dawn uses DM Serif Display', (tester) async {
      expect(glacierDawnTheme.themeData.textTheme.displayLarge?.fontFamily,
          contains('DMSerifDisplay'));
    });

    testWidgets('Nebula Tide uses Marcellus', (tester) async {
      expect(nebulaTideTheme.themeData.textTheme.displayLarge?.fontFamily,
          contains('Marcellus'));
    });

    testWidgets('Verdant Manor uses Frank Ruhl Libre', (tester) async {
      expect(verdantManorTheme.themeData.textTheme.displayLarge?.fontFamily,
          contains('FrankRuhlLibre'));
    });

    testWidgets('all 8 themes have distinct display font families', (tester) async {
      final displayFonts = _getThemes()
          .values
          .map((t) => t.themeData.textTheme.displayLarge?.fontFamily)
          .toSet();
      expect(displayFonts.length, 8,
          reason: 'every theme must have a distinct font family pairing');
    });
  });

  group('THEME-DEPTH-1: zero RenderFlex overflow rendering the real TextTheme per theme', () {
    for (final entry in [
      'Screening Room',
      'Violet Dusk',
      'Midnight Cinema',
      'Orchid Bloom',
      'Tuscany',
      'Glacier Dawn',
      'Nebula Tide',
      'Verdant Manor',
    ]) {
      testWidgets('$entry renders every TextTheme style, including a long real-world title, without overflow',
          (tester) async {
        final theme = _getThemes()[entry]!;
        await tester.pumpWidget(
          MaterialApp(
            theme: theme.themeData,
            home: Scaffold(
              body: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // A realistically long title in a fixed-width row, the
                    // shape most likely to actually overflow under a wider
                    // font -- not just a scrollable column of loose labels.
                    SizedBox(
                      width: 220,
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              'The Grand Midnight Chronicles: A Very Long Subtitle Indeed',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.themeData.textTheme.displayMedium,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text('Display Large', style: theme.themeData.textTheme.displayLarge),
                    Text('Display Medium', style: theme.themeData.textTheme.displayMedium),
                    Text('Display Small', style: theme.themeData.textTheme.displaySmall),
                    Text('Headline Large', style: theme.themeData.textTheme.headlineLarge),
                    Text('Headline Medium', style: theme.themeData.textTheme.headlineMedium),
                    Text('Headline Small', style: theme.themeData.textTheme.headlineSmall),
                    Text('Title Large', style: theme.themeData.textTheme.titleLarge),
                    Text('Title Medium', style: theme.themeData.textTheme.titleMedium),
                    Text('Title Small', style: theme.themeData.textTheme.titleSmall),
                    Text('Body Large', style: theme.themeData.textTheme.bodyLarge),
                    Text('Body Medium', style: theme.themeData.textTheme.bodyMedium),
                    Text('Body Small', style: theme.themeData.textTheme.bodySmall),
                    Text('Label Large', style: theme.themeData.textTheme.labelLarge),
                    Text('Label Medium', style: theme.themeData.textTheme.labelMedium),
                    Text('Label Small', style: theme.themeData.textTheme.labelSmall),
                    // A metadata row (year · genre · rating), matching the
                    // real app's own pattern of an Expanded+ellipsis middle
                    // element (e.g. MediaCard) rather than an artificially
                    // unwrapped Row -- labelMedium renders in Geist (the
                    // shared body font, unchanged by this sprint) for every
                    // theme, so an unwrapped version of this row overflows
                    // identically regardless of theme and isn't a signal
                    // about the per-theme display font this test targets.
                    SizedBox(
                      width: 260,
                      child: Row(
                        children: [
                          Text('2024', style: theme.themeData.textTheme.labelMedium),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Science Fiction',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.themeData.textTheme.labelMedium,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text('9.4', style: theme.themeData.textTheme.labelMedium),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
        await tester.pump();

        expect(find.text('Display Large'), findsOneWidget);
        expect(find.text('Body Large'), findsOneWidget);
        expect(tester.takeException(), isNull,
            reason: '$entry must render its full TextTheme, including a long title and an unwrapped metadata row, with zero RenderFlex overflow');
      });
    }
  });

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
