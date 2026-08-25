import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:the_lounge/screens/lobby_screen.dart';
import 'package:the_lounge/screens/detail_screen.dart';
import 'package:the_lounge/providers/repository_provider.dart';
import 'package:the_lounge/providers/media_provider.dart';
import 'package:the_lounge/providers/ambiance_provider.dart';
import 'package:the_lounge/providers/navigation_provider.dart';
import 'package:the_lounge/models/media_item.dart';
import 'package:the_lounge/models/discover_filter_params.dart';
import 'package:the_lounge/repositories/mock_movie_repository.dart';

class CachingTestRepository extends MockMovieRepository {
  int getTrendingMoviesCalls = 0;
  int getTrendingTvShowsCalls = 0;
  int getPopularMoviesCalls = 0;
  int getMediaDetailsCalls = 0;

  final List<MediaItem> movies;
  final List<MediaItem> tvShows;

  CachingTestRepository({required this.movies, required this.tvShows});

  @override
  Future<List<MediaItem>> getTrendingMovies({int page = 1, String? originalLanguage}) async {
    getTrendingMoviesCalls++;
    return movies;
  }

  @override
  Future<List<MediaItem>> getPopularMovies({int page = 1, String? originalLanguage}) async {
    getPopularMoviesCalls++;
    return movies;
  }

  @override
  Future<List<MediaItem>> getTrendingTvShows({int page = 1, String? originalLanguage}) async {
    getTrendingTvShowsCalls++;
    return tvShows;
  }

  @override
  Future<List<MediaItem>> getTopRatedMovies({int page = 1, String? originalLanguage}) async => movies;

  @override
  Future<List<MediaItem>> getTopRatedTvShows({int page = 1, String? originalLanguage}) async => tvShows;

  @override
  Future<List<MediaItem>> getNowPlayingMovies({int page = 1, String? region, String? originalLanguage}) async => movies;

  @override
  Future<List<MediaItem>> getAiringTodayTvShows({int page = 1, String? originalLanguage}) async => tvShows;

  @override
  Future<List<MediaItem>> getUpcomingMovies({int page = 1, String? region, String? originalLanguage}) async => movies;

  @override
  Future<List<MediaItem>> getOnTheAirTvShows({int page = 1, String? originalLanguage}) async => tvShows;

  @override
  Future<MediaItem?> getMediaDetails(String id, {String? region}) async {
    getMediaDetailsCalls++;
    final all = [...movies, ...tvShows];
    return all.firstWhere((item) => item.id == id);
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
      isMovies ? movies : tvShows;

  @override
  Future<List<Map<String, dynamic>>> searchPersons(String query) async => [];
}

void main() {
  setUp(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  final testMovie = MediaItem(
    id: 'm1',
    title: 'Test Movie 1',
    type: MediaType.movie,
    rating: 8.5,
    overview: 'Movie overview',
    genres: const ['Action'],
  );

  final testTv = MediaItem(
    id: 't1',
    title: 'Test TV 1',
    type: MediaType.tv,
    rating: 9.0,
    overview: 'TV overview',
    genres: const ['Drama'],
  );

  group('FutureProvider state caching verification', () {
    testWidgets(
        'DetailScreen rebuilds caused by status toggles do NOT flash loading spinner',
        (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final mockRepo = CachingTestRepository(
        movies: [testMovie],
        tvShows: [testTv],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            movieRepositoryProvider.overrideWithValue(mockRepo),
          ],
          child: const MaterialApp(
            home: DetailScreen(id: 'm1'),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));

      // CRAFT-LOGO-1: the title text can legitimately render twice now (the
      // hero's own fallback plus the collapsed top-bar title, invisible at
      // rest but still built) -- at-least-one, not exactly-one.
      expect(find.text('Test Movie 1'), findsAtLeastNWidgets(1));
      expect(find.byType(CircularProgressIndicator), findsNothing);
      final initialCalls = mockRepo.getMediaDetailsCalls;

      // Ensure Watchlist button is visible before tapping
      await tester.ensureVisible(find.text('Watchlist'));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));

      // Toggle Watchlist button
      await tester.tap(find.text('Watchlist'));
      await tester.pump(); // Start frame of state change

      // Verify NO CircularProgressIndicator is shown during rebuild
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.text('Test Movie 1'), findsAtLeastNWidgets(1));

      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byType(CircularProgressIndicator), findsNothing);
      // Repository call count should be cached and NOT incremented
      expect(mockRepo.getMediaDetailsCalls, equals(initialCalls));
    });

    testWidgets(
        'LobbyScreen rebuilds caused by media type toggle preserve cached data without loading spinner',
        (WidgetTester tester) async {
      final mockRepo = CachingTestRepository(
        movies: [testMovie],
        tvShows: [testTv],
      );

      tester.view.physicalSize = const Size(500, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      // NAV-3: the Movies/TV toggle no longer lives inside LobbyScreen itself
      // (it moved to the floating navigation capsule, shell-level) -- drive
      // the underlying media-type state directly via the container instead,
      // which is what this test actually cares about verifying.
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
            home: Scaffold(
              body: LobbyScreen(enableAnimation: false),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Test Movie 1'), findsWidgets);
      expect(find.byType(CircularProgressIndicator), findsNothing);

      // Switch to TV
      container.read(navigationProvider.notifier).setMediaType(MediaTypeToggle.tv);
      await tester.pumpAndSettle();

      expect(find.text('Test TV 1'), findsWidgets);
      expect(find.byType(CircularProgressIndicator), findsNothing);

      // Switch back to Movies
      container.read(navigationProvider.notifier).setMediaType(MediaTypeToggle.movies);
      await tester.pump(); // Frame of rebuild

      // Cached data should render immediately without progress indicator
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.text('Test Movie 1'), findsWidgets);

      await tester.pumpAndSettle();
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });
  });
}
