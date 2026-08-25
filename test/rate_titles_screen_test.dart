import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:the_lounge/screens/rate_titles_screen.dart';
import 'package:the_lounge/screens/detail_screen.dart';
import 'package:the_lounge/providers/media_provider.dart';
import 'package:the_lounge/providers/ambiance_provider.dart';
import 'package:the_lounge/models/media_item.dart';
import 'package:the_lounge/repositories/mock_movie_repository.dart';

/// The default MockMovieRepository simulates network latency
/// (Future.delayed(500ms)) on getMediaDetails -- addToWatchedList fires that
/// call fire-and-forget for collection enrichment, and the widget tree
/// disposing before it resolves trips flutter_test's pending-timer
/// invariant check. Mirrors settings_screen_test.dart's
/// _InstantEmptyRepository pattern.
class _InstantRepository extends MockMovieRepository {
  @override
  Future<MediaItem?> getMediaDetails(String id, {String? region}) async => null;
}

void main() {
  setUp(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  final movie1 = MediaItem(
    id: 'movie_1',
    title: 'Alpha',
    type: MediaType.movie,
    rating: 7.0,
    releaseOrAirDate: DateTime(2020, 1, 1),
    overview: 'First unrated movie.',
    genres: const ['Action'],
  );
  final movie2 = MediaItem(
    id: 'movie_2',
    title: 'Beta',
    type: MediaType.movie,
    rating: 6.5,
    releaseOrAirDate: DateTime(2021, 1, 1),
    overview: 'Second unrated movie.',
    genres: const ['Comedy'],
  );

  Future<ProviderContainer> pumpScreen(WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        movieRepositoryProvider.overrideWithValue(_InstantRepository()),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: RateTitlesScreen()),
      ),
    );
    await tester.pumpAndSettle();
    return container;
  }

  group('PERS-RATE-2: unratedWatchedTitles', () {
    test('only includes watched titles without an overall PersonalRating', () {
      const state = MediaState();
      final withWatched = state.copyWith(
        watchedList: {movie1.id: movie1, movie2.id: movie2},
        watchHistory: {
          movie1.id: [WatchRecord(rating: PersonalRating.loved, isFirstWatch: true)],
        },
      );

      final result = unratedWatchedTitles(withWatched);

      expect(result.map((m) => m.id), [movie2.id]);
    });
  });

  group('PERS-RATE-2: RateTitlesScreen', () {
    testWidgets('shows the congratulatory empty state when nothing is unrated', (tester) async {
      await pumpScreen(tester);

      expect(find.text("You're all caught up!"), findsOneWidget);
      expect(find.text('All watched movies are rated.'), findsOneWidget);
    });

    testWidgets('presents the first unrated watched title with rating tiers and a Skip button',
        (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final container = ProviderContainer(
        overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        movieRepositoryProvider.overrideWithValue(_InstantRepository()),
      ],
      );
      addTearDown(container.dispose);
      container.read(mediaProvider.notifier).addToWatchedList(movie1);
      container.read(mediaProvider.notifier).addToWatchedList(movie2);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: RateTitlesScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('2 titles left to rate'), findsOneWidget);
      expect(find.text('Alpha'), findsOneWidget);
      for (final rating in PersonalRating.values) {
        expect(find.text(rating.label), findsOneWidget);
      }
      expect(find.text('Skip'), findsOneWidget);
    });

    testWidgets('only queues unrated watched titles matching the active Movies/TV toggle',
        (tester) async {
      final tvShow = MediaItem(
        id: 'tv-1',
        title: 'Gamma',
        type: MediaType.tv,
        rating: 8.0,
        overview: 'An unrated show.',
        genres: const ['Drama'],
      );
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          movieRepositoryProvider.overrideWithValue(_InstantRepository()),
        ],
      );
      addTearDown(container.dispose);
      container.read(mediaProvider.notifier).addToWatchedList(movie1);
      container.read(mediaProvider.notifier).addToWatchedList(tvShow);
      // Default activeMediaType is movies -- no explicit override needed.

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: RateTitlesScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('1 title left to rate'), findsOneWidget);
      expect(find.text('Alpha'), findsOneWidget);
    });

    testWidgets('tapping a rating tier rates the front card and advances the queue',
        (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final container = ProviderContainer(
        overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        movieRepositoryProvider.overrideWithValue(_InstantRepository()),
      ],
      );
      addTearDown(container.dispose);
      container.read(mediaProvider.notifier).addToWatchedList(movie1);
      container.read(mediaProvider.notifier).addToWatchedList(movie2);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: RateTitlesScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Alpha'), findsOneWidget);
      await tester.tap(find.text('Loved it'));
      await tester.pumpAndSettle();

      final history = container.read(mediaProvider).watchHistory[movie1.id];
      expect(history, hasLength(1));
      expect(history!.first.rating, PersonalRating.loved);
      expect(history.first.isFirstWatch, isTrue);

      // Queue advanced: Beta is now the front card, and only 1 remains.
      expect(find.text('Beta'), findsOneWidget);
      expect(find.text('1 title left to rate'), findsOneWidget);
    });

    testWidgets('tapping Skip advances the queue without rating the card', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final container = ProviderContainer(
        overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        movieRepositoryProvider.overrideWithValue(_InstantRepository()),
      ],
      );
      addTearDown(container.dispose);
      container.read(mediaProvider.notifier).addToWatchedList(movie1);
      container.read(mediaProvider.notifier).addToWatchedList(movie2);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: RateTitlesScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Alpha'), findsOneWidget);
      await tester.tap(find.text('Skip'));
      await tester.pumpAndSettle();

      // Alpha rotates to the back of the (2-item) queue, unrated.
      expect(find.text('Beta'), findsOneWidget);
      expect(container.read(mediaProvider).watchHistory[movie1.id], isNull);
      expect(container.read(mediaProvider).watchHistory[movie2.id], isNull);
    });

    testWidgets('Undo reverses the last rating and restores the card to the front',
        (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final container = ProviderContainer(
        overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        movieRepositoryProvider.overrideWithValue(_InstantRepository()),
      ],
      );
      addTearDown(container.dispose);
      container.read(mediaProvider.notifier).addToWatchedList(movie1);
      container.read(mediaProvider.notifier).addToWatchedList(movie2);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: RateTitlesScreen()),
        ),
      );
      await tester.pumpAndSettle();

      // No undo button until an action has been taken.
      expect(find.byKey(const ValueKey('rate_titles_undo_button')), findsNothing);

      await tester.tap(find.text('Loved it'));
      await tester.pumpAndSettle();
      expect(find.text('Beta'), findsOneWidget);
      expect(container.read(mediaProvider).watchHistory[movie1.id], hasLength(1));

      await tester.tap(find.byKey(const ValueKey('rate_titles_undo_button')));
      await tester.pumpAndSettle();

      // The rating is reversed and Alpha is back at the front of the queue.
      expect(container.read(mediaProvider).watchHistory[movie1.id], isNull);
      expect(find.text('Alpha'), findsOneWidget);
      expect(find.text('2 titles left to rate'), findsOneWidget);
      expect(find.byKey(const ValueKey('rate_titles_undo_button')), findsNothing);
    });

    testWidgets('Undo reverses the last skip, restoring the card to the front',
        (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final container = ProviderContainer(
        overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        movieRepositoryProvider.overrideWithValue(_InstantRepository()),
      ],
      );
      addTearDown(container.dispose);
      container.read(mediaProvider.notifier).addToWatchedList(movie1);
      container.read(mediaProvider.notifier).addToWatchedList(movie2);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: RateTitlesScreen()),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Skip'));
      await tester.pumpAndSettle();
      expect(find.text('Beta'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('rate_titles_undo_button')));
      await tester.pumpAndSettle();

      expect(find.text('Alpha'), findsOneWidget);
      expect(container.read(mediaProvider).watchHistory[movie1.id], isNull);
    });

    testWidgets('RATE-CARD-1: tapping the card opens DetailScreen for that title',
        (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          movieRepositoryProvider.overrideWithValue(_InstantRepository()),
        ],
      );
      addTearDown(container.dispose);
      container.read(mediaProvider.notifier).addToWatchedList(movie1);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: RateTitlesScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Alpha'), findsOneWidget);
      await tester.tap(find.text('Alpha'));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(DetailScreen), findsOneWidget);
    });

    testWidgets('rating every title reaches the empty state', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final container = ProviderContainer(
        overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        movieRepositoryProvider.overrideWithValue(_InstantRepository()),
      ],
      );
      addTearDown(container.dispose);
      container.read(mediaProvider.notifier).addToWatchedList(movie1);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: RateTitlesScreen()),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Loved it'));
      await tester.pumpAndSettle();

      expect(find.text("You're all caught up!"), findsOneWidget);
    });
  });
}
