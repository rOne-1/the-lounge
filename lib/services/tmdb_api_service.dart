import 'dart:convert';
import 'package:http/http.dart' as http;

/// Container for search results filtered client-side into title matches vs person filmographies.
class SearchFilterResult {
  final List<Map<String, dynamic>> titles;
  final List<Map<String, dynamic>> personFilmographies;
  final List<Map<String, dynamic>> allOrdered;

  const SearchFilterResult({
    required this.titles,
    required this.personFilmographies,
    required this.allOrdered,
  });
}

/// Low-level service for interacting with the TMDB API v3 endpoints using v4 Bearer token header.
class TmdbApiService {
  static const String baseUrl = 'https://api.themoviedb.org/3';
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
    if (token != null && token!.trim().isNotEmpty && !token!.trim().startsWith('eyJ')) {
      stringParams['api_key'] = token!.trim();
    }
    if (queryParameters != null) {
      queryParameters.forEach((key, value) {
        if (value != null) {
          stringParams[key] = value.toString();
        }
      });
    }

    final uri = Uri.parse('$baseUrl$path').replace(
      queryParameters: stringParams.isNotEmpty ? stringParams : null,
    );

    final response = await _client.get(uri, headers: _headers);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception(
        'TMDB API Request Failed [$path]: Status ${response.statusCode} - ${response.body}',
      );
    }
  }

  /// GET /3/configuration
  Future<Map<String, dynamic>> getConfiguration() async {
    return _get('/configuration');
  }

  /// GET /3/trending/movie/week
  Future<Map<String, dynamic>> getTrendingMovies({int page = 1}) async {
    return _get('/trending/movie/week', {
      'page': page,
      'include_adult': false,
    });
  }

  /// GET /3/trending/tv/week
  Future<Map<String, dynamic>> getTrendingTvShows({int page = 1}) async {
    return _get('/trending/tv/week', {
      'page': page,
      'include_adult': false,
    });
  }

  /// GET /3/movie/popular
  Future<Map<String, dynamic>> getPopularMovies({int page = 1}) async {
    return _get('/movie/popular', {
      'page': page,
      'include_adult': false,
    });
  }

  /// GET /3/tv/popular
  Future<Map<String, dynamic>> getPopularTvShows({int page = 1}) async {
    return _get('/tv/popular', {
      'page': page,
      'include_adult': false,
    });
  }

  /// GET /3/discover/movie
  Future<Map<String, dynamic>> discoverMovies({
    int? withGenres,
    String? sortBy,
    int page = 1,
    Map<String, dynamic>? extraParams,
  }) async {
    final query = <String, dynamic>{
      'page': page,
      'include_adult': false,
    };
    if (withGenres != null) query['with_genres'] = withGenres;
    if (sortBy != null) query['sort_by'] = sortBy;
    if (extraParams != null) query.addAll(extraParams);
    return _get('/discover/movie', query);
  }

  /// GET /3/discover/tv
  Future<Map<String, dynamic>> discoverTvShows({
    int? withGenres,
    String? sortBy,
    int page = 1,
    Map<String, dynamic>? extraParams,
  }) async {
    final query = <String, dynamic>{
      'page': page,
      'include_adult': false,
    };
    if (withGenres != null) query['with_genres'] = withGenres;
    if (sortBy != null) query['sort_by'] = sortBy;
    if (extraParams != null) query.addAll(extraParams);
    return _get('/discover/tv', query);
  }

  /// GET /3/genre/movie/list
  Future<Map<String, dynamic>> getMovieGenres() async {
    return _get('/genre/movie/list');
  }

  /// GET /3/genre/tv/list
  Future<Map<String, dynamic>> getTvGenres() async {
    return _get('/genre/tv/list');
  }

  /// GET /3/search/multi
  Future<Map<String, dynamic>> multiSearch(
    String query, {
    int page = 1,
  }) async {
    return _get('/search/multi', {
      'query': query,
      'page': page,
      'include_adult': false,
    });
  }

  bool _isValidSearchItem(Map<String, dynamic> item) {
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
        (searchResponse['results'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final List<Map<String, dynamic>> titles = [];
    final List<Map<String, dynamic>> personFilmographies = [];
    final List<Map<String, dynamic>> allOrdered = [];

    for (final item in results) {
      final mediaType = item['media_type'] as String?;
      if (mediaType == 'movie' || mediaType == 'tv') {
        if (_isValidSearchItem(item)) {
          titles.add(item);
          allOrdered.add(item);
        }
      } else if (mediaType == 'person') {
        final knownFor =
            (item['known_for'] as List?)?.cast<Map<String, dynamic>>() ?? [];
        for (final kf in knownFor) {
          final kfType = kf['media_type'] as String?;
          if (kfType == 'movie' || kfType == 'tv') {
            if (_isValidSearchItem(kf)) {
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
    );
  }

  /// GET /3/movie/{id}
  Future<Map<String, dynamic>> getMovieDetails(
    String id, {
    String? appendToResponse,
  }) async {
    final query = appendToResponse != null
        ? {'append_to_response': appendToResponse}
        : null;
    return _get('/movie/$id', query);
  }

  /// GET /3/tv/{id}
  Future<Map<String, dynamic>> getTvDetails(
    String id, {
    String? appendToResponse,
  }) async {
    final query = appendToResponse != null
        ? {'append_to_response': appendToResponse}
        : null;
    return _get('/tv/$id', query);
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
    return _get('/movie/$id/credits');
  }

  /// GET /3/tv/{id}/credits
  Future<Map<String, dynamic>> getTvCredits(String id) async {
    return _get('/tv/$id/credits');
  }

  /// GET /3/movie/{id}/videos
  Future<Map<String, dynamic>> getMovieVideos(String id) async {
    return _get('/movie/$id/videos');
  }

  /// GET /3/tv/{id}/videos
  Future<Map<String, dynamic>> getTvVideos(String id) async {
    return _get('/tv/$id/videos');
  }

  /// GET /3/movie/{id}/watch/providers
  Future<Map<String, dynamic>> getMovieWatchProviders(String id) async {
    return _get('/movie/$id/watch/providers');
  }

  /// GET /3/tv/{id}/watch/providers
  Future<Map<String, dynamic>> getTvWatchProviders(String id) async {
    return _get('/tv/$id/watch/providers');
  }

  /// GET /3/tv/{id}/season/{season_number}
  Future<Map<String, dynamic>> getTvSeasonDetails(
    String tvId,
    int seasonNumber,
  ) async {
    return _get('/tv/$tvId/season/$seasonNumber');
  }

  /// GET /3/watch/providers/regions
  Future<Map<String, dynamic>> getWatchProviderRegions() async {
    return _get('/watch/providers/regions');
  }
}
