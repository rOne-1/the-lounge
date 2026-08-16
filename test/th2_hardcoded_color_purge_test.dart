import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

// TH-2: static scan asserting the files targeted by the UI/UX triage's
// "hardcoded color purge" no longer contain raw Color(0x...)/Color.fromRGBO
// dark/light ternaries for the patterns AmbianceColors now covers.
//
// This intentionally scopes to the files TH-2 actually touched, not the
// whole lib/screens + lib/widgets tree — later triage items (UC-1, DS-1/2/3,
// FC-1, FS-1/2/3) purge their own remaining hardcoded colors as they build
// their own components, per the roadmap's phased sequencing.
void main() {
  group('TH-2: hardcoded color literals purged from targeted files', () {
    final targetFiles = <String, List<String>>{
      'lib/main.dart': [],
      'lib/screens/splash_screen.dart': [],
      'lib/screens/detail_screen.dart': [
        // IMDb's own brand-yellow logo badge — a third-party brand mark,
        // not an app theme color, deliberately left un-retinted.
        'const Color(0xFFF5C518), // IMDb Yellow',
        // Similar-items card elevation/drop shadow (blurRadius 4, offset
        // (0,2), no blurStyle.inner) — a brightness-inverting elevation
        // shadow, semantically distinct from surfaceHighlight's inner
        // bevel sheen. No AmbianceColors token models "elevation shadow"
        // yet; worth a dedicated token in a future pass rather than
        // force-fitting an existing one.
        'const Color.fromRGBO(255, 255, 255, 0.05)',
        ': const Color.fromRGBO(0, 0, 0, 0.08),',
        // Fixed inset depth shading inside the selected/accent-colored
        // status pill — a universal black-based inset convention (works
        // regardless of the accent color underneath it), not a themed hue.
        'color: Color.fromRGBO(0, 0, 0, 0.15),',
      ],
      'lib/screens/discover_screen.dart': [
        // Deck card's outer elevation/drop shadow — same "no matching
        // token yet" reasoning as detail_screen.dart's similar-items card.
        'color: Color.fromRGBO(0, 0, 0, 0.6),',
        'color: Color.fromRGBO(80, 55, 30, 0.12),',
        // "Upcoming release" informational badge — not a destructive
        // action, so `danger` is the wrong semantic fit; needs its own
        // alert/info token rather than a forced reuse.
        'color: const Color(0xFFE53935),',
        // Title/overview text sits on the deck card's own permanent dark
        // photographic backdrop regardless of app ambiance — legible by
        // design in every theme, not an ambiance-color violation.
        'color: const Color.fromRGBO(255, 255, 255, 0.8)',
        'color: const Color.fromRGBO(255, 255, 255, 0.72)), maxLines: 2, overflow: TextOverflow.ellipsis),',
      ],
      'lib/screens/shell_screen.dart': [],
      'lib/screens/home_screen.dart': [],
      'lib/screens/collection_screen.dart': [
        // Back-button circular chip floating over a backdrop image inverts
        // fully black/white by brightness to stay visible regardless of
        // what's under it — a distinct "floating scrim chip" need, not
        // covered by the fixed-polarity `scrim` token.
        'const Color.fromRGBO(0, 0, 0, 0.6)',
        ': const Color.fromRGBO(255, 255, 255, 0.8),',
      ],
      'lib/screens/media_list_screen.dart': [],
    };

    final hardcodedColorPattern = RegExp(r'Color(\.fromRGBO)?\(0x[0-9A-Fa-f]{6,8}\)|Color\.fromRGBO\(');

    for (final entry in targetFiles.entries) {
      test('${entry.key} has no un-allowlisted hardcoded color literals', () {
        final file = File(entry.key);
        expect(file.existsSync(), isTrue, reason: '${entry.key} should exist');

        final lines = file.readAsLinesSync();
        final violations = <String>[];

        for (final line in lines) {
          if (!hardcodedColorPattern.hasMatch(line)) continue;
          final isAllowlisted = entry.value.any((allowed) => line.contains(allowed));
          if (!isAllowlisted) {
            violations.add(line.trim());
          }
        }

        expect(
          violations,
          isEmpty,
          reason: 'Un-allowlisted hardcoded color(s) in ${entry.key}:\n${violations.join('\n')}',
        );
      });
    }
  });
}
