import 'dart:convert';
import 'dart:developer' as developer;
import 'package:shared_preferences/shared_preferences.dart';

class _CacheRecord {
  final DateTime timestamp;
  final Map<String, dynamic> data;

  const _CacheRecord({
    required this.timestamp,
    required this.data,
  });
}

/// Service for caching TMDB API JSON responses with differentiated TTLs and disk/session persistence.
class TmdbLocalCacheService {
  /// TTL for Trending, Popular, Discover lists and Genres: 6 hours
  static const Duration trendingPopularTtl = Duration(hours: 6);

  /// TTL for Details, Credits, Videos, and Season Details: 7 days
  static const Duration detailsTtl = Duration(days: 7);

  /// TTL for Watch Providers: 24 hours
  static const Duration watchProvidersTtl = Duration(hours: 24);

  static const String keyPrefix = 'tmdb_cache_';

  final SharedPreferences? _prefs;
  final DateTime Function() _clock;

  /// In-memory cache for search results (session-only, not saved to persistent disk)
  final Map<String, _CacheRecord> _sessionCache = {};

  TmdbLocalCacheService({
    SharedPreferences? prefs,
    DateTime Function()? clock,
  })  : _prefs = prefs,
        _clock = clock ?? DateTime.now;

  /// Helper to generate a consistent cache key for an endpoint and query parameters.
  String generateKey(String endpoint, [Map<String, dynamic>? queryParameters]) {
    if (queryParameters == null || queryParameters.isEmpty) {
      return endpoint;
    }
    final sortedKeys = queryParameters.keys.toList()..sort();
    final queryParts = <String>[];
    for (final key in sortedKeys) {
      final value = queryParameters[key];
      if (value != null) {
        queryParts.add('$key=${value.toString()}');
      }
    }
    if (queryParts.isEmpty) return endpoint;
    return '$endpoint?${queryParts.join('&')}';
  }

  /// Determines default TTL duration based on endpoint path pattern.
  Duration getTtlForEndpoint(String endpoint) {
    if (endpoint.contains('/watch/providers')) {
      return watchProvidersTtl;
    }
    if (endpoint.contains('/trending/') ||
        endpoint.contains('/popular') ||
        endpoint.contains('/discover/') ||
        endpoint.contains('/genre/')) {
      return trendingPopularTtl;
    }
    if (endpoint.contains('/movie/') || endpoint.contains('/tv/')) {
      return detailsTtl;
    }
    return trendingPopularTtl;
  }

  /// Checks whether a cache timestamp has passed its TTL.
  bool isExpired(DateTime timestamp, Duration ttl) {
    final now = _clock();
    return now.difference(timestamp) > ttl;
  }

  /// Retrieves cached JSON data if present and not expired.
  Future<Map<String, dynamic>?> get(
    String key, {
    Duration? ttl,
    bool isSessionOnly = false,
  }) async {
    final effectiveTtl = ttl ?? getTtlForEndpoint(key);

    if (isSessionOnly || key.contains('/search/')) {
      final record = _sessionCache[key];
      if (record == null) return null;
      if (isExpired(record.timestamp, effectiveTtl)) {
        _sessionCache.remove(key);
        return null;
      }
      return record.data;
    }

    try {
      final prefs = _prefs ?? await SharedPreferences.getInstance();
      final prefKey = '$keyPrefix$key';
      final jsonString = prefs.getString(prefKey);
      if (jsonString == null) return null;

      final decoded = jsonDecode(jsonString) as Map<String, dynamic>;
      final timestampMs = decoded['timestamp'] as int?;
      final data = decoded['data'] as Map<String, dynamic>?;

      if (timestampMs == null || data == null) {
        await prefs.remove(prefKey);
        return null;
      }

      final timestamp = DateTime.fromMillisecondsSinceEpoch(timestampMs);
      if (isExpired(timestamp, effectiveTtl)) {
        await prefs.remove(prefKey);
        return null;
      }

      return data;
    } catch (e, stack) {
      developer.log(
        'Failed to read from persistent cache key "$key". Falling back to session cache.',
        name: 'TmdbLocalCacheService',
        error: e,
        stackTrace: stack,
      );
      final record = _sessionCache[key];
      if (record == null) return null;
      if (isExpired(record.timestamp, effectiveTtl)) {
        _sessionCache.remove(key);
        return null;
      }
      return record.data;
    }
  }

  /// Stores JSON data in cache with current timestamp.
  Future<void> put(
    String key,
    Map<String, dynamic> data, {
    bool isSessionOnly = false,
  }) async {
    final now = _clock();

    if (isSessionOnly || key.contains('/search/')) {
      _sessionCache[key] = _CacheRecord(
        timestamp: now,
        data: data,
      );
      return;
    }

    try {
      final prefs = _prefs ?? await SharedPreferences.getInstance();
      final prefKey = '$keyPrefix$key';
      final payload = jsonEncode({
        'timestamp': now.millisecondsSinceEpoch,
        'data': data,
      });
      await prefs.setString(prefKey, payload);
    } catch (e, stack) {
      developer.log(
        'Failed to write to persistent cache key "$key". Falling back to session cache.',
        name: 'TmdbLocalCacheService',
        error: e,
        stackTrace: stack,
      );
      _sessionCache[key] = _CacheRecord(
        timestamp: now,
        data: data,
      );
    }
  }

  /// Cleans up all expired cache entries from both session memory and persistent storage.
  Future<void> clearExpired() async {
    final now = _clock();

    _sessionCache.removeWhere((key, record) {
      final ttl = getTtlForEndpoint(key);
      return now.difference(record.timestamp) > ttl;
    });

    try {
      final prefs = _prefs ?? await SharedPreferences.getInstance();
      final keys =
          prefs.getKeys().where((k) => k.startsWith(keyPrefix)).toList();

      for (final prefKey in keys) {
        final rawKey = prefKey.substring(keyPrefix.length);
        final ttl = getTtlForEndpoint(rawKey);
        final jsonString = prefs.getString(prefKey);
        if (jsonString != null) {
          try {
            final decoded = jsonDecode(jsonString) as Map<String, dynamic>;
            final timestampMs = decoded['timestamp'] as int?;
            if (timestampMs == null) {
              await prefs.remove(prefKey);
            } else {
              final timestamp = DateTime.fromMillisecondsSinceEpoch(timestampMs);
              if (now.difference(timestamp) > ttl) {
                await prefs.remove(prefKey);
              }
            }
          } catch (_) {
            await prefs.remove(prefKey);
          }
        }
      }
    } catch (e, stack) {
      developer.log(
        'Failed to clear expired items from persistent cache.',
        name: 'TmdbLocalCacheService',
        error: e,
        stackTrace: stack,
      );
    }
  }

  /// Clears all cache entries (session and persistent).
  Future<void> clearAll() async {
    _sessionCache.clear();
    try {
      final prefs = _prefs ?? await SharedPreferences.getInstance();
      final keys =
          prefs.getKeys().where((k) => k.startsWith(keyPrefix)).toList();
      for (final key in keys) {
        await prefs.remove(key);
      }
    } catch (e, stack) {
      developer.log(
        'Failed to clear all items from persistent cache.',
        name: 'TmdbLocalCacheService',
        error: e,
        stackTrace: stack,
      );
    }
  }
}
