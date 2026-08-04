import 'dart:developer' as developer;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/discover_filter_params.dart';
import '../models/media_item.dart';
import '../repositories/mock_movie_repository.dart';
import '../repositories/movie_repository.dart';
import '../repositories/tmdb_movie_repository.dart';
import '../services/tmdb_api_service.dart';

/// Provider for [TmdbApiService] using environment token if available.
final tmdbApiServiceProvider = Provider<TmdbApiService>((ref) {
  String? token;
  try {
    if (dotenv.isInitialized) {
      token = dotenv.env['TMDB_READ_ACCESS_TOKEN'];
    }
  } catch (_) {}

  token ??= const String.fromEnvironment('TMDB_READ_ACCESS_TOKEN');

  return TmdbApiService(token: token);
});

/// Provider for [MovieRepository], automatically using [TmdbMovieRepository]
/// if TMDB token is valid, or falling back to [MockMovieRepository].
final movieRepositoryProvider = Provider<MovieRepository>((ref) {
  final apiService = ref.watch(tmdbApiServiceProvider);

  if (!apiService.hasToken) {
    developer.log(
      'TMDB_READ_ACCESS_TOKEN not found or default placeholder used. Falling back to MockMovieRepository.',
      name: 'RepositoryProvider',
    );
    return MockMovieRepository();
  }

  return TmdbMovieRepository(apiService: apiService);
});

/// Provider indicating whether the app is currently running in mock repository mode.
final isUsingMockRepositoryProvider = Provider<bool>((ref) {
  final repo = ref.watch(movieRepositoryProvider);
  if (repo is MockMovieRepository) return true;
  if (repo is TmdbMovieRepository) return !repo.isConfigured;
  return false;
});

final trendingMoviesProvider = FutureProvider<List<MediaItem>>((ref) async {
  final repo = ref.watch(movieRepositoryProvider);
  return repo.getTrendingMovies();
});

final trendingTvShowsProvider = FutureProvider<List<MediaItem>>((ref) async {
  final repo = ref.watch(movieRepositoryProvider);
  return repo.getTrendingTvShows();
});

final popularMoviesProvider = FutureProvider<List<MediaItem>>((ref) async {
  final repo = ref.watch(movieRepositoryProvider);
  return repo.getPopularMovies();
});

final mediaDetailsProvider =
    FutureProvider.family<MediaItem?, String>((ref, id) async {
  final repo = ref.watch(movieRepositoryProvider);
  return repo.getMediaDetails(id);
});

final watchProviderRegionsProvider =
    FutureProvider<List<Map<String, String>>>((ref) async {
  final repo = ref.watch(movieRepositoryProvider);
  return repo.getWatchProviderRegions();
});

final topRatedMoviesProvider = FutureProvider<List<MediaItem>>((ref) async {
  final repo = ref.watch(movieRepositoryProvider);
  return repo.getTopRatedMovies();
});

final topRatedTvShowsProvider = FutureProvider<List<MediaItem>>((ref) async {
  final repo = ref.watch(movieRepositoryProvider);
  return repo.getTopRatedTvShows();
});

final nowPlayingMoviesProvider = FutureProvider<List<MediaItem>>((ref) async {
  final repo = ref.watch(movieRepositoryProvider);
  return repo.getNowPlayingMovies();
});

final airingTodayTvShowsProvider = FutureProvider<List<MediaItem>>((ref) async {
  final repo = ref.watch(movieRepositoryProvider);
  return repo.getAiringTodayTvShows();
});

final upcomingMoviesProvider = FutureProvider<List<MediaItem>>((ref) async {
  final repo = ref.watch(movieRepositoryProvider);
  return repo.getUpcomingMovies();
});

final onTheAirTvShowsProvider = FutureProvider<List<MediaItem>>((ref) async {
  final repo = ref.watch(movieRepositoryProvider);
  return repo.getOnTheAirTvShows();
});

final tvSeasonDetailsProvider =
    FutureProvider.family<TvSeason?, ({String tvId, int seasonNumber})>(
        (ref, arg) async {
  final repo = ref.watch(movieRepositoryProvider);
  return repo.getTvSeasonDetails(arg.tvId, arg.seasonNumber);
});

final tvShowSeasonsProvider =
    FutureProvider.family<List<TvSeason>, MediaItem>((ref, item) async {
  final repo = ref.watch(movieRepositoryProvider);
  final seasonsCount = item.seasonsCount ?? 1;
  final List<TvSeason> seasons = [];
  for (int s = 1; s <= seasonsCount; s++) {
    final season = await repo.getTvSeasonDetails(item.id, s);
    if (season != null && season.episodes.isNotEmpty) {
      seasons.add(season);
    }
  }
  if (seasons.isNotEmpty) return seasons;

  final epTitles = item.episodesList;
  final epCount = epTitles?.length ?? item.episodesCount ?? 10;
  final episodes = List.generate(
    epCount,
    (i) => TvEpisode(
      id: i + 1,
      episodeNumber: i + 1,
      seasonNumber: 1,
      name: (epTitles != null && i < epTitles.length)
          ? epTitles[i]
          : 'Episode ${i + 1}',
    ),
  );
  return [
    TvSeason(id: 1, seasonNumber: 1, name: 'Season 1', episodes: episodes)
  ];
});

class DiscoverFilterNotifier extends Notifier<DiscoverFilterParams> {
  @override
  DiscoverFilterParams build() {
    return const DiscoverFilterParams();
  }

  void updateParams(DiscoverFilterParams params) {
    state = params;
  }

  void setGenre({int? genreId, String? genreName}) {
    state = state.copyWith(genreId: genreId, genreName: genreName);
  }

  void setKeyword({int? keywordId, String? keywordName}) {
    state = state.copyWith(keywordId: keywordId, keywordName: keywordName);
  }

  void setPerson({int? personId, String? personName}) {
    state = state.copyWith(personId: personId, personName: personName);
  }

  void setProvider(
      {int? providerId, String? providerName, String? watchRegion}) {
    state = state.copyWith(
      providerId: providerId,
      providerName: providerName,
      watchRegion: watchRegion,
    );
  }

  void setRuntime({int? minRuntime, int? maxRuntime}) {
    state = state.copyWith(minRuntime: minRuntime, maxRuntime: maxRuntime);
  }

  void setMinVoteCount(int? minVoteCount) {
    state = state.copyWith(minVoteCount: minVoteCount);
  }

  void setOriginalLanguage(String? originalLanguage) {
    state = state.copyWith(originalLanguage: originalLanguage);
  }

  void setTvNetwork({int? tvNetworkId, String? tvNetworkName}) {
    state =
        state.copyWith(tvNetworkId: tvNetworkId, tvNetworkName: tvNetworkName);
  }

  void setTvStatus(String? tvStatus) {
    state = state.copyWith(tvStatus: tvStatus);
  }

  void setSortBy(String sortBy) {
    state = state.copyWith(sortBy: sortBy);
  }

  void setReleaseYear(int? releaseYear) {
    state = state.copyWith(releaseYear: releaseYear);
  }

  void setMinRating(double? minRating) {
    state = state.copyWith(minRating: minRating);
  }

  void resetFilters() {
    state = const DiscoverFilterParams();
  }
}

final discoverFilterProvider =
    NotifierProvider<DiscoverFilterNotifier, DiscoverFilterParams>(() {
  return DiscoverFilterNotifier();
});

final discoverMediaProvider =
    FutureProvider.family<List<MediaItem>, bool>((ref, isMovies) async {
  final repo = ref.watch(movieRepositoryProvider);
  final filterParams = ref.watch(discoverFilterProvider);
  return repo.discoverMedia(isMovies: isMovies, params: filterParams);
});

final searchPersonsProvider =
    FutureProvider.family<List<Map<String, dynamic>>, String>(
        (ref, query) async {
  if (query.trim().isEmpty) return [];
  final repo = ref.watch(movieRepositoryProvider);
  return repo.searchPersons(query);
});



