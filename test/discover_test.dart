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
import 'package:the_lounge/main.dart';

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
          genres: [],
          voteCount: 5000),
      const MediaItem(
          id: '2',
          title: 'Movie 2',
          type: MediaType.movie,
          rating: 7.0,
          overview: '',
          genres: [],
          voteCount: 5000),
      const MediaItem(
          id: '3',
          title: 'Movie 3',
          type: MediaType.movie,
          rating: 7.5,
          overview: '',
          genres: [],
          voteCount: 5000),
      const MediaItem(
          id: '4',
          title: 'Movie 4',
          type: MediaType.movie,
          rating: 7.2,
          overview: '',
          genres: [],
          voteCount: 5000),
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

/// A repository that returns two brand-new, well-voted items for every page
/// requested (effectively unlimited unique content), used to prove
/// swipe-triggered auto-pagination keeps working regardless of page number.
class _ManyPagesRepository extends MockMovieRepository {
  final Set<int> pagesServed = {};

  @override
  Future<List<MediaItem>> discoverMedia({
    required bool isMovies,
    required DiscoverFilterParams params,
    int page = 1,
  }) async {
    if (!isMovies) return [];
    pagesServed.add(page);
    return [
      MediaItem(
        id: 'p${page}a',
        title: 'Page $page Movie A',
        type: MediaType.movie,
        rating: 8.0,
        overview: '',
        genres: const [],
        voteCount: 5000,
      ),
      MediaItem(
        id: 'p${page}b',
        title: 'Page $page Movie B',
        type: MediaType.movie,
        rating: 8.0,
        overview: '',
        genres: const [],
        voteCount: 5000,
      ),
    ];
  }

  @override
  Future<List<MediaItem>> getPopularMovies({int page = 1}) async => [];

  @override
  Future<List<MediaItem>> getTrendingMovies({int page = 1}) async => [];

  @override
  Future<List<MediaItem>> getTopRatedMovies({int page = 1}) async => [];

  @override
  Future<List<MediaItem>> getTrendingTvShows({int page = 1}) async => [];

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

  test('Skipped titles are successfully persisted to SharedPreferences and pruned after their 6-month expiration window (B9)', () async {
    SharedPreferences.setMockInitialValues({
      'the_lounge_skipped_media_v2': jsonEncode({
        // Older than the old 30-day window but well inside the new 6-month
        // (182-day) one -- must survive.
        'valid_id': {
          'lastSkippedAt': DateTime.now().subtract(const Duration(days: 60)).toIso8601String(),
          'count': 1,
        },
        // Older than even the new 6-month window -- must be pruned.
        'expired_id': {
          'lastSkippedAt': DateTime.now().subtract(const Duration(days: 200)).toIso8601String(),
          'count': 1,
        },
        // Old and would normally be pruned, but crossed the permanent-skip
        // threshold -- must survive regardless of age.
        'permanent_id': {
          'lastSkippedAt': DateTime.now().subtract(const Duration(days: 200)).toIso8601String(),
          'count': 6,
        },
      }),
    });
    final prefs = await SharedPreferences.getInstance();

    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
    );
    addTearDown(container.dispose);

    final skippedIds = container.read(skippedMediaIdsProvider);
    expect(skippedIds.containsKey('expired_id'), isFalse);
    expect(skippedIds.containsKey('valid_id'), isTrue);
    expect(skippedIds.containsKey('permanent_id'), isTrue);
    expect(skippedIds['permanent_id']!.isPermanent, isTrue);

    container.read(skippedMediaIdsProvider.notifier).add('new_id');
    final stored = prefs.getString('the_lounge_skipped_media_v2');
    expect(stored, isNotNull);
    final decoded = jsonDecode(stored!) as Map<String, dynamic>;
    expect(decoded.containsKey('new_id'), isTrue);
    expect(decoded.containsKey('valid_id'), isTrue);
    expect(decoded.containsKey('permanent_id'), isTrue);
    expect(decoded.containsKey('expired_id'), isFalse);
  });

  test('A title becomes permanently skipped after more than 5 skips, and undo correctly decrements rather than wiping history (B9)', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    );
    addTearDown(container.dispose);

    final notifier = container.read(skippedMediaIdsProvider.notifier);

    for (var i = 0; i < 5; i++) {
      notifier.add('title_x');
    }
    expect(container.read(skippedMediaIdsProvider)['title_x']!.count, equals(5));
    expect(container.read(skippedMediaIdsProvider)['title_x']!.isPermanent, isFalse);

    // The 6th skip tips it into permanent.
    notifier.add('title_x');
    expect(container.read(skippedMediaIdsProvider)['title_x']!.count, equals(6));
    expect(container.read(skippedMediaIdsProvider)['title_x']!.isPermanent, isTrue);

    // Undoing that 6th skip must decrement back to 5/not-permanent, not
    // erase the whole history.
    notifier.undoSkip('title_x');
    expect(container.read(skippedMediaIdsProvider)['title_x']!.count, equals(5));
    expect(container.read(skippedMediaIdsProvider)['title_x']!.isPermanent, isFalse);

    // Undoing down to zero removes the record entirely.
    for (var i = 0; i < 5; i++) {
      notifier.undoSkip('title_x');
    }
    expect(container.read(skippedMediaIdsProvider).containsKey('title_x'), isFalse);
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

  group('B9: daily-capped manual "Reload deck", unlimited swipe pagination', () {
    test('manualReload works once, then is a no-op for the rest of the calendar day', () async {
      final mockRepo = TestRepository();
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final container = ProviderContainer(
        overrides: [
          movieRepositoryProvider.overrideWithValue(mockRepo),
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(discoverMoviesDeckProvider.notifier);
      await notifier.loadPool();
      expect(container.read(discoverMoviesDeckProvider).canManuallyReloadToday, isTrue);

      final firstAttempt = await notifier.manualReload();
      expect(firstAttempt, isTrue);
      expect(container.read(discoverMoviesDeckProvider).canManuallyReloadToday, isFalse);
      expect(container.read(discoverMoviesDeckProvider).lastManualReloadAt, isNotNull);

      // Persisted, so it survives a fresh notifier read (simulates the app
      // being reopened later the same day).
      final stored = prefs.getString('the_lounge_last_manual_reload_movies');
      expect(stored, isNotNull);

      final secondAttempt = await notifier.manualReload();
      expect(secondAttempt, isFalse,
          reason: 'a second manual reload the same day must be a no-op');
    });

    test('movies and TV each get their own independent daily reload allowance', () async {
      final mockRepo = TestRepository();
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final container = ProviderContainer(
        overrides: [
          movieRepositoryProvider.overrideWithValue(mockRepo),
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
      );
      addTearDown(container.dispose);

      // Bare container.read() on a NotifierProvider that nothing else
      // watches can race its own build()-triggered microtask against
      // disposal; hold a listener as a real Discover screen would.
      container.listen(discoverMoviesDeckProvider, (_, __) {});
      container.listen(discoverTvDeckProvider, (_, __) {});

      await container.read(discoverMoviesDeckProvider.notifier).loadPool();
      await container.read(discoverMoviesDeckProvider.notifier).manualReload();

      expect(container.read(discoverMoviesDeckProvider).canManuallyReloadToday, isFalse);
      // The TV deck's allowance is untouched by the movies deck's use.
      expect(container.read(discoverTvDeckProvider).canManuallyReloadToday, isTrue);
    });

    test('swipe-triggered auto-pagination (popCard) stays unlimited within a session, unaffected by the manual-reload cap', () async {
      final mockRepo = _ManyPagesRepository();
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final container = ProviderContainer(
        overrides: [
          movieRepositoryProvider.overrideWithValue(mockRepo),
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(discoverMoviesDeckProvider.notifier);
      await notifier.loadPool();
      expect(container.read(discoverMoviesDeckProvider).pool, isNotEmpty);

      // Use up today's one manual reload up front.
      await notifier.manualReload();
      expect(container.read(discoverMoviesDeckProvider).canManuallyReloadToday, isFalse);

      // Swipe through several cards -- each pop that empties the pool
      // triggers popCard's internal auto-reload (isReload: true), which
      // must keep working even though the manual allowance is spent.
      for (var i = 0; i < 20; i++) {
        final pool = container.read(discoverMoviesDeckProvider).pool;
        if (pool.isEmpty) break;
        notifier.popCard(pool.first, 'Left');
        // popCard's internal reload is async; let it settle.
        await Future<void>.delayed(const Duration(milliseconds: 10));
      }

      expect(mockRepo.pagesServed.length, greaterThan(1),
          reason: 'auto-pagination must have fetched beyond page 1 despite '
              'the manual-reload allowance already being used');
      expect(container.read(discoverMoviesDeckProvider).pool, isNotEmpty,
          reason: 'there is still more content available via normal swipe '
              'pagination -- the daily cap must not have blocked it');
    });
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
        child: MaterialApp(
          navigatorKey: rootNavigatorKey,
          home: const ShellScreen(enableAnimation: false),
          builder: (context, child) {
            return Stack(
              children: [
                child ?? const SizedBox(),
                const GlobalCapsuleLayer(enableAnimation: false),
              ],
            );
          },
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

    final capsuleFinder = find.byKey(const ValueKey('floating_nav_capsule'));
    Future<void> openCapsule() async {
      await tester.tap(capsuleFinder);
      await tester.pumpAndSettle();
    }

    Future<void> closeCapsule() async {
      // NAV-3: expanding the capsule covers the screen with a dismiss
      // barrier, so it must be explicitly collapsed again before the
      // underlying Discover card's own swipe controls are reachable.
      // Tapping the capsule's own center (rather than outside it) would
      // land on an inner control (e.g. the media-type toggle) and get
      // consumed by that nested GestureDetector instead of collapsing it.
      await tester.tapAt(const Offset(20, 20));
      await tester.pumpAndSettle();
    }

    // Simulate Left swipe (Skip)
    await tester.tap(find.byIcon(Icons.close).last);
    await tester.pumpAndSettle();

    // Verify no SnackBar is shown (we removed it)
    expect(find.text('Skipped "Movie 1"'), findsNothing);

    // Undo now lives in the floating navigation capsule's expanded utility
    // row (NAV-3), not a persistent top-bar button.
    await openCapsule();
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

    await closeCapsule();

    // Second swipe invalidates first swipe
    await tester.tap(find.byIcon(Icons.star_border).last); // Right swipe (Save for later)
    await tester.pumpAndSettle();

    await openCapsule();
    expect(find.byIcon(Icons.undo), findsOneWidget);
    await closeCapsule();

    await tester.tap(find.byIcon(Icons.bookmark_border).last); // Down swipe (Watchlist)
    await tester.pumpAndSettle();

    await openCapsule();
    expect(find.byIcon(Icons.undo), findsOneWidget);

    // Tap Undo (should only undo Movie 2)
    await tester.tap(find.byIcon(Icons.undo));
    await tester.pumpAndSettle();

    expect(find.text('Movie 2'), findsOneWidget);
    final mediaState = container.read(mediaProvider);
    expect(mediaState.maybeList.containsKey('1'), isTrue); // Movie 1 remains saved
    expect(mediaState.watchlist.containsKey('2'), isFalse); // Movie 2 undone
  });

  testWidgets(
      'DISC-1: undoing a swipe restores the card fully visible, not stuck off-screen',
      (WidgetTester tester) async {
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
    addTearDown(container.dispose);

    container.read(navigationProvider.notifier).setTab(AppTab.discover);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          navigatorKey: rootNavigatorKey,
          home: const ShellScreen(enableAnimation: false),
          builder: (context, child) {
            return Stack(
              children: [
                child ?? const SizedBox(),
                const GlobalCapsuleLayer(enableAnimation: false),
              ],
            );
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    if (find.text('Got it — start swiping').evaluate().isNotEmpty) {
      await tester.tap(find.text('Got it — start swiping'));
      await tester.pumpAndSettle();
    } else {
      await tester.tapAt(const Offset(100, 100));
      await tester.pumpAndSettle();
    }

    final topLeftBeforeSwipe = tester.getTopLeft(find.text('Movie 1'));

    // Skip (left swipe) via the action button, which triggers the same
    // flyOff()/_onSwipe() path as a real drag-release.
    await tester.tap(find.byIcon(Icons.close).last);
    await tester.pumpAndSettle();
    expect(find.text('Movie 1'), findsNothing);

    // Undo through the floating navigation capsule (NAV-3).
    await tester.tap(find.byKey(const ValueKey('floating_nav_capsule')));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.undo));
    await tester.pumpAndSettle();

    expect(find.text('Movie 1'), findsOneWidget);
    // The restored card must render back at (roughly) its original resting
    // position, not still translated off-screen from its fly-off animation
    // -- a stale GlobalKey/State reuse would leave _dragOffset parked at
    // the fly-off distance instead of resetting to zero.
    final topLeftAfterUndo = tester.getTopLeft(find.text('Movie 1'));
    expect((topLeftAfterUndo - topLeftBeforeSwipe).distance, lessThan(5));
  });

  test(
      'TF-2: importBackupJson refreshes discover pool and evicts imported titles',
      () async {
    // Approach: seed the discover pool with movie_1 via _SingleMovieRepository,
    // confirm it's present, then import a backup that puts movie_1 in the
    // watchlist. importBackupJson's post-import pool refresh re-applies the
    // (now updated) exclusion list, so movie_1 must be evicted afterward.
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    // Build the backup JSON with movie_1 in watchlist.
    final backupJson = jsonEncode({
      'version': 1,
      'watchlist': {
        '1': {
          'id': '1',
          'title': 'Movie 1',
          'type': 'movie',
          'rating': 8.0,
          'posterUrl': null,
        },
      },
      'maybeList': {},
      'watchingList': {},
      'watchedList': {},
      'droppedList': {},
      'onHoldList': {},
      'watchedEpisodes': {},
      'watchProvidersCountry': 'US',
      'selectedAmbiance': null,
    });

    // Use a single container: repo that initially returns movie_1, but after
    // import the loadPool refresh is also run against that same repo.  To truly
    // evict movie_1 we rely on the exclusion logic: movie_1 is now in the
    // watchlist, so loadPool excludes it.  Use _SingleMovieRepository which
    // returns movie_1 from discoverMedia — importBackupJson's pool refresh will
    // then exclude it via the updated watchlist.
    final singleRepoContainer = ProviderContainer(
      overrides: [
        movieRepositoryProvider.overrideWithValue(_SingleMovieRepository()),
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
    );
    addTearDown(singleRepoContainer.dispose);

    // Seed the deck.
    await singleRepoContainer
        .read(discoverMoviesDeckProvider.notifier)
        .loadPool(isReload: false);
    expect(
        singleRepoContainer
            .read(discoverMoviesDeckProvider)
            .pool
            .any((item) => item.id == '1'),
        isTrue,
        reason: 'Precondition: movie_1 must be in pool before import');

    // Run the import.
    final importResult = await singleRepoContainer
        .read(mediaProvider.notifier)
        .importBackupJson(backupJson);
    expect(importResult, isTrue);

    // importBackupJson refreshes BOTH discover decks fire-and-forget
    // (deliberately not awaited in production, so import itself stays
    // fast -- see the `try { ...; ... } catch (_) {}` block with no
    // `await` in importBackupJson). A test-isolation bug here (notepad
    // item 18): this test previously only waited a flat delay and never
    // touched discoverTvDeckProvider directly, so its own fire-and-forget
    // loadPool could still be in flight -- using its Ref -- when
    // addTearDown disposed the container, throwing "Ref used after
    // dispose" when run standalone (masked in full-file runs by
    // incidental timing from earlier tests). Explicitly (re-)awaiting
    // both notifiers' loadPool here is idempotent and guarantees nothing
    // is left in flight before this test function returns.
    await singleRepoContainer
        .read(discoverMoviesDeckProvider.notifier)
        .loadPool(isReload: false);
    await singleRepoContainer
        .read(discoverTvDeckProvider.notifier)
        .loadPool(isReload: false);

    // Step 5: movie_1 must no longer appear in the discover pool.
    final poolAfter =
        singleRepoContainer.read(discoverMoviesDeckProvider).pool;
    expect(poolAfter.any((item) => item.id == '1'), isFalse,
        reason:
            'movie_1 was imported into watchlist and must be evicted from the discover pool');
  });
}

/// A mock repository that returns exactly one movie (id=1, rating=8.0) from
/// [discoverMedia], used to seed the discover deck pool in TF-2 tests.
class _SingleMovieRepository extends MockMovieRepository {
  static const _movie1 = MediaItem(
    id: '1',
    title: 'Movie 1',
    type: MediaType.movie,
    rating: 8.0,
    overview: '',
    genres: [],
    voteCount: 5000,
  );

  @override
  Future<List<MediaItem>> discoverMedia({
    required bool isMovies,
    required DiscoverFilterParams params,
    int page = 1,
  }) async {
    if (!isMovies || page > 1) return [];
    return [_movie1];
  }

  @override
  Future<List<MediaItem>> getPopularMovies({int page = 1}) async => [];

  @override
  Future<List<MediaItem>> getTrendingMovies({int page = 1}) async => [];

  @override
  Future<List<MediaItem>> getTopRatedMovies({int page = 1}) async => [];

  @override
  Future<List<MediaItem>> getNowPlayingMovies({
    int page = 1,
    String? region,
  }) async =>
      [];

  @override
  Future<List<MediaItem>> getUpcomingMovies({int page = 1}) async => [];
}
