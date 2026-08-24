import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:the_lounge/themes/app_theme.dart';
import 'package:the_lounge/themes/midnight_cinema_theme.dart';
import 'package:the_lounge/themes/orchid_bloom_theme.dart';
import 'package:the_lounge/themes/screening_room_theme.dart';
import 'package:the_lounge/themes/tuscany_theme.dart';
import 'package:the_lounge/themes/violet_dusk_theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  Map<String, AppTheme> getThemes() => {
        'Screening Room': screeningRoomTheme,
        'Midnight Cinema': midnightCinemaTheme,
        'Orchid Bloom': orchidBloomTheme,
        'Violet Dusk': violetDuskTheme,
        'Tuscany': tuscanyTheme,
      };

  group('THEME-DEPTH-1: TextTheme contract compliance across all 5 themes', () {
    for (final themeName in ['Screening Room', 'Midnight Cinema', 'Orchid Bloom', 'Violet Dusk', 'Tuscany']) {
      testWidgets('$themeName populates full TextTheme hierarchy without null styles', (tester) async {
        final theme = getThemes()[themeName]!;
        final textTheme = theme.themeData.textTheme;

        expect(textTheme.displayLarge, isNotNull);
        expect(textTheme.displayMedium, isNotNull);
        expect(textTheme.displaySmall, isNotNull);
        expect(textTheme.headlineLarge, isNotNull);
        expect(textTheme.headlineMedium, isNotNull);
        expect(textTheme.headlineSmall, isNotNull);
        expect(textTheme.titleLarge, isNotNull);
        expect(textTheme.titleMedium, isNotNull);
        expect(textTheme.titleSmall, isNotNull);
        expect(textTheme.bodyLarge, isNotNull);
        expect(textTheme.bodyMedium, isNotNull);
        expect(textTheme.bodySmall, isNotNull);
        expect(textTheme.labelLarge, isNotNull);
        expect(textTheme.labelMedium, isNotNull);
        expect(textTheme.labelSmall, isNotNull);
      });
    }
  });

  group('THEME-DEPTH-1: Distinct typography personalities per theme', () {
    testWidgets('Screening Room uses Fraunces with italic display/headline styles', (tester) async {
      final textTheme = screeningRoomTheme.themeData.textTheme;
      expect(textTheme.displayLarge?.fontFamily, contains('Fraunces'));
      expect(textTheme.displayLarge?.fontStyle, FontStyle.italic);
      expect(textTheme.headlineLarge?.fontStyle, FontStyle.italic);
    });

    testWidgets('Midnight Cinema uses Bricolage Grotesque display font', (tester) async {
      final textTheme = midnightCinemaTheme.themeData.textTheme;
      expect(textTheme.displayLarge?.fontFamily, contains('Bricolage'));
      expect(textTheme.displayLarge?.fontStyle, FontStyle.normal);
    });

    testWidgets('Orchid Bloom uses Cormorant Garamond with italic display/headline styles', (tester) async {
      final textTheme = orchidBloomTheme.themeData.textTheme;
      expect(textTheme.displayLarge?.fontFamily, contains('Cormorant'));
      expect(textTheme.displayLarge?.fontStyle, FontStyle.italic);
      expect(textTheme.headlineLarge?.fontStyle, FontStyle.italic);
    });

    testWidgets('Violet Dusk uses Playfair Display font', (tester) async {
      final textTheme = violetDuskTheme.themeData.textTheme;
      expect(textTheme.displayLarge?.fontFamily, contains('Playfair'));
    });

    testWidgets('Tuscany uses Lora font', (tester) async {
      final textTheme = tuscanyTheme.themeData.textTheme;
      expect(textTheme.displayLarge?.fontFamily, contains('Lora'));
    });

    testWidgets('All 5 themes have distinct display font families', (tester) async {
      final displayFonts = getThemes().values
          .map((t) => t.themeData.textTheme.displayLarge?.fontFamily)
          .toSet();
      expect(displayFonts.length, equals(5),
          reason: 'Every theme must have a distinct font family pairing');
    });
  });

  group('THEME-DEPTH-1: Widget rendering and zero layout overflow', () {
    for (final themeName in ['Screening Room', 'Midnight Cinema', 'Orchid Bloom', 'Violet Dusk', 'Tuscany']) {
      testWidgets('renders TextTheme elements under $themeName without error or overflow',
          (tester) async {
        final theme = getThemes()[themeName]!;
        await tester.pumpWidget(
          MaterialApp(
            theme: theme.themeData,
            home: Scaffold(
              body: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
                  ],
                ),
              ),
            ),
          ),
        );
        await tester.pump();

        expect(find.text('Display Large'), findsOneWidget);
        expect(find.text('Body Large'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  });
}
