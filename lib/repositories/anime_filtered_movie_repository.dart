import '../models/discover_filter_params.dart';
import '../models/media_item.dart';
import '../models/media_collection_detail.dart';
import '../utils/anime_filter.dart';
import 'movie_repository.dart';

/// E3/TF-7-a: strict anime exclusion from every discovery/browse surface.
///
/// Wraps any [MovieRepository] and filters anime out of every list-
/// returning method, so every current and future call site gets this for
/// free without needing to remember to filter individually (SP-1) --
/// rather than editing each of TmdbMovieRepository's ~15 list-returning
/// methods (and MockMovieRepository's) by hand, which would need to be
/// re-audited every time either gains a new method.
///
/// [getMediaDetails] (single-item lookup by ID) is deliberately NOT
/// filtered -- an anime title a user already saved before this filter
/// existed must stay reachable, not become a broken reference.
class AnimeFilteredMovieRepository implements MovieRepository {
  final MovieRepository inner;

  const AnimeFilteredMovieRepository(this.inner);

  @override
  Future<List<MediaItem>> getTrendingMovies({int page = 1, String? originalLanguage}) async =>
      (await inner.getTrendingMovies(page: page, originalLanguage: originalLanguage))
          .excludingAnime();

  @override
  Future<List<MediaItem>> getPopularMovies({int page = 1, String? originalLanguage}) async =>
      (await inner.getPopularMovies(page: page, originalLanguage: originalLanguage))
          .excludingAnime();

  @override
  Future<List<MediaItem>> getTrendingTvShows({int page = 1, String? originalLanguage}) async =>
      (await inner.getTrendingTvShows(page: page, originalLanguage: originalLanguage))
          .excludingAnime();

  @override
  Future<List<MediaItem>> getTopRatedMovies({int page = 1, String? originalLanguage}) async =>
      (await inner.getTopRatedMovies(page: page, originalLanguage: originalLanguage))
          .excludingAnime();

  @override
  Future<List<MediaItem>> getTopRatedTvShows({int page = 1, String? originalLanguage}) async =>
      (await inner.getTopRatedTvShows(page: page, originalLanguage: originalLanguage))
          .excludingAnime();

  @override
  Future<List<MediaItem>> getNowPlayingMovies(
          {int page = 1, String? region, String? originalLanguage}) async =>
      (await inner.getNowPlayingMovies(
              page: page, region: region, originalLanguage: originalLanguage))
          .excludingAnime();

  @override
  Future<List<MediaItem>> getAiringTodayTvShows({int page = 1, String? originalLanguage}) async =>
      (await inner.getAiringTodayTvShows(page: page, originalLanguage: originalLanguage))
          .excludingAnime();

  @override
  Future<List<MediaItem>> getUpcomingMovies({int page = 1, String? region, String? originalLanguage}) async =>
      (await inner.getUpcomingMovies(page: page, region: region, originalLanguage: originalLanguage))
          .excludingAnime();

  @override
  Future<List<MediaItem>> getOnTheAirTvShows({int page = 1, String? originalLanguage}) async =>
      (await inner.getOnTheAirTvShows(page: page, originalLanguage: originalLanguage))
          .excludingAnime();

  @override
  Future<MediaItem?> getMediaDetails(String id, {String? region}) =>
      inner.getMediaDetails(id, region: region);

  @override
  Future<TvSeason?> getTvSeasonDetails(String tvId, int seasonNumber) =>
      inner.getTvSeasonDetails(tvId, seasonNumber);

  @override
  Future<List<MediaItem>> searchMedia(String query) async =>
      (await inner.searchMedia(query)).excludingAnime();

  @override
  Future<List<Map<String, String>>> getWatchProviderRegions() =>
      inner.getWatchProviderRegions();

  @override
  Future<List<MediaItem>> discoverMedia({
    required bool isMovies,
    required DiscoverFilterParams params,
    int page = 1,
  }) async =>
      (await inner.discoverMedia(isMovies: isMovies, params: params, page: page))
          .excludingAnime();

  @override
  Future<List<Map<String, dynamic>>> searchPersons(String query) =>
      inner.searchPersons(query);

  @override
  Future<List<MediaItem>> getPersonFilmography(int personId) async =>
      (await inner.getPersonFilmography(personId)).excludingAnime();

  @override
  Future<List<MediaItem>> getRecommendations(String mediaId) async =>
      (await inner.getRecommendations(mediaId)).excludingAnime();

  @override
  Future<List<MediaItem>> getSimilarMedia(String mediaId) async =>
      (await inner.getSimilarMedia(mediaId)).excludingAnime();

  @override
  Future<MediaCollectionDetail?> getCollectionDetails(int collectionId) =>
      inner.getCollectionDetails(collectionId);
}
