// ITEM-2 (dev feedback, 2026-08-27): coverage for the swipe chain wired
// across archive_shelf_screen.dart and shell_screen.dart -- Watching <->
// Watched <-> Watchlist <-> Saved <-> Lobby <-> Search <-> Calendar. No
// coverage existed for the shelf-to-shelf swipe mechanism (or the Lobby<->
// Search<->Calendar tab swipe it was modeled on) before this.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:the_lounge/screens/shell_screen.dart';
import 'package:the_lounge/screens/archive_shelf_screen.dart';
import 'package:the_lounge/providers/media_provider.dart';
import 'package:the_lounge/providers/navigation_provider.dart';
import 'package:the_lounge/providers/ambiance_provider.dart';
import 'package:the_lounge/repositories/mock_movie_repository.dart';

void main() {
  setUp(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  Future<ProviderContainer> pumpShell(
      WidgetTester tester, AppTab startTab) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [
        movieRepositoryProvider.overrideWithValue(MockMovieRepository()),
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
    );
    container.read(navigationProvider.notifier).setTab(startTab);

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

  Future<void> swipeLeft(WidgetTester tester, Finder target) async {
    await tester.fling(target, const Offset(-400, 0), 1000);
    await tester.pumpAndSettle();
  }

  Future<void> swipeRight(WidgetTester tester, Finder target) async {
    await tester.fling(target, const Offset(400, 0), 1000);
    await tester.pumpAndSettle();
  }

  group('ITEM-2: Watching <-> Watched <-> Watchlist <-> Saved shelf chain', () {
    // Pushes the shelf screen ON TOP of a real base route (rather than
    // making it the Navigator's only/first route) so `popUntil(isFirst)`
    // in _navigateToAdjacentShelf's Lobby-exit path has an actual base
    // route to land on, matching how the real app reaches a shelf (pushed
    // from Lobby or Archive, never as the root route itself).
    Future<ProviderContainer> pumpShelf(
        WidgetTester tester, ArchiveShelfKind kind) async {
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
          child: const MaterialApp(home: Scaffold(body: SizedBox())),
        ),
      );
      final navigator = tester.state<NavigatorState>(find.byType(Navigator));
      navigator.push(
        MaterialPageRoute(builder: (_) => ArchiveShelfScreen(kind: kind)),
      );
      await tester.pumpAndSettle();
      return container;
    }

    testWidgets('swiping left steps through the full chain in the new order',
        (tester) async {
      final container = await pumpShelf(tester, ArchiveShelfKind.watching);
      addTearDown(container.dispose);

      expect(find.text('Watching'), findsOneWidget);

      await swipeLeft(tester, find.byType(ArchiveShelfScreen));
      expect(find.text('Watched'), findsOneWidget);

      await swipeLeft(tester, find.byType(ArchiveShelfScreen));
      expect(find.text('Watchlist'), findsOneWidget);

      await swipeLeft(tester, find.byType(ArchiveShelfScreen));
      expect(find.text('Saved'), findsOneWidget);
    });

    testWidgets('swiping right from Watching (chain start) is a no-op',
        (tester) async {
      final container = await pumpShelf(tester, ArchiveShelfKind.watching);
      addTearDown(container.dispose);

      await swipeRight(tester, find.byType(ArchiveShelfScreen));
      expect(find.text('Watching'), findsOneWidget);
    });

    testWidgets('swiping left past Saved (chain end) exits to the Lobby tab',
        (tester) async {
      final container = await pumpShelf(tester, ArchiveShelfKind.saved);
      addTearDown(container.dispose);

      expect(find.text('Saved'), findsOneWidget);
      expect(
          container.read(navigationProvider).currentTab, isNot(AppTab.lobby));

      await swipeLeft(tester, find.byType(ArchiveShelfScreen));

      expect(container.read(navigationProvider).currentTab, AppTab.lobby);
      expect(find.byType(ArchiveShelfScreen), findsNothing);
    });
  });

  group('ITEM-2: Lobby <-> Saved boundary (tab side)', () {
    testWidgets('swiping right on Lobby pushes ArchiveShelfScreen(kind: saved)',
        (tester) async {
      final container = await pumpShell(tester, AppTab.lobby);
      addTearDown(container.dispose);

      await swipeRight(tester, find.byType(ShellScreen));

      expect(find.byType(ArchiveShelfScreen), findsOneWidget);
      final shelfScreen =
          tester.widget<ArchiveShelfScreen>(find.byType(ArchiveShelfScreen));
      expect(shelfScreen.kind, ArchiveShelfKind.saved);
    });

    testWidgets(
        'swiping left on Lobby still goes to Search (unchanged boundary)',
        (tester) async {
      final container = await pumpShell(tester, AppTab.lobby);
      addTearDown(container.dispose);

      await swipeLeft(tester, find.byType(ShellScreen));

      expect(container.read(navigationProvider).currentTab, AppTab.search);
    });
  });
}
