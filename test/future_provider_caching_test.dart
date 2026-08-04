import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:the_lounge/screens/home_screen.dart';
import 'package:the_lounge/screens/detail_screen.dart';
import 'package:the_lounge/providers/repository_provider.dart';
import 'package:the_lounge/providers/media_provider.dart';
import 'package:the_lounge/providers/ambiance_provider.dart';
import 'package:the_lounge/models/media_item.dart';
import 'package:the_lounge/repositories/movie_repository.dart';

class CachingTestRepository implements MovieRepository {
  int getTrendingMoviesCalls = 0;
  int getTrendingTvShowsCalls = 0;
  int getPopularMoviesCalls = 0;
  int getMediaDetailsCalls = 0;

  final List<MediaItem> movies;
  final List<MediaItem> tvShows;

  CachingTestRepository({required this.movies, required this.tvShows});

  @override
  Future<List<MediaItem>> getTrendingMovies() async {
    getTrendingMoviesCalls++;
    return movies;
  }

  @override
  Future<List<MediaItem>> getPopularMovies() async {
    getPopularMoviesCalls++;
    return movies;
  }

  @override
  Future<List<MediaItem>> getTrendingTvShows() async {
    getTrendingTvShowsCalls++;
    return tvShows;
  }

  @override
  Future<List<MediaItem>> getTopRatedMovies() async => movies;

  @override
  Future<List<MediaItem>> getTopRatedTvShows() async => tvShows;

  @override
  Future<List<MediaItem>> getNowPlayingMovies() async => movies;

  @override
  Future<List<MediaItem>> getAiringTodayTvShows() async => tvShows;

  @override
  Future<List<MediaItem>> getUpcomingMovies() async => movies;

  @override
  Future<List<MediaItem>> getOnTheAirTvShows() async => tvShows;

  @override
  Future<MediaItem?> getMediaDetails(String id) async {
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
    required dynamic params,
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

      await tester.pumpAndSettle();

      expect(find.text('Test Movie 1'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
      final initialCalls = mockRepo.getMediaDetailsCalls;

      // Ensure Watchlist button is visible before tapping
      await tester.ensureVisible(find.text('Watchlist'));
      await tester.pumpAndSettle();

      // Toggle Watchlist button
      await tester.tap(find.text('Watchlist'));
      await tester.pump(); // Start frame of state change

      // Verify NO CircularProgressIndicator is shown during rebuild
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.text('Test Movie 1'), findsOneWidget);

      await tester.pumpAndSettle();
      expect(find.byType(CircularProgressIndicator), findsNothing);
      // Repository call count should be cached and NOT incremented
      expect(mockRepo.getMediaDetailsCalls, equals(initialCalls));
    });

    testWidgets(
        'HomeScreen rebuilds caused by media type toggle preserve cached data without loading spinner',
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

      expect(find.text('Test Movie 1'), findsWidgets);
      expect(find.byType(CircularProgressIndicator), findsNothing);

      // Tap TV toggle
      await tester.tap(find.text('TV'));
      await tester.pumpAndSettle();

      expect(find.text('Test TV 1'), findsWidgets);
      expect(find.byType(CircularProgressIndicator), findsNothing);

      // Switch back to Movies toggle
      await tester.tap(find.text('Movies'));
      await tester.pump(); // Frame of rebuild

      // Cached data should render immediately without progress indicator
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.text('Test Movie 1'), findsWidgets);

      await tester.pumpAndSettle();
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });
  });
}
