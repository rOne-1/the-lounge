import 'dart:developer' as developer;
import 'package:flutter/foundation.dart' show kReleaseMode;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/discover_filter_params.dart';
import '../models/media_item.dart';
import 'media_provider.dart';
import '../repositories/anime_filtered_movie_repository.dart';
import '../repositories/mock_movie_repository.dart';
import '../repositories/movie_repository.dart';
import '../repositories/tmdb_movie_repository.dart';
import '../services/tmdb_api_service.dart';

/// Provider for [TmdbApiService] using environment token if available.
///
/// Codes are TMDB's own `original_language` values (ISO 639-1, plus TMDB's
/// non-standard 'cn' for Cantonese). Expanded 2026-08-15 from an initial
/// 21-language list that covered only one Indian language (Hindi) despite
/// the app being used for Korean, Japanese, and Indian-language content --
/// every major Indian regional-language film/TV industry is now included,
/// alongside broader world-cinema coverage.
const List<Map<String, String>> supportedLanguages = [
  {'code': 'en', 'name': 'English'},
  {'code': 'ja', 'name': 'Japanese'},
  {'code': 'fr', 'name': 'French'},
  {'code': 'es', 'name': 'Spanish'},
  {'code': 'de', 'name': 'German'},
  {'code': 'ko', 'name': 'Korean'},
  {'code': 'it', 'name': 'Italian'},
  {'code': 'pt', 'name': 'Portuguese'},
  {'code': 'zh', 'name': 'Mandarin'},
  {'code': 'cn', 'name': 'Cantonese'},
  {'code': 'ru', 'name': 'Russian'},
  {'code': 'sv', 'name': 'Swedish'},
  {'code': 'pl', 'name': 'Polish'},
  {'code': 'da', 'name': 'Danish'},
  {'code': 'no', 'name': 'Norwegian'},
  {'code': 'nl', 'name': 'Dutch'},
  {'code': 'tr', 'name': 'Turkish'},
  {'code': 'th', 'name': 'Thai'},
  {'code': 'ar', 'name': 'Arabic'},
  {'code': 'vi', 'name': 'Vietnamese'},
  // Indian languages -- each has its own major film/TV industry on TMDB.
  {'code': 'hi', 'name': 'Hindi'},
  {'code': 'ta', 'name': 'Tamil'},
  {'code': 'te', 'name': 'Telugu'},
  {'code': 'ml', 'name': 'Malayalam'},
  {'code': 'kn', 'name': 'Kannada'},
  {'code': 'bn', 'name': 'Bengali'},
  {'code': 'mr', 'name': 'Marathi'},
  {'code': 'pa', 'name': 'Punjabi'},
  {'code': 'gu', 'name': 'Gujarati'},
  {'code': 'ur', 'name': 'Urdu'},
  {'code': 'or', 'name': 'Odia'},
  {'code': 'as', 'name': 'Assamese'},
  // Broader world-cinema coverage.
  {'code': 'id', 'name': 'Indonesian'},
  {'code': 'ms', 'name': 'Malay'},
  {'code': 'tl', 'name': 'Filipino'},
  {'code': 'fa', 'name': 'Persian'},
  {'code': 'he', 'name': 'Hebrew'},
  {'code': 'el', 'name': 'Greek'},
  {'code': 'hu', 'name': 'Hungarian'},
  {'code': 'cs', 'name': 'Czech'},
  {'code': 'ro', 'name': 'Romanian'},
  {'code': 'fi', 'name': 'Finnish'},
  {'code': 'uk', 'name': 'Ukrainian'},
  {'code': 'sr', 'name': 'Serbian'},
  {'code': 'hr', 'name': 'Croatian'},
  {'code': 'bg', 'name': 'Bulgarian'},
  {'code': 'sk', 'name': 'Slovak'},
  {'code': 'is', 'name': 'Icelandic'},
  {'code': 'ka', 'name': 'Georgian'},
  {'code': 'hy', 'name': 'Armenian'},
  {'code': 'mn', 'name': 'Mongolian'},
  {'code': 'my', 'name': 'Burmese'},
  {'code': 'km', 'name': 'Khmer'},
  {'code': 'lo', 'name': 'Lao'},
  {'code': 'ne', 'name': 'Nepali'},
  {'code': 'si', 'name': 'Sinhala'},
  {'code': 'sw', 'name': 'Swahili'},
  {'code': 'af', 'name': 'Afrikaans'},
  {'code': 'ca', 'name': 'Catalan'},
];

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

/// Whether this binary is a release build. Wraps [kReleaseMode] behind a
/// provider so tests can override it instead of relying on the real,
/// non-overridable compile-time constant (which is always false under
/// `flutter test`).
final isReleaseBuildProvider = Provider<bool>((ref) => kReleaseMode);

/// Provider for [MovieRepository], automatically using [TmdbMovieRepository]
/// if TMDB token is valid, or falling back to [MockMovieRepository] in
/// debug/profile builds only. A release build with a missing or placeholder
/// token must never silently serve fake data — it stays on an unconfigured
/// [TmdbMovieRepository] instead, and [shouldShowConfigurationErrorProvider]
/// gates the app on an explicit configuration-error state before any of its
/// (would-be-empty/failing) calls are made.
final movieRepositoryProvider = Provider<MovieRepository>((ref) {
  final apiService = ref.watch(tmdbApiServiceProvider);
  final isRelease = ref.watch(isReleaseBuildProvider);

  // E3/TF-7-a: strict anime exclusion, wrapped around whichever concrete
  // repository is chosen below so every current and future call site gets
  // it for free (see AnimeFilteredMovieRepository's own doc comment).
  if (!apiService.hasToken) {
    if (isRelease) {
      developer.log(
        'TMDB_READ_ACCESS_TOKEN not found or default placeholder used in a '
        'release build. Refusing to fall back to MockMovieRepository — the '
        'app will show a configuration-error state instead.',
        name: 'RepositoryProvider',
      );
      return AnimeFilteredMovieRepository(TmdbMovieRepository(apiService: apiService));
    }
    developer.log(
      'TMDB_READ_ACCESS_TOKEN not found or default placeholder used. Falling back to MockMovieRepository.',
      name: 'RepositoryProvider',
    );
    return AnimeFilteredMovieRepository(MockMovieRepository());
  }

  return AnimeFilteredMovieRepository(TmdbMovieRepository(apiService: apiService));
});

/// Provider indicating whether the app is currently running in mock repository mode.
final isUsingMockRepositoryProvider = Provider<bool>((ref) {
  final wrapped = ref.watch(movieRepositoryProvider);
  final repo = wrapped is AnimeFilteredMovieRepository ? wrapped.inner : wrapped;
  if (repo is MockMovieRepository) return true;
  if (repo is TmdbMovieRepository) return !repo.isConfigured;
  return false;
});

/// True only when this is a release build with no valid TMDB token — the
/// one case the app must refuse to render normally (see B6/D2 in the triage
/// report). The app root should show an explicit configuration-error state
/// instead of navigating into the shell.
final shouldShowConfigurationErrorProvider = Provider<bool>((ref) {
  if (!ref.watch(isReleaseBuildProvider)) return false;
  return ref.watch(isUsingMockRepositoryProvider);
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
  final country = ref.watch(mediaProvider.select((s) => s.watchProvidersCountry));
  return repo.getNowPlayingMovies(region: country);
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

final mediaRecommendationsProvider =
    FutureProvider.family<List<MediaItem>, String>((ref, id) async {
  final repo = ref.watch(movieRepositoryProvider);
  final mediaState = ref.read(mediaProvider);

  final excludedIds = <String>{
    ...mediaState.watchlist.keys,
    ...mediaState.maybeList.keys,
    ...mediaState.watchingList.keys,
    ...mediaState.watchedList.keys,
    ...mediaState.droppedList.keys,
    ...mediaState.onHoldList.keys,
  };

  bool isExcluded(MediaItem item) {
    final cleanId = item.id.replaceFirst(RegExp(r'^(movie_|tv_)'), '');
    return excludedIds.contains(item.id) ||
        excludedIds.contains(item.prefixedId) ||
        excludedIds.contains(cleanId);
  }

  final rawList = await repo.getRecommendations(id);
  return rawList.where((item) => !isExcluded(item)).toList();
});

final similarMediaProvider =
    FutureProvider.family<List<MediaItem>, String>((ref, id) async {
  final repo = ref.watch(movieRepositoryProvider);
  final mediaState = ref.read(mediaProvider);

  final excludedIds = <String>{
    ...mediaState.watchlist.keys,
    ...mediaState.maybeList.keys,
    ...mediaState.watchingList.keys,
    ...mediaState.watchedList.keys,
    ...mediaState.droppedList.keys,
    ...mediaState.onHoldList.keys,
  };

  bool isExcluded(MediaItem item) {
    final cleanId = item.id.replaceFirst(RegExp(r'^(movie_|tv_)'), '');
    return excludedIds.contains(item.id) ||
        excludedIds.contains(item.prefixedId) ||
        excludedIds.contains(cleanId);
  }

  final rawList = await repo.getSimilarMedia(id);
  return rawList.where((item) => !isExcluded(item)).toList();
});



