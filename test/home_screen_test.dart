import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:the_lounge/screens/home_screen.dart';
import 'package:the_lounge/screens/detail_screen.dart';
import 'package:the_lounge/providers/media_provider.dart';
import 'package:the_lounge/providers/navigation_provider.dart';
import 'package:the_lounge/models/media_item.dart';
import 'package:the_lounge/models/discover_filter_params.dart';
import 'package:the_lounge/repositories/mock_movie_repository.dart';
import 'package:the_lounge/widgets/pick_for_me_card.dart';

class MockTestRepository extends MockMovieRepository {
  final List<MediaItem> trendingMovies;
  final List<MediaItem> popularMovies;
  final List<MediaItem> trendingTvShows;

  MockTestRepository({
    required this.trendingMovies,
    required this.popularMovies,
    required this.trendingTvShows,
  });

  @override
  Future<List<MediaItem>> getTrendingMovies({int page = 1}) async => trendingMovies;

  @override
  Future<List<MediaItem>> getPopularMovies({int page = 1}) async => popularMovies;

  @override
  Future<List<MediaItem>> getTrendingTvShows({int page = 1}) async => trendingTvShows;

  @override
  Future<List<MediaItem>> getTopRatedMovies({int page = 1}) async => trendingMovies;

  @override
  Future<List<MediaItem>> getTopRatedTvShows({int page = 1}) async => trendingTvShows;

  @override
  Future<List<MediaItem>> getNowPlayingMovies({int page = 1, String? region}) async => trendingMovies;

  @override
  Future<List<MediaItem>> getAiringTodayTvShows({int page = 1}) async => trendingTvShows;

  @override
  Future<List<MediaItem>> getUpcomingMovies({int page = 1}) async => trendingMovies;

  @override
  Future<List<MediaItem>> getOnTheAirTvShows({int page = 1}) async => trendingTvShows;

  @override
  Future<MediaItem?> getMediaDetails(String id) async {
    final all = [...trendingMovies, ...popularMovies, ...trendingTvShows];
    final cleanId = id.replaceFirst(RegExp(r'^(movie_|tv_)'), '');
    return all.firstWhere(
      (item) => item.id == id || item.prefixedId == id || item.id == cleanId,
    );
  }

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
      isMovies ? trendingMovies : trendingTvShows;

  @override
  Future<List<Map<String, dynamic>>> searchPersons(String query) async => [];
}

void main() {
  setUp(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  List<MediaItem> createMockItems(int count, String prefix, MediaType type) {
    return List.generate(
      count,
      (index) => MediaItem(
        id: '$prefix-$index',
        title: '$prefix Movie $index',
        type: type,
        rating: 8.0,
        overview: 'Overview for $prefix $index',
        genres: const ['Action'],
      ),
    );
  }

  testWidgets('HomeScreen displays dynamic greeting, trending carousel, and PickForMe card', (WidgetTester tester) async {
    final trending = createMockItems(6, 'Trending', MediaType.movie);
    final popular = createMockItems(4, 'Continue', MediaType.movie);
    final mockRepo = MockTestRepository(
      trendingMovies: trending,
      popularMovies: popular,
      trendingTvShows: [],
    );

    final container = ProviderContainer(
      overrides: [
        movieRepositoryProvider.overrideWithValue(mockRepo),
      ],
    );
    container.read(mediaProvider.notifier).addToWatchlist(popular[0]);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: Scaffold(
            body: HomeScreen(enableAnimation: false),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify dynamic greeting contains current day name
    const dayNames = [
      'MONDAY',
      'TUESDAY',
      'WEDNESDAY',
      'THURSDAY',
      'FRIDAY',
      'SATURDAY',
      'SUNDAY',
    ];
    final currentDay = dayNames[DateTime.now().weekday - 1];
    expect(find.textContaining(currentDay), findsOneWidget);

    // Verify PickForMe card is rendered in Movies mode
    expect(find.text('PICK FOR ME'), findsOneWidget);
    // "Continue Movie 0" (popular[0], seeded into the watchlist above) now
    // legitimately appears twice: PickForMeCard picks from the watchlist,
    // and the E12 "Your Watchlist" rail shows the watchlist itself.
    expect(find.text('Continue Movie 0'), findsAtLeastNWidgets(1));

    // Verify Trending carousel items are rendered
    expect(find.text('Trending This Week'), findsOneWidget);

    // Verify tapping on PickForMe item navigates to DetailScreen
    await tester.tap(find.descendant(
      of: find.byType(PickForMeCard),
      matching: find.text('Continue Movie 0'),
    ));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byType(DetailScreen), findsOneWidget);
    expect(find.text('Continue Movie 0'), findsOneWidget);
  });

  testWidgets('HomeScreen contains AnimatedSize, AnimatedCrossFade and AnimatedSwitcher transitions for TV mode', (WidgetTester tester) async {
    final trending = createMockItems(6, 'Trending', MediaType.movie);
    final popular = createMockItems(4, 'Continue', MediaType.movie);
    // Non-empty: MediaRail now hides itself entirely (no AnimatedSwitcher)
    // once its data has resolved empty (E1 cleanup), so this needs real TV
    // rail content for the "at least 2 AnimatedSwitcher" assertion below to
    // mean anything in TV mode.
    final trendingTv = createMockItems(4, 'Trending TV', MediaType.tv);
    final mockRepo = MockTestRepository(
      trendingMovies: trending,
      popularMovies: popular,
      trendingTvShows: trendingTv,
    );

    final container = ProviderContainer(
      overrides: [
        movieRepositoryProvider.overrideWithValue(mockRepo),
      ],
    );
    container.read(navigationProvider.notifier).setMediaType(MediaTypeToggle.tv);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: Scaffold(
            body: HomeScreen(enableAnimation: false),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify AnimatedSize & AnimatedCrossFade exist for Next Episode card
    expect(find.byType(AnimatedSize), findsAtLeastNWidgets(1));
    expect(find.byType(AnimatedCrossFade), findsAtLeastNWidgets(1));

    // Verify AnimatedSwitcher exists for Continue Watching & Trending sections
    expect(find.byType(AnimatedSwitcher), findsAtLeastNWidgets(2));

    // E3/TF-25: "On The Air" TV carousel removed.
    expect(find.text('On The Air'), findsNothing);
  });

  testWidgets('E3/TF-25: movies mode keeps the "Upcoming" rail', (WidgetTester tester) async {
    final trending = createMockItems(2, 'Trending', MediaType.movie);
    final mockRepo = MockTestRepository(
      trendingMovies: trending,
      popularMovies: [],
      trendingTvShows: [],
    );

    final container = ProviderContainer(
      overrides: [
        movieRepositoryProvider.overrideWithValue(mockRepo),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: Scaffold(body: HomeScreen(enableAnimation: false)),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Upcoming'), findsOneWidget);
  });

  group('E12: Your Watchlist rail', () {
    testWidgets('shows watchlist items and "See all" navigates to Your Space',
        (WidgetTester tester) async {
      final trending = createMockItems(2, 'Trending', MediaType.movie);
      final watchlistItem = createMockItems(1, 'Watchlisted', MediaType.movie).first;
      final mockRepo = MockTestRepository(
        trendingMovies: trending,
        popularMovies: [],
        trendingTvShows: [],
      );

      final container = ProviderContainer(
        overrides: [
          movieRepositoryProvider.overrideWithValue(mockRepo),
        ],
      );
      addTearDown(container.dispose);
      container.read(mediaProvider.notifier).addToWatchlist(watchlistItem);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(body: HomeScreen(enableAnimation: false)),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Your Watchlist'), findsOneWidget);
      // findsAtLeastNWidgets, not findsOneWidget: with only one item in the
      // watchlist, PickForMeCard (which also picks from the watchlist)
      // legitimately shows the same title too.
      expect(find.text('Watchlisted Movie 0'), findsAtLeastNWidgets(1));

      await tester.tap(find.descendant(
        of: find.ancestor(
          of: find.text('Your Watchlist'),
          matching: find.byType(Row),
        ),
        matching: find.text('See all'),
      ));
      await tester.pumpAndSettle();

      expect(container.read(navigationProvider).currentTab, AppTab.yourSpace);
    });

    testWidgets('is hidden entirely when the watchlist is empty for the active type',
        (WidgetTester tester) async {
      final trending = createMockItems(2, 'Trending', MediaType.movie);
      final mockRepo = MockTestRepository(
        trendingMovies: trending,
        popularMovies: [],
        trendingTvShows: [],
      );

      final container = ProviderContainer(
        overrides: [
          movieRepositoryProvider.overrideWithValue(mockRepo),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(body: HomeScreen(enableAnimation: false)),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Your Watchlist'), findsNothing);
    });
  });
}

