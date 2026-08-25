import '../models/discover_filter_params.dart';
import '../models/media_item.dart';
import '../models/media_collection_detail.dart';

abstract class MovieRepository {
  // LANG-2 (2nd pass, 2026-08-19): originalLanguage on these 9 fixed-list
  // methods, when provided, must be honored server-side (TMDB
  // with_original_language) rather than the caller filtering the returned
  // page client-side -- these lists are globally-weighted/English-dominated,
  // so a regional-language lock can have zero matches on any given page of
  // the unfiltered list. See TmdbMovieRepository's implementations.
  Future<List<MediaItem>> getTrendingMovies({int page = 1, String? originalLanguage});
  Future<List<MediaItem>> getPopularMovies({int page = 1, String? originalLanguage});
  Future<List<MediaItem>> getTrendingTvShows({int page = 1, String? originalLanguage});
  Future<List<MediaItem>> getTopRatedMovies({int page = 1, String? originalLanguage});
  Future<List<MediaItem>> getTopRatedTvShows({int page = 1, String? originalLanguage});
  Future<List<MediaItem>> getNowPlayingMovies({int page = 1, String? region, String? originalLanguage});
  Future<List<MediaItem>> getAiringTodayTvShows({int page = 1, String? originalLanguage});
  // BETA3-NET-2: region, when provided, is passed as /discover/movie's own
  // `region` param -- it biases which release date TMDB uses to evaluate
  // the primary_release_date.gte filter for a title with region-specific
  // release dates, the same way getNowPlayingMovies' region already works.
  Future<List<MediaItem>> getUpcomingMovies({int page = 1, String? region, String? originalLanguage});
  Future<List<MediaItem>> getOnTheAirTvShows({int page = 1, String? originalLanguage});
  // DATA-CERT-1: region, when provided, resolves which country's
  // certification/content rating MediaItem.certification reports (movie
  // release_dates / TV content_ratings are per-country) -- falls back to
  // 'US' when omitted or when the requested region has no explicit
  // certification, same convention as getNowPlayingMovies/getUpcomingMovies'
  // region param above.
  Future<MediaItem?> getMediaDetails(String id, {String? region});
  Future<TvSeason?> getTvSeasonDetails(String tvId, int seasonNumber);
  Future<List<MediaItem>> searchMedia(String query);
  Future<List<Map<String, String>>> getWatchProviderRegions();
  Future<List<MediaItem>> discoverMedia({
    required bool isMovies,
    required DiscoverFilterParams params,
    int page = 1,
  });
  Future<List<Map<String, dynamic>>> searchPersons(String query);

  /// This person's real filmography (movie + TV, cast + crew), used to
  /// power cast/crew name search with an actual body of work instead of
  /// TMDB's narrow "known for" sample. Default no-op so existing
  /// implementers don't need to add it unless they want to support it.
  Future<List<MediaItem>> getPersonFilmography(int personId) async => [];

  Future<List<MediaItem>> getRecommendations(String mediaId) async => [];
  Future<List<MediaItem>> getSimilarMedia(String mediaId) async => [];
  Future<MediaCollectionDetail?> getCollectionDetails(int collectionId) async => null;
}
