import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:the_lounge/screens/home_screen.dart';
import 'package:the_lounge/screens/detail_screen.dart';
import 'package:the_lounge/providers/media_provider.dart';
import 'package:the_lounge/models/media_item.dart';
import 'package:the_lounge/models/discover_filter_params.dart';
import 'package:the_lounge/repositories/movie_repository.dart';

class MockTestRepository implements MovieRepository {
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
  Future<List<MediaItem>> getNowPlayingMovies({int page = 1}) async => trendingMovies;

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

  testWidgets('HomeScreen displays dynamic greeting, trending carousel, and continue watching list', (WidgetTester tester) async {
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
    container.read(mediaProvider.notifier).addToWatchingList(popular[0]);
    container.read(mediaProvider.notifier).addToWatchingList(popular[1]);

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

    // Verify Continue watching items are rendered without stub box
    expect(find.text('Continue Movie 0'), findsOneWidget);
    expect(find.text('Continue Movie 1'), findsOneWidget);

    // Verify Trending carousel items are rendered
    expect(find.text('Trending This Week'), findsOneWidget);

    // Verify tapping on a Continue Watching item navigates to DetailScreen
    await tester.tap(find.text('Continue Movie 0'));
    await tester.pumpAndSettle();

    expect(find.byType(DetailScreen), findsOneWidget);
    expect(find.text('Continue Movie 0'), findsOneWidget);
  });

  testWidgets('HomeScreen contains AnimatedSize, AnimatedCrossFade and AnimatedSwitcher transitions for section 7', (WidgetTester tester) async {
    final trending = createMockItems(6, 'Trending', MediaType.movie);
    final popular = createMockItems(4, 'Continue', MediaType.movie);
    final mockRepo = MockTestRepository(
      trendingMovies: trending,
      popularMovies: popular,
      trendingTvShows: [],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          movieRepositoryProvider.overrideWithValue(mockRepo),
        ],
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
  });
}

