import 'dart:convert';
import 'dart:io';
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

      final service =
          TmdbApiService(token: 'eyJ_secret_jwt_token', client: client);
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

      expect(
          requestedUrls,
          contains(
              'https://api.themoviedb.org/3/configuration?api_key=valid_token'));
      expect(
          requestedUrls,
          contains(
              'https://api.themoviedb.org/3/trending/movie/week?api_key=valid_token&page=2&include_adult=false'));
      expect(
          requestedUrls,
          contains(
              'https://api.themoviedb.org/3/trending/tv/week?api_key=valid_token&page=1&include_adult=false'));
      expect(
          requestedUrls,
          contains(
              'https://api.themoviedb.org/3/movie/popular?api_key=valid_token&page=1&include_adult=false'));
      expect(
          requestedUrls,
          contains(
              'https://api.themoviedb.org/3/tv/popular?api_key=valid_token&page=1&include_adult=false'));
      expect(
          requestedUrls,
          contains(
              'https://api.themoviedb.org/3/discover/movie?api_key=valid_token&page=1&include_adult=false&with_genres=28&sort_by=popularity.desc'));
      expect(
          requestedUrls,
          contains(
              'https://api.themoviedb.org/3/discover/tv?api_key=valid_token&page=1&include_adult=false&with_genres=18'));
      expect(
          requestedUrls,
          contains(
              'https://api.themoviedb.org/3/genre/movie/list?api_key=valid_token'));
      expect(
          requestedUrls,
          contains(
              'https://api.themoviedb.org/3/genre/tv/list?api_key=valid_token'));
      expect(
          requestedUrls,
          contains(
              'https://api.themoviedb.org/3/search/multi?api_key=valid_token&query=inception&page=1&include_adult=false'));
      expect(
          requestedUrls,
          contains(
              'https://api.themoviedb.org/3/movie/550?api_key=valid_token'));
      expect(requestedUrls,
          contains('https://api.themoviedb.org/3/tv/1399?api_key=valid_token'));
      expect(
          requestedUrls,
          contains(
              'https://api.themoviedb.org/3/movie/550/credits?api_key=valid_token'));
      expect(
          requestedUrls,
          contains(
              'https://api.themoviedb.org/3/tv/1399/credits?api_key=valid_token'));
      expect(
          requestedUrls,
          contains(
              'https://api.themoviedb.org/3/movie/550/videos?api_key=valid_token'));
      expect(
          requestedUrls,
          contains(
              'https://api.themoviedb.org/3/tv/1399/videos?api_key=valid_token'));
      expect(
          requestedUrls,
          contains(
              'https://api.themoviedb.org/3/movie/550/watch/providers?api_key=valid_token'));
      expect(
          requestedUrls,
          contains(
              'https://api.themoviedb.org/3/tv/1399/watch/providers?api_key=valid_token'));
      expect(
          requestedUrls,
          contains(
              'https://api.themoviedb.org/3/tv/1399/season/1?api_key=valid_token'));
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

    group('PERF-STAMPEDE-1: transient network error retry', () {
      test('retries a SocketException-style failure and succeeds', () async {
        var attempts = 0;
        final client = MockClient((request) async {
          attempts++;
          if (attempts < 3) {
            throw const SocketException('Connection reset by peer');
          }
          return http.Response(jsonEncode({'page': 1, 'results': []}), 200);
        });

        final service = TmdbApiService(token: 'valid_token', client: client);
        final result = await service.getTrendingMovies();

        expect(result['results'], isEmpty);
        expect(attempts, 3);
      });

      test('gives up after exhausting retries on a persistent failure',
          () async {
        var attempts = 0;
        final client = MockClient((request) async {
          attempts++;
          throw const SocketException('Connection reset by peer');
        });

        final service = TmdbApiService(token: 'valid_token', client: client);

        await expectLater(service.getTrendingMovies(), throwsA(anything));
        expect(attempts, 3);
      });

      test('does not retry a real API error response (e.g. 404)', () async {
        var attempts = 0;
        final client = MockClient((request) async {
          attempts++;
          return http.Response('{"status_message":"Not found"}', 404);
        });

        final service = TmdbApiService(token: 'valid_token', client: client);

        await expectLater(service.getTrendingMovies(), throwsA(anything));
        expect(attempts, 1);
      });
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
      expect(details!.id, equals('movie_1'));

      final searchResults = await repo.searchMedia('Inception');
      expect(searchResults, isNotEmpty);
    });

    test(
        'PERF-STAMPEDE-1: concurrent callers share one in-flight genre-list '
        'fetch instead of each firing their own', () async {
      var movieGenreRequests = 0;
      var tvGenreRequests = 0;
      final client = MockClient((request) async {
        final path = request.url.path;
        if (path.endsWith('/genre/movie/list')) {
          movieGenreRequests++;
          // Real-world regression: a slow-ish genre-list fetch leaves a
          // wide window for concurrent callers to race past a naive
          // "already loaded?" guard before it completes.
          await Future.delayed(const Duration(milliseconds: 20));
          return http.Response(
              jsonEncode({
                'genres': [
                  {'id': 28, 'name': 'Action'}
                ]
              }),
              200);
        }
        if (path.endsWith('/genre/tv/list')) {
          tvGenreRequests++;
          await Future.delayed(const Duration(milliseconds: 20));
          return http.Response(
              jsonEncode({
                'genres': [
                  {'id': 18, 'name': 'Drama'}
                ]
              }),
              200);
        }
        return http.Response(jsonEncode({'page': 1, 'results': []}), 200);
      });

      final service = TmdbApiService(token: 'valid_token', client: client);
      final repo = TmdbMovieRepository(apiService: service);

      // Mirrors real app startup: several Lobby rails fire concurrently,
      // each internally ensuring genres are loaded before mapping results.
      await Future.wait([
        repo.getTrendingMovies(),
        repo.getPopularMovies(),
        repo.getTrendingTvShows(),
        repo.getTopRatedMovies(),
      ]);

      expect(movieGenreRequests, 1);
      expect(tvGenreRequests, 1);
    });

    test(
        'BETA3-NET-1: concurrent getMediaDetails(id) calls share one '
        'in-flight fetch instead of firing duplicate requests', () async {
      var movieDetailRequests = 0;
      final client = MockClient((request) async {
        final path = request.url.path;
        if (path.contains('/movie/42')) {
          movieDetailRequests++;
          // Real-world regression: mediaDetailsProvider and
          // tvShowSeasonsProvider can both fire getMediaDetails(id) in the
          // same frame when seasonsCount is unknown -- a slow-ish fetch
          // leaves a wide window for both to race past independently.
          await Future.delayed(const Duration(milliseconds: 20));
          return http.Response(
              jsonEncode({'id': 42, 'title': 'Concurrent Movie'}), 200);
        }
        return http.Response(jsonEncode({'genres': []}), 200);
      });

      final service = TmdbApiService(token: 'valid_token', client: client);
      final repo = TmdbMovieRepository(apiService: service);

      final results = await Future.wait([
        repo.getMediaDetails('movie_42'),
        repo.getMediaDetails('movie_42'),
        repo.getMediaDetails('movie_42'),
      ]);

      expect(movieDetailRequests, 1);
      for (final r in results) {
        expect(r, isNotNull);
        expect(r!.title, equals('Concurrent Movie'));
      }
    });

    test(
        'BETA3-NET-1: concurrent getCollectionDetails(id) calls share one '
        'in-flight fetch instead of firing duplicate requests', () async {
      var collectionRequests = 0;
      final client = MockClient((request) async {
        final path = request.url.path;
        if (path.contains('/collection/7')) {
          collectionRequests++;
          // Mirrors the real collision: collection_screen.dart's
          // collectionDetailsProvider and analytics_provider.dart's
          // Franchise Completion metric can both request the same
          // collection independently.
          await Future.delayed(const Duration(milliseconds: 20));
          return http.Response(
              jsonEncode({'id': 7, 'name': 'Concurrent Collection', 'parts': []}),
              200);
        }
        return http.Response(jsonEncode({'genres': []}), 200);
      });

      final service = TmdbApiService(token: 'valid_token', client: client);
      final repo = TmdbMovieRepository(apiService: service);

      final results = await Future.wait([
        repo.getCollectionDetails(7),
        repo.getCollectionDetails(7),
      ]);

      expect(collectionRequests, 1);
      for (final r in results) {
        expect(r, isNotNull);
        expect(r!.name, equals('Concurrent Collection'));
      }
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

      final service = TmdbApiService(token: 'valid_token', client: mockClient);
      final repo = TmdbMovieRepository(apiService: service);

      final trending = await repo.getTrendingMovies();
      expect(trending.length, equals(1));
      expect(trending.first.id, equals('movie_550'));
      expect(trending.first.title, equals('Fight Club'));
      expect(trending.first.type, equals(MediaType.movie));
      expect(trending.first.rating, equals(8.4));
      expect(
        trending.first.posterUrl,
        equals(
            'https://image.tmdb.org/t/p/w342/pB8BM7pdSp6B6Ih7QZ4DrQ3PmJK.jpg'),
      );
      expect(
        trending.first.detailPosterUrl,
        equals(
            'https://image.tmdb.org/t/p/w500/pB8BM7pdSp6B6Ih7QZ4DrQ3PmJK.jpg'),
      );
      expect(
        trending.first.backdropUrl,
        equals(
            'https://image.tmdb.org/t/p/w780/hZkgoQYus5vesz7cgEz7Ieb3y2m.jpg'),
      );

      final details = await repo.getMediaDetails('550');
      expect(details, isNotNull);
      expect(details!.id, equals('movie_550'));
      expect(details.title, equals('Fight Club'));
      expect(details.tagline, equals('Mischief. Mayhem. Soap.'));
      expect(details.director, equals('David Fincher'));
      expect(details.certification, equals('R'));
      expect(details.voteCount, equals(25000));
      expect(details.imdbId, equals('tt0137523'));
      expect(details.belongsToCollection, isNotNull);
      expect(
          details.belongsToCollection!.name, equals('Fight Club Collection'));
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
      expect(details.productionCompanies?.first.name,
          equals('Regency Enterprises'));
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
        equals(
            'https://image.tmdb.org/t/p/w185/cckcYc2v0yh1tc9FjFqP2vHObux.jpg'),
      );
    });

    test(
        'TV details fall back to last_episode_to_air.runtime when episode_run_time is empty',
        () async {
      // Regression: some shows (e.g. deliberately variable episode lengths)
      // leave TMDB's aggregate `episode_run_time` empty at the show level
      // even though a real per-episode runtime is available elsewhere on
      // the same response -- Analytics' Time Investment previously showed
      // 0 hours for a fully-watched show like this because `runtime`
      // resolved to null and got silently excluded.
      final mockClient = MockClient((request) async {
        if (request.url.path.contains('/tv/94605')) {
          return http.Response(
              jsonEncode({
                'id': 94605,
                'name': 'Arcane',
                'vote_average': 8.751,
                'first_air_date': '2021-11-06',
                'overview': '',
                'genres': [
                  {'id': 16, 'name': 'Animation'}
                ],
                'episode_run_time': [],
                'last_episode_to_air': {'runtime': 51},
                'credits': {
                  'cast': [
                    {'id': 1, 'name': 'Hailee Steinfeld', 'character': 'Vi'},
                  ],
                  'crew': [
                    {'job': 'Director', 'name': 'Christian Linke'},
                  ]
                },
              }),
              200);
        }
        return http.Response(jsonEncode({'results': []}), 200);
      });

      final service = TmdbApiService(token: 'valid_token', client: mockClient);
      final repo = TmdbMovieRepository(apiService: service);

      final details = await repo.getMediaDetails('tv_94605');
      expect(details, isNotNull);
      expect(details!.runtime, equals(51));
    });

    test(
        'DATA-CAST-1: TV details request aggregate_credits (not credits) and parse full-series cast with per-role episode counts',
        () async {
      Uri? capturedTvRequestUrl;
      final mockClient = MockClient((request) async {
        if (request.url.path.contains('/tv/94997')) {
          capturedTvRequestUrl = request.url;
          return http.Response(
              jsonEncode({
                'id': 94997,
                'name': 'House of the Dragon',
                'vote_average': 8.4,
                'first_air_date': '2022-08-21',
                'overview': '',
                'genres': [
                  {'id': 18, 'name': 'Drama'}
                ],
                'aggregate_credits': {
                  'cast': [
                    {
                      'id': 1,
                      'name': 'Matt Smith',
                      'profile_path': '/matt.jpg',
                      'roles': [
                        {
                          'credit_id': 'c1',
                          'character': 'Daemon Targaryen',
                          'episode_count': 10
                        }
                      ],
                      'total_episode_count': 10,
                      'order': 0,
                    },
                    {
                      'id': 2,
                      'name': 'Emma D\'Arcy',
                      'profile_path': null,
                      'roles': [
                        {
                          'credit_id': 'c2',
                          'character': 'Rhaenyra Targaryen',
                          'episode_count': 8
                        }
                      ],
                      'total_episode_count': 8,
                      'order': 1,
                    },
                  ],
                  'crew': [
                    {
                      'id': 3,
                      'name': 'Ryan Condal',
                      'department': 'Writing',
                      'jobs': [
                        {'job': 'Director', 'episode_count': 1},
                        {'job': 'Writer', 'episode_count': 5},
                        {'job': 'Producer', 'episode_count': 10},
                      ],
                      'total_episode_count': 10,
                    },
                    {
                      'id': 4,
                      'name': 'Ramin Djawadi',
                      'department': 'Sound',
                      'jobs': [
                        {'job': 'Original Music Composer', 'episode_count': 10},
                      ],
                      'total_episode_count': 10,
                    },
                  ],
                },
              }),
              200);
        }
        return http.Response(jsonEncode({'results': []}), 200);
      });

      final service = TmdbApiService(token: 'valid_token', client: mockClient);
      final repo = TmdbMovieRepository(apiService: service);

      final details = await repo.getMediaDetails('tv_94997');
      expect(details, isNotNull);

      // The TV request must append aggregate_credits, not the standard
      // pilot-only credits.
      expect(capturedTvRequestUrl, isNotNull);
      final appendParts =
          capturedTvRequestUrl!.queryParameters['append_to_response']!
              .split(',');
      expect(appendParts, contains('aggregate_credits'));
      expect(appendParts, isNot(contains('credits')));

      expect(details!.castMembers.length, equals(2));
      final daemon = details.castMembers.first;
      expect(daemon.name, equals('Matt Smith'));
      expect(daemon.character, equals('Daemon Targaryen'));
      expect(daemon.roles, equals(['Daemon Targaryen']));
      expect(daemon.totalEpisodeCount, equals(10));

      // A director found via aggregate_credits' `jobs` array (not the
      // single `job` field standard credits uses).
      expect(details.director, equals('Ryan Condal'));

      // DATA-CAST-2: Writer/Composer/Producer extracted from the same
      // aggregate crew list, each with its own aggregated episode count.
      expect(details.extendedCrew, isNotNull);
      final byRole = {for (final c in details.extendedCrew!) c.role: c};
      expect(byRole['Writer']!.name, equals('Ryan Condal'));
      expect(byRole['Writer']!.totalEpisodeCount, equals(5));
      expect(byRole['Producer']!.name, equals('Ryan Condal'));
      expect(byRole['Producer']!.totalEpisodeCount, equals(10));
      expect(byRole['Composer']!.name, equals('Ramin Djawadi'));
      expect(byRole['Composer']!.totalEpisodeCount, equals(10));
    });

    test(
        'DATA-CAST-2: extended crew (Writer, Composer, DP, Producer) parsed from movie credits.crew',
        () async {
      final mockClient = MockClient((request) async {
        if (request.url.path.contains('/movie/200')) {
          return http.Response(
              jsonEncode({
                'id': 200,
                'title': 'A Prestige Picture',
                'credits': {
                  'cast': [],
                  'crew': [
                    {'id': 10, 'name': 'A Writer', 'job': 'Screenplay'},
                    {'id': 11, 'name': 'A Composer', 'job': 'Original Music Composer'},
                    {'id': 12, 'name': 'A DP', 'job': 'Director of Photography'},
                    {'id': 13, 'name': 'A Producer', 'job': 'Producer'},
                    {'id': 14, 'name': 'Another Producer', 'job': 'Producer'},
                    {'id': 15, 'name': 'Unrelated Crew', 'job': 'Gaffer'},
                  ],
                },
              }),
              200);
        }
        return http.Response(jsonEncode({'results': []}), 200);
      });

      final service = TmdbApiService(token: 'valid_token', client: mockClient);
      final repo = TmdbMovieRepository(apiService: service);

      final details = await repo.getMediaDetails('movie_200');
      expect(details, isNotNull);
      expect(details!.extendedCrew, isNotNull);
      expect(details.extendedCrew!.length, equals(5));
      final names = details.extendedCrew!.map((c) => c.name).toList();
      expect(names, isNot(contains('Unrelated Crew')));
      final producers =
          details.extendedCrew!.where((c) => c.role == 'Producer').toList();
      expect(producers.length, equals(2));
      final writer =
          details.extendedCrew!.firstWhere((c) => c.role == 'Writer');
      // 'Screenplay' is one of the raw job titles mapped onto the
      // 'Writer' canonical label.
      expect(writer.name, equals('A Writer'));
    });

    test('DATA-CAST-3: cast list is no longer capped at 8 actors',
        () async {
      final mockClient = MockClient((request) async {
        if (request.url.path.contains('/movie/300')) {
          return http.Response(
              jsonEncode({
                'id': 300,
                'title': 'Ensemble Picture',
                'credits': {
                  'cast': List.generate(
                    12,
                    (i) => {
                      'id': i,
                      'name': 'Actor $i',
                      'character': 'Character $i',
                    },
                  ),
                },
              }),
              200);
        }
        return http.Response(jsonEncode({'results': []}), 200);
      });

      final service = TmdbApiService(token: 'valid_token', client: mockClient);
      final repo = TmdbMovieRepository(apiService: service);

      final details = await repo.getMediaDetails('movie_300');
      expect(details, isNotNull);
      expect(details!.cast.length, equals(12));
      expect(details.castMembers.length, equals(12));
    });

    test(
        'DATA-CAST-4: getTvSeasonDetails parses guest_stars and crew already present on the episode payload',
        () async {
      final mockClient = MockClient((request) async {
        if (request.url.path.contains('/tv/500/season/1')) {
          return http.Response(
              jsonEncode({
                'id': 5001,
                'season_number': 1,
                'name': 'Season 1',
                'episodes': [
                  {
                    'id': 1,
                    'episode_number': 1,
                    'season_number': 1,
                    'name': 'Pilot',
                    'guest_stars': [
                      {
                        'id': 99,
                        'name': 'Guest Star',
                        'character': 'Visitor',
                        'profile_path': '/guest.jpg',
                      },
                    ],
                    'crew': [
                      {
                        'id': 88,
                        'name': 'Episode Director',
                        'job': 'Director',
                        'profile_path': null,
                      },
                    ],
                  },
                ],
              }),
              200);
        }
        return http.Response(jsonEncode({'results': []}), 200);
      });

      final service = TmdbApiService(token: 'valid_token', client: mockClient);
      final repo = TmdbMovieRepository(apiService: service);

      final season = await repo.getTvSeasonDetails('500', 1);
      expect(season, isNotNull);
      expect(season!.episodes.length, equals(1));
      final episode = season.episodes.first;
      expect(episode.guestStars, isNotNull);
      expect(episode.guestStars!.first.name, equals('Guest Star'));
      expect(episode.guestStars!.first.character, equals('Visitor'));
      expect(episode.crew, isNotNull);
      expect(episode.crew!.first.name, equals('Episode Director'));
      expect(episode.crew!.first.role, equals('Director'));
    });

    test(
        'DATA-CONT-1: details request appends images with include_image_language and parses ClearLogo/alternate backdrops/posters',
        () async {
      Uri? capturedUrl;
      final mockClient = MockClient((request) async {
        if (request.url.path.contains('/movie/800')) {
          capturedUrl = request.url;
          return http.Response(
              jsonEncode({
                'id': 800,
                'title': 'Logo Picture',
                'images': {
                  'logos': [
                    // A non-English SVG entry that should lose to the PNG
                    // English entry below despite appearing first.
                    {
                      'file_path': '/logo-fr.svg',
                      'iso_639_1': 'fr',
                      'vote_average': 9.0,
                    },
                    {
                      'file_path': '/logo-en.png',
                      'iso_639_1': 'en',
                      'vote_average': 5.0,
                    },
                  ],
                  'backdrops': [
                    {'file_path': '/backdrop1.jpg'},
                    {'file_path': '/backdrop2.jpg'},
                  ],
                  'posters': [
                    {'file_path': '/poster1.jpg'},
                  ],
                },
              }),
              200);
        }
        return http.Response(jsonEncode({'results': []}), 200);
      });

      final service = TmdbApiService(token: 'valid_token', client: mockClient);
      final repo = TmdbMovieRepository(apiService: service);

      final details = await repo.getMediaDetails('movie_800');
      expect(details, isNotNull);

      expect(capturedUrl, isNotNull);
      final appendParts =
          capturedUrl!.queryParameters['append_to_response']!.split(',');
      expect(appendParts, contains('images'));
      expect(capturedUrl!.queryParameters['include_image_language'],
          equals('en,null'));

      // PNG + English-tagged wins over an earlier-listed, higher-voted
      // non-English SVG.
      expect(details!.logoUrl,
          equals('https://image.tmdb.org/t/p/w500/logo-en.png'));
      expect(
          details.backdropUrls,
          equals([
            'https://image.tmdb.org/t/p/w780/backdrop1.jpg',
            'https://image.tmdb.org/t/p/w780/backdrop2.jpg',
          ]));
      expect(details.posterUrls,
          equals(['https://image.tmdb.org/t/p/w342/poster1.jpg']));
    });

    test(
        'DATA-CONT-2: parses reviews verbatim, including the Gravatar avatar_path quirk',
        () async {
      final mockClient = MockClient((request) async {
        if (request.url.path.contains('/movie/900')) {
          return http.Response(
              jsonEncode({
                'id': 900,
                'title': 'Reviewed Picture',
                'reviews': {
                  'results': [
                    {
                      'id': 'rev1',
                      'author': 'Alice',
                      'content': 'Loved it.',
                      'created_at': '2021-05-01T00:00:00.000Z',
                      'url': 'https://www.themoviedb.org/review/rev1',
                      'author_details': {
                        'rating': 9,
                        'avatar_path': '/tmdb-avatar.jpg',
                      },
                    },
                    {
                      'id': 'rev2',
                      'author': 'Bob',
                      'content': 'It was fine.',
                      'author_details': {
                        'rating': null,
                        'avatar_path':
                            '/https://secure.gravatar.com/avatar/xyz.jpg',
                      },
                    },
                  ],
                },
              }),
              200);
        }
        return http.Response(jsonEncode({'results': []}), 200);
      });

      final service = TmdbApiService(token: 'valid_token', client: mockClient);
      final repo = TmdbMovieRepository(apiService: service);

      final details = await repo.getMediaDetails('movie_900');
      expect(details, isNotNull);
      expect(details!.reviews, isNotNull);
      expect(details.reviews!.length, equals(2));

      final alice = details.reviews!.first;
      expect(alice.author, equals('Alice'));
      expect(alice.content, equals('Loved it.'));
      expect(alice.rating, equals(9.0));
      expect(alice.createdAt, equals(DateTime.parse('2021-05-01T00:00:00.000Z')));
      expect(alice.url, equals('https://www.themoviedb.org/review/rev1'));
      expect(alice.authorAvatarUrl,
          equals('https://image.tmdb.org/t/p/w185/tmdb-avatar.jpg'));

      final bob = details.reviews![1];
      expect(bob.rating, isNull);
      // The Gravatar-style external URL is used as-is (leading slash
      // stripped), not prefixed with TMDB's image base URL.
      expect(bob.authorAvatarUrl,
          equals('https://secure.gravatar.com/avatar/xyz.jpg'));
    });

    test(
        'DATA-CONT-4: parses alternative_titles (movie "titles" key) and translations, deduping repeats',
        () async {
      final mockClient = MockClient((request) async {
        if (request.url.path.contains('/movie/1000')) {
          return http.Response(
              jsonEncode({
                'id': 1000,
                'title': 'Original Title',
                'alternative_titles': {
                  'titles': [
                    {'iso_3166_1': 'BR', 'title': 'Origem', 'type': ''},
                    {'iso_3166_1': 'PT', 'title': 'Origem', 'type': ''},
                    {'iso_3166_1': 'RU', 'title': 'Начало', 'type': ''},
                    {'iso_3166_1': 'FR', 'title': '', 'type': ''},
                  ],
                },
                'translations': {
                  'translations': [
                    {
                      'iso_639_1': 'ja',
                      'iso_3166_1': 'JP',
                      'data': {'title': 'インセプション'},
                    },
                    {
                      'iso_639_1': 'de',
                      'iso_3166_1': 'DE',
                      'data': {'title': ''},
                    },
                  ],
                },
              }),
              200,
              // Cyrillic/Japanese characters in this fixture aren't
              // Latin-1-representable -- http.Response defaults to Latin-1
              // without an explicit UTF-8 content-type header.
              headers: {'content-type': 'application/json; charset=utf-8'});
        }
        return http.Response(jsonEncode({'results': []}), 200);
      });

      final service = TmdbApiService(token: 'valid_token', client: mockClient);
      final repo = TmdbMovieRepository(apiService: service);

      final details = await repo.getMediaDetails('movie_1000');
      expect(details, isNotNull);
      // 'Origem' appears for both BR and PT but is deduped to one entry.
      expect(details!.alternativeTitles, unorderedEquals(['Origem', 'Начало']));
      expect(details.translatedTitlesByLanguage, equals({'ja': 'インセプション'}));
    });

    test(
        'DATA-CONT-4: TV alternative_titles uses the "results" key, not "titles"',
        () async {
      final mockClient = MockClient((request) async {
        if (request.url.path.contains('/tv/1001')) {
          return http.Response(
              jsonEncode({
                'id': 1001,
                'name': 'Original Series',
                'alternative_titles': {
                  'results': [
                    {'iso_3166_1': 'JP', 'title': 'Japanese Title'},
                  ],
                },
              }),
              200);
        }
        return http.Response(jsonEncode({'results': []}), 200);
      });

      final service = TmdbApiService(token: 'valid_token', client: mockClient);
      final repo = TmdbMovieRepository(apiService: service);

      final details = await repo.getMediaDetails('tv_1001');
      expect(details, isNotNull);
      expect(details!.alternativeTitles, equals(['Japanese Title']));
    });

    test(
        'Configured repository parses multi-country flatrate, rent, and buy providers',
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
                      'flatrate': [
                        {'provider_name': 'Netflix'}
                      ],
                      'rent': [
                        {'provider_name': 'Apple TV'}
                      ],
                      'buy': [
                        {'provider_name': 'Amazon Video'}
                      ]
                    },
                    'GB': {
                      'flatrate': [
                        {'provider_name': 'BBC iPlayer'}
                      ],
                      'rent': [
                        {'provider_name': 'Rakuten TV'}
                      ]
                    },
                    'CA': {
                      'flatrate': [
                        {'provider_name': 'Crave'}
                      ]
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
      expect(
          usProviders,
          contains(const WatchProviderInfo(
              providerName: 'Netflix', category: 'Stream')));
      expect(
          usProviders,
          contains(const WatchProviderInfo(
              providerName: 'Apple TV', category: 'Rent')));
      expect(
          usProviders,
          contains(const WatchProviderInfo(
              providerName: 'Amazon Video', category: 'Buy')));

      final gbProviders = details.getWatchProvidersForCountry('GB');
      expect(
          gbProviders,
          contains(const WatchProviderInfo(
              providerName: 'BBC iPlayer', category: 'Stream')));
      expect(
          gbProviders,
          contains(const WatchProviderInfo(
              providerName: 'Rakuten TV', category: 'Rent')));

      final caProviders = details.getWatchProvidersForCountry('CA');
      expect(
          caProviders,
          contains(const WatchProviderInfo(
              providerName: 'Crave', category: 'Stream')));
    });

    test(
        'TF-22: getUpcomingMovies filters out already-released titles TMDB still lists as upcoming',
        () async {
      final now = DateTime.now();
      final futureDate =
          now.add(const Duration(days: 30)).toIso8601String().split('T').first;
      final pastDate = now
          .subtract(const Duration(days: 5))
          .toIso8601String()
          .split('T')
          .first;

      final mockClient = MockClient((request) async {
        if (request.url.path.contains('/discover/movie')) {
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
        'TF-22 regression: widens to a later page instead of returning an empty '
        'or unfiltered-raw list when page 1 is entirely already-released '
        '(confirmed live against the real TMDB API: not a hypothetical -- an '
        'entire real page can come back with zero titles still upcoming)',
        () async {
      final now = DateTime.now();
      final pastDate = now
          .subtract(const Duration(days: 5))
          .toIso8601String()
          .split('T')
          .first;
      final futureDate =
          now.add(const Duration(days: 30)).toIso8601String().split('T').first;

      final mockClient = MockClient((request) async {
        if (request.url.path.contains('/discover/movie')) {
          final page = request.url.queryParameters['page'];
          if (page == '2') {
            return http.Response(
                jsonEncode({
                  'page': 2,
                  'results': [
                    {
                      'id': 3,
                      'title': 'Genuinely Upcoming (page 2)',
                      'release_date': futureDate,
                    },
                  ]
                }),
                200);
          }
          return http.Response(
              jsonEncode({
                'page': 1,
                'results': [
                  {
                    'id': 1,
                    'title': 'Already Released A',
                    'release_date': pastDate
                  },
                  {
                    'id': 2,
                    'title': 'Already Released B',
                    'release_date': pastDate
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

      expect(upcoming.map((m) => m.title), ['Genuinely Upcoming (page 2)']);
    });

    test(
        'DATA-1: getUpcomingMovies queries /discover/movie with primary_release_date.gte '
        'so long-range anticipated blockbusters outside the narrow /movie/upcoming '
        'theatrical window are surfaced', () async {
      final now = DateTime.now();
      final farFutureDate =
          now.add(const Duration(days: 220)).toIso8601String().split('T').first;

      Uri? capturedUri;
      final mockClient = MockClient((request) async {
        if (request.url.path.contains('/discover/movie')) {
          capturedUri = request.url;
          return http.Response(
              jsonEncode({
                'page': 1,
                'results': [
                  {
                    'id': 99,
                    'title': 'Anticipated Sequel (6+ months out)',
                    'release_date': farFutureDate,
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
          contains('Anticipated Sequel (6+ months out)'));
      expect(capturedUri, isNotNull);
      expect(capturedUri!.path, contains('/discover/movie'));
      expect(
          capturedUri!.queryParameters['sort_by'], equals('popularity.desc'));
      expect(
          capturedUri!.queryParameters.containsKey('primary_release_date.gte'),
          isTrue);
    });

    test(
        'BETA3-NET-2: getUpcomingMovies passes region in the /discover/movie '
        'query when provided, and defaults to US when omitted', () async {
      Uri? capturedUri;
      final mockClient = MockClient((request) async {
        if (request.url.path.contains('/discover/movie')) {
          capturedUri = request.url;
          return http.Response(jsonEncode({'page': 1, 'results': []}), 200);
        }
        return http.Response(jsonEncode({'results': []}), 200);
      });

      final service = TmdbApiService(token: 'valid_token', client: mockClient);
      final repo = TmdbMovieRepository(apiService: service);

      await repo.getUpcomingMovies(region: 'GB');
      expect(capturedUri, isNotNull);
      expect(capturedUri!.queryParameters['region'], equals('GB'));

      capturedUri = null;
      await repo.getUpcomingMovies();
      expect(capturedUri, isNotNull);
      expect(capturedUri!.queryParameters['region'], equals('US'));
    });

    test(
        'TF-22 regression: returns empty rather than raw already-released data '
        'when every nearby page is entirely already-released', () async {
      final now = DateTime.now();
      final pastDate = now
          .subtract(const Duration(days: 5))
          .toIso8601String()
          .split('T')
          .first;

      final mockClient = MockClient((request) async {
        if (request.url.path.contains('/discover/movie')) {
          final page = request.url.queryParameters['page'] ?? '1';
          return http.Response(
              jsonEncode({
                'page': int.parse(page),
                'results': [
                  {
                    'id': int.parse(page),
                    'title': 'Already Released (page $page)',
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

      expect(upcoming, isEmpty);
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

    test(
        'searchMedia preserves TMDB relevance order and excludes low-relevance noise items',
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
      expect(results[0].id, equals('movie_1'));
      expect(results[0].title, equals('High Relevance Movie'));
      expect(results[1].id, equals('movie_4'));
      expect(results[1].title, equals('Actor Major Hit'));
    });

    test(
        'B1: searchMedia fetches the real filmography when the top result is a person, '
        'instead of known_for + unrelated title-text matches', () async {
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

  group(
      'LANG-2 (2nd pass, 2026-08-19): fixed-list methods route through '
      '/discover with server-side with_original_language when a language is '
      'given -- the actual fix for the dev-reported bug (a client-side '
      'filter/backfill over TMDB\'s globally-weighted, English-dominated '
      'trending/popular/now-playing charts could not reliably surface real '
      'regional-language content, no matter how many pages it tried).', () {
    // _ensureGenresLoaded() fires its own /genre/movie/list and
    // /genre/tv/list calls ahead of the real request being tested, so every
    // test here filters requestedUrls down to the one call that actually
    // matters instead of assuming it's the only request made.
    String findUrl(List<String> requestedUrls, String pathSegment) =>
        requestedUrls.firstWhere((u) => u.contains(pathSegment));

    test(
        'getTrendingMovies(originalLanguage: ...) hits /discover/movie with '
        'with_original_language, not /trending/movie/week', () async {
      final requestedUrls = <String>[];
      final client = MockClient((request) async {
        requestedUrls.add(request.url.toString());
        return http.Response(jsonEncode({'results': []}), 200);
      });
      final repo = TmdbMovieRepository(
        apiService: TmdbApiService(token: 'valid_token', client: client),
      );

      await repo.getTrendingMovies(originalLanguage: 'hi');

      expect(requestedUrls.any((u) => u.contains('/trending/movie/week')),
          isFalse);
      final url = findUrl(requestedUrls, '/discover/movie');
      expect(url, contains('with_original_language=hi'));
    });

    test(
        'getTrendingMovies() with no language still hits the real dedicated '
        'endpoint unchanged (regression guard: unlocked halls must not '
        'route through /discover)', () async {
      final requestedUrls = <String>[];
      final client = MockClient((request) async {
        requestedUrls.add(request.url.toString());
        return http.Response(jsonEncode({'results': []}), 200);
      });
      final repo = TmdbMovieRepository(
        apiService: TmdbApiService(token: 'valid_token', client: client),
      );

      await repo.getTrendingMovies();

      expect(
          requestedUrls.any((u) => u.contains('/trending/movie/week')), isTrue);
      expect(requestedUrls.any((u) => u.contains('/discover/movie')), isFalse);
    });

    test(
        'getPopularMovies/getTrendingTvShows/getTopRatedTvShows all route '
        'through /discover with the language too (systemic, not one '
        'method patched in isolation)', () async {
      final requestedUrls = <String>[];
      final client = MockClient((request) async {
        requestedUrls.add(request.url.toString());
        return http.Response(jsonEncode({'results': []}), 200);
      });
      final repo = TmdbMovieRepository(
        apiService: TmdbApiService(token: 'valid_token', client: client),
      );

      await repo.getPopularMovies(originalLanguage: 'ta');
      await repo.getTrendingTvShows(originalLanguage: 'ta');
      await repo.getTopRatedTvShows(originalLanguage: 'ta');

      final discoverUrls =
          requestedUrls.where((u) => u.contains('/discover/')).toList();
      expect(discoverUrls, hasLength(3));
      for (final url in discoverUrls) {
        expect(url, contains('with_original_language=ta'));
      }
    });

    test(
        'getTopRatedMovies(originalLanguage: ...) sorts by vote_average.desc '
        'with a vote_count.gte floor (avoids a single high-scoring, '
        'near-unvoted title dominating "top rated")', () async {
      final requestedUrls = <String>[];
      final client = MockClient((request) async {
        requestedUrls.add(request.url.toString());
        return http.Response(jsonEncode({'results': []}), 200);
      });
      final repo = TmdbMovieRepository(
        apiService: TmdbApiService(token: 'valid_token', client: client),
      );

      await repo.getTopRatedMovies(originalLanguage: 'hi');

      final url = findUrl(requestedUrls, '/discover/movie');
      expect(url, contains('with_original_language=hi'));
      expect(url, contains('sort_by=vote_average.desc'));
      expect(url, contains('vote_count.gte=50'));
    });

    test(
        'getNowPlayingMovies(originalLanguage: ...) approximates the '
        'now_playing rolling window via primary_release_date.gte/lte on '
        '/discover/movie', () async {
      final requestedUrls = <String>[];
      final client = MockClient((request) async {
        requestedUrls.add(request.url.toString());
        return http.Response(jsonEncode({'results': []}), 200);
      });
      final repo = TmdbMovieRepository(
        apiService: TmdbApiService(token: 'valid_token', client: client),
      );

      await repo.getNowPlayingMovies(originalLanguage: 'te');

      final url = findUrl(requestedUrls, '/discover/movie');
      final now = DateTime.now();
      final expectedLte = formatTmdbDate(now);
      final expectedGte =
          formatTmdbDate(now.subtract(const Duration(days: 45)));
      expect(url, contains('with_original_language=te'));
      expect(url, contains('primary_release_date.gte=$expectedGte'));
      expect(url, contains('primary_release_date.lte=$expectedLte'));
    });

    test(
        'getUpcomingMovies(originalLanguage: ...) keeps its existing '
        'discover-based date-widening logic (DATA-1) and adds '
        'with_original_language alongside it', () async {
      final requestedUrls = <String>[];
      final client = MockClient((request) async {
        requestedUrls.add(request.url.toString());
        return http.Response(jsonEncode({'results': []}), 200);
      });
      final repo = TmdbMovieRepository(
        apiService: TmdbApiService(token: 'valid_token', client: client),
      );

      await repo.getUpcomingMovies(originalLanguage: 'kn');

      final url = findUrl(requestedUrls, '/discover/movie');
      expect(url, contains('with_original_language=kn'));
      expect(url, contains('primary_release_date.gte='));
    });

    test(
        'getAiringTodayTvShows(originalLanguage: ...) scopes air_date.gte/'
        'lte to today only, on /discover/tv', () async {
      final requestedUrls = <String>[];
      final client = MockClient((request) async {
        requestedUrls.add(request.url.toString());
        return http.Response(jsonEncode({'results': []}), 200);
      });
      final repo = TmdbMovieRepository(
        apiService: TmdbApiService(token: 'valid_token', client: client),
      );

      await repo.getAiringTodayTvShows(originalLanguage: 'ml');

      final url = findUrl(requestedUrls, '/discover/tv');
      final today = formatTmdbDate(DateTime.now());
      expect(url, contains('with_original_language=ml'));
      expect(url, contains('air_date.gte=$today'));
      expect(url, contains('air_date.lte=$today'));
    });

    test(
        'getOnTheAirTvShows(originalLanguage: ...) widens air_date.gte/lte '
        'to a ~7-day window (wider than Airing Today\'s single-day window), '
        'on /discover/tv', () async {
      final requestedUrls = <String>[];
      final client = MockClient((request) async {
        requestedUrls.add(request.url.toString());
        return http.Response(jsonEncode({'results': []}), 200);
      });
      final repo = TmdbMovieRepository(
        apiService: TmdbApiService(token: 'valid_token', client: client),
      );

      await repo.getOnTheAirTvShows(originalLanguage: 'bn');

      final url = findUrl(requestedUrls, '/discover/tv');
      final now = DateTime.now();
      final expectedGte = formatTmdbDate(now);
      final expectedLte = formatTmdbDate(now.add(const Duration(days: 7)));
      expect(url, contains('with_original_language=bn'));
      expect(url, contains('air_date.gte=$expectedGte'));
      expect(url, contains('air_date.lte=$expectedLte'));
    });
  });

  group('CAL-1 (2026-08-20): next_episode_to_air parsing', () {
    test(
        'getOnTheAirTvShows parses next_episode_to_air.air_date into '
        'nextEpisodeAirDate, separately from the show\'s original '
        'first_air_date', () async {
      // Regression: dev-reported bug -- Calendar was grouping/displaying
      // ongoing TV shows by first_air_date (routinely years in the past
      // for a long-running show), not by when the next episode actually
      // airs.
      final nextEpisodeDate = DateTime.now()
          .add(const Duration(days: 3))
          .toIso8601String()
          .split('T')
          .first;
      final client = MockClient((request) async {
        if (request.url.path.contains('/tv/on_the_air')) {
          return http.Response(
              jsonEncode({
                'results': [
                  {
                    'id': 10,
                    'name': 'Long Running Show',
                    'first_air_date': '2015-03-01',
                    'next_episode_to_air': {
                      'air_date': nextEpisodeDate,
                      'episode_number': 5,
                    },
                  },
                ],
              }),
              200);
        }
        return http.Response(jsonEncode({'results': []}), 200);
      });

      final repo = TmdbMovieRepository(
        apiService: TmdbApiService(token: 'valid_token', client: client),
      );

      final results = await repo.getOnTheAirTvShows();
      expect(results, hasLength(1));
      expect(results.first.releaseOrAirDate, DateTime.parse('2015-03-01'));
      expect(results.first.nextEpisodeAirDate, DateTime.parse(nextEpisodeDate));
    });

    test(
        'a show with no next_episode_to_air in the response leaves nextEpisodeAirDate null',
        () async {
      final client = MockClient((request) async {
        return http.Response(
            jsonEncode({
              'results': [
                {
                  'id': 11,
                  'name': 'No Next Episode Info',
                  'first_air_date': '2020-01-01'
                },
              ],
            }),
            200);
      });
      final repo = TmdbMovieRepository(
        apiService: TmdbApiService(token: 'valid_token', client: client),
      );

      final results = await repo.getOnTheAirTvShows();
      expect(results, hasLength(1));
      expect(results.first.nextEpisodeAirDate, isNull);
      expect(results.first.releaseOrAirDate, DateTime.parse('2020-01-01'));
    });
  });
}
