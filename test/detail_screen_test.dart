import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:the_lounge/screens/detail_screen.dart';
import 'package:the_lounge/providers/media_provider.dart';
import 'package:the_lounge/providers/navigation_provider.dart';
import 'package:the_lounge/providers/ambiance_provider.dart';
import 'package:the_lounge/models/media_item.dart';
import 'package:the_lounge/models/discover_filter_params.dart';
import 'package:the_lounge/repositories/mock_movie_repository.dart';
import 'package:the_lounge/widgets/pressable_scale.dart';
import 'package:the_lounge/widgets/status_pulse_ring.dart';
import 'package:the_lounge/widgets/trailer_player.dart';

class MockDetailRepository extends MockMovieRepository {
  final Map<String, MediaItem> items;

  MockDetailRepository(this.items);

  @override
  Future<List<MediaItem>> getTrendingMovies({int page = 1, String? originalLanguage}) async => items.values.toList();

  @override
  Future<List<MediaItem>> getPopularMovies({int page = 1, String? originalLanguage}) async => items.values.toList();

  @override
  Future<List<MediaItem>> getTrendingTvShows({int page = 1, String? originalLanguage}) async => items.values.toList();

  @override
  Future<List<MediaItem>> getTopRatedMovies({int page = 1, String? originalLanguage}) async => items.values.toList();

  @override
  Future<List<MediaItem>> getTopRatedTvShows({int page = 1, String? originalLanguage}) async => items.values.toList();

  @override
  Future<List<MediaItem>> getNowPlayingMovies({int page = 1, String? region, String? originalLanguage}) async => items.values.toList();

  @override
  Future<List<MediaItem>> getAiringTodayTvShows({int page = 1, String? originalLanguage}) async => items.values.toList();

  @override
  Future<List<MediaItem>> getUpcomingMovies({int page = 1, String? originalLanguage}) async => items.values.toList();

  @override
  Future<List<MediaItem>> getOnTheAirTvShows({int page = 1, String? originalLanguage}) async => items.values.toList();

  @override
  Future<MediaItem?> getMediaDetails(String id) async => items[id];

  @override
  Future<TvSeason?> getTvSeasonDetails(String tvId, int seasonNumber) async => null;

  @override
  Future<List<MediaItem>> searchMedia(String query) async => [];

  @override
  Future<List<Map<String, String>>> getWatchProviderRegions() async => const [
        {'code': 'US', 'name': 'United States'},
        {'code': 'GB', 'name': 'United Kingdom'},
      ];

  @override
  Future<List<MediaItem>> discoverMedia({
    required bool isMovies,
    required DiscoverFilterParams params,
    int page = 1,
  }) async =>
      items.values.toList();

  @override
  Future<List<Map<String, dynamic>>> searchPersons(String query) async => [];
}

void main() {
  setUp(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  final testMovie = MediaItem(
    id: 'movie-1',
    title: 'Inception',
    type: MediaType.movie,
    rating: 8.8,
    releaseOrAirDate: DateTime(2010, 7, 16),
    overview: 'A thief who steals corporate secrets through dream-sharing...',
    genres: const ['Action', 'Sci-Fi', 'Thriller'],
    runtime: 148,
    watchProviders: const ['Netflix', 'Amazon Prime'],
    cast: const ['Leonardo DiCaprio', 'Joseph Gordon-Levitt'],
  );

  final testTvShow = MediaItem(
    id: 'tv-1',
    title: 'Stranger Things',
    type: MediaType.tv,
    rating: 8.7,
    releaseOrAirDate: DateTime(2016, 7, 15),
    nextEpisodeAirDate: DateTime(2026, 8, 10),
    overview: 'When a young boy vanishes, a small town uncovers a mystery...',
    genres: const ['Sci-Fi & Fantasy', 'Drama', 'Mystery'],
    seasonsCount: 4,
    episodesCount: 34,
    watchProviders: const ['Netflix'],
    cast: const ['Millie Bobby Brown', 'Winona Ryder'],
  );

  final testMovieNoProviders = MediaItem(
    id: 'movie-2',
    title: 'Indie Film',
    type: MediaType.movie,
    rating: 7.2,
    releaseOrAirDate: DateTime(2022, 1, 1),
    overview: 'An indie film with no streaming providers.',
    genres: const ['Drama'],
    runtime: 90,
    watchProviders: const [],
  );

  group('MediaNotifier SharedPreferences Unit Tests', () {
    test('defaults to US when SharedPreferences is empty', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
      );
      addTearDown(container.dispose);

      final state = container.read(mediaProvider);
      expect(state.watchProvidersCountry, equals('US'));
    });

    test('loads pre-saved watch_providers_country from SharedPreferences',
        () async {
      SharedPreferences.setMockInitialValues({
        'watch_providers_country': 'GB',
      });
      final prefs = await SharedPreferences.getInstance();

      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
      );
      addTearDown(container.dispose);

      final state = container.read(mediaProvider);
      expect(state.watchProvidersCountry, equals('GB'));
    });

    test('setWatchProvidersCountry updates state and saves to SharedPreferences',
        () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(mediaProvider.notifier);
      await notifier.setWatchProvidersCountry('CA');

      expect(container.read(mediaProvider).watchProvidersCountry, equals('CA'));
      expect(prefs.getString('watch_providers_country'), equals('CA'));
    });
  });

  group('DetailScreen UI and Metadata Tests', () {
    testWidgets('displays movie rating badge, genres, runtime, and release date',
        (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final mockRepo = MockDetailRepository({'movie-1': testMovie});

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            movieRepositoryProvider.overrideWithValue(mockRepo),
          ],
          child: const MaterialApp(
            home: DetailScreen(id: 'movie-1'),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));

      // Verify Title
      expect(find.text('Inception'), findsAtLeastNWidgets(1));

      // Verify Rating badge
      expect(find.text('★ 8.8'), findsOneWidget);

      // Verify Genre chips
      expect(find.text('Action'), findsOneWidget);
      expect(find.text('Sci-Fi'), findsOneWidget);
      expect(find.text('Thriller'), findsOneWidget);

      // Verify Movie-specific metadata: runtime and release date
      expect(find.text('148 min'), findsOneWidget);
      expect(find.text('Jul 16, 2010'), findsOneWidget);

      // Verify Watch providers
      expect(find.text('Where to Watch'), findsOneWidget);
      expect(find.text('Netflix'), findsOneWidget);
      expect(find.text('Amazon Prime'), findsOneWidget);
    });

    testWidgets('tapping a genre chip updates searchGenreProvider and navigates to SearchScreen',
        (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final mockRepo = MockDetailRepository({'movie-1': testMovie});

      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          movieRepositoryProvider.overrideWithValue(mockRepo),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: DetailScreen(id: 'movie-1'),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));

      final genreChip = find.ancestor(
        of: find.text('Sci-Fi'),
        matching: find.byType(PressableScale),
      );
      expect(genreChip, findsOneWidget);

      await tester.scrollUntilVisible(genreChip, 100, scrollable: find.byType(Scrollable).first);
      await tester.tap(genreChip);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(container.read(searchGenreProvider), equals('Sci-Fi'));
    });

    testWidgets(
        'displays TV show rating badge, genres, seasons, episodes, and next air date',
        (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final mockRepo = MockDetailRepository({'tv-1': testTvShow});

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            movieRepositoryProvider.overrideWithValue(mockRepo),
          ],
          child: const MaterialApp(
            home: DetailScreen(id: 'tv-1'),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));

      // Verify Title
      expect(find.text('Stranger Things'), findsAtLeastNWidgets(1));

      // Verify Rating badge
      expect(find.text('★ 8.7'), findsOneWidget);

      // Verify Genre chips
      expect(find.text('Sci-Fi & Fantasy'), findsOneWidget);
      expect(find.text('Drama'), findsOneWidget);
      expect(find.text('Mystery'), findsOneWidget);

      // Verify TV-specific metadata: seasons, episodes, next air date
      expect(find.text('4 Seasons'), findsOneWidget);
      expect(find.text('34 Episodes'), findsOneWidget);
      expect(find.text('Next: Aug 10, 2026'), findsOneWidget);
      expect(find.text('Jul 15, 2016'), findsOneWidget);
    });

    testWidgets('TV Detail Screen displays Seasons & Episodes section with interactive episode watched checkmark toggle',
        (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final mockRepo = MockDetailRepository({'tv-1': testTvShow});

      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          movieRepositoryProvider.overrideWithValue(mockRepo),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: DetailScreen(id: 'tv-1'),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));

      // Verify Seasons & Episodes section is rendered
      expect(find.text('Seasons & Episodes'), findsOneWidget);

      // Verify checkmark icon buttons are rendered for episodes
      final checkmarkIcons = find.byIcon(Icons.check_outlined);
      expect(checkmarkIcons, findsAtLeastNWidgets(1));

      // Tap first episode watched toggle button
      await tester.scrollUntilVisible(checkmarkIcons.first, 100, scrollable: find.byType(Scrollable).first);
      await tester.tap(checkmarkIcons.first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Verify episode is marked watched in mediaProvider
      final mediaState = container.read(mediaProvider);
      expect(mediaState.watchedEpisodes['tv-1']?.contains('S1E1'), isTrue);
    });

    testWidgets('country selector dropdown updates provider state and preferences',
        (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final mockRepo = MockDetailRepository({'movie-1': testMovie});

      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          movieRepositoryProvider.overrideWithValue(mockRepo),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: DetailScreen(id: 'movie-1'),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));

      // Default country should be US
      expect(find.text('US'), findsOneWidget);
      expect(container.read(mediaProvider).watchProvidersCountry, equals('US'));

      // Ensure the dropdown is scrolled into view and tapped
      await tester.ensureVisible(find.text('US'));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.tap(find.text('US'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Tap GB from dropdown menu
      await tester.tap(find.text('GB').last);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Verify state and preference update
      expect(container.read(mediaProvider).watchProvidersCountry, equals('GB'));
      expect(prefs.getString('watch_providers_country'), equals('GB'));
    });

    testWidgets('displays empty streaming message when watchProviders is empty',
        (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final mockRepo = MockDetailRepository({'movie-2': testMovieNoProviders});

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            movieRepositoryProvider.overrideWithValue(mockRepo),
          ],
          child: const MaterialApp(
            home: DetailScreen(id: 'movie-2'),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Where to Watch'), findsOneWidget);
      expect(
        find.text('No streaming providers available in US.'),
        findsOneWidget,
      );
    });

    testWidgets('large layout renders without error and displays all metadata',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final mockRepo = MockDetailRepository({'movie-1': testMovie});

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            movieRepositoryProvider.overrideWithValue(mockRepo),
          ],
          child: const MaterialApp(
            home: DetailScreen(id: 'movie-1'),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Inception'), findsAtLeastNWidgets(1));
      expect(find.text('★ 8.8'), findsOneWidget);
      expect(find.text('Action'), findsOneWidget);
      expect(find.text('148 min'), findsOneWidget);
      expect(find.text('Where to Watch'), findsOneWidget);
    });
  });

  group('Motion Identity Pass Section 4 & Section 5 Tests', () {
    final longOverviewMovie = MediaItem(
      id: 'movie-long',
      title: 'Long Movie Overview Test',
      type: MediaType.movie,
      rating: 8.4,
      releaseOrAirDate: DateTime(2024, 5, 10),
      overview: 'This is line 1 of a very detailed overview text. '
          'This is line 2 containing additional plot information about characters and setting. '
          'This is line 3 which continues the complex backstory of the protagonist and their journey. '
          'This is line 4 describing key dramatic conflicts, thematic depth, and secondary character arcs. '
          'This is line 5 concluding the comprehensive summary of the media item.',
      genres: const ['Drama', 'Sci-Fi'],
      runtime: 135,
      watchProviders: const ['Netflix'],
    );

    testWidgets('Section 4: StatusPulseRing animates when status toggles are activated',
        (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final mockRepo = MockDetailRepository({'movie-long': longOverviewMovie});

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            movieRepositoryProvider.overrideWithValue(mockRepo),
          ],
          child: const MaterialApp(
            home: DetailScreen(id: 'movie-long'),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));

      // Find status toggle buttons
      final watchlistFinder = find.text('Watchlist');
      expect(watchlistFinder, findsOneWidget);

      // Verify StatusPulseRing widgets exist wrapping the status buttons (4 primary + 2 secondary)
      expect(find.byType(StatusPulseRing), findsNWidgets(6));

      // Tap Watchlist button to activate it
      await tester.tap(watchlistFinder);
      await tester.pump(); // Start animation frame

      // Pulse animation should be running
      await tester.pump(const Duration(milliseconds: 150));
      // Settle animation
      await tester.pump(const Duration(milliseconds: 500));

      // Tap Saved button to activate it
      final saveFinder = find.text('Saved');
      await tester.tap(saveFinder);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Tap Watching button to activate it
      final watchingFinder = find.text('Watching');
      await tester.tap(watchingFinder);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Tap Watched button to activate it
      final watchedFinder = find.text('Watched');
      await tester.tap(watchedFinder);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
    });

    testWidgets('Section 5: ExpandableOverviewText expands/collapses with AnimatedSize and AnimatedRotation',
        (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final mockRepo = MockDetailRepository({'movie-long': longOverviewMovie});

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            movieRepositoryProvider.overrideWithValue(mockRepo),
          ],
          child: const MaterialApp(
            home: DetailScreen(id: 'movie-long'),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));

      // Verify ExpandableOverviewText and AnimatedSize / AnimatedRotation exist
      expect(find.byType(ExpandableOverviewText), findsOneWidget);
      expect(find.byType(AnimatedSize), findsOneWidget);

      final showMoreFinder = find.text('Show more');
      expect(showMoreFinder, findsOneWidget);

      // Verify initial AnimatedRotation has turns 0.0
      final animatedRotationBefore = tester.widget<AnimatedRotation>(
        find.byType(AnimatedRotation),
      );
      expect(animatedRotationBefore.turns, equals(0.0));

      // Tap 'Show more'
      await tester.tap(showMoreFinder);
      await tester.pump(); // Start animation

      // Pump partially through animation duration (300ms curve: houseSpringCurve)
      await tester.pump(const Duration(milliseconds: 150));
      await tester.pump(const Duration(milliseconds: 500));

      // Text should now show 'Show less'
      expect(find.text('Show less'), findsOneWidget);

      // Verify AnimatedRotation has turns 0.5 (rotated 180 degrees)
      final animatedRotationAfter = tester.widget<AnimatedRotation>(
        find.byType(AnimatedRotation),
      );
      expect(animatedRotationAfter.turns, equals(0.5));

      // Tap 'Show less' to collapse again
      await tester.tap(find.text('Show less'));
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Show more'), findsOneWidget);
      final animatedRotationCollapsed = tester.widget<AnimatedRotation>(
        find.byType(AnimatedRotation),
      );
      expect(animatedRotationCollapsed.turns, equals(0.0));
    });
  });

  group('Section 2 & 3 Detail View Overhaul & Interactivity Tests', () {
    final detailedMovie = MediaItem(
      id: 'movie-overhaul',
      title: 'Inception Deluxe',
      type: MediaType.movie,
      rating: 8.8,
      voteCount: 40000,
      releaseOrAirDate: DateTime(2010, 7, 16),
      overview: 'A thief who enters dreams to steal secrets...',
      genres: const ['Action', 'Sci-Fi'],
      runtime: 148,
      tagline: 'Your mind is the scene of the crime',
      director: 'Christopher Nolan',
      certification: 'PG-13',
      belongsToCollection: const MediaCollection(
        id: 10,
        name: 'Inception Collection',
      ),
      networks: const [
        MediaNetwork(id: 1, name: 'HBO Max'),
      ],
      productionCompanies: const [
        ProductionCompany(id: 2, name: 'Warner Bros. Pictures'),
      ],
      keywords: const [
        MediaKeyword(id: 100, name: 'dream'),
      ],
      imdbId: 'tt1375666',
      watchProviders: const ['Netflix'],
    );

    testWidgets(
        'displays tagline, certification, vote count, director credit, collection banner, networks, production companies, and IMDb link',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1000, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final mockRepo = MockDetailRepository({'movie-overhaul': detailedMovie});

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            movieRepositoryProvider.overrideWithValue(mockRepo),
          ],
          child: const MaterialApp(
            home: DetailScreen(id: 'movie-overhaul'),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));

      // Tagline
      expect(find.text('"Your mind is the scene of the crime"'), findsOneWidget);

      // Certification
      expect(find.text('PG-13'), findsOneWidget);

      // Rating with vote count
      expect(find.text('★ 8.8 (40k votes)'), findsOneWidget);

      // Director credit
      expect(find.text('Director'), findsOneWidget);
      expect(find.text('Christopher Nolan'), findsOneWidget);

      // Collection banner
      expect(find.text('Part of the Inception Collection'), findsOneWidget);

      // Networks
      expect(find.text('Networks'), findsOneWidget);
      expect(find.text('HBO Max'), findsOneWidget);

      // E3/TF-18: production companies removed from the detail page.
      expect(find.text('Production Companies'), findsNothing);
      expect(find.text('Warner Bros. Pictures'), findsNothing);

      // IMDb button
      expect(find.text('View on IMDb'), findsOneWidget);

      // Keywords chip
      expect(find.text('Keywords'), findsOneWidget);
      expect(find.text('#dream'), findsOneWidget);
    });

    testWidgets(
        'tapping a keyword chip updates searchKeywordProvider and resets searchGenreProvider',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1000, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final mockRepo = MockDetailRepository({'movie-overhaul': detailedMovie});

      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          movieRepositoryProvider.overrideWithValue(mockRepo),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: DetailScreen(id: 'movie-overhaul'),
          ),
        ),
      );

      await container.read(mediaDetailsProvider('movie-overhaul').future);
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));

      final keywordChip = find.text('#dream');
      expect(keywordChip, findsOneWidget);

      await tester.ensureVisible(keywordChip);
      await tester.pump(const Duration(milliseconds: 500));
      await tester.tap(keywordChip);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(container.read(searchKeywordProvider), equals('dream'));
      expect(container.read(searchGenreProvider), equals('All'));
    });

    testWidgets('tapping Watch trailer button opens TrailerPlayer',
        (WidgetTester tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.windows;
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final mockRepo = MockDetailRepository({'movie-overhaul': detailedMovie});

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            movieRepositoryProvider.overrideWithValue(mockRepo),
          ],
          child: const MaterialApp(
            home: DetailScreen(id: 'movie-overhaul'),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));

      final watchTrailerFinder = find.text('Watch trailer');
      expect(watchTrailerFinder, findsOneWidget);

      await tester.tap(watchTrailerFinder);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(TrailerPlayer), findsOneWidget);
      debugDefaultTargetPlatformOverride = null;
    });
  });

  group('Section 2 Demote Trailer Prominence & Trailers Section Tests', () {
    final movieWithTrailers = MediaItem(
      id: 'movie-trailers-1',
      title: 'Inception Video Test',
      type: MediaType.movie,
      rating: 8.8,
      overview: 'Test movie overview with trailers rail.',
      genres: const ['Action'],
      trailers: const [
        MediaVideo(
          id: 'v101',
          key: 'key101',
          name: 'Official Main Trailer',
          type: 'Trailer',
          site: 'YouTube',
          official: true,
        ),
        MediaVideo(
          id: 'v102',
          key: 'key102',
          name: 'Teaser Trailer 1',
          type: 'Teaser',
          site: 'YouTube',
          official: false,
        ),
      ],
    );

    testWidgets(
        'renders horizontal rail of trailer cards when trailers list is non-empty and tapping card opens TrailerPlayer',
        (WidgetTester tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.windows;
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final mockRepo = MockDetailRepository({'movie-trailers-1': movieWithTrailers});

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            movieRepositoryProvider.overrideWithValue(mockRepo),
          ],
          child: const MaterialApp(
            home: DetailScreen(id: 'movie-trailers-1'),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));

      // Verify "Trailers" header section is visible
      expect(find.text('Trailers'), findsOneWidget);

      // Verify trailer titles and badges
      expect(find.text('Official Main Trailer'), findsOneWidget);
      expect(find.text('Teaser Trailer 1'), findsOneWidget);
      expect(find.text('Trailer'), findsOneWidget);
      expect(find.text('Teaser'), findsOneWidget);
      expect(find.text('Official'), findsOneWidget);

      // Tap trailer card
      await tester.tap(find.text('Official Main Trailer'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Verify TrailerPlayer is pushed with correct videoId and videoTitle
      final playerFinder = find.byType(TrailerPlayer);
      expect(playerFinder, findsOneWidget);
      final player = tester.widget<TrailerPlayer>(playerFinder);
      expect(player.videoId, equals('key101'));
      expect(player.videoTitle, equals('Official Main Trailer'));
      debugDefaultTargetPlatformOverride = null;
    });
  });
}



