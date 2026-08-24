import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:the_lounge/themes/ambiance_colors.dart';
import 'package:the_lounge/themes/screening_room_theme.dart';
import 'package:the_lounge/themes/violet_dusk_theme.dart';
import 'package:the_lounge/themes/midnight_cinema_theme.dart';
import 'package:the_lounge/themes/orchid_bloom_theme.dart';
import 'package:the_lounge/themes/tuscany_theme.dart';
import 'package:the_lounge/themes/shadow_tokens.dart';
import 'package:the_lounge/widgets/frosted_glass_surface.dart';

// THEME-DEPTH-3: cardShadow/ambientGlowShadow/dialogShadow now live per
// theme (AmbianceColors), replacing scattered hardcoded black-alpha
// BoxShadows in MediaCard, the Discover swipe card, FrostedGlassSurface
// (which backs LoungeDialog/WhatsNewDialog/LoungeDropdown/LoungeToast),
// FloatingNavigationCapsule, and PersonSearchAutocomplete's suggestion
// panel. Tests the AmbianceColors instances directly (not `allThemes`/
// AppTheme) for the same reason theme_depth_test.dart does -- an
// AppTheme's themeData eagerly builds its TextTheme via GoogleFonts,
// which a plain test() can't safely await.
void main() {
  setUp(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  group('THEME-DEPTH-3: buildThemeShadows', () {
    test('dark themes get a colored glow layer plus a grounding contact shadow', () {
      final shadows = buildThemeShadows(accent: const Color(0xFF00B4D8), isDark: true);

      for (final tier in [shadows.cardShadow, shadows.ambientGlowShadow, shadows.dialogShadow]) {
        expect(tier.length, 2, reason: 'dark themes should layer a colored glow + contact shadow');
        expect(tier[0].color.withValues(alpha: 1.0), const Color(0xFF00B4D8),
            reason: 'first layer should bleed the theme\'s own accent hue');
      }
    });

    test('light themes get a single, softer accent-tinted diffuse shadow', () {
      final shadows = buildThemeShadows(accent: const Color(0xFF4B1F6F), isDark: false);

      for (final tier in [shadows.cardShadow, shadows.ambientGlowShadow, shadows.dialogShadow]) {
        expect(tier.length, 1,
            reason: 'light themes should use a single diffuse shadow, not a stacked glow');
        expect(tier[0].color.a, lessThan(0.15),
            reason: 'light-theme shadows must stay soft, not read as a solid colored block');
      }
    });
  });

  group('THEME-DEPTH-3: per-theme shadow tokens', () {
    final allAmbianceColors = <String, AmbianceColors>{
      'Screening Room': srAmbianceColors,
      'Violet Dusk': vdAmbianceColors,
      'Midnight Cinema': mcAmbianceColors,
      'Orchid Bloom': obAmbianceColors,
      'Tuscany': tsAmbianceColors,
    };

    test('every theme declares non-empty cardShadow/ambientGlowShadow/dialogShadow', () {
      for (final entry in allAmbianceColors.entries) {
        final colors = entry.value;
        expect(colors.cardShadow, isNotEmpty, reason: '${entry.key}.cardShadow');
        expect(colors.ambientGlowShadow, isNotEmpty, reason: '${entry.key}.ambientGlowShadow');
        expect(colors.dialogShadow, isNotEmpty, reason: '${entry.key}.dialogShadow');
      }
    });

    test('shadow tokens are distinct per theme, not copy-pasted', () {
      final cardShadowColors =
          allAmbianceColors.values.map((c) => c.cardShadow.first.color).toSet();
      expect(cardShadowColors.length, allAmbianceColors.length,
          reason: 'each theme\'s card shadow should bleed its own accent, not a shared default');
    });
  });

  group('THEME-DEPTH-3: FrostedGlassSurface renders with the new dialogShadow layer', () {
    testWidgets('renders without error under every theme, dialogShadow applied alongside the inner highlight',
        (tester) async {
      for (final theme in [
        screeningRoomTheme,
        violetDuskTheme,
        midnightCinemaTheme,
        orchidBloomTheme,
        tuscanyTheme,
      ]) {
        await tester.pumpWidget(
          MaterialApp(
            theme: theme.themeData,
            home: Scaffold(
              body: FrostedGlassSurface(
                borderRadius: 16,
                backgroundColor: theme.colors.card,
                borderColor: theme.colors.lineRgba,
                child: const Text('content'),
              ),
            ),
          ),
        );
        await tester.pump();

        final container = tester.widget<Container>(find.descendant(
          of: find.byType(FrostedGlassSurface),
          matching: find.byType(Container),
        ));
        final decoration = container.decoration as BoxDecoration;
        expect(decoration.boxShadow!.length, greaterThanOrEqualTo(2),
            reason: '${theme.displayName}: dialogShadow layer(s) + the existing inner highlight');
        expect(tester.takeException(), isNull);
      }
    });
  });
}
