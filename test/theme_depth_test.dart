import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:the_lounge/themes/ambiance_colors.dart';
import 'package:the_lounge/themes/theme_registry.dart';
import 'package:the_lounge/themes/screening_room_theme.dart';
import 'package:the_lounge/themes/violet_dusk_theme.dart';
import 'package:the_lounge/themes/midnight_cinema_theme.dart';
import 'package:the_lounge/themes/orchid_bloom_theme.dart';
import 'package:the_lounge/themes/tuscany_theme.dart';
import 'package:the_lounge/themes/glacier_dawn_theme.dart';
import 'package:the_lounge/themes/nebula_tide_theme.dart';
import 'package:the_lounge/themes/amethyst_veil_theme.dart';
import 'package:the_lounge/widgets/noise_texture_overlay.dart';

// THEME-DEPTH-2: grain opacity/tint now live per-theme (AmbianceColors)
// instead of one fixed global constant, and AppNoiseTexture reads them off
// the active theme reactively. _NoiseTexturePainter itself is library-private
// (by design -- it's an implementation detail, not part of the public
// widget contract), so these tests verify the two things that actually
// matter: every theme declares its own real grain configuration (not a
// copy-pasted default), and AppNoiseTexture renders without error under
// each theme and across a live theme switch.
//
// The pure-data group below tests the AmbianceColors instances directly
// (srAmbianceColors etc.), not `allThemes`/AppTheme -- referencing an
// AppTheme's `themeData` eagerly builds its TextTheme via GoogleFonts,
// which a plain (non-widget) test() can't safely await, unlike
// theme_tokens_test.dart's identical pattern this mirrors.
void main() {
  setUp(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  group('THEME-DEPTH-2: per-theme grain configuration', () {
    final allAmbianceColors = <String, AmbianceColors>{
      'Screening Room': srAmbianceColors,
      'Violet Dusk': vdAmbianceColors,
      'Midnight Cinema': mcAmbianceColors,
      'Orchid Bloom': obAmbianceColors,
      'Tuscany': tsAmbianceColors,
      'Glacier Dawn': gdAmbianceColors,
      'Nebula Tide': ntAmbianceColors,
      'Amethyst Veil': avAmbianceColors,
    };

    test('every theme declares its own grainOpacity and grainTint, not a shared default', () {
      for (final entry in allAmbianceColors.entries) {
        final colors = entry.value;
        expect(colors.grainOpacity, greaterThan(0),
            reason: '${entry.key} should have a visible grain');
        expect(colors.grainOpacity, lessThan(0.15),
            reason: '${entry.key} grain should stay subtle, not overpower content');
        expect(colors.grainTint.a, greaterThan(0),
            reason: '${entry.key} grain tint should actually wash the grain, not be fully transparent');
      }

      final tints = allAmbianceColors.values.map((c) => c.grainTint).toSet();
      expect(tints.length, allAmbianceColors.length,
          reason: 'grain tints should be distinct per theme, not copy-pasted');

      final opacities = allAmbianceColors.values.map((c) => c.grainOpacity).toSet();
      expect(opacities.length, allAmbianceColors.length,
          reason: 'grain opacities should be distinct per theme, not copy-pasted');
    });

    test('the light theme carries a noticeably finer grain than the dark luxury themes', () {
      expect(obAmbianceColors.grainOpacity, lessThan(srAmbianceColors.grainOpacity));
      expect(obAmbianceColors.grainOpacity, lessThan(tsAmbianceColors.grainOpacity));
    });
  });

  group('THEME-DEPTH-2: AppNoiseTexture reactivity', () {
    Future<void> pumpWithTheme(WidgetTester tester, ThemeData theme) {
      return tester.pumpWidget(
        MaterialApp(
          theme: theme,
          home: const Scaffold(body: AppNoiseTexture()),
        ),
      );
    }

    testWidgets('renders without error under every theme\'s own grain configuration',
        (tester) async {
      for (final theme in allThemes) {
        await pumpWithTheme(tester, theme.themeData);
        await tester.pump();
        expect(find.byType(AppNoiseTexture), findsOneWidget);
        expect(find.byType(CustomPaint), findsWidgets);
        expect(tester.takeException(), isNull);
      }
    });

    testWidgets(
        'switching themes rebuilds the grain without throwing, animating across the House Spring duration',
        (tester) async {
      await pumpWithTheme(tester, screeningRoomTheme.themeData);
      await tester.pump();

      await pumpWithTheme(tester, midnightCinemaTheme.themeData);
      // Mid cross-fade -- must not throw.
      await tester.pump(const Duration(milliseconds: 250));
      // Past the 550ms House Spring duration -- settled on the new theme.
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.byType(AppNoiseTexture), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('explicit opacity/tint overrides still render without error', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: screeningRoomTheme.themeData,
          home: const Scaffold(
            body: AppNoiseTexture(
              opacity: 0.1,
              tint: Color.fromRGBO(255, 0, 0, 0.5),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(AppNoiseTexture), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
