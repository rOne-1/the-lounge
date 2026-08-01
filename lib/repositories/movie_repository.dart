import '../models/media_item.dart';

abstract class MovieRepository {
  Future<List<MediaItem>> getTrendingMovies();
  Future<List<MediaItem>> getPopularMovies();
  Future<List<MediaItem>> getTrendingTvShows();
  Future<MediaItem?> getMediaDetails(String id);
  Future<List<MediaItem>> searchMedia(String query);
}
