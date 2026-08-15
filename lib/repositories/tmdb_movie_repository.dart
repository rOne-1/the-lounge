import 'dart:async';
import 'dart:io';
import 'dart:developer' as developer;
import 'package:http/http.dart' as http;
import '../models/discover_filter_params.dart';
import '../models/media_item.dart';
import '../models/media_collection_detail.dart';
import '../services/crash_reporting_service.dart';
import '../services/tmdb_api_service.dart';
import '../services/tmdb_cache_service.dart';
import '../utils/tmdb_image_helper.dart';
import 'mock_movie_repository.dart';
import 'movie_repository.dart';

/// Helper function to detect socket/network exceptions.
bool isNetworkException(Object error) {
  if (error is SocketException ||
      error is TimeoutException ||
      error is HandshakeException ||
      error is http.ClientException) {
    return true;
  }
  final s = error.toString().toLowerCase();
  return s.contains('socketexception') ||
      s.contains('clientexception') ||
      s.contains('failed host lookup') ||
      s.contains('no internet') ||
      s.contains('no connection') ||
      s.contains('network exception') ||
      s.contains('connection refused') ||
      s.contains('connection timed out') ||
      s.contains('network is unreachable') ||
      s.contains('host lookup failed');
}

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
      CrashReportingService.sanitizeString(message),
      name: 'TmdbMovieRepository',
      error: error,
      stackTrace: stackTrace,
      level: 1000,
    );
    CrashReportingService.captureException(error ?? message, stackTrace);
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
  Future<List<MediaItem>> getTrendingMovies({int page = 1}) async {
    if (!isConfigured) {
      _logWarning(
          'TMDB token is missing or unconfigured.');
      if (fallbackRepository != null) {
        return fallbackRepository!.getTrendingMovies(page: page);
      }
      throw Exception('TMDB API token is missing or unconfigured.');
    }
    try {
      await _ensureGenresLoaded();
      final key = cacheService
          .generateKey('/trending/movie/week', {'page': page, 'include_adult': false});
      Map<String, dynamic>? res = await cacheService.get(key);
      if (res == null) {
        res = await apiService.getTrendingMovies(page: page);
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
        return fallbackRepository!.getTrendingMovies(page: page);
      }
      rethrow;
    }
  }

  @override
  Future<List<MediaItem>> getPopularMovies({int page = 1}) async {
    if (!isConfigured) {
      _logWarning(
          'TMDB token is missing or unconfigured.');
      if (fallbackRepository != null) {
        return fallbackRepository!.getPopularMovies(page: page);
      }
      throw Exception('TMDB API token is missing or unconfigured.');
    }
    try {
      await _ensureGenresLoaded();
      final key = cacheService
          .generateKey('/movie/popular', {'page': page, 'include_adult': false});
      Map<String, dynamic>? res = await cacheService.get(key);
      if (res == null) {
        res = await apiService.getPopularMovies(page: page);
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
        return fallbackRepository!.getPopularMovies(page: page);
      }
      rethrow;
    }
  }

  @override
  Future<List<MediaItem>> getTrendingTvShows({int page = 1}) async {
    if (!isConfigured) {
      _logWarning(
          'TMDB token is missing or unconfigured.');
      if (fallbackRepository != null) {
        return fallbackRepository!.getTrendingTvShows(page: page);
      }
      throw Exception('TMDB API token is missing or unconfigured.');
    }
    try {
      await _ensureGenresLoaded();
      final key = cacheService
          .generateKey('/trending/tv/week', {'page': page, 'include_adult': false});
      Map<String, dynamic>? res = await cacheService.get(key);
      if (res == null) {
        res = await apiService.getTrendingTvShows(page: page);
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
        return fallbackRepository!.getTrendingTvShows(page: page);
      }
      rethrow;
    }
  }

  @override
  Future<List<MediaItem>> getTopRatedMovies({int page = 1}) async {
    if (!isConfigured) {
      _logWarning('TMDB token is missing or unconfigured.');
      if (fallbackRepository != null) {
        return fallbackRepository!.getTopRatedMovies(page: page);
      }
      throw Exception('TMDB API token is missing or unconfigured.');
    }
    try {
      await _ensureGenresLoaded();
      final key = cacheService
          .generateKey('/movie/top_rated', {'page': page, 'include_adult': false});
      Map<String, dynamic>? res = await cacheService.get(key);
      if (res == null) {
        res = await apiService.getTopRatedMovies(page: page);
        await cacheService.put(key, res);
      }
      final results =
          (res['results'] as List?)?.cast<Map<String, dynamic>>() ?? [];
      return results
          .map((item) => _mapJsonToMediaItem(item, overrideType: MediaType.movie))
          .toList();
    } catch (e, stack) {
      _logError('Failed to fetch top rated movies from TMDB API.', e, stack);
      if (fallbackRepository != null) {
        return fallbackRepository!.getTopRatedMovies(page: page);
      }
      rethrow;
    }
  }

  @override
  Future<List<MediaItem>> getTopRatedTvShows({int page = 1}) async {
    if (!isConfigured) {
      _logWarning('TMDB token is missing or unconfigured.');
      if (fallbackRepository != null) {
        return fallbackRepository!.getTopRatedTvShows(page: page);
      }
      throw Exception('TMDB API token is missing or unconfigured.');
    }
    try {
      await _ensureGenresLoaded();
      final key = cacheService
          .generateKey('/tv/top_rated', {'page': page, 'include_adult': false});
      Map<String, dynamic>? res = await cacheService.get(key);
      if (res == null) {
        res = await apiService.getTopRatedTvShows(page: page);
        await cacheService.put(key, res);
      }
      final results =
          (res['results'] as List?)?.cast<Map<String, dynamic>>() ?? [];
      return results
          .map((item) => _mapJsonToMediaItem(item, overrideType: MediaType.tv))
          .toList();
    } catch (e, stack) {
      _logError('Failed to fetch top rated TV shows from TMDB API.', e, stack);
      if (fallbackRepository != null) {
        return fallbackRepository!.getTopRatedTvShows(page: page);
      }
      rethrow;
    }
  }

  @override
  Future<List<MediaItem>> getNowPlayingMovies({int page = 1, String? region}) async {
    if (!isConfigured) {
      _logWarning('TMDB token is missing or unconfigured.');
      if (fallbackRepository != null) {
        return fallbackRepository!.getNowPlayingMovies(page: page, region: region);
      }
      throw Exception('TMDB API token is missing or unconfigured.');
    }
    try {
      await _ensureGenresLoaded();
      final activeRegion = (region != null && region.isNotEmpty) ? region : 'US';
      final key = cacheService.generateKey('/movie/now_playing', {
        'page': page,
        'include_adult': false,
        'region': activeRegion,
      });
      Map<String, dynamic>? res = await cacheService.get(key);
      if (res == null) {
        res = await apiService.getNowPlayingMovies(page: page, region: activeRegion);
        await cacheService.put(key, res);
      }
      final results =
          (res['results'] as List?)?.cast<Map<String, dynamic>>() ?? [];
      return results
          .map((item) => _mapJsonToMediaItem(item, overrideType: MediaType.movie))
          .toList();
    } catch (e, stack) {
      _logError('Failed to fetch now playing movies from TMDB API.', e, stack);
      if (fallbackRepository != null) {
        return fallbackRepository!.getNowPlayingMovies(page: page, region: region);
      }
      rethrow;
    }
  }

  @override
  Future<List<MediaItem>> getAiringTodayTvShows({int page = 1}) async {
    if (!isConfigured) {
      _logWarning('TMDB token is missing or unconfigured.');
      if (fallbackRepository != null) {
        return fallbackRepository!.getAiringTodayTvShows(page: page);
      }
      throw Exception('TMDB API token is missing or unconfigured.');
    }
    try {
      await _ensureGenresLoaded();
      final key = cacheService
          .generateKey('/tv/airing_today', {'page': page, 'include_adult': false});
      Map<String, dynamic>? res = await cacheService.get(key);
      if (res == null) {
        res = await apiService.getAiringTodayTvShows(page: page);
        await cacheService.put(key, res);
      }
      final results =
          (res['results'] as List?)?.cast<Map<String, dynamic>>() ?? [];
      return results
          .map((item) => _mapJsonToMediaItem(item, overrideType: MediaType.tv))
          .toList();
    } catch (e, stack) {
      _logError('Failed to fetch airing today TV shows from TMDB API.', e, stack);
      if (fallbackRepository != null) {
        return fallbackRepository!.getAiringTodayTvShows(page: page);
      }
      rethrow;
    }
  }

  @override
  Future<List<MediaItem>> getUpcomingMovies({int page = 1}) async {
    if (!isConfigured) {
      _logWarning('TMDB token is missing or unconfigured.');
      if (fallbackRepository != null) {
        return fallbackRepository!.getUpcomingMovies(page: page);
      }
      throw Exception('TMDB API token is missing or unconfigured.');
    }
    try {
      await _ensureGenresLoaded();
      final key = cacheService
          .generateKey('/movie/upcoming', {'page': page, 'include_adult': false});
      Map<String, dynamic>? res = await cacheService.get(key);
      if (res == null) {
        res = await apiService.getUpcomingMovies(page: page);
        await cacheService.put(key, res);
      }
      final results =
          (res['results'] as List?)?.cast<Map<String, dynamic>>() ?? [];
      final now = DateTime.now();
      final mapped = results
          .map((item) => _mapJsonToMediaItem(item, overrideType: MediaType.movie))
          .toList();
      // TF-22: TMDB's /movie/upcoming can include titles already released
      // (region/date-window quirks) — filter those out client-side. Falls
      // back to the unfiltered page rather than an empty rail if every item
      // gets excluded (e.g. device clock skew vs. TMDB's release window) —
      // a genuinely empty "Upcoming" list is worse than a few already-out
      // titles slipping through, and MediaRail renders total silence (no
      // error, no empty state) when this list is empty, so the failure mode
      // is invisible to the user otherwise.
      final upcoming = mapped
          .where((item) =>
              item.releaseOrAirDate == null ||
              item.releaseOrAirDate!.isAfter(now))
          .toList();
      return upcoming.isNotEmpty ? upcoming : mapped;
    } catch (e, stack) {
      _logError('Failed to fetch upcoming movies from TMDB API.', e, stack);
      if (fallbackRepository != null) {
        return fallbackRepository!.getUpcomingMovies(page: page);
      }
      rethrow;
    }
  }

  @override
  Future<List<MediaItem>> getOnTheAirTvShows({int page = 1}) async {
    if (!isConfigured) {
      _logWarning('TMDB token is missing or unconfigured.');
      if (fallbackRepository != null) {
        return fallbackRepository!.getOnTheAirTvShows(page: page);
      }
      throw Exception('TMDB API token is missing or unconfigured.');
    }
    try {
      await _ensureGenresLoaded();
      final key = cacheService
          .generateKey('/tv/on_the_air', {'page': page, 'include_adult': false});
      Map<String, dynamic>? res = await cacheService.get(key);
      if (res == null) {
        res = await apiService.getOnTheAirTvShows(page: page);
        await cacheService.put(key, res);
      }
      final results =
          (res['results'] as List?)?.cast<Map<String, dynamic>>() ?? [];
      return results
          .map((item) => _mapJsonToMediaItem(item, overrideType: MediaType.tv))
          .toList();
    } catch (e, stack) {
      _logError('Failed to fetch on the air TV shows from TMDB API.', e, stack);
      if (fallbackRepository != null) {
        return fallbackRepository!.getOnTheAirTvShows(page: page);
      }
      rethrow;
    }
  }

  @override
  Future<TvSeason?> getTvSeasonDetails(String tvId, int seasonNumber) async {
    if (!isConfigured) {
      _logWarning('TMDB token is missing or unconfigured.');
      if (fallbackRepository != null) {
        return fallbackRepository!.getTvSeasonDetails(tvId, seasonNumber);
      }
      return null;
    }
    try {
      final cleanId = tvId.replaceFirst(RegExp(r'^(tv_|movie_)'), '');
      final key = cacheService.generateKey('/tv/$cleanId/season/$seasonNumber');
      Map<String, dynamic>? res = await cacheService.get(key);
      if (res == null) {
        res = await apiService.getTvSeasonDetails(cleanId, seasonNumber);
        await cacheService.put(key, res);
      }
      return _mapJsonToTvSeason(res);
    } catch (e, stack) {
      _logError('Failed to fetch TV season details for $tvId S$seasonNumber', e, stack);
      if (fallbackRepository != null) {
        return fallbackRepository!.getTvSeasonDetails(tvId, seasonNumber);
      }
      return null;
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

      if (filterResult.topPersonId != null) {
        // TMDB's own combined relevance ranking judged a person to be the
        // strongest match for this query -- a cast/crew name search, not a
        // title search. TMDB's "known for" sample is only 2-4 titles, and
        // literal title-text matches for a person's name pull in unrelated
        // biography documentaries/specials (e.g. searching "Tom Hanks"
        // surfacing an SNL episode titled "Tom Hanks"). Fetch their real
        // filmography instead of mixing known_for with title-text noise.
        final filmography = await getPersonFilmography(filterResult.topPersonId!);
        if (filmography.isNotEmpty) {
          return filmography;
        }
        // Fall through to the title-match path if this person had no
        // usable credits (e.g. a crew-only role with nothing valid).
      }

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

  @override
  Future<List<MediaItem>> discoverMedia({
    required bool isMovies,
    required DiscoverFilterParams params,
    int page = 1,
  }) async {
    if (!isConfigured) {
      _logWarning('TMDB token is missing or unconfigured.');
      if (fallbackRepository != null) {
        return fallbackRepository!.discoverMedia(
          isMovies: isMovies,
          params: params,
          page: page,
        );
      }
      throw Exception('TMDB API token is missing or unconfigured.');
    }
    try {
      await _ensureGenresLoaded();

      // TMDB's /discover/tv endpoint has no with_people parameter at all
      // (unlike /discover/movie, which does) -- a cast/crew filter there
      // silently does nothing server-side, so a TV-mode person filter
      // combined with Discover just returns the generic, unfiltered
      // result set. Use the person's real filmography (already built for
      // cast/crew search) as the candidate set instead, for both movies
      // and TV, so the filter actually works in both modes.
      if (params.personId != null) {
        if (page > 1) {
          // The filmography is fetched whole, not paginated -- nothing
          // further to add on subsequent "Load More" pages.
          return [];
        }
        final filmography = await getPersonFilmography(params.personId!);
        final targetType = isMovies ? MediaType.movie : MediaType.tv;
        return filmography.where((item) => item.type == targetType).toList();
      }

      final endpoint = isMovies ? '/discover/movie' : '/discover/tv';
      final queryParams = <String, dynamic>{
        'page': page,
        'include_adult': false,
      };
      if (params.genreId != null) {
        queryParams['with_genres'] = params.genreId;
      } else if (params.genreName != null && params.genreName!.isNotEmpty) {
        final entry = _genreMap.entries.cast<MapEntry<int, String>?>().firstWhere(
              (e) => e!.value.toLowerCase() == params.genreName!.toLowerCase(),
              orElse: () => null,
            );
        if (entry != null) {
          queryParams['with_genres'] = entry.key;
        }
      }
      if (params.keywordId != null) {
        queryParams['with_keywords'] = params.keywordId;
      }
      if (params.personId != null) queryParams['with_people'] = params.personId;
      if (params.providerId != null) {
        queryParams['with_watch_providers'] = params.providerId;
      }
      if (params.watchRegion != null && params.watchRegion!.isNotEmpty) {
        queryParams['watch_region'] = params.watchRegion;
      }
      if (params.minRuntime != null) {
        queryParams['with_runtime.gte'] = params.minRuntime;
      }
      if (params.maxRuntime != null) {
        queryParams['with_runtime.lte'] = params.maxRuntime;
      }
      if (params.minVoteCount != null) {
        queryParams['vote_count.gte'] = params.minVoteCount;
      }
      if (params.originalLanguage != null &&
          params.originalLanguage!.isNotEmpty) {
        queryParams['with_original_language'] = params.originalLanguage;
      }
      if (!isMovies && params.tvNetworkId != null) {
        queryParams['with_networks'] = params.tvNetworkId;
      }
      if (!isMovies &&
          params.tvStatus != null &&
          params.tvStatus!.isNotEmpty) {
        queryParams['with_status'] = params.tvStatus;
      }
      if (params.releaseYear != null) {
        if (isMovies) {
          queryParams['primary_release_year'] = params.releaseYear;
        } else {
          queryParams['first_air_date_year'] = params.releaseYear;
        }
      }
      if (params.minRating != null) {
        queryParams['vote_average.gte'] = params.minRating;
      }
      queryParams['sort_by'] = params.sortBy;

      final key = cacheService.generateKey(endpoint, queryParams);
      Map<String, dynamic>? res = await cacheService.get(key);
      if (res == null) {
        res = isMovies
            ? await apiService.discoverMovies(params: params, page: page)
            : await apiService.discoverTvShows(params: params, page: page);
        await cacheService.put(key, res);
      }
      final results =
          (res['results'] as List?)?.cast<Map<String, dynamic>>() ?? [];
      return results
          .map((item) => _mapJsonToMediaItem(
                item,
                overrideType: isMovies ? MediaType.movie : MediaType.tv,
              ))
          .toList();
    } catch (e, stack) {
      _logError('Failed to discover media from TMDB API.', e, stack);
      if (fallbackRepository != null) {
        return fallbackRepository!.discoverMedia(
          isMovies: isMovies,
          params: params,
          page: page,
        );
      }
      rethrow;
    }
  }

  @override
  Future<List<Map<String, dynamic>>> searchPersons(String query) async {
    if (!isConfigured) {
      _logWarning('TMDB token is missing or unconfigured.');
      if (fallbackRepository != null) {
        return fallbackRepository!.searchPersons(query);
      }
      return [];
    }
    try {
      final key = cacheService.generateKey('/search/person', {
        'query': query,
        'page': 1,
        'include_adult': false,
      });
      Map<String, dynamic>? res =
          await cacheService.get(key, isSessionOnly: true);
      if (res == null) {
        res = await apiService.searchPersons(query);
        await cacheService.put(key, res, isSessionOnly: true);
      }
      final results =
          (res['results'] as List?)?.cast<Map<String, dynamic>>() ?? [];
      return results;
    } catch (e, stack) {
      _logError(
          'Failed to search persons for query "$query" from TMDB API.',
          e,
          stack);
      if (fallbackRepository != null) {
        return fallbackRepository!.searchPersons(query);
      }
      return [];
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

    final releaseStr = json['release_date'] as String?;
    final airStr = json['first_air_date'] as String?;
    final dateStr = (releaseStr != null && releaseStr.trim().isNotEmpty)
        ? releaseStr.trim()
        : ((airStr != null && airStr.trim().isNotEmpty) ? airStr.trim() : null);
    DateTime? releaseOrAirDate;
    if (dateStr != null) {
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
    List<MediaVideo>? trailers;
    final videosObj = json['videos'] as Map<String, dynamic>?;
    if (videosObj != null && videosObj['results'] is List) {
      final videoList = videosObj['results'] as List;

      final parsedTrailers = <MediaVideo>[];
      for (final item in videoList) {
        if (item is! Map) continue;
        final map = item.cast<String, dynamic>();
        final id = map['id']?.toString() ?? '';
        final key = map['key']?.toString() ?? '';
        final name = map['name']?.toString() ?? '';
        final typeStr = map['type']?.toString() ?? '';
        final site = map['site']?.toString() ?? '';
        final official = map['official'] == true;

        if (site == 'YouTube' &&
            (typeStr == 'Trailer' || typeStr == 'Teaser') &&
            key.isNotEmpty) {
          parsedTrailers.add(MediaVideo(
            id: id,
            key: key,
            name: name,
            type: typeStr,
            site: site,
            official: official,
          ));
        }
      }
      if (parsedTrailers.isNotEmpty) {
        trailers = parsedTrailers;
      }

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

    final parsedDirectors = <MediaCastMember>[];
    final seenDirectorIds = <String>{};

    void addDirector(String id, String name, String? profilePath, {String role = 'Director'}) {
      if (name.trim().isNotEmpty && seenDirectorIds.add(id.isNotEmpty ? id : name)) {
        parsedDirectors.add(MediaCastMember(
          id: id,
          name: name.trim(),
          profileUrl: TmdbImageHelper.getCastHeadshotUrl(profilePath),
          role: role,
        ));
      }
    }

    if (creditsObj != null && creditsObj['crew'] is List) {
      for (final member in creditsObj['crew'] as List) {
        if (member is Map &&
            member['job'] == 'Director' &&
            member['name'] != null) {
          final id = member['id']?.toString() ?? '';
          final name = member['name'].toString();
          final profilePath = member['profile_path'] as String?;
          addDirector(id, name, profilePath, role: 'Director');
        }
      }
    }

    if (json['created_by'] is List) {
      for (final creator in json['created_by'] as List) {
        if (creator is Map && creator['name'] != null) {
          final id = creator['id']?.toString() ?? '';
          final name = creator['name'].toString();
          final profilePath = creator['profile_path'] as String?;
          addDirector(id, name, profilePath, role: 'Creator');
        }
      }
    }

    String? director;
    if (parsedDirectors.isNotEmpty) {
      director = parsedDirectors.map((d) => d.name).join(', ');
    } else if (type == MediaType.movie) {
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

    final originalLanguage = json['original_language'] as String?;
    List<String>? spokenLanguages;
    if (json['spoken_languages'] is List) {
      final spokenList = <String>[];
      for (final item in json['spoken_languages'] as List) {
        if (item is Map) {
          final englishName = item['english_name'] as String?;
          final name = item['name'] as String?;
          if (englishName != null && englishName.isNotEmpty) {
            spokenList.add(englishName);
          } else if (name != null && name.isNotEmpty) {
            spokenList.add(name);
          }
        }
      }
      if (spokenList.isNotEmpty) {
        spokenLanguages = spokenList;
      }
    }

    final status = json['status'] as String?;

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
      trailers: trailers,
      watchProviders: watchProviders,
      watchProvidersByCountry: watchProvidersByCountry,
      cast: cast,
      castMembers: castMembers,
      tagline: tagline,
      director: director,
      directors: parsedDirectors.isNotEmpty ? parsedDirectors : null,
      certification: certification,
      belongsToCollection: belongsToCollection,
      createdBy: createdBy,
      networks: networks,
      voteCount: voteCount,
      keywords: keywords,
      imdbId: imdbId,
      productionCompanies: productionCompanies,
      originalLanguage: originalLanguage,
      spokenLanguages: spokenLanguages,
      status: status,
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

  TvSeason _mapJsonToTvSeason(Map<String, dynamic> json) {
    final seasonId = (json['id'] as num?)?.toInt() ?? 0;
    final seasonNum = (json['season_number'] as num?)?.toInt() ?? 1;
    final name = json['name'] as String? ?? 'Season $seasonNum';
    final overview = json['overview'] as String?;
    final posterPath = json['poster_path'] as String?;
    final posterUrl = TmdbImageHelper.getPosterThumbnailUrl(posterPath);
    DateTime? airDate;
    final airDateStr = json['air_date'] as String?;
    if (airDateStr != null && airDateStr.isNotEmpty) {
      airDate = DateTime.tryParse(airDateStr);
    }
    final episodesJson =
        (json['episodes'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final episodes = episodesJson.map((ep) {
      final epId = (ep['id'] as num?)?.toInt() ?? 0;
      final epNum = (ep['episode_number'] as num?)?.toInt() ?? 1;
      final epSeasonNum = (ep['season_number'] as num?)?.toInt() ?? seasonNum;
      final epName = ep['name'] as String? ?? 'Episode $epNum';
      final epOverview = ep['overview'] as String?;
      final epStillPath = ep['still_path'] as String?;
      final epStillUrl = TmdbImageHelper.w500(epStillPath);
      DateTime? epAirDate;
      final epAirDateStr = ep['air_date'] as String?;
      if (epAirDateStr != null && epAirDateStr.isNotEmpty) {
        epAirDate = DateTime.tryParse(epAirDateStr);
      }
      final epVote = (ep['vote_average'] as num?)?.toDouble();
      final epRuntime = (ep['runtime'] as num?)?.toInt();
      return TvEpisode(
        id: epId,
        episodeNumber: epNum,
        seasonNumber: epSeasonNum,
        name: epName,
        overview: epOverview,
        stillUrl: epStillUrl,
        airDate: epAirDate,
        voteAverage: epVote,
        runtime: epRuntime,
      );
    }).toList();

    return TvSeason(
      id: seasonId,
      seasonNumber: seasonNum,
      name: name,
      overview: overview,
      posterUrl: posterUrl,
      airDate: airDate,
      episodes: episodes,
    );
  }

  @override
  Future<List<MediaItem>> getRecommendations(String mediaId) async {
    if (!isConfigured) {
      if (fallbackRepository != null) {
        return fallbackRepository!.getRecommendations(mediaId);
      }
      return [];
    }
    try {
      await _ensureGenresLoaded();
      String cleanId = mediaId;
      bool isMovie = true;
      if (mediaId.startsWith('tv_') || mediaId.startsWith('tv:')) {
        cleanId = mediaId.substring(3);
        isMovie = false;
      } else if (mediaId.startsWith('movie_') || mediaId.startsWith('movie:')) {
        cleanId = mediaId.substring(6);
        isMovie = true;
      }
      final endpoint = isMovie ? '/movie/$cleanId/recommendations' : '/tv/$cleanId/recommendations';
      final key = cacheService.generateKey(endpoint, {'page': 1, 'include_adult': false});
      Map<String, dynamic>? res = await cacheService.get(key);
      if (res == null) {
        res = isMovie
            ? await apiService.getMovieRecommendations(cleanId)
            : await apiService.getTvRecommendations(cleanId);
        await cacheService.put(key, res);
      }
      final results = (res['results'] as List?)?.cast<Map<String, dynamic>>() ?? [];
      return results
          .map((item) => _mapJsonToMediaItem(item, overrideType: isMovie ? MediaType.movie : MediaType.tv))
          .toList();
    } catch (e, stack) {
      _logError('Failed to fetch recommendations for $mediaId', e, stack);
      if (fallbackRepository != null) {
        return fallbackRepository!.getRecommendations(mediaId);
      }
      return [];
    }
  }

  @override
  Future<List<MediaItem>> getSimilarMedia(String mediaId) async {
    if (!isConfigured) {
      if (fallbackRepository != null) {
        return fallbackRepository!.getSimilarMedia(mediaId);
      }
      return [];
    }
    try {
      await _ensureGenresLoaded();
      String cleanId = mediaId;
      bool isMovie = true;
      if (mediaId.startsWith('tv_') || mediaId.startsWith('tv:')) {
        cleanId = mediaId.substring(3);
        isMovie = false;
      } else if (mediaId.startsWith('movie_') || mediaId.startsWith('movie:')) {
        cleanId = mediaId.substring(6);
        isMovie = true;
      }
      final endpoint = isMovie ? '/movie/$cleanId/similar' : '/tv/$cleanId/similar';
      final key = cacheService.generateKey(endpoint, {'page': 1, 'include_adult': false});
      Map<String, dynamic>? res = await cacheService.get(key);
      if (res == null) {
        res = isMovie
            ? await apiService.getSimilarMovies(cleanId)
            : await apiService.getSimilarTvShows(cleanId);
        await cacheService.put(key, res);
      }
      final results = (res['results'] as List?)?.cast<Map<String, dynamic>>() ?? [];
      return results
          .map((item) => _mapJsonToMediaItem(item, overrideType: isMovie ? MediaType.movie : MediaType.tv))
          .toList();
    } catch (e, stack) {
      _logError('Failed to fetch similar media for $mediaId', e, stack);
      if (fallbackRepository != null) {
        return fallbackRepository!.getSimilarMedia(mediaId);
      }
      return [];
    }
  }

  @override
  Future<List<MediaItem>> getPersonFilmography(int personId) async {
    if (!isConfigured) {
      if (fallbackRepository != null) {
        return fallbackRepository!.getPersonFilmography(personId);
      }
      return [];
    }
    try {
      await _ensureGenresLoaded();

      final movieKey =
          cacheService.generateKey('/person/$personId/movie_credits');
      Map<String, dynamic>? movieRes = await cacheService.get(movieKey);
      if (movieRes == null) {
        movieRes = await apiService.getPersonMovieCredits('$personId');
        await cacheService.put(movieKey, movieRes);
      }

      final tvKey = cacheService.generateKey('/person/$personId/tv_credits');
      Map<String, dynamic>? tvRes = await cacheService.get(tvKey);
      if (tvRes == null) {
        tvRes = await apiService.getPersonTvCredits('$personId');
        await cacheService.put(tvKey, tvRes);
      }

      final items = <MediaItem>[];
      final seenIds = <String>{};

      void addCredits(Map<String, dynamic> res, MediaType type) {
        final cast =
            (res['cast'] as List?)?.cast<Map<String, dynamic>>() ?? [];
        final crew =
            (res['crew'] as List?)?.cast<Map<String, dynamic>>() ?? [];
        for (final json in [...cast, ...crew]) {
          if (!apiService.isValidSearchItem(json)) continue;
          final item = _mapJsonToMediaItem(json, overrideType: type);
          if (seenIds.add(item.prefixedId)) {
            items.add(item);
          }
        }
      }

      addCredits(movieRes, MediaType.movie);
      addCredits(tvRes, MediaType.tv);

      return items;
    } catch (e, stack) {
      _logError('Failed to fetch filmography for person $personId', e, stack);
      if (fallbackRepository != null) {
        return fallbackRepository!.getPersonFilmography(personId);
      }
      return [];
    }
  }

  @override
  Future<MediaCollectionDetail?> getCollectionDetails(int collectionId) async {
    try {
      final key = cacheService.generateKey('/collection/$collectionId', {});
      Map<String, dynamic>? res = await cacheService.get(key);
      if (res == null) {
        res = await apiService.getCollectionDetails(collectionId);
        await cacheService.put(key, res);
      }
      final partsJson = res['parts'] as List? ?? [];
      final parts = partsJson
          .map((p) => _mapJsonToMediaItem(p as Map<String, dynamic>, overrideType: MediaType.movie))
          .toList();
      return MediaCollectionDetail(
        id: res['id'] as int? ?? collectionId,
        name: res['name'] as String? ?? 'Collection',
        overview: res['overview'] as String?,
        posterUrl: TmdbImageHelper.getPosterThumbnailUrl(res['poster_path'] as String?),
        backdropUrl: TmdbImageHelper.getBackdropUrl(res['backdrop_path'] as String?),
        parts: parts,
      );
    } catch (e, stack) {
      _logError('Failed to fetch collection details for $collectionId', e, stack);
      if (fallbackRepository != null) {
        return fallbackRepository!.getCollectionDetails(collectionId);
      }
      return null;
    }
  }
}

