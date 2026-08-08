import '../models/discover_filter_params.dart';
import '../models/media_item.dart';
import '../models/media_collection_detail.dart';

abstract class MovieRepository {
  Future<List<MediaItem>> getTrendingMovies({int page = 1});
  Future<List<MediaItem>> getPopularMovies({int page = 1});
  Future<List<MediaItem>> getTrendingTvShows({int page = 1});
  Future<List<MediaItem>> getTopRatedMovies({int page = 1});
  Future<List<MediaItem>> getTopRatedTvShows({int page = 1});
  Future<List<MediaItem>> getNowPlayingMovies({int page = 1, String? region});
  Future<List<MediaItem>> getAiringTodayTvShows({int page = 1});
  Future<List<MediaItem>> getUpcomingMovies({int page = 1});
  Future<List<MediaItem>> getOnTheAirTvShows({int page = 1});
  Future<MediaItem?> getMediaDetails(String id);
  Future<TvSeason?> getTvSeasonDetails(String tvId, int seasonNumber);
  Future<List<MediaItem>> searchMedia(String query);
  Future<List<Map<String, String>>> getWatchProviderRegions();
  Future<List<MediaItem>> discoverMedia({
    required bool isMovies,
    required DiscoverFilterParams params,
    int page = 1,
  });
  Future<List<Map<String, dynamic>>> searchPersons(String query);
  Future<List<MediaItem>> getRecommendations(String mediaId) async => [];
  Future<List<MediaItem>> getSimilarMedia(String mediaId) async => [];
  Future<MediaCollectionDetail?> getCollectionDetails(int collectionId) async => null;
}
