import 'dart:developer' as developer;
import '../models/media_item.dart';
import '../services/tmdb_api_service.dart';
import '../services/tmdb_cache_service.dart';
import '../utils/tmdb_image_helper.dart';
import 'mock_movie_repository.dart';
import 'movie_repository.dart';

/// Repository implementation backed by TMDB API with graceful fallback to [MockMovieRepository].
class TmdbMovieRepository implements MovieRepository {
  static const Map<int, String> _defaultGenreMap = {
    28: 'Action',
    12: 'Adventure',
    16: 'Animation',
    35: 'Comedy',
    80: 'Crime',
    99: 'Documentary',
    18: 'Drama',
    10751: 'Family',
    14: 'Fantasy',
    36: 'History',
    27: 'Horror',
    10402: 'Music',
    9648: 'Mystery',
    10749: 'Romance',
    878: 'Sci-Fi',
    10770: 'TV Movie',
    53: 'Thriller',
    10752: 'War',
    37: 'Western',
    10759: 'Action & Adventure',
    10762: 'Kids',
    10763: 'News',
    10764: 'Reality',
    10765: 'Sci-Fi & Fantasy',
    10766: 'Soap',
    10767: 'Talk',
    10768: 'War & Politics',
  };

  final TmdbApiService apiService;
  final MovieRepository? fallbackRepository;
  final TmdbLocalCacheService cacheService;
  final Map<int, String> _genreMap = Map.of(_defaultGenreMap);
  bool _genresLoaded = false;

  TmdbMovieRepository({
    required this.apiService,
    this.fallbackRepository,
    TmdbLocalCacheService? cacheService,
  })  : cacheService = cacheService ?? TmdbLocalCacheService();

  /// Returns true if API service is initialized with a valid token.
  bool get isConfigured => apiService.hasToken;

  void _logWarning(String message) {
    developer.log(message, name: 'TmdbMovieRepository', level: 800);
  }

  void _logError(String message, [Object? error, StackTrace? stackTrace]) {
    developer.log(
      message,
      name: 'TmdbMovieRepository',
      error: error,
      stackTrace: stackTrace,
      level: 1000,
    );
  }

  Future<void> _ensureGenresLoaded() async {
    if (_genresLoaded || !isConfigured) return;
    try {
      final movieGenresKey = cacheService.generateKey('/genre/movie/list');
      final tvGenresKey = cacheService.generateKey('/genre/tv/list');

      Map<String, dynamic>? movieGenresRes =
          await cacheService.get(movieGenresKey);
      if (movieGenresRes == null) {
        movieGenresRes = await apiService.getMovieGenres();
        await cacheService.put(movieGenresKey, movieGenresRes);
      }

      Map<String, dynamic>? tvGenresRes = await cacheService.get(tvGenresKey);
      if (tvGenresRes == null) {
        tvGenresRes = await apiService.getTvGenres();
        await cacheService.put(tvGenresKey, tvGenresRes);
      }

      final movieGenres = (movieGenresRes['genres'] as List?)
              ?.cast<Map<String, dynamic>>() ??
          [];
      final tvGenres =
          (tvGenresRes['genres'] as List?)?.cast<Map<String, dynamic>>() ?? [];

      for (final g in movieGenres) {
        final id = (g['id'] as num?)?.toInt();
        final name = g['name'] as String?;
        if (id != null && name != null) {
          _genreMap[id] = name;
        }
      }
      for (final g in tvGenres) {
        final id = (g['id'] as num?)?.toInt();
        final name = g['name'] as String?;
        if (id != null && name != null) {
          _genreMap[id] = name;
        }
      }
      _genresLoaded = true;
    } catch (e) {
      // Non-fatal, use default genre map
      _genresLoaded = true;
    }
  }

  @override
  Future<List<MediaItem>> getTrendingMovies() async {
    if (!isConfigured) {
      _logWarning(
          'TMDB token is missing or unconfigured.');
      if (fallbackRepository != null) {
        return fallbackRepository!.getTrendingMovies();
      }
      throw Exception('TMDB API token is missing or unconfigured.');
    }
    try {
      await _ensureGenresLoaded();
      final key = cacheService
          .generateKey('/trending/movie/week', {'page': 1, 'include_adult': false});
      Map<String, dynamic>? res = await cacheService.get(key);
      if (res == null) {
        res = await apiService.getTrendingMovies();
        await cacheService.put(key, res);
      }
      final results =
          (res['results'] as List?)?.cast<Map<String, dynamic>>() ?? [];
      return results
          .map((item) => _mapJsonToMediaItem(item, overrideType: MediaType.movie))
          .toList();
    } catch (e, stack) {
      _logError(
          'Failed to fetch trending movies from TMDB API.',
          e,
          stack);
      if (fallbackRepository != null) {
        return fallbackRepository!.getTrendingMovies();
      }
      rethrow;
    }
  }

  @override
  Future<List<MediaItem>> getPopularMovies() async {
    if (!isConfigured) {
      _logWarning(
          'TMDB token is missing or unconfigured.');
      if (fallbackRepository != null) {
        return fallbackRepository!.getPopularMovies();
      }
      throw Exception('TMDB API token is missing or unconfigured.');
    }
    try {
      await _ensureGenresLoaded();
      final key = cacheService
          .generateKey('/movie/popular', {'page': 1, 'include_adult': false});
      Map<String, dynamic>? res = await cacheService.get(key);
      if (res == null) {
        res = await apiService.getPopularMovies();
        await cacheService.put(key, res);
      }
      final results =
          (res['results'] as List?)?.cast<Map<String, dynamic>>() ?? [];
      return results
          .map((item) => _mapJsonToMediaItem(item, overrideType: MediaType.movie))
          .toList();
    } catch (e, stack) {
      _logError(
          'Failed to fetch popular movies from TMDB API.',
          e,
          stack);
      if (fallbackRepository != null) {
        return fallbackRepository!.getPopularMovies();
      }
      rethrow;
    }
  }

  @override
  Future<List<MediaItem>> getTrendingTvShows() async {
    if (!isConfigured) {
      _logWarning(
          'TMDB token is missing or unconfigured.');
      if (fallbackRepository != null) {
        return fallbackRepository!.getTrendingTvShows();
      }
      throw Exception('TMDB API token is missing or unconfigured.');
    }
    try {
      await _ensureGenresLoaded();
      final key = cacheService
          .generateKey('/trending/tv/week', {'page': 1, 'include_adult': false});
      Map<String, dynamic>? res = await cacheService.get(key);
      if (res == null) {
        res = await apiService.getTrendingTvShows();
        await cacheService.put(key, res);
      }
      final results =
          (res['results'] as List?)?.cast<Map<String, dynamic>>() ?? [];
      return results
          .map((item) => _mapJsonToMediaItem(item, overrideType: MediaType.tv))
          .toList();
    } catch (e, stack) {
      _logError(
          'Failed to fetch trending TV shows from TMDB API.',
          e,
          stack);
      if (fallbackRepository != null) {
        return fallbackRepository!.getTrendingTvShows();
      }
      rethrow;
    }
  }

  @override
  Future<MediaItem?> getMediaDetails(String id) async {
    if (!isConfigured) {
      _logWarning(
          'TMDB token is missing or unconfigured.');
      if (fallbackRepository != null) {
        return fallbackRepository!.getMediaDetails(id);
      }
      throw Exception('TMDB API token is missing or unconfigured.');
    }
    try {
      await _ensureGenresLoaded();

      // Check for type prefixes if present (e.g. "tv_123", "movie_123")
      String cleanId = id;
      MediaType? explicitType;
      if (id.startsWith('tv_') || id.startsWith('tv:')) {
        cleanId = id.substring(3);
        explicitType = MediaType.tv;
      } else if (id.startsWith('movie_') || id.startsWith('movie:')) {
        cleanId = id.substring(6);
        explicitType = MediaType.movie;
      }

      Map<String, dynamic>? detailsJson;
      MediaType resolvedType = explicitType ?? MediaType.movie;

      final queryParams = {
        'append_to_response':
            'credits,videos,watch/providers,release_dates,content_ratings,keywords,external_ids'
      };

      if (explicitType == MediaType.tv) {
        final key = cacheService.generateKey('/tv/$cleanId', queryParams);
        detailsJson = await cacheService.get(key);
        if (detailsJson == null) {
          detailsJson = await apiService.getTvDetails(cleanId,
              appendToResponse:
                  'credits,videos,watch/providers,release_dates,content_ratings,keywords,external_ids');
          await cacheService.put(key, detailsJson);
        }
      } else if (explicitType == MediaType.movie) {
        final key = cacheService.generateKey('/movie/$cleanId', queryParams);
        detailsJson = await cacheService.get(key);
        if (detailsJson == null) {
          detailsJson = await apiService.getMovieDetails(cleanId,
              appendToResponse:
                  'credits,videos,watch/providers,release_dates,content_ratings,keywords,external_ids');
          await cacheService.put(key, detailsJson);
        }
      } else {
        // Try movie details first
        final movieKey = cacheService.generateKey('/movie/$cleanId', queryParams);
        detailsJson = await cacheService.get(movieKey);
        if (detailsJson != null) {
          resolvedType = MediaType.movie;
        } else {
          final tvKey = cacheService.generateKey('/tv/$cleanId', queryParams);
          detailsJson = await cacheService.get(tvKey);
          if (detailsJson != null) {
            resolvedType = MediaType.tv;
          } else {
            try {
              detailsJson = await apiService.getMovieDetails(cleanId,
                  appendToResponse:
                      'credits,videos,watch/providers,release_dates,content_ratings,keywords,external_ids');
              await cacheService.put(movieKey, detailsJson);
              resolvedType = MediaType.movie;
            } catch (_) {
              // Fall back to trying TV details
              detailsJson = await apiService.getTvDetails(cleanId,
                  appendToResponse:
                      'credits,videos,watch/providers,release_dates,content_ratings,keywords,external_ids');
              await cacheService.put(tvKey, detailsJson);
              resolvedType = MediaType.tv;
            }
          }
        }
      }

      return _mapJsonToMediaItem(detailsJson, overrideType: resolvedType);
    } catch (e, stack) {
      _logError(
          'Failed to fetch details for id "$id" from TMDB API.',
          e,
          stack);
      if (fallbackRepository != null) {
        return fallbackRepository!.getMediaDetails(id);
      }
      rethrow;
    }
  }

  @override
  Future<List<MediaItem>> searchMedia(String query) async {
    if (!isConfigured) {
      _logWarning(
          'TMDB token is missing or unconfigured.');
      if (fallbackRepository != null) {
        return fallbackRepository!.searchMedia(query);
      }
      throw Exception('TMDB API token is missing or unconfigured.');
    }
    try {
      await _ensureGenresLoaded();
      final key = cacheService.generateKey('/search/multi', {
        'query': query,
        'page': 1,
        'include_adult': false,
      });

      Map<String, dynamic>? res =
          await cacheService.get(key, isSessionOnly: true);
      if (res == null) {
        res = await apiService.multiSearch(query);
        await cacheService.put(key, res, isSessionOnly: true);
      }

      final filterResult = apiService.filterSearchResults(res);

      final items = <MediaItem>[];
      final seenIds = <String>{};

      for (final mediaJson in filterResult.allOrdered) {
        final item = _mapJsonToMediaItem(mediaJson);
        if (seenIds.add(item.id)) {
          items.add(item);
        }
      }

      return items;
    } catch (e, stack) {
      _logError(
          'Failed to search media for query "$query" from TMDB API.',
          e,
          stack);
      if (fallbackRepository != null) {
        return fallbackRepository!.searchMedia(query);
      }
      rethrow;
    }
  }

  static const List<Map<String, String>> _defaultRegions = [
    {'code': 'US', 'name': 'United States'},
    {'code': 'GB', 'name': 'United Kingdom'},
    {'code': 'CA', 'name': 'Canada'},
    {'code': 'AU', 'name': 'Australia'},
    {'code': 'DE', 'name': 'Germany'},
    {'code': 'FR', 'name': 'France'},
    {'code': 'JP', 'name': 'Japan'},
  ];

  @override
  Future<List<Map<String, String>>> getWatchProviderRegions() async {
    if (!isConfigured) {
      if (fallbackRepository != null) {
        return fallbackRepository!.getWatchProviderRegions();
      }
      return _defaultRegions;
    }
    try {
      final key = cacheService.generateKey('/watch/providers/regions');
      Map<String, dynamic>? res = await cacheService.get(key);
      if (res == null) {
        res = await apiService.getWatchProviderRegions();
        await cacheService.put(key, res);
      }
      final results =
          (res['results'] as List?)?.cast<Map<String, dynamic>>() ?? [];
      final List<Map<String, String>> regions = [];
      for (final item in results) {
        final code = item['iso_3166_1'] as String?;
        final name = item['english_name'] as String? ??
            item['native_name'] as String? ??
            code;
        if (code != null && code.isNotEmpty) {
          regions.add({'code': code, 'name': name ?? code});
        }
      }
      return regions.isNotEmpty ? regions : _defaultRegions;
    } catch (e, stack) {
      _logError(
          'Failed to fetch watch provider regions from TMDB API.', e, stack);
      if (fallbackRepository != null) {
        return fallbackRepository!.getWatchProviderRegions();
      }
      return _defaultRegions;
    }
  }

  MediaItem _mapJsonToMediaItem(
    Map<String, dynamic> json, {
    MediaType? overrideType,
  }) {
    final rawId = json['id']?.toString() ?? '';
    final title = json['title'] as String? ??
        json['name'] as String? ??
        json['original_title'] as String? ??
        json['original_name'] as String? ??
        'Untitled';

    MediaType type;
    if (overrideType != null) {
      type = overrideType;
    } else {
      final mediaTypeStr = json['media_type'] as String?;
      if (mediaTypeStr == 'tv') {
        type = MediaType.tv;
      } else if (mediaTypeStr == 'movie') {
        type = MediaType.movie;
      } else if (json.containsKey('first_air_date') ||
          json.containsKey('number_of_seasons')) {
        type = MediaType.tv;
      } else {
        type = MediaType.movie;
      }
    }

    final rating = (json['vote_average'] as num?)?.toDouble() ?? 0.0;

    final dateStr = (json['release_date'] as String?) ??
        (json['first_air_date'] as String?);
    DateTime? releaseOrAirDate;
    if (dateStr != null && dateStr.isNotEmpty) {
      releaseOrAirDate = DateTime.tryParse(dateStr);
    }

    final overview = json['overview'] as String? ?? '';

    final genres = <String>[];
    if (json['genres'] is List) {
      final genreList = json['genres'] as List;
      for (final g in genreList) {
        if (g is Map && g['name'] != null) {
          genres.add(g['name'].toString());
        }
      }
    } else if (json['genre_ids'] is List) {
      final idList = (json['genre_ids'] as List).cast<num>();
      for (final id in idList) {
        final name = _genreMap[id.toInt()];
        if (name != null) {
          genres.add(name);
        }
      }
    }

    final posterPath = json['poster_path'] as String?;
    final posterUrl = TmdbImageHelper.getPosterThumbnailUrl(posterPath);
    final detailPosterUrl = TmdbImageHelper.getDetailPosterUrl(posterPath);

    final backdropPath = json['backdrop_path'] as String?;
    final backdropUrl = TmdbImageHelper.getBackdropUrl(backdropPath);

    final runtime = (json['runtime'] as num?)?.toInt() ??
        ((json['episode_run_time'] as List?)?.isNotEmpty == true
            ? ((json['episode_run_time'] as List).first as num).toInt()
            : null);

    final seasonsCount = (json['number_of_seasons'] as num?)?.toInt();
    final episodesCount = (json['number_of_episodes'] as num?)?.toInt();

    // Cast parsing from credits append_to_response or credits key
    final cast = <String>[];
    final castMembers = <CastMember>[];
    final creditsObj = json['credits'] as Map<String, dynamic>?;
    if (creditsObj != null && creditsObj['cast'] is List) {
      final castList = creditsObj['cast'] as List;
      for (final member in castList.take(8)) {
        if (member is Map && member['name'] != null) {
          final memberName = member['name'].toString();
          cast.add(memberName);

          final memberId = member['id']?.toString() ?? '';
          final character = member['character'] as String?;
          final profilePath = member['profile_path'] as String?;
          final profileUrl = TmdbImageHelper.getCastHeadshotUrl(profilePath);

          castMembers.add(CastMember(
            id: memberId,
            name: memberName,
            character: character,
            profileUrl: profileUrl,
          ));
        }
      }
    }

    // Trailer parsing from videos append_to_response
    bool hasTrailer = false;
    String? trailerVideoId;
    final videosObj = json['videos'] as Map<String, dynamic>?;
    if (videosObj != null && videosObj['results'] is List) {
      final videoList = videosObj['results'] as List;

      Map<String, dynamic>? findBestMatch(String targetType) {
        Map<String, dynamic>? candidate;
        for (final item in videoList) {
          if (item is! Map) continue;
          final map = item.cast<String, dynamic>();
          final type = map['type'] as String?;
          final site = map['site'] as String?;
          final key = map['key']?.toString();
          if (type == targetType &&
              site == 'YouTube' &&
              key != null &&
              key.isNotEmpty) {
            if (candidate == null) {
              candidate = map;
            } else if (map['official'] == true && candidate['official'] != true) {
              candidate = map;
            }
          }
        }
        return candidate;
      }

      // Pass 1 (Full Trailers): Search videos['results'] for site == 'YouTube' && type == 'Trailer'. Prefer official == true.
      final trailerMatch = findBestMatch('Trailer');
      if (trailerMatch != null) {
        trailerVideoId = trailerMatch['key']?.toString();
      } else {
        // Pass 2 (Teaser Fallback): Search videos['results'] for site == 'YouTube' && type == 'Teaser'. Prefer official == true.
        final teaserMatch = findBestMatch('Teaser');
        if (teaserMatch != null) {
          trailerVideoId = teaserMatch['key']?.toString();
        }
      }

      if (trailerVideoId != null && trailerVideoId.isNotEmpty) {
        hasTrailer = true;
      } else {
        trailerVideoId = null;
      }
    }

    // Watch providers parsing from watch/providers append_to_response
    final providersObj = json['watch/providers'] as Map<String, dynamic>? ??
        json['watch_providers'] as Map<String, dynamic>?;
    final watchProvidersByCountry = _mapWatchProvidersJson(providersObj);
    final watchProviders = watchProvidersByCountry['US']
            ?.where((p) => p.category == 'Stream')
            .map((p) => p.providerName)
            .toList() ??
        <String>[];

    final tagline = (json['tagline'] as String?)?.isNotEmpty == true
        ? json['tagline'] as String
        : null;

    String? director;
    if (type == MediaType.movie) {
      final creditsObj = json['credits'] as Map<String, dynamic>?;
      if (creditsObj != null && creditsObj['crew'] is List) {
        for (final member in creditsObj['crew'] as List) {
          if (member is Map &&
              member['job'] == 'Director' &&
              member['name'] != null) {
            director = member['name'].toString();
            break;
          }
        }
      }
    } else if (type == MediaType.tv) {
      if (json['created_by'] is List) {
        final creators = (json['created_by'] as List)
            .whereType<Map>()
            .map((e) => e['name']?.toString())
            .where((n) => n != null && n.isNotEmpty)
            .cast<String>()
            .toList();
        if (creators.isNotEmpty) {
          director = creators.join(', ');
        }
      }
      if (director == null) {
        final creditsObj = json['credits'] as Map<String, dynamic>?;
        if (creditsObj != null && creditsObj['crew'] is List) {
          for (final member in creditsObj['crew'] as List) {
            if (member is Map &&
                member['job'] == 'Director' &&
                member['name'] != null) {
              director = member['name'].toString();
              break;
            }
          }
        }
      }
    }

    String? certification;
    if (type == MediaType.movie) {
      final releaseDatesObj = json['release_dates'] as Map<String, dynamic>?;
      if (releaseDatesObj != null && releaseDatesObj['results'] is List) {
        final results = releaseDatesObj['results'] as List;
        for (final country in results) {
          if (country is Map && country['iso_3166_1'] == 'US') {
            final dates = country['release_dates'];
            if (dates is List) {
              for (final d in dates) {
                if (d is Map && d['certification'] != null) {
                  final cert = d['certification'].toString().trim();
                  if (cert.isNotEmpty) {
                    certification = cert;
                    break;
                  }
                }
              }
            }
            if (certification != null) break;
          }
        }
      }
    } else if (type == MediaType.tv) {
      final contentRatingsObj = json['content_ratings'] as Map<String, dynamic>?;
      if (contentRatingsObj != null && contentRatingsObj['results'] is List) {
        final results = contentRatingsObj['results'] as List;
        for (final country in results) {
          if (country is Map && country['iso_3166_1'] == 'US') {
            final rating = country['rating']?.toString().trim();
            if (rating != null && rating.isNotEmpty) {
              certification = rating;
              break;
            }
          }
        }
      }
    }

    MediaCollection? belongsToCollection;
    if (json['belongs_to_collection'] is Map) {
      final colMap = json['belongs_to_collection'] as Map<String, dynamic>;
      final colId = (colMap['id'] as num?)?.toInt();
      final colName = colMap['name'] as String?;
      if (colId != null && colName != null) {
        belongsToCollection = MediaCollection(
          id: colId,
          name: colName,
          posterUrl: TmdbImageHelper.w500(colMap['poster_path'] as String?),
          backdropUrl: TmdbImageHelper.w780(colMap['backdrop_path'] as String?),
        );
      }
    }

    List<String>? createdBy;
    if (json['created_by'] is List) {
      final list = (json['created_by'] as List)
          .whereType<Map>()
          .map((e) => e['name']?.toString())
          .where((n) => n != null && n.isNotEmpty)
          .cast<String>()
          .toList();
      if (list.isNotEmpty) {
        createdBy = list;
      }
    }

    List<MediaNetwork>? networks;
    if (json['networks'] is List) {
      final netList = <MediaNetwork>[];
      for (final item in json['networks'] as List) {
        if (item is Map) {
          final netId = (item['id'] as num?)?.toInt();
          final netName = item['name'] as String?;
          if (netId != null && netName != null) {
            netList.add(MediaNetwork(
              id: netId,
              name: netName,
              logoUrl: TmdbImageHelper.w185(item['logo_path'] as String?),
            ));
          }
        }
      }
      if (netList.isNotEmpty) {
        networks = netList;
      }
    }

    final voteCount = (json['vote_count'] as num?)?.toInt();

    List<MediaKeyword>? keywords;
    final keywordsObj = json['keywords'];
    List? kwList;
    if (keywordsObj is Map) {
      if (keywordsObj['keywords'] is List) {
        kwList = keywordsObj['keywords'] as List;
      } else if (keywordsObj['results'] is List) {
        kwList = keywordsObj['results'] as List;
      }
    } else if (keywordsObj is List) {
      kwList = keywordsObj;
    }

    if (kwList != null) {
      final parsedKw = <MediaKeyword>[];
      for (final item in kwList) {
        if (item is Map) {
          final kwId = (item['id'] as num?)?.toInt();
          final kwName = item['name'] as String?;
          if (kwId != null && kwName != null) {
            parsedKw.add(MediaKeyword(id: kwId, name: kwName));
          }
        }
      }
      if (parsedKw.isNotEmpty) {
        keywords = parsedKw;
      }
    }

    String? imdbId = json['imdb_id'] as String?;
    if (imdbId == null || imdbId.isEmpty) {
      final externalIds = json['external_ids'] as Map<String, dynamic>?;
      if (externalIds != null) {
        imdbId = externalIds['imdb_id'] as String?;
      }
    }
    if (imdbId?.isEmpty == true) imdbId = null;

    List<ProductionCompany>? productionCompanies;
    if (json['production_companies'] is List) {
      final pcList = <ProductionCompany>[];
      for (final item in json['production_companies'] as List) {
        if (item is Map) {
          final pcId = (item['id'] as num?)?.toInt();
          final pcName = item['name'] as String?;
          if (pcId != null && pcName != null) {
            pcList.add(ProductionCompany(
              id: pcId,
              name: pcName,
              logoUrl: TmdbImageHelper.w185(item['logo_path'] as String?),
            ));
          }
        }
      }
      if (pcList.isNotEmpty) {
        productionCompanies = pcList;
      }
    }

    return MediaItem(
      id: rawId,
      title: title,
      type: type,
      rating: rating,
      releaseOrAirDate: releaseOrAirDate,
      overview: overview,
      genres: genres,
      posterUrl: posterUrl,
      detailPosterUrl: detailPosterUrl,
      backdropUrl: backdropUrl,
      runtime: runtime,
      seasonsCount: seasonsCount,
      episodesCount: episodesCount,
      hasTrailer: hasTrailer,
      trailerVideoId: trailerVideoId,
      watchProviders: watchProviders,
      watchProvidersByCountry: watchProvidersByCountry,
      cast: cast,
      castMembers: castMembers,
      tagline: tagline,
      director: director,
      certification: certification,
      belongsToCollection: belongsToCollection,
      createdBy: createdBy,
      networks: networks,
      voteCount: voteCount,
      keywords: keywords,
      imdbId: imdbId,
      productionCompanies: productionCompanies,
    );
  }

  Map<String, List<WatchProviderInfo>> _mapWatchProvidersJson(
    Map<String, dynamic>? providersObj,
  ) {
    final map = <String, List<WatchProviderInfo>>{};
    if (providersObj == null) return map;
    final results = providersObj['results'];
    if (results is! Map) return map;

    for (final countryKey in results.keys) {
      final country = countryKey.toString();
      final countryData = results[countryKey];
      if (countryData is Map) {
        final list = <WatchProviderInfo>[];

        void parseCategory(String tmdbKey, String categoryName) {
          final rawList = countryData[tmdbKey];
          if (rawList is List) {
            for (final p in rawList) {
              if (p is Map && p['provider_name'] != null) {
                final pName = p['provider_name'].toString();
                if (!list.any((item) =>
                    item.providerName == pName && item.category == categoryName)) {
                  list.add(WatchProviderInfo(
                    providerName: pName,
                    category: categoryName,
                  ));
                }
              }
            }
          }
        }

        parseCategory('flatrate', 'Stream');
        parseCategory('rent', 'Rent');
        parseCategory('buy', 'Buy');

        if (list.isNotEmpty) {
          map[country] = list;
        }
      }
    }

    return map;
  }
}
