import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:the_lounge/screens/discover_screen.dart';
import 'package:the_lounge/providers/media_provider.dart';
import 'package:the_lounge/models/media_item.dart';
import 'package:the_lounge/models/discover_filter_params.dart';
import 'package:the_lounge/services/tmdb_cache_service.dart';
import 'package:the_lounge/repositories/mock_movie_repository.dart';

class _MockTestRepository extends MockMovieRepository {
  @override
  Future<List<MediaItem>> getTrendingMovies({int page = 1}) async {
    return [
      const MediaItem(
        id: 'item1',
        title: 'Item One',
        type: MediaType.movie,
        rating: 8.5,
        overview: 'Overview 1',
        genres: [],
      ),
      const MediaItem(
        id: 'item2',
        title: 'Item Two',
        type: MediaType.movie,
        rating: 7.5,
        overview: 'Overview 2',
        genres: [],
      ),
      const MediaItem(
        id: 'item3',
        title: 'Item Three',
        type: MediaType.movie,
        rating: 6.5,
        overview: 'Overview 3',
        genres: [],
      ),
    ];
  }

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
  }) async => [];

  @override
  Future<List<Map<String, dynamic>>> searchPersons(String query) async => [];

  @override
  Future<List<MediaItem>> getRecommendations(String mediaId) async => [];

  @override
  Future<List<MediaItem>> getSimilarMedia(String mediaId) async => [];
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  group('Item 1: Dominant Axis Swipe Commit', () {
    testWidgets('Pan end along dominant horizontal axis triggers left/right swipe', (tester) async {
      final repo = _MockTestRepository();
      final container = ProviderContainer(
        overrides: [
          movieRepositoryProvider.overrideWithValue(repo),
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
      await tester.tapAt(const Offset(100, 100));
      await tester.pumpAndSettle();

      expect(find.text('Item One'), findsOneWidget);

      // Perform left swipe gesture (Skip)
      await tester.drag(find.text('Item One'), const Offset(-300, 20));
      await tester.pumpAndSettle();

      // Item One skipped -> Item Two should now be shown
      expect(find.text('Item Two'), findsOneWidget);

      // Verify item1 is in skippedMediaIdsProvider
      final skippedSet = container.read(skippedMediaIdsProvider);
      expect(skippedSet.contains('item1'), isTrue);
    });
  });

  group('Item 2: Session-Level Skip Tracking', () {
    testWidgets('Skipped media IDs persist in skippedMediaIdsProvider and are excluded on reload', (tester) async {
      final repo = _MockTestRepository();
      final container = ProviderContainer(
        overrides: [
          movieRepositoryProvider.overrideWithValue(repo),
        ],
      );

      // Manually pre-skip item1
      container.read(skippedMediaIdsProvider.notifier).add('item1');

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
      await tester.tapAt(const Offset(100, 100));
      await tester.pumpAndSettle();

      // Since item1 was pre-skipped, Item Two should be the top card displayed immediately!
      expect(find.text('Item One'), findsNothing);
      expect(find.text('Item Two'), findsOneWidget);
    });
  });

  group('Item 3: Now Playing TTL and Region Fix', () {
    test('TmdbLocalCacheService assigns 6 hours TTL for now_playing and airing_today endpoints', () {
      final cacheService = TmdbLocalCacheService();

      expect(
        cacheService.getTtlForEndpoint('/movie/now_playing'),
        equals(const Duration(hours: 6)),
      );
      expect(
        cacheService.getTtlForEndpoint('/tv/airing_today'),
        equals(const Duration(hours: 6)),
      );
      expect(
        cacheService.getTtlForEndpoint('/tv/on_the_air'),
        equals(const Duration(hours: 6)),
      );
      expect(
        cacheService.getTtlForEndpoint('/movie/upcoming'),
        equals(const Duration(hours: 6)),
      );
      expect(
        cacheService.getTtlForEndpoint('/movie/12345'),
        equals(const Duration(days: 7)),
      );
    });
  });
}
