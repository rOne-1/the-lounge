/// Helper functions and utilities for formatting context-aware TMDB image URLs.
class TmdbImageHelper {
  static const String baseUrl = 'https://image.tmdb.org/t/p';

  /// Helper to generate a full image URL given a TMDB path and size tier.
  static String? buildUrl(String? path, String size) {
    if (path == null || path.trim().isEmpty) return null;
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return path;
    }
    final cleanPath = path.startsWith('/') ? path : '/$path';
    return '$baseUrl/$size$cleanPath';
  }

  /// Poster thumbnail URL for grids and lists (w342).
  static String? getPosterThumbnailUrl(String? path) => buildUrl(path, 'w342');

  /// Detail poster URL for single item detail views (w500).
  static String? getDetailPosterUrl(String? path) => buildUrl(path, 'w500');

  /// Backdrop URL for hero banners and wide backdrops (w780).
  static String? getBackdropUrl(String? path) => buildUrl(path, 'w780');

  /// Cast headshot profile URL for cast list headshots (w185).
  static String? getCastHeadshotUrl(String? path) => buildUrl(path, 'w185');

  /// Image size tier aliases
  static String? w185(String? path) => buildUrl(path, 'w185');
  static String? w500(String? path) => buildUrl(path, 'w500');
  static String? w780(String? path) => buildUrl(path, 'w780');
}

/// Standalone top-level functions for convenience.
String? getPosterThumbnailUrl(String? path) => TmdbImageHelper.getPosterThumbnailUrl(path);
String? getDetailPosterUrl(String? path) => TmdbImageHelper.getDetailPosterUrl(path);
String? getBackdropUrl(String? path) => TmdbImageHelper.getBackdropUrl(path);
String? getCastHeadshotUrl(String? path) => TmdbImageHelper.getCastHeadshotUrl(path);
