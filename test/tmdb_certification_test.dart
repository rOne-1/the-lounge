import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:the_lounge/repositories/tmdb_movie_repository.dart';
import 'package:the_lounge/services/tmdb_api_service.dart';

/// DATA-CERT-1: Multi-Country Certification Resolution.
///
/// Verifies TmdbMovieRepository.getMediaDetails resolves the display
/// [MediaItem.certification] from the caller's requested `region` against
/// the real per-country shape TMDB returns (movie `release_dates.results[]`,
/// TV `content_ratings.results[]`) instead of the previous hardcoded 'US'
/// lookup, while [MediaItem.certificationsByCountry] keeps every parsed
/// country available for a second region without a second fetch.
void main() {
  group('DATA-CERT-1: multi-country certification resolution', () {
    int movieRequestCount = 0;
    int tvRequestCount = 0;

    http.Client buildClient() {
      return MockClient((request) async {
        if (request.url.path.contains('/movie/600')) {
          movieRequestCount++;
          return http.Response(
              jsonEncode({
                'id': 600,
                'title': 'International Release',
                'release_dates': {
                  'results': [
                    {
                      'iso_3166_1': 'US',
                      'release_dates': [
                        {'certification': 'R', 'type': 3},
                      ],
                    },
                    {
                      'iso_3166_1': 'GB',
                      'release_dates': [
                        {'certification': '15', 'type': 3},
                      ],
                    },
                    {
                      'iso_3166_1': 'DE',
                      'release_dates': [
                        {'certification': 'FSK 16', 'type': 3},
                      ],
                    },
                    // A country present in the payload but with no actual
                    // certification value on any of its release_dates
                    // entries -- must not be recorded at all.
                    {
                      'iso_3166_1': 'FR',
                      'release_dates': [
                        {'certification': '', 'type': 3},
                      ],
                    },
                  ],
                },
              }),
              200);
        }
        if (request.url.path.contains('/tv/700')) {
          tvRequestCount++;
          return http.Response(
              jsonEncode({
                'id': 700,
                'name': 'International Series',
                'content_ratings': {
                  'results': [
                    {'iso_3166_1': 'US', 'rating': 'TV-MA'},
                    {'iso_3166_1': 'JP', 'rating': 'PG12'},
                    {'iso_3166_1': 'IN', 'rating': 'U/A'},
                  ],
                },
              }),
              200);
        }
        return http.Response(jsonEncode({'results': []}), 200);
      });
    }

    setUp(() {
      movieRequestCount = 0;
      tvRequestCount = 0;
    });

    test('movie: defaults to US when no region is requested', () async {
      final service = TmdbApiService(token: 'valid_token', client: buildClient());
      final repo = TmdbMovieRepository(apiService: service);

      final details = await repo.getMediaDetails('movie_600');
      expect(details, isNotNull);
      expect(details!.certification, equals('R'));
      expect(details.certificationsByCountry['GB'], equals('15'));
      expect(details.certificationsByCountry['DE'], equals('FSK 16'));
      expect(details.certificationsByCountry.containsKey('FR'), isFalse);
    });

    test('movie: resolves GB certification when region=GB is requested',
        () async {
      final service = TmdbApiService(token: 'valid_token', client: buildClient());
      final repo = TmdbMovieRepository(apiService: service);

      final details =
          await repo.getMediaDetails('movie_600', region: 'GB');
      expect(details, isNotNull);
      expect(details!.certification, equals('15'));
    });

    test('movie: resolves DE certification when region=DE is requested',
        () async {
      final service = TmdbApiService(token: 'valid_token', client: buildClient());
      final repo = TmdbMovieRepository(apiService: service);

      final details =
          await repo.getMediaDetails('movie_600', region: 'de');
      expect(details, isNotNull);
      // Lowercase input still resolves correctly (normalized internally).
      expect(details!.certification, equals('FSK 16'));
    });

    test(
        'movie: falls back to US when the requested region has no explicit certification',
        () async {
      final service = TmdbApiService(token: 'valid_token', client: buildClient());
      final repo = TmdbMovieRepository(apiService: service);

      final details =
          await repo.getMediaDetails('movie_600', region: 'JP');
      expect(details, isNotNull);
      expect(details!.certification, equals('R'));
    });

    test('tv: resolves JP and IN ratings from content_ratings', () async {
      final service = TmdbApiService(token: 'valid_token', client: buildClient());
      final repo = TmdbMovieRepository(apiService: service);

      final jpDetails =
          await repo.getMediaDetails('tv_700', region: 'JP');
      expect(jpDetails, isNotNull);
      expect(jpDetails!.certification, equals('PG12'));

      final inDetails =
          await repo.getMediaDetails('tv_700', region: 'IN');
      expect(inDetails, isNotNull);
      expect(inDetails!.certification, equals('U/A'));

      // The second call re-resolves against the cached payload rather than
      // firing a second real request -- one fetch serves any number of
      // region resolutions.
      expect(tvRequestCount, equals(1));
    });

    test(
        'concurrent calls for the same id with different regions each resolve their own certification from one shared fetch',
        () async {
      final service = TmdbApiService(token: 'valid_token', client: buildClient());
      final repo = TmdbMovieRepository(apiService: service);

      final results = await Future.wait([
        repo.getMediaDetails('movie_600', region: 'GB'),
        repo.getMediaDetails('movie_600', region: 'DE'),
        repo.getMediaDetails('movie_600'),
      ]);

      // BETA3-NET-1's dedup is keyed by id only (region-agnostic fetch) --
      // still exactly one real HTTP request despite 3 concurrent callers.
      expect(movieRequestCount, equals(1));

      expect(results[0]!.certification, equals('15')); // GB
      expect(results[1]!.certification, equals('FSK 16')); // DE
      expect(results[2]!.certification, equals('R')); // default US
    });
  });
}
