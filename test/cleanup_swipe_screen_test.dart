import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:the_lounge/screens/cleanup_swipe_screen.dart';
import 'package:the_lounge/screens/archive_shelf_screen.dart';
import 'package:the_lounge/providers/media_provider.dart';
import 'package:the_lounge/providers/ambiance_provider.dart';
import 'package:the_lounge/models/media_item.dart';
import 'package:the_lounge/repositories/mock_movie_repository.dart';

class _InstantRepository extends MockMovieRepository {
  @override
  Future<MediaItem?> getMediaDetails(String id) async => null;
}

MediaItem _movie(int i) => MediaItem(
      id: 'movie_$i',
      title: 'Movie $i',
      type: MediaType.movie,
      rating: 7.0,
      overview: 'Overview $i',
      genres: const ['Drama'],
    );

MediaItem _tvShow(int i) => MediaItem(
      id: 'tv_$i',
      title: 'Show $i',
      type: MediaType.tv,
      rating: 7.0,
      overview: 'Overview $i',
      genres: const ['Drama'],
    );

void main() {
  setUp(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  group('PERS-SORT-1: CleanupSwipeScreen', () {
    Future<ProviderContainer> pumpCleanup(WidgetTester tester, {required int count}) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          movieRepositoryProvider.overrideWithValue(_InstantRepository()),
        ],
      );
      addTearDown(container.dispose);
      for (var i = 0; i < count; i++) {
        container.read(mediaProvider.notifier).addToMaybeList(_movie(i));
      }

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: CleanupSwipeScreen()),
        ),
      );
      await tester.pumpAndSettle();
      return container;
    }

    testWidgets('shows the empty state when Saved has nothing to review', (tester) async {
      await pumpCleanup(tester, count: 0);
      expect(find.text('All cleaned up!'), findsOneWidget);
    });

    testWidgets('Promote adds the front card to Watchlist and advances the queue', (tester) async {
      final container = await pumpCleanup(tester, count: 2);

      expect(find.text('Movie 0'), findsOneWidget);
      await tester.tap(find.text('Promote'));
      await tester.pumpAndSettle();

      final state = container.read(mediaProvider);
      expect(state.watchlist.containsKey('movie_0'), isTrue);
      expect(find.text('Movie 1'), findsOneWidget);
    });

    testWidgets('Keep advances the queue without moving the card anywhere', (tester) async {
      final container = await pumpCleanup(tester, count: 2);

      await tester.tap(find.text('Keep'));
      await tester.pumpAndSettle();

      final state = container.read(mediaProvider);
      expect(state.maybeList.containsKey('movie_0'), isTrue);
      expect(state.watchlist.containsKey('movie_0'), isFalse);
      expect(state.droppedList.containsKey('movie_0'), isFalse);
      expect(find.text('Movie 1'), findsOneWidget);
    });

    testWidgets('Drop moves the front card to Dropped and advances the queue', (tester) async {
      final container = await pumpCleanup(tester, count: 2);

      await tester.tap(find.text('Drop'));
      await tester.pumpAndSettle();

      final state = container.read(mediaProvider);
      expect(state.droppedList.containsKey('movie_0'), isTrue);
      expect(find.text('Movie 1'), findsOneWidget);
    });

    testWidgets('no Undo button until an action has been taken', (tester) async {
      await pumpCleanup(tester, count: 1);
      expect(find.byKey(const ValueKey('cleanup_undo_button')), findsNothing);
    });

    testWidgets('Undo reverses Promote, restoring the card to Saved and the front of the queue',
        (tester) async {
      final container = await pumpCleanup(tester, count: 2);

      await tester.tap(find.text('Promote'));
      await tester.pumpAndSettle();
      expect(container.read(mediaProvider).watchlist.containsKey('movie_0'), isTrue);
      expect(find.text('Movie 1'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('cleanup_undo_button')));
      await tester.pumpAndSettle();

      final state = container.read(mediaProvider);
      expect(state.watchlist.containsKey('movie_0'), isFalse);
      expect(state.maybeList.containsKey('movie_0'), isTrue);
      expect(find.text('Movie 0'), findsOneWidget);
      expect(find.byKey(const ValueKey('cleanup_undo_button')), findsNothing);
    });

    testWidgets('Undo reverses Drop, restoring the card to Saved and the front of the queue',
        (tester) async {
      final container = await pumpCleanup(tester, count: 2);

      await tester.tap(find.text('Drop'));
      await tester.pumpAndSettle();
      expect(container.read(mediaProvider).droppedList.containsKey('movie_0'), isTrue);

      await tester.tap(find.byKey(const ValueKey('cleanup_undo_button')));
      await tester.pumpAndSettle();

      final state = container.read(mediaProvider);
      expect(state.droppedList.containsKey('movie_0'), isFalse);
      expect(state.maybeList.containsKey('movie_0'), isTrue);
      expect(find.text('Movie 0'), findsOneWidget);
    });

    testWidgets('Undo reverses Keep, restoring the card to the front of the queue',
        (tester) async {
      final container = await pumpCleanup(tester, count: 2);

      await tester.tap(find.text('Keep'));
      await tester.pumpAndSettle();
      expect(find.text('Movie 1'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('cleanup_undo_button')));
      await tester.pumpAndSettle();

      // Keep never touched the provider -- Movie 0 was always still Saved,
      // this just verifies the queue position itself is restored.
      expect(container.read(mediaProvider).maybeList.containsKey('movie_0'), isTrue);
      expect(find.text('Movie 0'), findsOneWidget);
    });

    testWidgets('reviewing every card reaches the empty state', (tester) async {
      await pumpCleanup(tester, count: 1);

      await tester.tap(find.text('Keep'));
      await tester.pumpAndSettle();

      expect(find.text('All cleaned up!'), findsOneWidget);
      expect(find.text('You reviewed 1 title.'), findsOneWidget);
    });

    testWidgets('only queues Saved titles matching the active Movies/TV toggle', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          movieRepositoryProvider.overrideWithValue(_InstantRepository()),
        ],
      );
      addTearDown(container.dispose);
      container.read(mediaProvider.notifier).addToMaybeList(_movie(0));
      container.read(mediaProvider.notifier).addToMaybeList(_tvShow(0));
      // Default activeMediaType is movies -- no explicit override needed.

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: CleanupSwipeScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Movie 0'), findsOneWidget);
      expect(find.text('Show 0'), findsNothing);
    });
  });

  group('PERS-SORT-1: cleanup banner in Saved shelf', () {
    Future<ProviderContainer> pumpSavedShelf(WidgetTester tester, {required int savedCount}) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          movieRepositoryProvider.overrideWithValue(_InstantRepository()),
        ],
      );
      addTearDown(container.dispose);
      for (var i = 0; i < savedCount; i++) {
        container.read(mediaProvider.notifier).addToMaybeList(_movie(i));
      }

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: Scaffold(body: ArchiveShelfScreen(kind: ArchiveShelfKind.saved))),
        ),
      );
      await tester.pumpAndSettle();
      return container;
    }

    testWidgets('does not appear at or below the threshold', (tester) async {
      await pumpSavedShelf(tester, savedCount: kArchiveCleanupThreshold);
      expect(find.byKey(const ValueKey('cleanup_banner_cta')), findsNothing);
    });

    testWidgets('appears once the Saved shelf exceeds the threshold', (tester) async {
      await pumpSavedShelf(tester, savedCount: kArchiveCleanupThreshold + 1);
      expect(find.byKey(const ValueKey('cleanup_banner_cta')), findsOneWidget);
    });

    testWidgets('dismissing the banner hides it for the session', (tester) async {
      await pumpSavedShelf(tester, savedCount: kArchiveCleanupThreshold + 1);
      expect(find.byKey(const ValueKey('cleanup_banner_cta')), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('cleanup_banner_dismiss')));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('cleanup_banner_cta')), findsNothing);
    });

    testWidgets('tapping "Clean up" opens CleanupSwipeScreen', (tester) async {
      await pumpSavedShelf(tester, savedCount: kArchiveCleanupThreshold + 1);

      await tester.tap(find.byKey(const ValueKey('cleanup_banner_cta')));
      await tester.pumpAndSettle();

      expect(find.byType(CleanupSwipeScreen), findsOneWidget);
    });
  });
}
