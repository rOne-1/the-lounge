import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:the_lounge/constants/app_status_colors.dart';

// TH-STATE: AppStatusColors is the single, theme-*independent* source of
// truth for media/watch tracking status colors -- locked design decision,
// see local-notes/the_lounge_standing_issues_and_systems_triage.md.
void main() {
  group('AppStatusColors token coverage', () {
    test('all 7 status tokens are defined, opaque, and non-null', () {
      for (final color in AppStatusColors.all) {
        expect(color, isA<Color>());
        expect(color.a, equals(1.0));
      }
      expect(AppStatusColors.all.length, equals(7));
    });

    test('every status token is visually distinct from every other', () {
      final unique = AppStatusColors.all.toSet();
      expect(unique.length, equals(AppStatusColors.all.length));
    });

    test('every status token has enough luminance contrast to read on a dark surface', () {
      // Locked palette is meant to sit on the app's dark card surfaces --
      // each hue must be bright/saturated enough not to wash out there.
      const darkSurface = Color(0xFF171310);
      for (final color in AppStatusColors.all) {
        final contrast = _contrastRatio(color, darkSurface);
        expect(contrast, greaterThan(2.0),
            reason: 'AppStatusColors token $color has insufficient contrast '
                'against a dark surface ($contrast)');
      }
    });
  });

  group('No status color hexes hardcoded outside app_status_colors.dart', () {
    final lockedHexes = [
      '0xFFE5A93C', // watchlist
      '0xFFEC4899', // save
      '0xFF3B82F6', // watching
      '0xFF10B981', // watched
      '0xFFF97316', // onHold
      '0xFFEF4444', // dropped
      '0xFF8B5CF6', // skip
    ];

    test('lib/ contains no duplicate literal of a locked status hex', () {
      final libDir = Directory('lib');
      final violations = <String>[];

      for (final entity in libDir.listSync(recursive: true)) {
        if (entity is! File || !entity.path.endsWith('.dart')) continue;
        if (entity.path.replaceAll('\\', '/').endsWith('lib/constants/app_status_colors.dart')) {
          continue;
        }
        final content = entity.readAsStringSync();
        for (final hex in lockedHexes) {
          if (content.contains(hex)) {
            violations.add('${entity.path}: $hex');
          }
        }
      }

      expect(violations, isEmpty,
          reason: 'Status color hexes must only live in app_status_colors.dart:\n'
              '${violations.join('\n')}');
    });
  });
}

double _contrastRatio(Color a, Color b) {
  final l1 = a.computeLuminance() + 0.05;
  final l2 = b.computeLuminance() + 0.05;
  return l1 > l2 ? l1 / l2 : l2 / l1;
}
