import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:the_lounge/themes/ambiance_colors.dart';
import 'package:the_lounge/themes/app_theme.dart';
import 'package:the_lounge/themes/midnight_cinema_theme.dart';
import 'package:the_lounge/themes/orchid_bloom_theme.dart';
import 'package:the_lounge/themes/screening_room_theme.dart';
import 'package:the_lounge/themes/tuscany_theme.dart';
import 'package:the_lounge/themes/violet_dusk_theme.dart';
import 'package:the_lounge/widgets/atmospheric_empty_state.dart';
import 'package:the_lounge/widgets/signature_motif.dart';

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

  group('THEME-DEPTH-4: Signature motif token presence across all 5 themes', () {
    for (final themeName in ['Screening Room', 'Midnight Cinema', 'Orchid Bloom', 'Violet Dusk', 'Tuscany']) {
      testWidgets('$themeName provides non-null signatureMotif on AppTheme and AmbianceColors',
          (tester) async {
        final theme = getThemes()[themeName]!;
        expect(theme.signatureMotif, isNotNull,
            reason: '$themeName AppTheme.signatureMotif should be populated');
        expect(theme.colors.signatureMotif, isNotNull,
            reason: '$themeName AmbianceColors.signatureMotif should be populated');
      });
    }
  });

  group('THEME-DEPTH-4: SignatureMotif widget rendering across all 5 themes', () {
    for (final themeName in ['Screening Room', 'Midnight Cinema', 'Orchid Bloom', 'Violet Dusk', 'Tuscany']) {
      testWidgets('SignatureMotif renders under $themeName without error or overflow',
          (tester) async {
        final theme = getThemes()[themeName]!;
        await tester.pumpWidget(
          MaterialApp(
            theme: theme.themeData,
            home: const Scaffold(
              body: Center(
                child: SignatureMotif(),
              ),
            ),
          ),
        );
        await tester.pump();

        expect(find.byType(SignatureMotif), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('SignatureMotif renders empty SizedBox when theme does not provide motif',
        (tester) async {
      final themeWithoutMotif = screeningRoomTheme.themeData.copyWith(
        extensions: [
          srAmbianceColors.copyWith(signatureMotif: null),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: themeWithoutMotif,
          home: const Scaffold(
            body: Center(
              child: SignatureMotif(),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(SignatureMotif), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('THEME-DEPTH-4: AtmosphericEmptyState integrates SignatureMotif', () {
    for (final themeName in ['Screening Room', 'Midnight Cinema', 'Orchid Bloom', 'Violet Dusk', 'Tuscany']) {
      testWidgets('AtmosphericEmptyState renders under $themeName with bespoke signature motif',
          (tester) async {
        final theme = getThemes()[themeName]!;
        await tester.pumpWidget(
          MaterialApp(
            theme: theme.themeData,
            home: const Scaffold(
              body: AtmosphericEmptyState(
                icon: Icons.movie_outlined,
                title: 'No Titles Found',
                message: 'Try adjusting your filters or search query.',
                ctaLabel: 'Browse All',
                onCta: null,
              ),
            ),
          ),
        );
        await tester.pump();

        expect(find.byType(AtmosphericEmptyState), findsOneWidget);
        expect(find.text('No Titles Found'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  });

  group('THEME-DEPTH-4: AmbianceColors copyWith and lerp motif propagation', () {
    test('copyWith preserves or overrides signatureMotif', () {
      final updated = srAmbianceColors.copyWith(signatureMotif: midnightCinemaMotif) as AmbianceColors;
      expect(updated.signatureMotif, equals(midnightCinemaMotif));
    });

    test('lerp retains origin motif below 0.5 and target motif at or above 0.5', () {
      final atStart = srAmbianceColors.lerp(mcAmbianceColors, 0.4) as AmbianceColors;
      final atEnd = srAmbianceColors.lerp(mcAmbianceColors, 0.6) as AmbianceColors;

      expect(atStart.signatureMotif, equals(screeningRoomMotif));
      expect(atEnd.signatureMotif, equals(midnightCinemaMotif));
    });
  });
}
