// Regression coverage for B3 (TF-14/CO-13): real ShellScreen bottom-nav
// navigation must not reset a tab's own local UI state (selected sub-tab,
// scroll position, etc). Root cause was shell_screen.dart wrapping its
// IndexedStack in a KeyedSubtree keyed by the active tab, which made
// PageTransitionSwitcher tear down and rebuild every tab (not just the one
// becoming visible) on every single bottom-nav tap.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:the_lounge/screens/shell_screen.dart';
import 'package:the_lounge/providers/media_provider.dart';
import 'package:the_lounge/providers/navigation_provider.dart';
import 'package:the_lounge/providers/ambiance_provider.dart';
import 'package:the_lounge/models/media_item.dart';
import 'package:the_lounge/repositories/mock_movie_repository.dart';

void main() {
  setUp(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  const watchingShow = MediaItem(
    id: 'tv-900',
    title: 'Persistence Test Show',
    type: MediaType.tv,
    rating: 7.5,
    overview: '',
    genres: ['Drama'],
    seasonsCount: 1,
    episodesCount: 1,
  );

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
      'YourSpace In Progress tab + Watching sub-filter survive a real Home -> YourSpace -> Home -> YourSpace round trip',
      (WidgetTester tester) async {
    final container = await pumpShell(tester);
    addTearDown(container.dispose);

    container.read(mediaProvider.notifier).addToWatchingList(watchingShow);

    // Navigate to YourSpace, then to its "In Progress" tab.
    container.read(navigationProvider.notifier).setTab(AppTab.yourSpace);
    await tester.pumpAndSettle();

    await tester.tap(find.text('In Progress'));
    await tester.pumpAndSettle();

    expect(find.text('Persistence Test Show'), findsOneWidget);
    // "Watching" sub-pill is the default and only one with content here.

    // Round-trip through Home -- this is the exact repro from TF-14.
    container.read(navigationProvider.notifier).setTab(AppTab.home);
    await tester.pumpAndSettle();
    container.read(navigationProvider.notifier).setTab(AppTab.yourSpace);
    await tester.pumpAndSettle();

    // Before the fix, this remounted YourSpaceScreen fresh, resetting the
    // TabBar to "Watchlist" (index 0) and _inProgressFilter to its default.
    // The content must still be the In Progress grid, not a reset-to-
    // Watchlist empty state -- i.e. the TabBar highlight and the actual
    // displayed content must still agree after the round trip.
    expect(find.text('Track active, paused, or stopped viewing progress.'),
        findsOneWidget);
    expect(find.text('Persistence Test Show'), findsOneWidget);
    expect(find.text('Nothing here yet.'), findsNothing);
  });

  testWidgets(
      'Discover deck pool survives a real Home -> Discover -> Home -> Discover round trip (CO-13 gap)',
      (WidgetTester tester) async {
    final container = await pumpShell(tester);
    addTearDown(container.dispose);

    container.read(navigationProvider.notifier).setTab(AppTab.discover);
    await tester.pumpAndSettle();

    final deckBefore = container.read(discoverTvDeckProvider);
    expect(deckBefore.pool, isNotEmpty);

    container.read(navigationProvider.notifier).setTab(AppTab.home);
    await tester.pumpAndSettle();
    container.read(navigationProvider.notifier).setTab(AppTab.discover);
    await tester.pumpAndSettle();

    final deckAfter = container.read(discoverTvDeckProvider);
    expect(deckAfter.pool, equals(deckBefore.pool));
  });
}
