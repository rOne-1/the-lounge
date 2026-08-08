import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:the_lounge/screens/home_screen.dart';
import 'package:the_lounge/screens/your_space_screen.dart';
import 'package:the_lounge/providers/media_provider.dart';
import 'package:the_lounge/providers/navigation_provider.dart';
import 'package:the_lounge/models/media_item.dart';
import 'package:the_lounge/models/discover_filter_params.dart';
import 'package:the_lounge/repositories/mock_movie_repository.dart';

class MockWatchingRepository extends MockMovieRepository {
  final Map<String, MediaItem> items;
  final Map<String, List<TvSeason>> seasonsMap;

  MockWatchingRepository({
    required this.items,
    this.seasonsMap = const {},
  });

  @override
  Future<List<MediaItem>> getTrendingMovies({int page = 1}) async => items.values.where((i) => i.type == MediaType.movie).toList();

  @override
  Future<List<MediaItem>> getPopularMovies({int page = 1}) async => items.values.where((i) => i.type == MediaType.movie).toList();

  @override
  Future<List<MediaItem>> getTrendingTvShows({int page = 1}) async => items.values.where((i) => i.type == MediaType.tv).toList();

  @override
  Future<List<MediaItem>> getTopRatedMovies({int page = 1}) async => items.values.where((i) => i.type == MediaType.movie).toList();

  @override
  Future<List<MediaItem>> getTopRatedTvShows({int page = 1}) async => items.values.where((i) => i.type == MediaType.tv).toList();

  @override
  Future<List<MediaItem>> getNowPlayingMovies({int page = 1, String? region}) async => items.values.where((i) => i.type == MediaType.movie).toList();

  @override
  Future<List<MediaItem>> getAiringTodayTvShows({int page = 1}) async => items.values.where((i) => i.type == MediaType.tv).toList();

  @override
  Future<List<MediaItem>> getUpcomingMovies({int page = 1}) async => items.values.where((i) => i.type == MediaType.movie).toList();

  @override
  Future<List<MediaItem>> getOnTheAirTvShows({int page = 1}) async => items.values.where((i) => i.type == MediaType.tv).toList();

  @override
  Future<MediaItem?> getMediaDetails(String id) async => items[id];

  @override
  Future<TvSeason?> getTvSeasonDetails(String tvId, int seasonNumber) async {
    final list = seasonsMap[tvId];
    if (list == null) return null;
    return list.firstWhere((s) => s.seasonNumber == seasonNumber, orElse: () => list.first);
  }

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
      items.values.where((i) => i.type == (isMovies ? MediaType.movie : MediaType.tv)).toList();

  @override
  Future<List<Map<String, dynamic>>> searchPersons(String query) async => [];

  @override
  Future<List<MediaItem>> getRecommendations(String mediaId) async => [];

  @override
  Future<List<MediaItem>> getSimilarMedia(String mediaId) async => [];
}

void main() {
  setUp(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  final testMovie = MediaItem(
    id: 'movie-10',
    title: 'Inception',
    type: MediaType.movie,
    rating: 8.8,
    overview: 'Dream thief...',
    genres: const ['Sci-Fi'],
  );

  final testTvShow = MediaItem(
    id: 'tv-20',
    title: 'Severance',
    type: MediaType.tv,
    rating: 8.7,
    overview: 'Work life balance...',
    genres: const ['Sci-Fi', 'Thriller'],
    seasonsCount: 1,
    episodesCount: 2,
  );

  final testSeasons = [
    TvSeason(
      id: 1,
      seasonNumber: 1,
      name: 'Season 1',
      episodes: [
        TvEpisode(
          id: 101,
          episodeNumber: 1,
          seasonNumber: 1,
          name: 'Good News About Hell',
          airDate: DateTime(2026, 8, 1),
        ),
        TvEpisode(
          id: 102,
          episodeNumber: 2,
          seasonNumber: 1,
          name: 'Half Loop',
          airDate: DateTime(2026, 8, 8),
        ),
      ],
    )
  ];

  testWidgets('YourSpaceScreen has tabs: Watchlist, Saved, In Progress, Watched', (WidgetTester tester) async {
    final mockRepo = MockWatchingRepository(items: {'movie-10': testMovie, 'tv-20': testTvShow});

    final container = ProviderContainer(
      overrides: [
        movieRepositoryProvider.overrideWithValue(mockRepo),
      ],
    );
    addTearDown(container.dispose);

    // Add movie to watchingList
    container.read(mediaProvider.notifier).addToWatchingList(testMovie);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: Scaffold(
            body: YourSpaceScreen(),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Watchlist'), findsAtLeast(1));
    expect(find.text('Saved'), findsAtLeast(1));
    expect(find.text('In Progress'), findsAtLeast(1));
    expect(find.text('Watched'), findsAtLeast(1));

    // Tap 'In Progress' tab
    await tester.tap(find.text('In Progress'));
    await tester.pumpAndSettle();

    // Verify item in watching tab
    expect(find.text('Inception'), findsOneWidget);
  });

  testWidgets('Section 2 & 3: HomeScreen Continue Watching rail strictly uses watchingList & Next Episode Banner shows real data for TV', (WidgetTester tester) async {
    final mockRepo = MockWatchingRepository(
      items: {'tv-20': testTvShow},
      seasonsMap: {'tv-20': testSeasons},
    );

    final container = ProviderContainer(
      overrides: [
        movieRepositoryProvider.overrideWithValue(mockRepo),
      ],
    );
    addTearDown(container.dispose);

    // Set TV mode
    container.read(navigationProvider.notifier).setMediaType(MediaTypeToggle.tv);

    // Add TV show to watchingList via episode watch
    container.read(mediaProvider.notifier).toggleEpisodeWatched(
          showId: testTvShow.id,
          seasonNumber: 1,
          episodeNumber: 1,
          showItem: testTvShow,
          totalEpisodeCount: 2,
        );

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

    // Rail 1 Continue watching title
    expect(find.text('Continue watching'), findsOneWidget);
    expect(find.text('Severance'), findsAtLeastNWidgets(1));

    // Next Episode banner displays real episode info
    expect(find.text('NEXT EPISODE'), findsOneWidget);
    expect(find.textContaining('Severance · S1 E2'), findsOneWidget);
    expect(find.textContaining('Half Loop'), findsNWidgets(2));
  });

  testWidgets('HomeScreen hides Next Episode banner when no TV show is in watchingList', (WidgetTester tester) async {
    final mockRepo = MockWatchingRepository(
      items: {'tv-20': testTvShow},
      seasonsMap: {'tv-20': testSeasons},
    );

    final container = ProviderContainer(
      overrides: [
        movieRepositoryProvider.overrideWithValue(mockRepo),
      ],
    );
    addTearDown(container.dispose);

    // Set TV mode, but no TV show in watchingList
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

    // Next Episode banner header should NOT be visible when watchingList has no TV show
    expect(find.text('NEXT EPISODE'), findsNothing);
  });
}
