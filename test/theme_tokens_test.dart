import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:the_lounge/themes/ambiance_colors.dart';
import 'package:the_lounge/themes/screening_room_theme.dart';
import 'package:the_lounge/themes/reading_room_theme.dart';
import 'package:the_lounge/themes/midnight_cinema_theme.dart';
import 'package:the_lounge/themes/alpine_chalet_theme.dart';
import 'package:the_lounge/themes/violet_dusk_theme.dart';
import 'package:the_lounge/themes/orchid_bloom_theme.dart';
import 'package:the_lounge/themes/tuscany_theme.dart';
import 'package:the_lounge/themes/gilded_plum_theme.dart';
import 'package:the_lounge/themes/riviera_theme.dart';

// Tests the AmbianceColors instances directly (not through AppTheme.themeData)
// so this stays independent of google_fonts asset loading in the test sandbox.
//
// Note: status* tokens (statusWatchlist, statusSkip, etc.) used to live here
// as theme-adaptive AmbianceColors fields, but per the TH-STATE locked
// design decision they've moved to the theme-*independent*
// lib/constants/app_status_colors.dart -- see status_colors_test.dart.
void main() {
  final allAmbianceColors = <String, AmbianceColors>{
    'Screening Room': srAmbianceColors,
    'Reading Room': rrAmbianceColors,
    'Midnight Cinema': mcAmbianceColors,
    'Alpine Chalet': acAmbianceColors,
    'Violet Dusk': vdAmbianceColors,
    'Orchid Bloom': obAmbianceColors,
    'Tuscany': tsAmbianceColors,
    'Gilded Plum': gpAmbianceColors,
    'Riviera': rvAmbianceColors,
  };

  group('Semantic token coverage across all 9 themes', () {
    for (final entry in allAmbianceColors.entries) {
      test('${entry.key} populates all new semantic tokens with non-transparent values', () {
        final colors = entry.value;
        expect(colors.starRating.a, greaterThan(0));
        expect(colors.surfaceHighlight.a, greaterThan(0));
        expect(colors.navBarBg.a, greaterThan(0));
        expect(colors.scrim.a, greaterThan(0));
        expect(colors.danger.a, greaterThan(0));
        expect(colors.success.a, greaterThan(0));
      });
    }
  });

  group('AmbianceColors.lerp interpolates new semantic tokens smoothly', () {
    test('lerp at t=0.5 produces valid intermediate colors without assertion errors', () {
      final result = srAmbianceColors.lerp(rrAmbianceColors, 0.5) as AmbianceColors;

      expect(result.starRating, isA<Color>());
      expect(result.surfaceHighlight, isA<Color>());
      expect(result.navBarBg, isA<Color>());
      expect(result.scrim, isA<Color>());
      expect(result.danger, isA<Color>());
      expect(result.success, isA<Color>());
    });

    test('lerp at t=0 returns the origin theme, t=1 returns the target theme', () {
      final atStart = srAmbianceColors.lerp(rrAmbianceColors, 0.0) as AmbianceColors;
      final atEnd = srAmbianceColors.lerp(rrAmbianceColors, 1.0) as AmbianceColors;

      expect(atStart.danger, equals(srAmbianceColors.danger));
      expect(atEnd.danger, equals(rrAmbianceColors.danger));
    });

    test('copyWith overrides only the targeted new tokens', () {
      final updated = srAmbianceColors.copyWith(danger: const Color(0xFF123456)) as AmbianceColors;

      expect(updated.danger, equals(const Color(0xFF123456)));
      expect(updated.starRating, equals(srAmbianceColors.starRating));
    });
  });
}
