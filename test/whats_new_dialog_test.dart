// Regression coverage for the What's New changelog dialog shown once per
// release to testers after they install a new build.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:the_lounge/constants/whats_new.dart';
import 'package:the_lounge/providers/ambiance_provider.dart';
import 'package:the_lounge/screens/shell_screen.dart';
import 'package:the_lounge/providers/media_provider.dart';
import 'package:the_lounge/repositories/mock_movie_repository.dart';
import 'package:the_lounge/widgets/whats_new_dialog.dart';

void main() {
  setUp(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  testWidgets('WhatsNewDialog renders every section title and item',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: WhatsNewDialog())),
    );
    await tester.pump();

    expect(find.text("What's New"), findsOneWidget);
    for (final section in kWhatsNewSections) {
      expect(find.text(section.title), findsOneWidget);
      for (final item in section.items) {
        expect(find.text(item), findsOneWidget);
      }
    }
  });

  testWidgets('tapping Got it dismisses the dialog', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () => WhatsNewDialog.show(context),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.byType(WhatsNewDialog), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('whats_new_dismiss_button')));
    await tester.pumpAndSettle();
    expect(find.byType(WhatsNewDialog), findsNothing);
  });

  group('WhatsNewGate', () {
    Future<ProviderContainer> pumpShell(
      WidgetTester tester, {
      bool? enableAnimation,
    }) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final container = ProviderContainer(
        overrides: [
          movieRepositoryProvider.overrideWithValue(MockMovieRepository()),
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: ShellScreen(enableAnimation: enableAnimation),
          ),
        ),
      );
      // With enableAnimation left null/true, the capsule's AmbientGlowWidget
      // runs a continuously-repeating animation, so pumpAndSettle() never
      // terminates -- bounded pumps instead, matching the pattern already
      // established for DetailScreen elsewhere in this suite. Several
      // short pumps (rather than one long one) so LobbyScreen's own
      // staggered rail-item entrance animations, which lazily build more
      // items as the sliver's cache extent is reached, get a chance to
      // fully settle too.
      await tester.pump();
      for (var i = 0; i < 8; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      return container;
    }

    testWidgets('enableAnimation: false suppresses the automatic show (test convention)',
        (tester) async {
      final container = await pumpShell(tester, enableAnimation: false);
      addTearDown(container.dispose);

      expect(find.byType(WhatsNewDialog), findsNothing);
    });

    testWidgets('shows automatically on first launch and persists the shown version',
        (tester) async {
      final container = await pumpShell(tester, enableAnimation: null);
      addTearDown(container.dispose);

      expect(find.byType(WhatsNewDialog), findsOneWidget);

      final prefs = container.read(sharedPreferencesProvider);
      expect(prefs.getString('whats_new_last_shown_version'), equals(kWhatsNewVersion));
    });

    testWidgets('does not show again once the current version was already recorded',
        (tester) async {
      SharedPreferences.setMockInitialValues({
        'whats_new_last_shown_version': kWhatsNewVersion,
      });
      final prefs = await SharedPreferences.getInstance();
      final container = ProviderContainer(
        overrides: [
          movieRepositoryProvider.overrideWithValue(MockMovieRepository()),
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: ShellScreen()),
        ),
      );
      await tester.pump();
      for (var i = 0; i < 8; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }

      expect(find.byType(WhatsNewDialog), findsNothing);
    });
  });
}
