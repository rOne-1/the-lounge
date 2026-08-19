// Regression coverage for B3 (TF-14/CO-13): real ShellScreen bottom-nav
// navigation must not reset a tab's own local UI state (selected sub-tab,
// scroll position, etc). Root cause was shell_screen.dart wrapping its
// IndexedStack in a KeyedSubtree keyed by the active tab, which made
// PageTransitionSwitcher tear down and rebuild every tab (not just the one
// becoming visible) on every single bottom-nav tap.
//
// PERS-SPACE-1 note: the original TF-14 repro test here exercised Your
// Space's old "In Progress" tab + sub-filter selection surviving a tab
// round trip. That state no longer exists -- PERS-SPACE-1's 3-group
// redesign retired the tab/sub-filter UI entirely in favor of standalone
// ArchiveBucketScreen destinations pushed onto the Navigator, and Your Space itself
// carries no meaningful per-visit UI state anymore. Removed rather than
// kept passing vacuously; the CO-13 Discover-deck-pool test below still
// covers the same underlying IndexedStack-preservation concern.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:the_lounge/screens/shell_screen.dart';
import 'package:the_lounge/providers/media_provider.dart';
import 'package:the_lounge/providers/navigation_provider.dart';
import 'package:the_lounge/providers/ambiance_provider.dart';
import 'package:the_lounge/repositories/mock_movie_repository.dart';

void main() {
  setUp(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  Future<ProviderContainer> pumpShell(WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [
        movieRepositoryProvider.overrideWithValue(MockMovieRepository()),
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
    );

    container.read(navigationProvider.notifier).setMediaType(MediaTypeToggle.tv);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: ShellScreen(enableAnimation: false),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return container;
  }

  testWidgets(
      'Discover deck pool survives a real Home -> Discover -> Home -> Discover round trip (CO-13 gap)',
      (WidgetTester tester) async {
    final container = await pumpShell(tester);
    addTearDown(container.dispose);

    container.read(navigationProvider.notifier).setTab(AppTab.discover);
    await tester.pumpAndSettle();

    final deckBefore = container.read(discoverTvDeckProvider);
    expect(deckBefore.pool, isNotEmpty);

    container.read(navigationProvider.notifier).setTab(AppTab.lobby);
    await tester.pumpAndSettle();
    container.read(navigationProvider.notifier).setTab(AppTab.discover);
    await tester.pumpAndSettle();

    final deckAfter = container.read(discoverTvDeckProvider);
    expect(deckAfter.pool, equals(deckBefore.pool));
  });
}
