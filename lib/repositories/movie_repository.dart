import '../models/discover_filter_params.dart';
import '../models/media_item.dart';

abstract class MovieRepository {
  Future<List<MediaItem>> getTrendingMovies();
  Future<List<MediaItem>> getPopularMovies();
  Future<List<MediaItem>> getTrendingTvShows();
  Future<List<MediaItem>> getTopRatedMovies();
  Future<List<MediaItem>> getTopRatedTvShows();
  Future<List<MediaItem>> getNowPlayingMovies();
  Future<List<MediaItem>> getAiringTodayTvShows();
  Future<List<MediaItem>> getUpcomingMovies();
  Future<List<MediaItem>> getOnTheAirTvShows();
  Future<MediaItem?> getMediaDetails(String id);
  Future<TvSeason?> getTvSeasonDetails(String tvId, int seasonNumber);
  Future<List<MediaItem>> searchMedia(String query);
  Future<List<Map<String, String>>> getWatchProviderRegions();
  Future<List<MediaItem>> discoverMedia({
    required bool isMovies,
    required DiscoverFilterParams params,
  });
  Future<List<Map<String, dynamic>>> searchPersons(String query);
}
