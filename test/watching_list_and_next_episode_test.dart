import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:the_lounge/screens/lobby_screen.dart';
import 'package:the_lounge/screens/lounge_screen.dart';
import 'package:the_lounge/providers/ambiance_provider.dart';
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
    SharedPreferences.setMockInitialValues({});
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

  testWidgets(
      'LoungeScreen shows the 3-group landing page, and the Watching pile card opens its ArchiveShelfScreen',
      (WidgetTester tester) async {
    final mockRepo = MockWatchingRepository(items: {'movie-10': testMovie, 'tv-20': testTvShow});
    final prefs = await SharedPreferences.getInstance();

    final container = ProviderContainer(
      overrides: [
        movieRepositoryProvider.overrideWithValue(mockRepo),
        sharedPreferencesProvider.overrideWithValue(prefs),
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
            body: LoungeScreen(),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Sanctuary Gateway: 4-card dock with Archive, Browse, Tools, Settings.
    expect(find.text('Archive'), findsOneWidget);
    expect(find.text('Browse'), findsOneWidget);
    expect(find.text('Tools'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);

    // Tap the "Archive" dock card, which opens ArchiveScreen.
    await tester.tap(find.text('Archive'));
    await tester.pumpAndSettle();

    // Tap the "Watching" hero card, which pushes ArchiveShelfScreen.
    await tester.tap(find.text('Watching'));
    await tester.pumpAndSettle();

    expect(find.text('Inception'), findsOneWidget);
  });

  testWidgets('Section 2 & 3: LobbyScreen Continue Watching rail strictly uses watchingList & Next Episode Banner shows real data for TV', (WidgetTester tester) async {
    final mockRepo = MockWatchingRepository(
      items: {'tv-20': testTvShow},
      seasonsMap: {'tv-20': testSeasons},
    );
    final prefs = await SharedPreferences.getInstance();

    final container = ProviderContainer(
      overrides: [
        movieRepositoryProvider.overrideWithValue(mockRepo),
        sharedPreferencesProvider.overrideWithValue(prefs),
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
            body: LobbyScreen(enableAnimation: false),
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

  testWidgets(
      'TV-1: a 3-season show with seasonsCount == null advances to Season 2 Episode 1 instead of showing a false "Done"',
      (WidgetTester tester) async {
    // Lightweight MediaItem exactly as search/discover/trending endpoints
    // hand it over -- no seasonsCount at all.
    final lightweightShow = MediaItem(
      id: 'tv-30',
      title: 'Multi Season Show',
      type: MediaType.tv,
      rating: 8.0,
      overview: 'A show with more than one season.',
      genres: const ['Drama'],
    );

    // Full details (as returned by getMediaDetails) carries the real count.
    final fullShowDetails = lightweightShow.copyWith(seasonsCount: 3);

    List<TvEpisode> seasonEpisodes(int season) => [
          TvEpisode(
            id: season * 100 + 1,
            episodeNumber: 1,
            seasonNumber: season,
            name: 'S$season Episode 1',
            airDate: DateTime(2026, 1, season),
          ),
          TvEpisode(
            id: season * 100 + 2,
            episodeNumber: 2,
            seasonNumber: season,
            name: 'S$season Episode 2',
            airDate: DateTime(2026, 1, season + 1),
          ),
        ];

    final threeSeasons = [
      TvSeason(id: 1, seasonNumber: 1, name: 'Season 1', episodes: seasonEpisodes(1)),
      TvSeason(id: 2, seasonNumber: 2, name: 'Season 2', episodes: seasonEpisodes(2)),
      TvSeason(id: 3, seasonNumber: 3, name: 'Season 3', episodes: seasonEpisodes(3)),
    ];

    final mockRepo = MockWatchingRepository(
      items: {'tv-30': fullShowDetails},
      seasonsMap: {'tv-30': threeSeasons},
    );
    final prefs = await SharedPreferences.getInstance();

    final container = ProviderContainer(
      overrides: [
        movieRepositoryProvider.overrideWithValue(mockRepo),
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
    );
    addTearDown(container.dispose);

    container.read(navigationProvider.notifier).setMediaType(MediaTypeToggle.tv);

    // Add the show to Watching using the lightweight item (seasonsCount ==
    // null), matching how it actually arrives from Discover/search/trending.
    container.read(mediaProvider.notifier).addToWatchingList(lightweightShow);

    // Mark every Season 1 episode watched.
    container.read(mediaProvider.notifier).toggleEpisodeWatched(
          showId: lightweightShow.id,
          seasonNumber: 1,
          episodeNumber: 1,
          showItem: lightweightShow,
          totalEpisodeCount: 6,
        );
    container.read(mediaProvider.notifier).toggleEpisodeWatched(
          showId: lightweightShow.id,
          seasonNumber: 1,
          episodeNumber: 2,
          showItem: lightweightShow,
          totalEpisodeCount: 6,
        );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: Scaffold(
            body: LobbyScreen(enableAnimation: false),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Done'), findsNothing);
    expect(find.textContaining('S2 · E1'), findsWidgets);
  });

  testWidgets(
      'LAYOUT-1: Continue Watching rail and Next Episode banner render without overflow at a narrow (360px) viewport',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final mockRepo = MockWatchingRepository(
      items: {'tv-20': testTvShow},
      seasonsMap: {'tv-20': testSeasons},
    );
    final prefs = await SharedPreferences.getInstance();

    final container = ProviderContainer(
      overrides: [
        movieRepositoryProvider.overrideWithValue(mockRepo),
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
    );
    addTearDown(container.dispose);

    container.read(navigationProvider.notifier).setMediaType(MediaTypeToggle.tv);
    container.read(mediaProvider.notifier).toggleEpisodeWatched(
          showId: testTvShow.id,
          seasonNumber: 1,
          episodeNumber: 1,
          showItem: testTvShow,
          totalEpisodeCount: 2,
        );

    // A RenderFlex overflow throws a FlutterError during layout, which
    // pumpWidget/pump surface as a test failure -- no explicit assertion
    // needed beyond successfully pumping and settling.
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: Scaffold(
            body: LobbyScreen(enableAnimation: false),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Continue watching'), findsOneWidget);
    expect(find.text('NEXT EPISODE'), findsOneWidget);
  });

  testWidgets('LobbyScreen hides Next Episode banner when no TV show is in watchingList', (WidgetTester tester) async {
    final mockRepo = MockWatchingRepository(
      items: {'tv-20': testTvShow},
      seasonsMap: {'tv-20': testSeasons},
    );
    final prefs = await SharedPreferences.getInstance();

    final container = ProviderContainer(
      overrides: [
        movieRepositoryProvider.overrideWithValue(mockRepo),
        sharedPreferencesProvider.overrideWithValue(prefs),
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
            body: LobbyScreen(enableAnimation: false),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Next Episode banner header should NOT be visible when watchingList has no TV show
    expect(find.text('NEXT EPISODE'), findsNothing);
  });
}
