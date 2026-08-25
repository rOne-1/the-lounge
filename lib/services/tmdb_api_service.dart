import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/discover_filter_params.dart';
import 'api_call_tracker.dart';
import 'tmdb_endpoints.dart';

/// Whether [error] represents a transient network failure (a dropped/reset
/// connection, DNS hiccup, timeout) worth retrying, as opposed to a real API
/// response (404, 401, etc.) that would fail again identically.
bool isTransientNetworkError(Object error) {
  if (error is SocketException ||
      error is TimeoutException ||
      error is HandshakeException ||
      error is http.ClientException) {
    return true;
  }
  final s = error.toString().toLowerCase();
  return s.contains('socketexception') ||
      s.contains('clientexception') ||
      s.contains('connection reset') ||
      s.contains('connection closed') ||
      s.contains('failed host lookup') ||
      s.contains('no internet') ||
      s.contains('no connection') ||
      s.contains('network exception') ||
      s.contains('connection refused') ||
      s.contains('connection timed out') ||
      s.contains('network is unreachable') ||
      s.contains('host lookup failed');
}

/// Container for search results filtered client-side into title matches vs person filmographies.
class SearchFilterResult {
  final List<Map<String, dynamic>> titles;
  final List<Map<String, dynamic>> personFilmographies;
  final List<Map<String, dynamic>> allOrdered;

  /// The TMDB person ID of the *top-ranked* result, only when that top
  /// result is itself a `person` match — i.e. TMDB's own combined
  /// relevance ranking judged a person to be the strongest match for this
  /// query, not just "a person happened to appear somewhere in the list."
  /// Null otherwise. Callers should treat a non-null value as "this is a
  /// cast/crew name search" and fetch that person's real filmography (see
  /// [TmdbApiService.getPersonMovieCredits] / [getPersonTvCredits]) rather
  /// than mixing in [personFilmographies], which is only TMDB's own narrow
  /// "known for" sample (2-4 titles), not a filmography.
  final int? topPersonId;

  const SearchFilterResult({
    required this.titles,
    required this.personFilmographies,
    required this.allOrdered,
    this.topPersonId,
  });
}

/// Low-level service for interacting with the TMDB API v3 endpoints using v4 Bearer token header.
class TmdbApiService {
  final String? token;
  final http.Client _client;

  TmdbApiService({
    this.token,
    http.Client? client,
  }) : _client = client ?? http.Client();

  /// Returns true if a valid non-placeholder token is present.
  bool get hasToken =>
      token != null &&
      token!.trim().isNotEmpty &&
      token != 'your_tmdb_read_access_token_here';

  Map<String, String> get _headers {
    final headers = <String, String>{
      'Accept': 'application/json',
    };
    if (token != null && token!.trim().startsWith('eyJ')) {
      headers['Authorization'] = 'Bearer ${token!.trim()}';
    }
    return headers;
  }

  Future<Map<String, dynamic>> _get(
    String path, [
    Map<String, dynamic>? queryParameters,
  ]) async {
    final Map<String, String> stringParams = {};
    if (token != null &&
        token!.trim().isNotEmpty &&
        !token!.trim().startsWith('eyJ')) {
      stringParams['api_key'] = token!.trim();
    }
    if (queryParameters != null) {
      queryParameters.forEach((key, value) {
        if (value != null) {
          stringParams[key] = value.toString();
        }
      });
    }

    final uri = Uri.parse('${TmdbEndpoints.baseUrl}$path').replace(
      queryParameters: stringParams.isNotEmpty ? stringParams : null,
    );

    // PERF-STAMPEDE-1: a dropped/reset connection (SocketException, seen in
    // bulk during a real-world regression report -- "Connection reset by
    // peer" across dozens of otherwise-unrelated endpoints) used to fail
    // the request permanently on the very first attempt, with no built-in
    // recovery -- every such hiccup became a hard, user-visible failure.
    // Retry transient network errors a couple of times with backoff before
    // giving up; a real API response (404, 401, etc.) is never retried,
    // since it would just fail identically again.
    const maxAttempts = 3;
    const retryDelay = Duration(milliseconds: 500);

    for (var attempt = 1;; attempt++) {
      // E6: every TMDB request funnels through this single method, making it
      // the one place to track total calls/failures for the session.
      ApiCallTracker.instance.recordCall();
      try {
        final response = await _client.get(uri, headers: _headers);

        if (response.statusCode >= 200 && response.statusCode < 300) {
          return jsonDecode(response.body) as Map<String, dynamic>;
        } else {
          ApiCallTracker.instance.recordFailure(
            endpoint: path,
            uri: uri,
            statusCode: response.statusCode,
            error:
                'TMDB API Request Failed [$path]: Status ${response.statusCode}',
            responseBody: response.body,
            queryParams: queryParameters,
          );
          throw Exception(
            'TMDB API Request Failed [$path]: Status ${response.statusCode} - ${response.body}',
          );
        }
      } catch (e) {
        final isRealApiFailure = e is Exception &&
            e.toString().startsWith('Exception: TMDB API Request Failed');
        if (!isRealApiFailure &&
            isTransientNetworkError(e) &&
            attempt < maxAttempts) {
          await Future.delayed(retryDelay * attempt);
          continue;
        }
        if (!isRealApiFailure) {
          ApiCallTracker.instance.recordFailure(
            endpoint: path,
            uri: uri,
            error: e,
            queryParams: queryParameters,
          );
        }
        rethrow;
      }
    }
  }

  /// GET /3/configuration
  Future<Map<String, dynamic>> getConfiguration() async {
    return _get(TmdbEndpoints.configuration);
  }

  /// GET /3/trending/movie/week
  Future<Map<String, dynamic>> getTrendingMovies({int page = 1}) async {
    return _get(TmdbEndpoints.trendingMoviesWeek, {
      'page': page,
      'include_adult': false,
    });
  }

  /// GET /3/trending/tv/week
  Future<Map<String, dynamic>> getTrendingTvShows({int page = 1}) async {
    return _get(TmdbEndpoints.trendingTvShowsWeek, {
      'page': page,
      'include_adult': false,
    });
  }

  /// GET /3/movie/popular
  Future<Map<String, dynamic>> getPopularMovies({int page = 1}) async {
    return _get(TmdbEndpoints.popularMovies, {
      'page': page,
      'include_adult': false,
    });
  }

  /// GET /3/tv/popular
  Future<Map<String, dynamic>> getPopularTvShows({int page = 1}) async {
    return _get(TmdbEndpoints.popularTvShows, {
      'page': page,
      'include_adult': false,
    });
  }

  /// GET /3/movie/top_rated
  Future<Map<String, dynamic>> getTopRatedMovies({int page = 1}) async {
    return _get(TmdbEndpoints.topRatedMovies, {
      'page': page,
      'include_adult': false,
    });
  }

  /// GET /3/tv/top_rated
  Future<Map<String, dynamic>> getTopRatedTvShows({int page = 1}) async {
    return _get(TmdbEndpoints.topRatedTvShows, {
      'page': page,
      'include_adult': false,
    });
  }

  /// GET /3/movie/now_playing
  Future<Map<String, dynamic>> getNowPlayingMovies({
    int page = 1,
    String region = 'US',
  }) async {
    return _get(TmdbEndpoints.nowPlayingMovies, {
      'page': page,
      'include_adult': false,
      'region': region,
    });
  }

  /// GET /3/tv/airing_today
  Future<Map<String, dynamic>> getAiringTodayTvShows({int page = 1}) async {
    return _get(TmdbEndpoints.airingTodayTvShows, {
      'page': page,
      'include_adult': false,
    });
  }

  /// GET /3/movie/upcoming
  Future<Map<String, dynamic>> getUpcomingMovies({int page = 1}) async {
    return _get(TmdbEndpoints.upcomingMovies, {
      'page': page,
      'include_adult': false,
    });
  }

  /// GET /3/tv/on_the_air
  Future<Map<String, dynamic>> getOnTheAirTvShows({int page = 1}) async {
    return _get(TmdbEndpoints.onTheAirTvShows, {
      'page': page,
      'include_adult': false,
    });
  }

  /// GET /3/discover/movie
  Future<Map<String, dynamic>> discoverMovies({
    int? withGenres,
    String? sortBy,
    int page = 1,
    DiscoverFilterParams? params,
    Map<String, dynamic>? extraParams,
  }) async {
    final query = <String, dynamic>{
      'page': page,
      'include_adult': false,
    };
    if (params != null) {
      if (params.genreId != null) query['with_genres'] = params.genreId;
      if (params.keywordId != null) query['with_keywords'] = params.keywordId;
      if (params.personId != null) query['with_people'] = params.personId;
      if (params.providerId != null) {
        query['with_watch_providers'] = params.providerId;
      }
      if (params.watchRegion != null && params.watchRegion!.isNotEmpty) {
        query['watch_region'] = params.watchRegion;
      }
      if (params.minRuntime != null) {
        query['with_runtime.gte'] = params.minRuntime;
      }
      if (params.maxRuntime != null) {
        query['with_runtime.lte'] = params.maxRuntime;
      }
      if (params.minVoteCount != null) {
        query['vote_count.gte'] = params.minVoteCount;
      }
      if (params.originalLanguage != null &&
          params.originalLanguage!.isNotEmpty) {
        query['with_original_language'] = params.originalLanguage;
      }
      if (params.releaseYear != null) {
        query['primary_release_year'] = params.releaseYear;
      }
      if (params.minRating != null) {
        query['vote_average.gte'] = params.minRating;
      }
      if (params.primaryReleaseDateGte != null) {
        query['primary_release_date.gte'] = params.primaryReleaseDateGte;
      }
      if (params.primaryReleaseDateLte != null) {
        query['primary_release_date.lte'] = params.primaryReleaseDateLte;
      }
      query['sort_by'] = params.sortBy;
    }
    if (withGenres != null) query['with_genres'] = withGenres;
    if (sortBy != null) query['sort_by'] = sortBy;
    if (extraParams != null) query.addAll(extraParams);
    return _get(TmdbEndpoints.discoverMovies, query);
  }

  /// GET /3/discover/tv
  Future<Map<String, dynamic>> discoverTvShows({
    int? withGenres,
    String? sortBy,
    int page = 1,
    DiscoverFilterParams? params,
    Map<String, dynamic>? extraParams,
  }) async {
    final query = <String, dynamic>{
      'page': page,
      'include_adult': false,
    };
    if (params != null) {
      if (params.genreId != null) query['with_genres'] = params.genreId;
      if (params.keywordId != null) query['with_keywords'] = params.keywordId;
      if (params.personId != null) query['with_people'] = params.personId;
      if (params.providerId != null) {
        query['with_watch_providers'] = params.providerId;
      }
      if (params.watchRegion != null && params.watchRegion!.isNotEmpty) {
        query['watch_region'] = params.watchRegion;
      }
      if (params.minRuntime != null) {
        query['with_runtime.gte'] = params.minRuntime;
      }
      if (params.maxRuntime != null) {
        query['with_runtime.lte'] = params.maxRuntime;
      }
      if (params.minVoteCount != null) {
        query['vote_count.gte'] = params.minVoteCount;
      }
      if (params.originalLanguage != null &&
          params.originalLanguage!.isNotEmpty) {
        query['with_original_language'] = params.originalLanguage;
      }
      if (params.tvNetworkId != null) {
        query['with_networks'] = params.tvNetworkId;
      }
      if (params.tvStatus != null && params.tvStatus!.isNotEmpty) {
        query['with_status'] = params.tvStatus;
      }
      if (params.releaseYear != null) {
        query['first_air_date_year'] = params.releaseYear;
      }
      if (params.minRating != null) {
        query['vote_average.gte'] = params.minRating;
      }
      if (params.airDateGte != null) {
        query['air_date.gte'] = params.airDateGte;
      }
      if (params.airDateLte != null) {
        query['air_date.lte'] = params.airDateLte;
      }
      query['sort_by'] = params.sortBy;
    }
    if (withGenres != null) query['with_genres'] = withGenres;
    if (sortBy != null) query['sort_by'] = sortBy;
    if (extraParams != null) query.addAll(extraParams);
    return _get(TmdbEndpoints.discoverTv, query);
  }

  /// GET /3/genre/movie/list
  Future<Map<String, dynamic>> getMovieGenres() async {
    return _get(TmdbEndpoints.movieGenres);
  }

  /// GET /3/genre/tv/list
  Future<Map<String, dynamic>> getTvGenres() async {
    return _get(TmdbEndpoints.tvGenres);
  }

  /// GET /3/search/multi
  Future<Map<String, dynamic>> multiSearch(
    String query, {
    int page = 1,
  }) async {
    return _get(TmdbEndpoints.searchMulti, {
      'query': query,
      'page': page,
      'include_adult': false,
    });
  }

  /// GET /3/search/person
  Future<Map<String, dynamic>> searchPersons(
    String query, {
    int page = 1,
  }) async {
    return _get(TmdbEndpoints.searchPerson, {
      'query': query,
      'page': page,
      'include_adult': false,
    });
  }

  /// GET /3/person/{id}/movie_credits — this person's actual movie
  /// filmography (cast + crew), not TMDB's narrow "known for" sample.
  Future<Map<String, dynamic>> getPersonMovieCredits(String personId) async {
    return _get(TmdbEndpoints.personMovieCredits(personId));
  }

  /// GET /3/person/{id}/tv_credits — this person's actual TV filmography
  /// (cast + crew), not TMDB's narrow "known for" sample.
  Future<Map<String, dynamic>> getPersonTvCredits(String personId) async {
    return _get(TmdbEndpoints.personTvCredits(personId));
  }

  /// Whether a raw TMDB search/credit item is worth showing: has a real
  /// title, and (when present) a poster and non-zero popularity. Shared by
  /// [filterSearchResults] and person-filmography fetching so both apply
  /// the same noise filter.
  bool isValidSearchItem(Map<String, dynamic> item) {
    final title = item['title'] as String? ??
        item['name'] as String? ??
        item['original_title'] as String? ??
        item['original_name'] as String?;
    if (title == null || title.trim().isEmpty || title == 'Untitled') {
      return false;
    }

    if (item.containsKey('poster_path')) {
      final poster = item['poster_path'] as String?;
      if (poster == null || poster.trim().isEmpty) {
        return false;
      }
    }

    if (item.containsKey('popularity')) {
      final pop = (item['popularity'] as num?)?.toDouble() ?? 0.0;
      if (pop <= 0.0) {
        return false;
      }
    }

    return true;
  }

  /// Client-side filter separating title matches (movies & tv) vs person filmographies (known_for)
  /// while preserving natural TMDB relevance/popularity ordering and excluding search noise.
  SearchFilterResult filterSearchResults(Map<String, dynamic> searchResponse) {
    final results =
        (searchResponse['results'] as List?)?.cast<Map<String, dynamic>>() ??
            [];
    final List<Map<String, dynamic>> titles = [];
    final List<Map<String, dynamic>> personFilmographies = [];
    final List<Map<String, dynamic>> allOrdered = [];
    final int? topPersonId = results.isNotEmpty &&
            results.first['media_type'] == 'person' &&
            results.first['id'] is int
        ? results.first['id'] as int
        : null;

    for (final item in results) {
      final mediaType = item['media_type'] as String?;
      if (mediaType == 'movie' || mediaType == 'tv') {
        if (isValidSearchItem(item)) {
          titles.add(item);
          allOrdered.add(item);
        }
      } else if (mediaType == 'person') {
        final knownFor =
            (item['known_for'] as List?)?.cast<Map<String, dynamic>>() ?? [];
        for (final kf in knownFor) {
          final kfType = kf['media_type'] as String?;
          if (kfType == 'movie' || kfType == 'tv') {
            if (isValidSearchItem(kf)) {
              personFilmographies.add(kf);
              allOrdered.add(kf);
            }
          }
        }
      }
    }

    return SearchFilterResult(
      titles: titles,
      personFilmographies: personFilmographies,
      allOrdered: allOrdered,
      topPersonId: topPersonId,
    );
  }

  /// GET /3/movie/{id}
  Future<Map<String, dynamic>> getMovieDetails(
    String id, {
    String? appendToResponse,
    // DATA-CONT-1: scopes the `images` append (when present in
    // appendToResponse) to logos/posters tagged with one of these
    // languages -- 'en,null' keeps English-tagged and language-neutral
    // (typically textless ClearLogo) entries, dropping every other
    // language's images server-side instead of filtering client-side.
    String? includeImageLanguage,
  }) async {
    final query = <String, dynamic>{
      if (appendToResponse != null) 'append_to_response': appendToResponse,
      if (includeImageLanguage != null)
        'include_image_language': includeImageLanguage,
    };
    return _get(TmdbEndpoints.movieDetails(id), query.isEmpty ? null : query);
  }

  /// GET /3/tv/{id}
  Future<Map<String, dynamic>> getTvDetails(
    String id, {
    String? appendToResponse,
    String? includeImageLanguage,
  }) async {
    final query = <String, dynamic>{
      if (appendToResponse != null) 'append_to_response': appendToResponse,
      if (includeImageLanguage != null)
        'include_image_language': includeImageLanguage,
    };
    return _get(TmdbEndpoints.tvDetails(id), query.isEmpty ? null : query);
  }

  /// GET /3/tv/{id} (Alias for getTvDetails)
  Future<Map<String, dynamic>> getTvShowDetails(
    String id, {
    String? appendToResponse,
  }) async {
    return getTvDetails(id, appendToResponse: appendToResponse);
  }

  /// GET /3/movie/{id}/credits
  Future<Map<String, dynamic>> getMovieCredits(String id) async {
    return _get(TmdbEndpoints.movieCredits(id));
  }

  /// GET /3/tv/{id}/credits
  Future<Map<String, dynamic>> getTvCredits(String id) async {
    return _get(TmdbEndpoints.tvCredits(id));
  }

  /// GET /3/movie/{id}/videos
  Future<Map<String, dynamic>> getMovieVideos(String id) async {
    return _get(TmdbEndpoints.movieVideos(id));
  }

  /// GET /3/tv/{id}/videos
  Future<Map<String, dynamic>> getTvVideos(String id) async {
    return _get(TmdbEndpoints.tvVideos(id));
  }

  /// GET /3/movie/{id}/watch/providers
  Future<Map<String, dynamic>> getMovieWatchProviders(String id) async {
    return _get(TmdbEndpoints.movieWatchProviders(id));
  }

  /// GET /3/tv/{id}/watch/providers
  Future<Map<String, dynamic>> getTvWatchProviders(String id) async {
    return _get(TmdbEndpoints.tvWatchProviders(id));
  }

  /// GET /3/tv/{id}/season/{season_number}
  Future<Map<String, dynamic>> getTvSeasonDetails(
    String tvId,
    int seasonNumber,
  ) async {
    return _get(TmdbEndpoints.tvSeasonDetails(tvId, seasonNumber));
  }

  /// GET /3/watch/providers/regions
  Future<Map<String, dynamic>> getWatchProviderRegions() async {
    return _get(TmdbEndpoints.watchProviderRegions);
  }

  Future<Map<String, dynamic>> getMovieRecommendations(String id,
      {int page = 1}) async {
    return _get(TmdbEndpoints.movieRecommendations(id),
        {'page': page, 'include_adult': false});
  }

  Future<Map<String, dynamic>> getTvRecommendations(String id,
      {int page = 1}) async {
    return _get(TmdbEndpoints.tvRecommendations(id),
        {'page': page, 'include_adult': false});
  }

  Future<Map<String, dynamic>> getSimilarMovies(String id,
      {int page = 1}) async {
    return _get(TmdbEndpoints.similarMovies(id),
        {'page': page, 'include_adult': false});
  }

  Future<Map<String, dynamic>> getSimilarTvShows(String id,
      {int page = 1}) async {
    return _get(TmdbEndpoints.similarTvShows(id),
        {'page': page, 'include_adult': false});
  }

  /// GET /3/collection/{collection_id}
  Future<Map<String, dynamic>> getCollectionDetails(int collectionId) async {
    return _get(TmdbEndpoints.collectionDetails(collectionId));
  }
}
