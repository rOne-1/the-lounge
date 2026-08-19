import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:the_lounge/constants/app_languages.dart';
import 'package:the_lounge/models/discover_filter_params.dart';
import 'package:the_lounge/models/media_item.dart';
import 'package:the_lounge/providers/repository_provider.dart';
import 'package:the_lounge/repositories/mock_movie_repository.dart';
import 'package:the_lounge/repositories/tmdb_movie_repository.dart';
import 'package:the_lounge/services/tmdb_api_service.dart';

void main() {
  group('DiscoverFilterParams Model Tests', () {
    test('Default constructor values', () {
      const params = DiscoverFilterParams();
      expect(params.genreId, isNull);
      expect(params.genreName, isNull);
      expect(params.keywordId, isNull);
      expect(params.keywordName, isNull);
      expect(params.personId, isNull);
      expect(params.personName, isNull);
      expect(params.providerId, isNull);
      expect(params.providerName, isNull);
      expect(params.watchRegion, isNull);
      expect(params.minRuntime, isNull);
      expect(params.maxRuntime, isNull);
      expect(params.minVoteCount, isNull);
      expect(params.originalLanguage, isNull);
      expect(params.tvNetworkId, isNull);
      expect(params.tvNetworkName, isNull);
      expect(params.tvStatus, isNull);
      expect(params.sortBy, equals('popularity.desc'));
      expect(params.releaseYear, isNull);
      expect(params.minRating, isNull);
      expect(params.hasActiveFilters, isFalse);
    });

    test('hasActiveFilters detects active non-sortBy filters', () {
      const p1 = DiscoverFilterParams(genreId: 28);
      expect(p1.hasActiveFilters, isTrue);

      const p2 = DiscoverFilterParams(minRating: 7.5);
      expect(p2.hasActiveFilters, isTrue);

      const p3 = DiscoverFilterParams(sortBy: 'vote_average.desc');
      expect(p3.hasActiveFilters, isFalse);
    });

    test('copyWith updates and sentinel resets fields', () {
      const initial = DiscoverFilterParams(
        genreId: 28,
        genreName: 'Action',
        minRating: 8.0,
      );

      final updated = initial.copyWith(minRating: 9.0, releaseYear: 2024);
      expect(updated.genreId, equals(28));
      expect(updated.minRating, equals(9.0));
      expect(updated.releaseYear, equals(2024));

      final cleared = updated.copyWith(genreId: null, genreName: null);
      expect(cleared.genreId, isNull);
      expect(cleared.genreName, isNull);
      expect(cleared.minRating, equals(9.0));
    });

    test('Equality, hashCode and toString', () {
      const p1 = DiscoverFilterParams(genreId: 28, minRating: 8.0);
      const p2 = DiscoverFilterParams(genreId: 28, minRating: 8.0);
      const p3 = DiscoverFilterParams(genreId: 12, minRating: 8.0);

      expect(p1, equals(p2));
      expect(p1.hashCode, equals(p2.hashCode));
      expect(p1, isNot(equals(p3)));
      expect(p1.toString(), contains('genreId: 28'));
    });
  });

  group('supportedLanguages', () {
    test('includes every major Indian regional-language film/TV industry', () {
      final codes = supportedLanguages.map((l) => l['code']).toSet();
      // Hindi already existed; these are the ones that were missing.
      for (final code in ['hi', 'ta', 'te', 'ml', 'kn', 'bn', 'mr', 'pa', 'gu', 'ur', 'or', 'as']) {
        expect(codes, contains(code), reason: 'missing Indian language code $code');
      }
    });

    test('has no duplicate language codes', () {
      final codes = supportedLanguages.map((l) => l['code']).toList();
      expect(codes.toSet().length, equals(codes.length));
    });
  });

  group('TmdbApiService Discover & SearchPersons Unit Tests', () {
    test('discoverMovies passes parameters correctly', () async {
      late Uri requestedUri;
      final client = MockClient((request) async {
        requestedUri = request.url;
        return http.Response(
          jsonEncode({'page': 1, 'results': [], 'total_results': 0}),
          200,
        );
      });

      final api = TmdbApiService(token: 'eyJ_mock_token', client: client);
      const params = DiscoverFilterParams(
        genreId: 28,
        keywordId: 100,
        personId: 500,
        providerId: 8,
        watchRegion: 'US',
        minRuntime: 90,
        maxRuntime: 180,
        minVoteCount: 50,
        originalLanguage: 'en',
        releaseYear: 2023,
        minRating: 7.0,
        sortBy: 'vote_average.desc',
      );

      await api.discoverMovies(params: params);

      expect(requestedUri.path, equals('/3/discover/movie'));
      expect(requestedUri.queryParameters['with_genres'], equals('28'));
      expect(requestedUri.queryParameters['with_keywords'], equals('100'));
      expect(requestedUri.queryParameters['with_people'], equals('500'));
      expect(requestedUri.queryParameters['with_watch_providers'], equals('8'));
      expect(requestedUri.queryParameters['watch_region'], equals('US'));
      expect(requestedUri.queryParameters['with_runtime.gte'], equals('90'));
      expect(requestedUri.queryParameters['with_runtime.lte'], equals('180'));
      expect(requestedUri.queryParameters['vote_count.gte'], equals('50'));
      expect(requestedUri.queryParameters['with_original_language'], equals('en'));
      expect(requestedUri.queryParameters['primary_release_year'], equals('2023'));
      expect(requestedUri.queryParameters['vote_average.gte'], equals('7.0'));
      expect(requestedUri.queryParameters['sort_by'], equals('vote_average.desc'));
    });

    test('discoverTvShows passes parameters correctly', () async {
      late Uri requestedUri;
      final client = MockClient((request) async {
        requestedUri = request.url;
        return http.Response(
          jsonEncode({'page': 1, 'results': [], 'total_results': 0}),
          200,
        );
      });

      final api = TmdbApiService(token: 'eyJ_mock_token', client: client);
      const params = DiscoverFilterParams(
        genreId: 18,
        tvNetworkId: 213,
        tvStatus: '0',
        releaseYear: 2022,
        sortBy: 'popularity.desc',
      );

      await api.discoverTvShows(params: params);

      expect(requestedUri.path, equals('/3/discover/tv'));
      expect(requestedUri.queryParameters['with_genres'], equals('18'));
      expect(requestedUri.queryParameters['with_networks'], equals('213'));
      expect(requestedUri.queryParameters['with_status'], equals('0'));
      expect(requestedUri.queryParameters['first_air_date_year'], equals('2022'));
      expect(requestedUri.queryParameters['sort_by'], equals('popularity.desc'));
    });

    test('searchPersons calls /3/search/person', () async {
      late Uri requestedUri;
      final client = MockClient((request) async {
        requestedUri = request.url;
        return http.Response(
          jsonEncode({
            'page': 1,
            'results': [
              {'id': 123, 'name': 'Nolan', 'known_for_department': 'Directing'}
            ]
          }),
          200,
        );
      });

      final api = TmdbApiService(token: 'eyJ_mock_token', client: client);
      final res = await api.searchPersons('Nolan');

      expect(requestedUri.path, equals('/3/search/person'));
      expect(requestedUri.queryParameters['query'], equals('Nolan'));
      expect(res['results'], isNotEmpty);
    });
  });

  group('TmdbMovieRepository Discover & Person Search Unit Tests', () {
    test('discoverMedia delegates to apiService and maps items', () async {
      final client = MockClient((request) async {
        if (request.url.path.contains('/genre/')) {
          return http.Response(jsonEncode({'genres': []}), 200);
        }
        return http.Response(
          jsonEncode({
            'page': 1,
            'results': [
              {
                'id': 999,
                'title': 'Test Movie',
                'vote_average': 8.5,
                'overview': 'Test overview',
              }
            ]
          }),
          200,
        );
      });

      final api = TmdbApiService(token: 'eyJ_mock_token', client: client);
      final repo = TmdbMovieRepository(apiService: api);

      final items = await repo.discoverMedia(
        isMovies: true,
        params: const DiscoverFilterParams(minRating: 8.0),
      );

      expect(items, hasLength(1));
      expect(items.first.title, equals('Test Movie'));
    });

    test('searchPersons delegates to apiService', () async {
      final client = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'page': 1,
            'results': [
              {'id': 456, 'name': 'Spielberg'}
            ]
          }),
          200,
        );
      });

      final api = TmdbApiService(token: 'eyJ_mock_token', client: client);
      final repo = TmdbMovieRepository(apiService: api);

      final persons = await repo.searchPersons('Spielberg');
      expect(persons, hasLength(1));
      expect(persons.first['name'], equals('Spielberg'));
    });
  });

  group('MockMovieRepository Discover & Person Search Tests', () {
    final repo = MockMovieRepository();

    test('discoverMedia filters by rating and type', () async {
      const params = DiscoverFilterParams(minRating: 8.5);
      final movies = await repo.discoverMedia(isMovies: true, params: params);

      expect(movies, isNotEmpty);
      expect(movies.every((m) => m.type == MediaType.movie), isTrue);
      expect(movies.every((m) => m.rating >= 8.5), isTrue);
    });

    test('searchPersons finds actors/directors in mock dataset', () async {
      final results = await repo.searchPersons('Nolan');
      expect(results, isNotEmpty);
      expect(results.any((p) => (p['name'] as String).contains('Nolan')), isTrue);
    });
  });

  group('Riverpod Discover Filter & Media Providers Tests', () {
    test('discoverFilterProvider state management', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(discoverFilterProvider), equals(const DiscoverFilterParams()));

      container.read(discoverFilterProvider.notifier).setGenre(genreId: 28, genreName: 'Action');
      expect(container.read(discoverFilterProvider).genreId, equals(28));
      expect(container.read(discoverFilterProvider).genreName, equals('Action'));

      container.read(discoverFilterProvider.notifier).setMinRating(8.0);
      expect(container.read(discoverFilterProvider).minRating, equals(8.0));

      container.read(discoverFilterProvider.notifier).resetFilters();
      expect(container.read(discoverFilterProvider), equals(const DiscoverFilterParams()));
    });

    test('discoverMediaProvider fetches media asynchronously', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final movies = await container.read(discoverMediaProvider(true).future);
      expect(movies, isNotEmpty);
      expect(movies.first.type, equals(MediaType.movie));

      final shows = await container.read(discoverMediaProvider(false).future);
      expect(shows, isNotEmpty);
      expect(shows.first.type, equals(MediaType.tv));
    });

    test('searchPersonsProvider fetches person results', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final persons = await container.read(searchPersonsProvider('Nolan').future);
      expect(persons, isNotEmpty);
    });
  });
}
