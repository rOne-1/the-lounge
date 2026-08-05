import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:the_lounge/models/media_item.dart';
import 'package:the_lounge/providers/repository_provider.dart';
import 'package:the_lounge/models/discover_filter_params.dart';
import 'package:the_lounge/repositories/tmdb_movie_repository.dart';
import 'package:the_lounge/screens/detail_screen.dart';
import 'package:the_lounge/screens/discover_screen.dart';
import 'package:the_lounge/screens/home_screen.dart';
import 'package:the_lounge/screens/search_screen.dart';
import 'package:the_lounge/services/tmdb_api_service.dart';
import 'package:the_lounge/widgets/fallback_widgets.dart';
import 'package:the_lounge/widgets/trailer_player.dart';

import 'package:the_lounge/repositories/mock_movie_repository.dart';

class FailingMovieRepository extends MockMovieRepository {
  final Exception errorToThrow;
  final List<MediaItem> searchResultsToReturn;

  FailingMovieRepository({
    required this.errorToThrow,
    this.searchResultsToReturn = const [],
  });

  @override
  Future<List<MediaItem>> getTrendingMovies({int page = 1}) async => throw errorToThrow;

  @override
  Future<List<MediaItem>> getPopularMovies({int page = 1}) async => throw errorToThrow;

  @override
  Future<List<MediaItem>> getTrendingTvShows({int page = 1}) async => throw errorToThrow;

  @override
  Future<List<MediaItem>> getTopRatedMovies({int page = 1}) async => throw errorToThrow;

  @override
  Future<List<MediaItem>> getTopRatedTvShows({int page = 1}) async => throw errorToThrow;

  @override
  Future<List<MediaItem>> getNowPlayingMovies({int page = 1, String? region}) async => throw errorToThrow;

  @override
  Future<List<MediaItem>> getAiringTodayTvShows({int page = 1}) async => throw errorToThrow;

  @override
  Future<List<MediaItem>> getUpcomingMovies({int page = 1}) async => throw errorToThrow;

  @override
  Future<List<MediaItem>> getOnTheAirTvShows({int page = 1}) async => throw errorToThrow;

  @override
  Future<MediaItem?> getMediaDetails(String id) async => throw errorToThrow;

  @override
  Future<TvSeason?> getTvSeasonDetails(String tvId, int seasonNumber) async => throw errorToThrow;

  @override
  Future<List<MediaItem>> searchMedia(String query) async {
    if (searchResultsToReturn.isEmpty) {
      throw errorToThrow;
    }
    return searchResultsToReturn;
  }

  @override
  Future<List<Map<String, String>>> getWatchProviderRegions() async => throw errorToThrow;

  @override
  Future<List<MediaItem>> discoverMedia({
    required bool isMovies,
    required DiscoverFilterParams params,
    int page = 1,
  }) async =>
      throw errorToThrow;

  @override
  Future<List<Map<String, dynamic>>> searchPersons(String query) async =>
      throw errorToThrow;
}

class EmptyMovieRepository extends MockMovieRepository {
  @override
  Future<List<MediaItem>> getTrendingMovies({int page = 1}) async => [];

  @override
  Future<List<MediaItem>> getPopularMovies({int page = 1}) async => [];

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
      [];

  @override
  Future<List<Map<String, dynamic>>> searchPersons(String query) async => [];
}

void main() {
  group('Real Error Handling - Repository Unit Tests', () {
    test('SocketException and ClientException rethrow when fallbackRepository is null', () async {
      final client = MockClient((request) async {
        throw const SocketException('Failed host lookup: api.themoviedb.org');
      });

      final service = TmdbApiService(token: 'valid_token', client: client);
      final repo = TmdbMovieRepository(apiService: service, fallbackRepository: null);

      expect(() => repo.getTrendingMovies(), throwsA(isA<SocketException>()));
    });

    test('HTTP status codes 401, 429, 500 trigger exceptions when fallbackRepository is null', () async {
      for (final statusCode in [401, 429, 500]) {
        final client = MockClient((request) async {
          return http.Response(
            jsonEncode({'status_message': 'Error', 'status_code': statusCode}),
            statusCode,
          );
        });

        final service = TmdbApiService(token: 'valid_token', client: client);
        final repo = TmdbMovieRepository(apiService: service, fallbackRepository: null);

        expect(
          () => repo.getTrendingMovies(),
          throwsA(predicate((e) => e.toString().contains('Status $statusCode'))),
        );
      }
    });

    test('Missing or unconfigured token throws Exception when fallbackRepository is null', () async {
      final service = TmdbApiService(token: null);
      final repo = TmdbMovieRepository(apiService: service, fallbackRepository: null);

      expect(
        () => repo.getTrendingMovies(),
        throwsA(predicate((e) => e.toString().contains('TMDB API token is missing'))),
      );
    });
  });

  group('Real Error Handling - Widget Tests', () {
    const dummyItem = MediaItem(
      id: '1',
      title: 'Inception',
      type: MediaType.movie,
      rating: 8.8,
      overview: 'A thief who steals corporate secrets...',
      genres: ['Sci-Fi', 'Action'],
    );

    testWidgets('FullScreenErrorWidget appears on HomeScreen when primary data loading fails',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            trendingMoviesProvider.overrideWith((ref) => Future.error(Exception('SocketException: Host un-reachable'))),
            popularMoviesProvider.overrideWith((ref) => Future.error(Exception('HTTP 500 Internal Server Error'))),
          ],
          child: const MaterialApp(
            home: HomeScreen(enableAnimation: false),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(FullScreenErrorWidget), findsOneWidget);
      expect(find.text('Try again'), findsOneWidget);
    });

    testWidgets('InlinePartialErrorWidget appears on HomeScreen when single rail fails',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            trendingMoviesProvider.overrideWith((ref) => Future.error(Exception('HTTP 429 Rate Limit'))),
            popularMoviesProvider.overrideWith((ref) => Future.value([dummyItem])),
            topRatedMoviesProvider.overrideWith((ref) => Future.value([dummyItem])),
          ],
          child: const MaterialApp(
            home: HomeScreen(enableAnimation: false),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(FullScreenErrorWidget), findsNothing);
      expect(find.byType(InlinePartialErrorWidget), findsOneWidget);
      expect(find.text('Failed to load Trending titles'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
      expect(find.text('Inception'), findsWidgets);
    });

    testWidgets('FullScreenErrorWidget appears on DetailScreen when media details fetch fails',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            mediaDetailsProvider('550').overrideWith((ref) => Future.error(Exception('HTTP 401 Unauthorized'))),
          ],
          child: const MaterialApp(
            home: DetailScreen(id: '550'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(FullScreenErrorWidget), findsOneWidget);
      expect(find.text('Try again'), findsOneWidget);
    });

    testWidgets('PlaybackUnavailableWidget appears when trailer is unavailable',
        (tester) async {
      const itemNoTrailer = MediaItem(
        id: '2',
        title: 'No Trailer Title',
        type: MediaType.movie,
        rating: 7.0,
        overview: 'Overview text',
        genres: ['Drama'],
        hasTrailer: false,
      );

      await tester.pumpWidget(
        ProviderScope(
          child: const MaterialApp(
            home: TrailerPlayer(item: itemNoTrailer),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(PlaybackUnavailableWidget), findsOneWidget);
      expect(find.text('No Trailer Title'), findsOneWidget);
      expect(find.text('Add to watchlist'), findsOneWidget);
    });

    testWidgets('Trailer player shows SnackBar feedback ("Trailer playback isn\'t available for this title")',
        (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.windows;
      const itemWithTrailer = MediaItem(
        id: '3',
        title: 'Title With Trailer',
        type: MediaType.movie,
        rating: 8.0,
        overview: 'Overview',
        genres: ['Action'],
        hasTrailer: true,
        trailerVideoId: 'dQw4w9WgXcQ',
      );

      await tester.pumpWidget(
        ProviderScope(
          child: const MaterialApp(
            home: TrailerPlayer(item: itemWithTrailer),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final playButton = find.byIcon(Icons.play_circle_fill);
      expect(playButton, findsOneWidget);
      await tester.tap(playButton);
      await tester.pump();

      expect(find.text("Trailer playback isn't available for this title"), findsOneWidget);

      ScaffoldMessenger.of(tester.element(find.byType(Scaffold))).clearSnackBars();
      await tester.pumpAndSettle();
      debugDefaultTargetPlatformOverride = null;
    });

    testWidgets('SearchScreen renders clear empty result set state with clear search button',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            movieRepositoryProvider.overrideWithValue(EmptyMovieRepository()),
          ],
          child: const MaterialApp(
            home: Scaffold(body: SearchScreen()),
          ),
        ),
      );

      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'NonExistentTitleXYZ');
      await tester.pumpAndSettle();

      expect(find.text('No results found for "NonExistentTitleXYZ"'), findsOneWidget);
      expect(find.text('Clear search'), findsOneWidget);

      await tester.tap(find.text('Clear search'));
      await tester.pumpAndSettle();

      expect(find.text('Search across the catalog'), findsOneWidget);
    });

    testWidgets('SearchScreen network failure renders FullScreenErrorWidget with retry action',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            movieRepositoryProvider.overrideWithValue(
              FailingMovieRepository(errorToThrow: Exception('SocketException: ClientException')),
            ),
          ],
          child: const MaterialApp(
            home: Scaffold(body: SearchScreen()),
          ),
        ),
      );

      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'TestQuery');
      await tester.pumpAndSettle();

      expect(find.byType(FullScreenErrorWidget), findsOneWidget);
      expect(find.text('Try again'), findsOneWidget);
    });

    testWidgets('DiscoverScreen empty deck renders no titles state with Reload deck action',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            movieRepositoryProvider.overrideWithValue(EmptyMovieRepository()),
          ],
          child: const MaterialApp(
            home: Scaffold(body: DiscoverScreen()),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('No titles in recommendations'), findsOneWidget);
      expect(find.text('Reload deck'), findsOneWidget);
    });

    testWidgets('DiscoverScreen error renders FullScreenErrorWidget with retry action',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            movieRepositoryProvider.overrideWithValue(
              FailingMovieRepository(errorToThrow: Exception('HTTP 500 Internal Server Error')),
            ),
          ],
          child: const MaterialApp(
            home: Scaffold(body: DiscoverScreen()),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(FullScreenErrorWidget), findsOneWidget);
      expect(find.text('Try again'), findsOneWidget);
    });
  });
}
