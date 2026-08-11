import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:the_lounge/screens/discover_screen.dart';
import 'package:the_lounge/screens/detail_screen.dart';
import 'package:the_lounge/providers/media_provider.dart';
import 'package:the_lounge/models/media_item.dart';
import 'package:the_lounge/models/discover_filter_params.dart';
import 'package:the_lounge/repositories/mock_movie_repository.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:the_lounge/providers/navigation_provider.dart';
import 'package:the_lounge/providers/ambiance_provider.dart';
import 'package:the_lounge/screens/shell_screen.dart';

class TestRepository extends MockMovieRepository {
  @override
  Future<List<MediaItem>> getTrendingMovies({int page = 1}) async {
    return [
      const MediaItem(
          id: '1',
          title: 'Movie 1',
          type: MediaType.movie,
          rating: 8.0,
          overview: '',
          genres: []),
      const MediaItem(
          id: '2',
          title: 'Movie 2',
          type: MediaType.movie,
          rating: 7.0,
          overview: '',
          genres: []),
      const MediaItem(
          id: '3',
          title: 'Movie 3',
          type: MediaType.movie,
          rating: 7.5,
          overview: '',
          genres: []),
      const MediaItem(
          id: '4',
          title: 'Movie 4',
          type: MediaType.movie,
          rating: 7.2,
          overview: '',
          genres: []),
    ];
  }

  @override
  Future<List<MediaItem>> getPopularMovies({int page = 1}) async {
    return [];
  }

  @override
  Future<List<MediaItem>> getTrendingTvShows({int page = 1}) async => [];

  @override
  Future<List<MediaItem>> getTopRatedMovies({int page = 1}) async => [];

  @override
  Future<List<MediaItem>> getTopRatedTvShows({int page = 1}) async => [];

  @override
  Future<List<MediaItem>> getNowPlayingMovies({int page = 1, String? region}) async => [];

  @override
  Future<List<MediaItem>> getAiringTodayTvShows({int page = 1}) async => [];

  @override
  Future<List<MediaItem>> getUpcomingMovies({int page = 1}) async => [];

  @override
  Future<List<MediaItem>> getOnTheAirTvShows({int page = 1}) async => [];

  @override
  Future<MediaItem?> getMediaDetails(String id) async => null;

  @override
  Future<TvSeason?> getTvSeasonDetails(String tvId, int seasonNumber) async => null;

  @override
  Future<List<MediaItem>> searchMedia(String query) async => [];

  @override
  Future<List<Map<String, String>>> getWatchProviderRegions() async => [];

  @override
  Future<List<MediaItem>> discoverMedia({
    required bool isMovies,
    required DiscoverFilterParams params,
    int page = 1,
  }) async =>
      getTrendingMovies();

  @override
  Future<List<Map<String, dynamic>>> searchPersons(String query) async => [];
}

void main() {
  testWidgets('Discover screen swipe gestures update provider state',
      (WidgetTester tester) async {
    GoogleFonts.config.allowRuntimeFetching = false;
    final mockRepo = TestRepository();
    final container = ProviderContainer(
      overrides: [
        movieRepositoryProvider.overrideWithValue(mockRepo),
      ],
    );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: Scaffold(
            body: DiscoverScreen(),
          ),
        ),
      ),
    );

    // Wait for the Future to complete and UI to update
    await tester.pumpAndSettle();

    // Dismiss Legend Overlay
    await tester.tapAt(const Offset(100, 100));
    await tester.pumpAndSettle();

    // Verify Movie 1 is displayed
    expect(find.text('Movie 1'), findsOneWidget);

    // Simulate Right swipe (Maybe) by tapping the floating action button
    // It's a star_border or star in our new UI (we used star_border)
    await tester.tap(find.byIcon(Icons.star_border));
    await tester.pumpAndSettle();

    // Verify provider state
    var state = container.read(mediaProvider);
    expect(state.maybeList.containsKey('1'), isTrue);

    // Verify Movie 2 is now displayed
    expect(find.text('Movie 2'), findsOneWidget);

    // Simulate Down swipe (Watchlist) (we used bookmark_border)
    await tester.tap(find.byIcon(Icons.bookmark_border));
    await tester.pumpAndSettle();

    state = container.read(mediaProvider);
    expect(state.watchlist.containsKey('2'), isTrue);

    // Simulate Up swipe (Watched) (we used check)
    await tester.tap(find.byIcon(Icons.check).last);
    await tester.pumpAndSettle();

    state = container.read(mediaProvider);
    expect(state.watchedList.containsKey('3'), isTrue);

    // Simulate Left swipe (Skip) (we used close)
    await tester.tap(find.byIcon(Icons.close).last);
    await tester.pumpAndSettle();

    // Verify it was skipped (not in any list)
    state = container.read(mediaProvider);
    expect(state.watchlist.containsKey('4'), isFalse);
    expect(state.maybeList.containsKey('4'), isFalse);
    expect(state.watchedList.containsKey('4'), isFalse);

    expect(find.text('No titles in recommendations'), findsOneWidget);
  });

  testWidgets('Tapping Discover card navigates to DetailScreen',
      (WidgetTester tester) async {
    GoogleFonts.config.allowRuntimeFetching = false;
    final mockRepo = TestRepository();
    final container = ProviderContainer(
      overrides: [
        movieRepositoryProvider.overrideWithValue(mockRepo),
      ],
    );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: Scaffold(
            body: DiscoverScreen(),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Dismiss Legend Overlay
    await tester.tap(find.text('Got it — start swiping'));
    await tester.pumpAndSettle();

    // Verify Movie 1 is displayed
    expect(find.text('Movie 1'), findsOneWidget);

    // Tap on the card
    await tester.tap(find.text('Movie 1'));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 500));

    // Verify we navigated to DetailScreen (e.g. Back button or detail layout appears)
    expect(find.byType(DetailScreen), findsOneWidget);
  });

  testWidgets('Swiping drag gesture triggers early completion when exceeding 70% threshold',
      (WidgetTester tester) async {
    GoogleFonts.config.allowRuntimeFetching = false;
    final mockRepo = TestRepository();
    final container = ProviderContainer(
      overrides: [
        movieRepositoryProvider.overrideWithValue(mockRepo),
      ],
    );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: Scaffold(
            body: DiscoverScreen(),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Dismiss Legend Overlay
    await tester.tap(find.text('Got it — start swiping'));
    await tester.pumpAndSettle();

    expect(find.text('Movie 1'), findsOneWidget);

    // Drag Movie 1 to the right past 70% of screen width (e.g. 500px)
    await tester.drag(find.text('Movie 1'), const Offset(600, 0));
    await tester.pump(const Duration(milliseconds: 50));

    // Movie 1 should be removed and Movie 2 should now be visible
    expect(find.text('Movie 2'), findsOneWidget);
  });

  testWidgets('Action button visual highlight triggers on swipe gesture and direct button tap',
      (WidgetTester tester) async {
    GoogleFonts.config.allowRuntimeFetching = false;
    final mockRepo = TestRepository();
    final container = ProviderContainer(
      overrides: [
        movieRepositoryProvider.overrideWithValue(mockRepo),
      ],
    );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: Scaffold(
            body: DiscoverScreen(),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Dismiss Legend Overlay
    await tester.tap(find.text('Got it — start swiping'));
    await tester.pumpAndSettle();

    expect(find.text('Movie 1'), findsOneWidget);

    // Tap Right action button (Save/Maybe)
    await tester.tap(find.byIcon(Icons.star_border));
    await tester.pump();

    // During tap/flyoff animation, Right action button highlights with scale 1.12
    final tapScales = tester.widgetList<AnimatedScale>(find.byType(AnimatedScale));
    expect(tapScales.any((s) => (s.scale - 1.12).abs() < 0.01), isTrue);

    await tester.pumpAndSettle();

    // Movie 2 is now displayed and all action button scales revert to 1.0
    expect(find.text('Movie 2'), findsOneWidget);
    final settledScales = tester.widgetList<AnimatedScale>(find.byType(AnimatedScale));
    expect(settledScales.every((s) => (s.scale - 1.0).abs() < 0.01), isTrue);

    // Tap Down action button (Watchlist)
    await tester.tap(find.byIcon(Icons.bookmark_border));
    await tester.pump();

    // During flyoff animation, Watchlist button highlights with scale 1.12
    final watchlistScales = tester.widgetList<AnimatedScale>(find.byType(AnimatedScale));
    expect(watchlistScales.any((s) => (s.scale - 1.12).abs() < 0.01), isTrue);

    await tester.pumpAndSettle();

    // Movie 3 is now displayed
    expect(find.text('Movie 3'), findsOneWidget);
  });

  test('Skipped titles are successfully persisted to SharedPreferences and pruned after their expiration window', () async {
    SharedPreferences.setMockInitialValues({
      'the_lounge_skipped_media_v2': jsonEncode({
        'expired_id': DateTime.now().subtract(const Duration(days: 35)).toIso8601String(),
        'valid_id': DateTime.now().subtract(const Duration(days: 10)).toIso8601String(),
      }),
    });
    final prefs = await SharedPreferences.getInstance();
    
    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
    );

    final skippedIds = container.read(skippedMediaIdsProvider);
    expect(skippedIds.containsKey('expired_id'), isFalse);
    expect(skippedIds.containsKey('valid_id'), isTrue);

    container.read(skippedMediaIdsProvider.notifier).add('new_id');
    final stored = prefs.getString('the_lounge_skipped_media_v2');
    expect(stored, isNotNull);
    final decoded = jsonDecode(stored!) as Map<String, dynamic>;
    expect(decoded.containsKey('new_id'), isTrue);
    expect(decoded.containsKey('valid_id'), isTrue);
    expect(decoded.containsKey('expired_id'), isFalse);
  });

  testWidgets('Discover deck state is preserved when switching tabs', (WidgetTester tester) async {
    GoogleFonts.config.allowRuntimeFetching = false;
    final mockRepo = TestRepository();
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [
        movieRepositoryProvider.overrideWithValue(mockRepo),
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
    );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: Scaffold(
            body: DiscoverScreen(),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();
    
    final moviesDeckBefore = container.read(discoverMoviesDeckProvider);
    expect(moviesDeckBefore.pool.isNotEmpty, isTrue);

    // Switch to TV
    container.read(navigationProvider.notifier).setMediaType(MediaTypeToggle.tv);
    await tester.pumpAndSettle();

    // Switch back to Movies
    container.read(navigationProvider.notifier).setMediaType(MediaTypeToggle.movies);
    await tester.pumpAndSettle();

    final moviesDeckAfter = container.read(discoverMoviesDeckProvider);
    expect(moviesDeckAfter.pool, equals(moviesDeckBefore.pool));
  });

  test('Discover deck pagination search automatically fetches new pages in background when pages are fully excluded', () async {
    final mockRepo = TestRepository();
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [
        movieRepositoryProvider.overrideWithValue(mockRepo),
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
    );
    
    // add '1' and '2' to watchlist so they are excluded
    final mediaNotifier = container.read(mediaProvider.notifier);
    mediaNotifier.addToWatchlist(const MediaItem(id: '1', title: 'Movie 1', type: MediaType.movie, rating: 8.0, overview: '', genres: []));
    mediaNotifier.addToWatchlist(const MediaItem(id: '2', title: 'Movie 2', type: MediaType.movie, rating: 7.0, overview: '', genres: []));

    // this will attempt to load and initially see 1 and 2 excluded, and since TestRepository only returns 4 items, 
    // it should fetch pages and then end up with item 3 and 4 in the pool.
    final deckNotifier = container.read(discoverMoviesDeckProvider.notifier);
    await deckNotifier.loadPool();
    
    final pool = container.read(discoverMoviesDeckProvider).pool;
    expect(pool.any((item) => item.id == '1' || item.id == '2'), isFalse);
    expect(pool.any((item) => item.id == '3' || item.id == '4'), isTrue);
  });

  testWidgets('Swiping a card shows Undo SnackBar and tapping it reverts the swipe', (WidgetTester tester) async {
    GoogleFonts.config.allowRuntimeFetching = false;
    final mockRepo = TestRepository();
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [
        movieRepositoryProvider.overrideWithValue(mockRepo),
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
    );

    // Switch active tab to AppTab.discover
    container.read(navigationProvider.notifier).setTab(AppTab.discover);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: ShellScreen(enableAnimation: false),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Dismiss Legend Overlay if it exists
    if (find.text('Got it — start swiping').evaluate().isNotEmpty) {
      await tester.tap(find.text('Got it — start swiping'));
      await tester.pumpAndSettle();
    } else {
      await tester.tapAt(const Offset(100, 100));
      await tester.pumpAndSettle();
    }

    // Verify Movie 1 is displayed
    expect(find.text('Movie 1'), findsOneWidget);

    // Simulate Left swipe (Skip)
    await tester.tap(find.byIcon(Icons.close).last);
    await tester.pumpAndSettle();

    // Verify no SnackBar is shown (we removed it)
    expect(find.text('Skipped "Movie 1"'), findsNothing);
    
    // Find the undo button on the top bar
    expect(find.byIcon(Icons.undo), findsOneWidget);
    
    // Movie 1 should be gone, Movie 2 displayed
    expect(find.text('Movie 1'), findsNothing);
    expect(find.text('Movie 2'), findsOneWidget);

    // Tap Undo
    await tester.tap(find.byIcon(Icons.undo));
    await tester.pumpAndSettle();

    // Movie 1 should be back
    expect(find.text('Movie 1'), findsOneWidget);

    // Verify it was unskipped
    final skippedState = container.read(skippedMediaIdsProvider);
    expect(skippedState.containsKey('1'), isFalse);
    expect(skippedState.containsKey('movie_1'), isFalse); // Assert on prefixed id as well

    // Second swipe invalidates first swipe
    await tester.tap(find.byIcon(Icons.star_border).last); // Right swipe (Save for later)
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.undo), findsOneWidget);
    
    await tester.tap(find.byIcon(Icons.bookmark_border).last); // Down swipe (Watchlist)
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.undo), findsOneWidget);
    
    // Tap Undo (should only undo Movie 2)
    await tester.tap(find.byIcon(Icons.undo));
    await tester.pumpAndSettle();

    expect(find.text('Movie 2'), findsOneWidget);
    final mediaState = container.read(mediaProvider);
    expect(mediaState.maybeList.containsKey('1'), isTrue); // Movie 1 remains saved
    expect(mediaState.watchlist.containsKey('2'), isFalse); // Movie 2 undone
  });
}


