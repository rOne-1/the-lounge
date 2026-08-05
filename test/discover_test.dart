import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:the_lounge/screens/discover_screen.dart';
import 'package:the_lounge/providers/media_provider.dart';
import 'package:the_lounge/models/media_item.dart';
import 'package:the_lounge/models/discover_filter_params.dart';
import 'package:the_lounge/repositories/mock_movie_repository.dart';

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
          rating: 6.0,
          overview: '',
          genres: []),
      const MediaItem(
          id: '4',
          title: 'Movie 4',
          type: MediaType.movie,
          rating: 5.0,
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
    await tester.pumpAndSettle();

    // Verify we navigated to DetailScreen (e.g. Back button or detail layout appears)
    expect(find.byIcon(Icons.arrow_back), findsOneWidget);
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
}



