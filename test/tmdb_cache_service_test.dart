import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:the_lounge/repositories/tmdb_movie_repository.dart';
import 'package:the_lounge/services/tmdb_api_service.dart';
import 'package:the_lounge/services/tmdb_cache_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('TmdbLocalCacheService Unit Tests', () {
    late SharedPreferences prefs;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
    });

    test('generateKey creates deterministic keys with sorted query parameters', () {
      final cacheService = TmdbLocalCacheService(prefs: prefs);

      final key1 = cacheService.generateKey('/discover/movie', {
        'page': 1,
        'with_genres': 28,
        'sort_by': 'popularity.desc',
      });

      final key2 = cacheService.generateKey('/discover/movie', {
        'sort_by': 'popularity.desc',
        'page': 1,
        'with_genres': 28,
      });

      expect(key1, equals('/discover/movie?page=1&sort_by=popularity.desc&with_genres=28'));
      expect(key1, equals(key2));

      final keyNoParams = cacheService.generateKey('/trending/movie/week');
      expect(keyNoParams, equals('/trending/movie/week'));
    });

    test('getTtlForEndpoint assigns differentiated TTLs correctly', () {
      final cacheService = TmdbLocalCacheService(prefs: prefs);

      expect(
        cacheService.getTtlForEndpoint('/trending/movie/week'),
        equals(TmdbLocalCacheService.trendingPopularTtl),
      );
      expect(
        cacheService.getTtlForEndpoint('/movie/popular'),
        equals(TmdbLocalCacheService.trendingPopularTtl),
      );
      expect(
        cacheService.getTtlForEndpoint('/discover/movie'),
        equals(TmdbLocalCacheService.trendingPopularTtl),
      );
      expect(
        cacheService.getTtlForEndpoint('/movie/550'),
        equals(TmdbLocalCacheService.detailsTtl),
      );
      expect(
        cacheService.getTtlForEndpoint('/tv/1399/credits'),
        equals(TmdbLocalCacheService.detailsTtl),
      );
      expect(
        cacheService.getTtlForEndpoint('/movie/550/watch/providers'),
        equals(TmdbLocalCacheService.watchProvidersTtl),
      );
      expect(
        cacheService.getTtlForEndpoint('/tv/1399/watch/providers'),
        equals(TmdbLocalCacheService.watchProvidersTtl),
      );
    });

    test('Persistent cache saves and loads valid data, handles expiration', () async {
      DateTime currentTime = DateTime(2026, 8, 3, 12, 0, 0);
      final cacheService = TmdbLocalCacheService(
        prefs: prefs,
        clock: () => currentTime,
      );

      const endpoint = '/movie/popular?page=1';
      final testData = {'page': 1, 'results': [{'id': 100, 'title': 'Cached Movie'}]};

      await cacheService.put(endpoint, testData);

      // Verify written to SharedPreferences under prefix key
      final rawStored = prefs.getString('tmdb_cache_$endpoint');
      expect(rawStored, isNotNull);
      expect(rawStored, contains('Cached Movie'));

      // Retrieve before TTL expiration (6 hours for popular)
      final hitBeforeExpiry = await cacheService.get(endpoint);
      expect(hitBeforeExpiry, isNotNull);
      expect(hitBeforeExpiry!['results'][0]['title'], equals('Cached Movie'));

      // Advance time by 6 hours and 1 minute
      currentTime = currentTime.add(const Duration(hours: 6, minutes: 1));

      // Retrieve after TTL expiration should return null and clear SharedPreferences key
      final hitAfterExpiry = await cacheService.get(endpoint);
      expect(hitAfterExpiry, isNull);
      expect(prefs.getString('tmdb_cache_$endpoint'), isNull);
    });

    test('Search results are cached session-only and NOT persisted to disk', () async {
      final cacheService = TmdbLocalCacheService(prefs: prefs);
      const searchKey = '/search/multi?page=1&query=Inception';
      final searchData = {'results': [{'id': 27205, 'title': 'Inception'}]};

      await cacheService.put(searchKey, searchData, isSessionOnly: true);

      // Should be retrievable via get
      final retrieved = await cacheService.get(searchKey, isSessionOnly: true);
      expect(retrieved, isNotNull);
      expect(retrieved!['results'][0]['title'], equals('Inception'));

      // Should NOT exist in SharedPreferences disk storage
      final diskEntry = prefs.getString('tmdb_cache_$searchKey');
      expect(diskEntry, isNull);
    });

    test('clearExpired cleans expired records from both session and persistent storage', () async {
      DateTime currentTime = DateTime(2026, 8, 3, 12, 0, 0);
      final cacheService = TmdbLocalCacheService(
        prefs: prefs,
        clock: () => currentTime,
      );

      const popularKey = '/movie/popular?page=1';
      const detailsKey = '/movie/550';
      const searchKey = '/search/multi?page=1&query=Batman';

      await cacheService.put(popularKey, {'data': 'popular'});
      await cacheService.put(detailsKey, {'data': 'details'});
      await cacheService.put(searchKey, {'data': 'search'}, isSessionOnly: true);

      // Advance time by 7 hours (popular expires [6h], details remains valid [7d])
      currentTime = currentTime.add(const Duration(hours: 7));

      await cacheService.clearExpired();

      expect(await cacheService.get(popularKey), isNull);
      expect(await cacheService.get(detailsKey), isNotNull);
    });

    test('clearAll flushes session memory and persistent storage', () async {
      final cacheService = TmdbLocalCacheService(prefs: prefs);

      await cacheService.put('/movie/popular?page=1', {'data': 'popular'});
      await cacheService.put('/search/multi?page=1&query=Test', {'data': 'search'}, isSessionOnly: true);

      await cacheService.clearAll();

      expect(await cacheService.get('/movie/popular?page=1'), isNull);
      expect(await cacheService.get('/search/multi?page=1&query=Test', isSessionOnly: true), isNull);
    });
  });

  group('TmdbMovieRepository Cache Integration', () {
    late SharedPreferences prefs;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
    });

    test('Repository serves cached data on second call without hitting network HTTP client', () async {
      int networkCallCount = 0;

      final mockClient = MockClient((request) async {
        networkCallCount++;

        if (request.url.path.contains('/genre/')) {
          return http.Response(
              jsonEncode({
                'genres': [
                  {'id': 28, 'name': 'Action'}
                ]
              }),
              200);
        }

        if (request.url.path.contains('/trending/movie/')) {
          return http.Response(
              jsonEncode({
                'page': 1,
                'results': [
                  {
                    'id': 550,
                    'title': 'Fight Club',
                    'vote_average': 8.4,
                    'genre_ids': [28],
                  }
                ]
              }),
              200);
        }

        return http.Response(jsonEncode({'results': []}), 200);
      });

      final apiService = TmdbApiService(token: 'valid_token', client: mockClient);
      final cacheService = TmdbLocalCacheService(prefs: prefs);
      final repository = TmdbMovieRepository(
        apiService: apiService,
        cacheService: cacheService,
      );

      // Call 1: Network should be called for genres + trending movies
      final movies1 = await repository.getTrendingMovies();
      expect(movies1.length, equals(1));
      expect(movies1.first.title, equals('Fight Club'));
      final initialCallCount = networkCallCount;
      expect(initialCallCount, greaterThan(0));

      // Call 2: Network should NOT be called; served directly from cache
      final movies2 = await repository.getTrendingMovies();
      expect(movies2.length, equals(1));
      expect(movies2.first.title, equals('Fight Club'));
      expect(networkCallCount, equals(initialCallCount));
    });

    test('Search queries use session cache on second call', () async {
      int searchCallCount = 0;

      final mockClient = MockClient((request) async {
        if (request.url.path.contains('/genre/')) {
          return http.Response(jsonEncode({'genres': []}), 200);
        }
        if (request.url.path.contains('/search/multi')) {
          searchCallCount++;
          return http.Response(
              jsonEncode({
                'page': 1,
                'results': [
                  {
                    'id': 27205,
                    'media_type': 'movie',
                    'title': 'Inception',
                  }
                ]
              }),
              200);
        }
        return http.Response(jsonEncode({'results': []}), 200);
      });

      final apiService = TmdbApiService(token: 'valid_token', client: mockClient);
      final cacheService = TmdbLocalCacheService(prefs: prefs);
      final repository = TmdbMovieRepository(
        apiService: apiService,
        cacheService: cacheService,
      );

      final search1 = await repository.searchMedia('Inception');
      expect(search1.first.title, equals('Inception'));
      expect(searchCallCount, equals(1));

      final search2 = await repository.searchMedia('Inception');
      expect(search2.first.title, equals('Inception'));
      expect(searchCallCount, equals(1)); // Served from session cache!
    });

    test('Negative 404 cache prevents burst loops on missing media IDs', () async {
      int apiCallCount = 0;
      final mockClient = MockClient((request) async {
        if (request.url.path.contains('/tv/999999/season/1')) {
          apiCallCount++;
          return http.Response(
            jsonEncode({'status_code': 34, 'status_message': 'The resource you requested could not be found.'}),
            404,
          );
        }
        return http.Response(jsonEncode({'results': []}), 200);
      });

      final apiService = TmdbApiService(token: 'valid_token', client: mockClient);
      final cacheService = TmdbLocalCacheService(prefs: prefs);
      final repository = TmdbMovieRepository(
        apiService: apiService,
        cacheService: cacheService,
      );

      // First call fails with 404 and is cached in negative cache
      final season1 = await repository.getTvSeasonDetails('tv_999999', 1);
      expect(season1, isNull);
      expect(apiCallCount, equals(1));

      // Subsequent 5 calls hit negative cache immediately without firing network requests
      for (int i = 0; i < 5; i++) {
        final seasonRetry = await repository.getTvSeasonDetails('tv_999999', 1);
        expect(seasonRetry, isNull);
      }
      expect(apiCallCount, equals(1)); // No additional network calls!
    });
  });
}
