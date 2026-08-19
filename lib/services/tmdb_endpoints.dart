/// Every TMDB API v3 endpoint path this app calls, centralized here rather
/// than scattered as inline string literals through [TmdbApiService]. Fixed
/// paths are plain constants; paths requiring an id are builder methods
/// that return the path with the id already interpolated.
class TmdbEndpoints {
  TmdbEndpoints._();

  static const String baseUrl = 'https://api.themoviedb.org/3';

  static const String configuration = '/configuration';

  static const String trendingMoviesWeek = '/trending/movie/week';
  static const String trendingTvShowsWeek = '/trending/tv/week';
  static const String popularMovies = '/movie/popular';
  static const String popularTvShows = '/tv/popular';
  static const String topRatedMovies = '/movie/top_rated';
  static const String topRatedTvShows = '/tv/top_rated';
  static const String nowPlayingMovies = '/movie/now_playing';
  static const String airingTodayTvShows = '/tv/airing_today';
  static const String upcomingMovies = '/movie/upcoming';
  static const String onTheAirTvShows = '/tv/on_the_air';

  static const String discoverMovies = '/discover/movie';
  static const String discoverTv = '/discover/tv';

  static const String movieGenres = '/genre/movie/list';
  static const String tvGenres = '/genre/tv/list';

  static const String searchMulti = '/search/multi';
  static const String searchPerson = '/search/person';

  static const String watchProviderRegions = '/watch/providers/regions';

  static String personMovieCredits(String personId) =>
      '/person/$personId/movie_credits';
  static String personTvCredits(String personId) =>
      '/person/$personId/tv_credits';

  static String movieDetails(String id) => '/movie/$id';
  static String tvDetails(String id) => '/tv/$id';
  static String movieCredits(String id) => '/movie/$id/credits';
  static String tvCredits(String id) => '/tv/$id/credits';
  static String movieVideos(String id) => '/movie/$id/videos';
  static String tvVideos(String id) => '/tv/$id/videos';
  static String movieWatchProviders(String id) => '/movie/$id/watch/providers';
  static String tvWatchProviders(String id) => '/tv/$id/watch/providers';
  static String tvSeasonDetails(String tvId, int seasonNumber) =>
      '/tv/$tvId/season/$seasonNumber';
  static String movieRecommendations(String id) => '/movie/$id/recommendations';
  static String tvRecommendations(String id) => '/tv/$id/recommendations';
  static String similarMovies(String id) => '/movie/$id/similar';
  static String similarTvShows(String id) => '/tv/$id/similar';
  static String collectionDetails(int collectionId) => '/collection/$collectionId';
}
