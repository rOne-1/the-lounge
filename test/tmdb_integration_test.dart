import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:the_lounge/models/discover_filter_params.dart';
import 'package:the_lounge/models/media_item.dart';
import 'package:the_lounge/repositories/mock_movie_repository.dart';
import 'package:the_lounge/repositories/tmdb_movie_repository.dart';
import 'package:the_lounge/services/tmdb_api_service.dart';

void main() {
  group('TmdbApiService', () {
    test('hasToken returns true only for valid non-placeholder token', () {
      final serviceNoToken = TmdbApiService(token: null);
      expect(serviceNoToken.hasToken, isFalse);

      final serviceEmptyToken = TmdbApiService(token: '  ');
      expect(serviceEmptyToken.hasToken, isFalse);

      final servicePlaceholderToken =
          TmdbApiService(token: 'your_tmdb_read_access_token_here');
      expect(servicePlaceholderToken.hasToken, isFalse);

      final serviceValidToken = TmdbApiService(token: 'test_token_123');
      expect(serviceValidToken.hasToken, isTrue);
    });

    test('Header authentication includes Bearer token and Accept header',
        () async {
      late String authHeader;
      late String acceptHeader;

      final client = MockClient((request) async {
        authHeader = request.headers['Authorization'] ?? '';
        acceptHeader = request.headers['Accept'] ?? '';
        return http.Response(
            jsonEncode({
              'page': 1,
              'results': [],
            }),
            200);
      });

      final service = TmdbApiService(token: 'eyJ_secret_jwt_token', client: client);
      await service.getTrendingMovies();

      expect(authHeader, equals('Bearer eyJ_secret_jwt_token'));
      expect(acceptHeader, equals('application/json'));
    });

    test('Endpoints request correct path and parameters', () async {
      final requestedUrls = <String>[];

      final client = MockClient((request) async {
        requestedUrls.add(request.url.toString());
        return http.Response(
            jsonEncode({'page': 1, 'results': [], 'genres': []}), 200);
      });

      final service = TmdbApiService(token: 'valid_token', client: client);

      await service.getConfiguration();
      await service.getTrendingMovies(page: 2);
      await service.getTrendingTvShows();
      await service.getPopularMovies();
      await service.getPopularTvShows();
      await service.discoverMovies(withGenres: 28, sortBy: 'popularity.desc');
      await service.discoverTvShows(withGenres: 18);
      await service.getMovieGenres();
      await service.getTvGenres();
      await service.multiSearch('inception');
      await service.getMovieDetails('550');
      await service.getTvDetails('1399');
      await service.getMovieCredits('550');
      await service.getTvCredits('1399');
      await service.getMovieVideos('550');
      await service.getTvVideos('1399');
      await service.getMovieWatchProviders('550');
      await service.getTvWatchProviders('1399');
      await service.getTvSeasonDetails('1399', 1);

      expect(requestedUrls, contains('https://api.themoviedb.org/3/configuration?api_key=valid_token'));
      expect(requestedUrls, contains('https://api.themoviedb.org/3/trending/movie/week?api_key=valid_token&page=2&include_adult=false'));
      expect(requestedUrls, contains('https://api.themoviedb.org/3/trending/tv/week?api_key=valid_token&page=1&include_adult=false'));
      expect(requestedUrls, contains('https://api.themoviedb.org/3/movie/popular?api_key=valid_token&page=1&include_adult=false'));
      expect(requestedUrls, contains('https://api.themoviedb.org/3/tv/popular?api_key=valid_token&page=1&include_adult=false'));
      expect(requestedUrls, contains('https://api.themoviedb.org/3/discover/movie?api_key=valid_token&page=1&include_adult=false&with_genres=28&sort_by=popularity.desc'));
      expect(requestedUrls, contains('https://api.themoviedb.org/3/discover/tv?api_key=valid_token&page=1&include_adult=false&with_genres=18'));
      expect(requestedUrls, contains('https://api.themoviedb.org/3/genre/movie/list?api_key=valid_token'));
      expect(requestedUrls, contains('https://api.themoviedb.org/3/genre/tv/list?api_key=valid_token'));
      expect(requestedUrls, contains('https://api.themoviedb.org/3/search/multi?api_key=valid_token&query=inception&page=1&include_adult=false'));
      expect(requestedUrls, contains('https://api.themoviedb.org/3/movie/550?api_key=valid_token'));
      expect(requestedUrls, contains('https://api.themoviedb.org/3/tv/1399?api_key=valid_token'));
      expect(requestedUrls, contains('https://api.themoviedb.org/3/movie/550/credits?api_key=valid_token'));
      expect(requestedUrls, contains('https://api.themoviedb.org/3/tv/1399/credits?api_key=valid_token'));
      expect(requestedUrls, contains('https://api.themoviedb.org/3/movie/550/videos?api_key=valid_token'));
      expect(requestedUrls, contains('https://api.themoviedb.org/3/tv/1399/videos?api_key=valid_token'));
      expect(requestedUrls, contains('https://api.themoviedb.org/3/movie/550/watch/providers?api_key=valid_token'));
      expect(requestedUrls, contains('https://api.themoviedb.org/3/tv/1399/watch/providers?api_key=valid_token'));
      expect(requestedUrls, contains('https://api.themoviedb.org/3/tv/1399/season/1?api_key=valid_token'));
    });

    test('filterSearchResults separates direct titles vs person filmographies',
        () {
      final mockResponse = {
        'results': [
          {
            'id': 550,
            'media_type': 'movie',
            'title': 'Fight Club',
          },
          {
            'id': 1399,
            'media_type': 'tv',
            'name': 'Game of Thrones',
          },
          {
            'id': 287,
            'media_type': 'person',
            'name': 'Brad Pitt',
            'known_for': [
              {
                'id': 550,
                'media_type': 'movie',
                'title': 'Fight Club',
              },
              {
                'id': 16869,
                'media_type': 'movie',
                'title': 'Inglourious Basterds',
              }
            ]
          }
        ]
      };

      final service = TmdbApiService(token: 'dummy');
      final result = service.filterSearchResults(mockResponse);

      expect(result.titles.length, equals(2));
      expect(result.titles[0]['title'], equals('Fight Club'));
      expect(result.titles[1]['name'], equals('Game of Thrones'));

      expect(result.personFilmographies.length, equals(2));
      expect(result.personFilmographies[0]['title'], equals('Fight Club'));
      expect(result.personFilmographies[1]['title'],
          equals('Inglourious Basterds'));
    });
  });

  group('TmdbMovieRepository', () {
    test('Unconfigured repository falls back gracefully to MockMovieRepository',
        () async {
      final unconfiguredService = TmdbApiService(token: null);
      final repo = TmdbMovieRepository(
        apiService: unconfiguredService,
        fallbackRepository: MockMovieRepository(),
      );

      expect(repo.isConfigured, isFalse);

      final trendingMovies = await repo.getTrendingMovies();
      expect(trendingMovies, isNotEmpty);
      expect(trendingMovies.first.title, isNotEmpty);

      final popularMovies = await repo.getPopularMovies();
      expect(popularMovies, isNotEmpty);

      final trendingTv = await repo.getTrendingTvShows();
      expect(trendingTv, isNotEmpty);

      final details = await repo.getMediaDetails('1');
      expect(details, isNotNull);
      expect(details!.id, equals('1'));

      final searchResults = await repo.searchMedia('Inception');
      expect(searchResults, isNotEmpty);
    });

    test('Network exceptions fall back gracefully without crashing app',
        () async {
      final failingClient = MockClient((request) async {
        return http.Response('Internal Server Error', 500);
      });

      final service =
          TmdbApiService(token: 'valid_token', client: failingClient);
      final repo = TmdbMovieRepository(
        apiService: service,
        fallbackRepository: MockMovieRepository(),
      );

      final trendingMovies = await repo.getTrendingMovies();
      expect(trendingMovies, isNotEmpty);

      final searchResults = await repo.searchMedia('Inception');
      expect(searchResults, isNotEmpty);
    });

    test('Configured repository parses API responses into MediaItems',
        () async {
      final mockClient = MockClient((request) async {
        if (request.url.path.contains('/genre/')) {
          return http.Response(
              jsonEncode({
                'genres': [
                  {'id': 28, 'name': 'Action'},
                  {'id': 878, 'name': 'Sci-Fi'}
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
                    'release_date': '1999-10-15',
                    'overview': 'An insomniac office worker...',
                    'genre_ids': [28],
                    'poster_path': '/pB8BM7pdSp6B6Ih7QZ4DrQ3PmJK.jpg',
                    'backdrop_path': '/hZkgoQYus5vesz7cgEz7Ieb3y2m.jpg',
                  }
                ]
              }),
              200);
        }
        if (request.url.path.contains('/movie/550')) {
          return http.Response(
              jsonEncode({
                'id': 550,
                'title': 'Fight Club',
                'tagline': 'Mischief. Mayhem. Soap.',
                'vote_average': 8.4,
                'vote_count': 25000,
                'imdb_id': 'tt0137523',
                'release_date': '1999-10-15',
                'overview': 'An insomniac office worker...',
                'genres': [
                  {'id': 28, 'name': 'Action'}
                ],
                'poster_path': '/pB8BM7pdSp6B6Ih7QZ4DrQ3PmJK.jpg',
                'backdrop_path': '/hZkgoQYus5vesz7cgEz7Ieb3y2m.jpg',
                'runtime': 139,
                'belongs_to_collection': {
                  'id': 1234,
                  'name': 'Fight Club Collection',
                  'poster_path': '/fc_poster.jpg',
                  'backdrop_path': '/fc_backdrop.jpg'
                },
                'credits': {
                  'cast': [
                    {
                      'id': 287,
                      'name': 'Brad Pitt',
                      'character': 'Tyler Durden',
                      'profile_path': '/cckcYc2v0yh1tc9FjFqP2vHObux.jpg'
                    },
                    {
                      'id': 819,
                      'name': 'Edward Norton',
                      'character': 'The Narrator',
                      'profile_path': '/53St7eQk1n4C9z90s01t3N3n702.jpg'
                    }
                  ],
                  'crew': [
                    {'job': 'Director', 'name': 'David Fincher'}
                  ]
                },
                'release_dates': {
                  'results': [
                    {
                      'iso_3166_1': 'US',
                      'release_dates': [
                        {'certification': 'R'}
                      ]
                    }
                  ]
                },
                'keywords': {
                  'keywords': [
                    {'id': 5, 'name': 'insomnia'},
                    {'id': 6, 'name': 'fight'}
                  ]
                },
                'production_companies': [
                  {
                    'id': 508,
                    'name': 'Regency Enterprises',
                    'logo_path': '/logo.png'
                  }
                ],
                'videos': {
                  'results': [
                    {'type': 'Trailer', 'site': 'YouTube', 'key': 'O1tObeYv2Q'}
                  ]
                },
                'watch/providers': {
                  'results': {
                    'US': {
                      'flatrate': [
                        {'provider_name': 'Hulu'}
                      ]
                    }
                  }
                }
              }),
              200);
        }
        return http.Response(jsonEncode({'results': []}), 200);
      });

      final service =
          TmdbApiService(token: 'valid_token', client: mockClient);
      final repo = TmdbMovieRepository(apiService: service);

      final trending = await repo.getTrendingMovies();
      expect(trending.length, equals(1));
      expect(trending.first.id, equals('550'));
      expect(trending.first.title, equals('Fight Club'));
      expect(trending.first.type, equals(MediaType.movie));
      expect(trending.first.rating, equals(8.4));
      expect(
        trending.first.posterUrl,
        equals('https://image.tmdb.org/t/p/w342/pB8BM7pdSp6B6Ih7QZ4DrQ3PmJK.jpg'),
      );
      expect(
        trending.first.detailPosterUrl,
        equals('https://image.tmdb.org/t/p/w500/pB8BM7pdSp6B6Ih7QZ4DrQ3PmJK.jpg'),
      );
      expect(
        trending.first.backdropUrl,
        equals('https://image.tmdb.org/t/p/w780/hZkgoQYus5vesz7cgEz7Ieb3y2m.jpg'),
      );

      final details = await repo.getMediaDetails('550');
      expect(details, isNotNull);
      expect(details!.id, equals('550'));
      expect(details.title, equals('Fight Club'));
      expect(details.tagline, equals('Mischief. Mayhem. Soap.'));
      expect(details.director, equals('David Fincher'));
      expect(details.certification, equals('R'));
      expect(details.voteCount, equals(25000));
      expect(details.imdbId, equals('tt0137523'));
      expect(details.belongsToCollection, isNotNull);
      expect(details.belongsToCollection!.name, equals('Fight Club Collection'));
      expect(
        details.belongsToCollection!.posterUrl,
        equals('https://image.tmdb.org/t/p/w500/fc_poster.jpg'),
      );
      expect(
        details.belongsToCollection!.backdropUrl,
        equals('https://image.tmdb.org/t/p/w780/fc_backdrop.jpg'),
      );
      expect(details.keywords?.length, equals(2));
      expect(details.keywords?.first.name, equals('insomnia'));
      expect(details.productionCompanies?.length, equals(1));
      expect(details.productionCompanies?.first.name, equals('Regency Enterprises'));
      expect(
        details.productionCompanies?.first.logoUrl,
        equals('https://image.tmdb.org/t/p/w185/logo.png'),
      );
      expect(details.runtime, equals(139));
      expect(details.hasTrailer, isTrue);
      expect(details.cast, contains('Brad Pitt'));
      expect(details.watchProviders, contains('Hulu'));
      expect(details.castMembers.length, equals(2));
      expect(details.castMembers.first.name, equals('Brad Pitt'));
      expect(details.castMembers.first.character, equals('Tyler Durden'));
      expect(
        details.castMembers.first.profileUrl,
        equals('https://image.tmdb.org/t/p/w185/cckcYc2v0yh1tc9FjFqP2vHObux.jpg'),
      );
    });

    test('Configured repository parses multi-country flatrate, rent, and buy providers',
        () async {
      final mockClient = MockClient((request) async {
        if (request.url.path.contains('/movie/100')) {
          return http.Response(
              jsonEncode({
                'id': 100,
                'title': 'Multi Country Movie',
                'watch/providers': {
                  'results': {
                    'US': {
                      'flatrate': [{'provider_name': 'Netflix'}],
                      'rent': [{'provider_name': 'Apple TV'}],
                      'buy': [{'provider_name': 'Amazon Video'}]
                    },
                    'GB': {
                      'flatrate': [{'provider_name': 'BBC iPlayer'}],
                      'rent': [{'provider_name': 'Rakuten TV'}]
                    },
                    'CA': {
                      'flatrate': [{'provider_name': 'Crave'}]
                    }
                  }
                }
              }),
              200);
        }
        return http.Response(jsonEncode({'results': []}), 200);
      });

      final service = TmdbApiService(token: 'valid_token', client: mockClient);
      final repo = TmdbMovieRepository(apiService: service);

      final details = await repo.getMediaDetails('movie_100');
      expect(details, isNotNull);

      final usProviders = details!.getWatchProvidersForCountry('US');
      expect(usProviders, contains(const WatchProviderInfo(providerName: 'Netflix', category: 'Stream')));
      expect(usProviders, contains(const WatchProviderInfo(providerName: 'Apple TV', category: 'Rent')));
      expect(usProviders, contains(const WatchProviderInfo(providerName: 'Amazon Video', category: 'Buy')));

      final gbProviders = details.getWatchProvidersForCountry('GB');
      expect(gbProviders, contains(const WatchProviderInfo(providerName: 'BBC iPlayer', category: 'Stream')));
      expect(gbProviders, contains(const WatchProviderInfo(providerName: 'Rakuten TV', category: 'Rent')));

      final caProviders = details.getWatchProvidersForCountry('CA');
      expect(caProviders, contains(const WatchProviderInfo(providerName: 'Crave', category: 'Stream')));
    });

    test('TF-22: getUpcomingMovies filters out already-released titles TMDB still lists as upcoming',
        () async {
      final now = DateTime.now();
      final futureDate =
          now.add(const Duration(days: 30)).toIso8601String().split('T').first;
      final pastDate =
          now.subtract(const Duration(days: 5)).toIso8601String().split('T').first;

      final mockClient = MockClient((request) async {
        if (request.url.path.contains('/movie/upcoming')) {
          return http.Response(
              jsonEncode({
                'page': 1,
                'results': [
                  {
                    'id': 1,
                    'title': 'Genuinely Upcoming',
                    'release_date': futureDate,
                  },
                  {
                    'id': 2,
                    'title': 'Already Released (stale TMDB bucket)',
                    'release_date': pastDate,
                  },
                  {
                    'id': 3,
                    'title': 'No Release Date Yet',
                  },
                ]
              }),
              200);
        }
        return http.Response(jsonEncode({'results': []}), 200);
      });

      final service = TmdbApiService(token: 'valid_token', client: mockClient);
      final repo = TmdbMovieRepository(apiService: service);

      final upcoming = await repo.getUpcomingMovies();

      expect(upcoming.map((m) => m.title),
          containsAll(['Genuinely Upcoming', 'No Release Date Yet']));
      expect(upcoming.map((m) => m.title),
          isNot(contains('Already Released (stale TMDB bucket)')));
    });

    test(
        'TF-22 regression: falls back to the unfiltered page instead of an empty list '
        'when every title is filtered out (e.g. device clock skew)', () async {
      final now = DateTime.now();
      final pastDate =
          now.subtract(const Duration(days: 5)).toIso8601String().split('T').first;

      final mockClient = MockClient((request) async {
        if (request.url.path.contains('/movie/upcoming')) {
          return http.Response(
              jsonEncode({
                'page': 1,
                'results': [
                  {
                    'id': 1,
                    'title': 'Already Released A',
                    'release_date': pastDate,
                  },
                  {
                    'id': 2,
                    'title': 'Already Released B',
                    'release_date': pastDate,
                  },
                ]
              }),
              200);
        }
        return http.Response(jsonEncode({'results': []}), 200);
      });

      final service = TmdbApiService(token: 'valid_token', client: mockClient);
      final repo = TmdbMovieRepository(apiService: service);

      final upcoming = await repo.getUpcomingMovies();

      expect(upcoming.map((m) => m.title),
          containsAll(['Already Released A', 'Already Released B']));
    });

    test('getWatchProviderRegions fetches and returns dynamic country regions',
        () async {
      final mockClient = MockClient((request) async {
        if (request.url.path.contains('/watch/providers/regions')) {
          return http.Response(
              jsonEncode({
                'results': [
                  {'iso_3166_1': 'US', 'english_name': 'United States'},
                  {'iso_3166_1': 'IN', 'english_name': 'India'},
                  {'iso_3166_1': 'BR', 'english_name': 'Brazil'}
                ]
              }),
              200);
        }
        return http.Response(jsonEncode({'results': []}), 200);
      });

      final service = TmdbApiService(token: 'valid_token', client: mockClient);
      final repo = TmdbMovieRepository(apiService: service);

      final regions = await repo.getWatchProviderRegions();
      expect(regions.length, equals(3));
      expect(regions[0], equals({'code': 'US', 'name': 'United States'}));
      expect(regions[1], equals({'code': 'IN', 'name': 'India'}));
      expect(regions[2], equals({'code': 'BR', 'name': 'Brazil'}));
    });

    test('searchMedia preserves TMDB relevance order and excludes low-relevance noise items',
        () async {
      final mockClient = MockClient((request) async {
        if (request.url.path.contains('/search/multi')) {
          return http.Response(
              jsonEncode({
                'results': [
                  {
                    'id': 1,
                    'media_type': 'movie',
                    'title': 'High Relevance Movie',
                    'popularity': 150.0,
                    'poster_path': '/poster1.jpg',
                  },
                  {
                    'id': 2,
                    'media_type': 'movie',
                    'title': 'Zero Popularity Noise',
                    'popularity': 0.0,
                    'poster_path': '/poster2.jpg',
                  },
                  {
                    'id': 3,
                    'media_type': 'movie',
                    'title': 'Missing Poster Noise',
                    'popularity': 80.0,
                    'poster_path': null,
                  },
                  {
                    'id': 100,
                    'media_type': 'person',
                    'name': 'Famous Actor',
                    'popularity': 90.0,
                    'known_for': [
                      {
                        'id': 4,
                        'media_type': 'movie',
                        'title': 'Actor Major Hit',
                        'popularity': 200.0,
                        'poster_path': '/poster4.jpg',
                      }
                    ]
                  }
                ]
              }),
              200);
        }
        return http.Response(jsonEncode({'results': []}), 200);
      });

      final service = TmdbApiService(token: 'valid_token', client: mockClient);
      final repo = TmdbMovieRepository(apiService: service);

      final results = await repo.searchMedia('test');
      expect(results.length, equals(2));
      expect(results[0].id, equals('1'));
      expect(results[0].title, equals('High Relevance Movie'));
      expect(results[1].id, equals('4'));
      expect(results[1].title, equals('Actor Major Hit'));
    });

    test(
        'B1: searchMedia fetches the real filmography when the top result is a person, '
        'instead of known_for + unrelated title-text matches',
        () async {
      final mockClient = MockClient((request) async {
        if (request.url.path.contains('/search/multi')) {
          return http.Response(
              jsonEncode({
                'results': [
                  {
                    'id': 31,
                    'media_type': 'person',
                    'name': 'Tom Hanks',
                    'popularity': 95.0,
                    'known_for': [
                      {
                        'id': 13,
                        'media_type': 'movie',
                        'title': 'Forrest Gump',
                        'popularity': 80.0,
                        'poster_path': '/gump.jpg',
                      }
                    ],
                  },
                  {
                    'id': 999,
                    'media_type': 'movie',
                    'title': 'Tom Hanks: Hollywood\'s Mr. Nice Guy',
                    'popularity': 5.0,
                    'poster_path': '/doc.jpg',
                  },
                ],
              }),
              200);
        }
        if (request.url.path.contains('/person/31/movie_credits')) {
          return http.Response(
              jsonEncode({
                'cast': [
                  {
                    'id': 13,
                    'title': 'Forrest Gump',
                    'popularity': 80.0,
                    'poster_path': '/gump.jpg',
                  },
                  {
                    'id': 857,
                    'title': 'Saving Private Ryan',
                    'popularity': 70.0,
                    'poster_path': '/ryan.jpg',
                  },
                ],
                'crew': [
                  {
                    'id': 13,
                    'title': 'Forrest Gump',
                    'popularity': 80.0,
                    'poster_path': '/gump.jpg',
                  },
                  {
                    'id': 12345,
                    'title': 'Unposterable Credit',
                    'popularity': 1.0,
                    'poster_path': null,
                  },
                ],
              }),
              200);
        }
        if (request.url.path.contains('/person/31/tv_credits')) {
          return http.Response(
              jsonEncode({
                'cast': [
                  {
                    'id': 55,
                    'name': 'Band of Brothers',
                    'popularity': 60.0,
                    'poster_path': '/bob.jpg',
                  },
                ],
                'crew': [],
              }),
              200);
        }
        if (request.url.path.contains('/genre/')) {
          return http.Response(jsonEncode({'genres': []}), 200);
        }
        return http.Response(jsonEncode({'results': []}), 200);
      });

      final service = TmdbApiService(token: 'valid_token', client: mockClient);
      final repo = TmdbMovieRepository(apiService: service);

      final results = await repo.searchMedia('Tom Hanks');

      // Real filmography (movie + TV, cast + crew, deduped), not the noisy
      // known_for + title-text-match mix.
      final titles = results.map((r) => r.title).toSet();
      expect(titles, contains('Forrest Gump'));
      expect(titles, contains('Saving Private Ryan'));
      expect(titles, contains('Band of Brothers'));
      // Deduped: Forrest Gump appeared in both cast and crew.
      expect(results.where((r) => r.title == 'Forrest Gump').length, equals(1));
      // Invalid credit (no poster) excluded.
      expect(titles, isNot(contains('Unposterable Credit')));
      // The unrelated documentary that only matched on literal title text
      // must not appear -- this is exactly the TF-16/TF-24 bug.
      expect(titles, isNot(contains('Tom Hanks: Hollywood\'s Mr. Nice Guy')));
    });

    test(
        'B1: searchMedia falls back to title matches when the top result is not a person',
        () async {
      // A title search for an actual person's-name-shaped movie title
      // (no person entry ranked first) must not trigger the filmography
      // path -- covered structurally by the existing relevance-order test
      // above (its top result is 'High Relevance Movie', a movie), plus
      // this explicit no-person-at-all case.
      final mockClient = MockClient((request) async {
        if (request.url.path.contains('/search/multi')) {
          return http.Response(
              jsonEncode({
                'results': [
                  {
                    'id': 1,
                    'media_type': 'movie',
                    'title': 'Dune',
                    'popularity': 120.0,
                    'poster_path': '/dune.jpg',
                  },
                ],
              }),
              200);
        }
        return http.Response(jsonEncode({'results': []}), 200);
      });

      final service = TmdbApiService(token: 'valid_token', client: mockClient);
      final repo = TmdbMovieRepository(apiService: service);

      final results = await repo.searchMedia('Dune');
      expect(results.length, equals(1));
      expect(results.first.title, equals('Dune'));
    });

    test(
        'B1: discoverMedia with a person filter uses real filmography instead of '
        "TMDB's with_people, which /discover/tv doesn't support at all",
        () async {
      var discoverTvWasCalled = false;

      final mockClient = MockClient((request) async {
        if (request.url.path.contains('/discover/tv')) {
          // TMDB's real /discover/tv endpoint has no with_people param --
          // if the app were still relying on it, this would be hit and
          // would return an unfiltered, generic result set.
          discoverTvWasCalled = true;
          return http.Response(
              jsonEncode({
                'results': [
                  {
                    'id': 999,
                    'name': 'Unrelated Generic Show',
                    'popularity': 500.0,
                    'poster_path': '/generic.jpg',
                  },
                ],
              }),
              200);
        }
        if (request.url.path.contains('/person/77/movie_credits')) {
          return http.Response(jsonEncode({'cast': [], 'crew': []}), 200);
        }
        if (request.url.path.contains('/person/77/tv_credits')) {
          return http.Response(
              jsonEncode({
                'cast': [
                  {
                    'id': 55,
                    'name': 'Their Actual Drama',
                    'popularity': 40.0,
                    'poster_path': '/drama.jpg',
                  },
                ],
                'crew': [],
              }),
              200);
        }
        if (request.url.path.contains('/genre/')) {
          return http.Response(jsonEncode({'genres': []}), 200);
        }
        return http.Response(jsonEncode({'results': []}), 200);
      });

      final service = TmdbApiService(token: 'valid_token', client: mockClient);
      final repo = TmdbMovieRepository(apiService: service);

      final results = await repo.discoverMedia(
        isMovies: false,
        params: const DiscoverFilterParams(personId: 77),
      );

      expect(discoverTvWasCalled, isFalse,
          reason: 'must not hit /discover/tv at all when a person filter is '
              'active -- with_people silently does nothing there');
      expect(results.length, equals(1));
      expect(results.first.title, equals('Their Actual Drama'));
    });

    test(
        'selects full official trailer key when both teaser and trailer are present in videos.results',
        () async {
      final mockClient = MockClient((request) async {
        if (request.url.path.contains('/movie/10')) {
          return http.Response(
              jsonEncode({
                'id': 10,
                'title': 'Both Teaser and Trailer',
                'videos': {
                  'results': [
                    {
                      'type': 'Teaser',
                      'site': 'YouTube',
                      'key': 'teaser_key_official',
                      'official': true,
                    },
                    {
                      'type': 'Trailer',
                      'site': 'YouTube',
                      'key': 'trailer_key_unofficial',
                      'official': false,
                    },
                    {
                      'type': 'Trailer',
                      'site': 'YouTube',
                      'key': 'trailer_key_official',
                      'official': true,
                    },
                  ]
                }
              }),
              200);
        }
        return http.Response(jsonEncode({'results': []}), 200);
      });

      final service = TmdbApiService(token: 'valid_token', client: mockClient);
      final repo = TmdbMovieRepository(apiService: service);

      final item = await repo.getMediaDetails('movie_10');
      expect(item, isNotNull);
      expect(item!.hasTrailer, isTrue);
      expect(item.trailerVideoId, equals('trailer_key_official'));
      expect(item.trailers, isNotNull);
      expect(item.trailers!.length, equals(3));
      expect(item.trailers![0].key, equals('teaser_key_official'));
      expect(item.trailers![0].type, equals('Teaser'));
      expect(item.trailers![2].key, equals('trailer_key_official'));
      expect(item.trailers![2].official, isTrue);
    });

    test(
        'selects teaser key as fallback when only teaser is present in videos.results',
        () async {
      final mockClient = MockClient((request) async {
        if (request.url.path.contains('/movie/20')) {
          return http.Response(
              jsonEncode({
                'id': 20,
                'title': 'Only Teaser Present',
                'videos': {
                  'results': [
                    {
                      'type': 'Teaser',
                      'site': 'YouTube',
                      'key': 'teaser_key_unofficial',
                      'official': false,
                    },
                    {
                      'type': 'Teaser',
                      'site': 'YouTube',
                      'key': 'teaser_key_official',
                      'official': true,
                    },
                  ]
                }
              }),
              200);
        }
        return http.Response(jsonEncode({'results': []}), 200);
      });

      final service = TmdbApiService(token: 'valid_token', client: mockClient);
      final repo = TmdbMovieRepository(apiService: service);

      final item = await repo.getMediaDetails('movie_20');
      expect(item, isNotNull);
      expect(item!.hasTrailer, isTrue);
      expect(item.trailerVideoId, equals('teaser_key_official'));
    });

    test(
        'sets hasTrailer to false and trailerVideoId to null when no YouTube trailer/teaser exists',
        () async {
      final mockClient = MockClient((request) async {
        if (request.url.path.contains('/movie/30')) {
          return http.Response(
              jsonEncode({
                'id': 30,
                'title': 'No YouTube Trailer or Teaser',
                'videos': {
                  'results': [
                    {
                      'type': 'Trailer',
                      'site': 'Vimeo',
                      'key': 'vimeo_trailer',
                      'official': true,
                    },
                    {
                      'type': 'Behind the Scenes',
                      'site': 'YouTube',
                      'key': 'bts_youtube',
                      'official': true,
                    },
                  ]
                }
              }),
              200);
        }
        return http.Response(jsonEncode({'results': []}), 200);
      });

      final service = TmdbApiService(token: 'valid_token', client: mockClient);
      final repo = TmdbMovieRepository(apiService: service);

      final item = await repo.getMediaDetails('movie_30');
      expect(item, isNotNull);
      expect(item!.hasTrailer, isFalse);
      expect(item.trailerVideoId, isNull);
    });
  });
}


