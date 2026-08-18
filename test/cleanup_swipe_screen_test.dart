import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:the_lounge/screens/cleanup_swipe_screen.dart';
import 'package:the_lounge/screens/pile_screen.dart';
import 'package:the_lounge/providers/media_provider.dart';
import 'package:the_lounge/providers/ambiance_provider.dart';
import 'package:the_lounge/models/media_item.dart';
import 'package:the_lounge/repositories/mock_movie_repository.dart';

class _InstantRepository extends MockMovieRepository {
  @override
  Future<MediaItem?> getMediaDetails(String id) async => null;
}

MediaItem _movie(int i) => MediaItem(
      id: 'movie-$i',
      title: 'Movie $i',
      type: MediaType.movie,
      rating: 7.0,
      overview: 'Overview $i',
      genres: const ['Drama'],
    );

MediaItem _tvShow(int i) => MediaItem(
      id: 'tv-$i',
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
      expect(state.watchlist.containsKey('movie-0'), isTrue);
      expect(find.text('Movie 1'), findsOneWidget);
    });

    testWidgets('Keep advances the queue without moving the card anywhere', (tester) async {
      final container = await pumpCleanup(tester, count: 2);

      await tester.tap(find.text('Keep'));
      await tester.pumpAndSettle();

      final state = container.read(mediaProvider);
      expect(state.maybeList.containsKey('movie-0'), isTrue);
      expect(state.watchlist.containsKey('movie-0'), isFalse);
      expect(state.droppedList.containsKey('movie-0'), isFalse);
      expect(find.text('Movie 1'), findsOneWidget);
    });

    testWidgets('Drop moves the front card to Dropped and advances the queue', (tester) async {
      final container = await pumpCleanup(tester, count: 2);

      await tester.tap(find.text('Drop'));
      await tester.pumpAndSettle();

      final state = container.read(mediaProvider);
      expect(state.droppedList.containsKey('movie-0'), isTrue);
      expect(find.text('Movie 1'), findsOneWidget);
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

  group('PERS-SORT-1: cleanup banner in Your Space', () {
    Future<ProviderContainer> pumpYourSpace(WidgetTester tester, {required int savedCount}) async {
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
          child: const MaterialApp(home: Scaffold(body: PileScreen(kind: PileKind.saved))),
        ),
      );
      await tester.pumpAndSettle();
      return container;
    }

    testWidgets('does not appear at or below the threshold', (tester) async {
      await pumpYourSpace(tester, savedCount: kPileCleanupThreshold);
      expect(find.byKey(const ValueKey('cleanup_banner_cta')), findsNothing);
    });

    testWidgets('appears once the Saved pile exceeds the threshold', (tester) async {
      await pumpYourSpace(tester, savedCount: kPileCleanupThreshold + 1);
      expect(find.byKey(const ValueKey('cleanup_banner_cta')), findsOneWidget);
    });

    testWidgets('dismissing the banner hides it for the session', (tester) async {
      await pumpYourSpace(tester, savedCount: kPileCleanupThreshold + 1);
      expect(find.byKey(const ValueKey('cleanup_banner_cta')), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('cleanup_banner_dismiss')));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('cleanup_banner_cta')), findsNothing);
    });

    testWidgets('tapping "Clean up" opens CleanupSwipeScreen', (tester) async {
      await pumpYourSpace(tester, savedCount: kPileCleanupThreshold + 1);

      await tester.tap(find.byKey(const ValueKey('cleanup_banner_cta')));
      await tester.pumpAndSettle();

      expect(find.byType(CleanupSwipeScreen), findsOneWidget);
    });
  });
}
