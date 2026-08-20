import 'dart:async' show unawaited;
import 'dart:developer' as developer;
import 'package:flutter/foundation.dart' show kReleaseMode;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/discover_filter_params.dart';
import '../models/media_item.dart';
import 'ambiance_provider.dart';
import 'hall_provider.dart';
import 'media_provider.dart';
import '../repositories/anime_filtered_movie_repository.dart';
import '../repositories/mock_movie_repository.dart';
import '../repositories/movie_repository.dart';
import '../repositories/tmdb_movie_repository.dart';
import '../services/episode_skeleton_cache_service.dart';
import '../services/tmdb_api_service.dart';
import '../utils/bounded_concurrency.dart';

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

/// LANG-2 (2nd pass, 2026-08-19): TMDB's fixed-list endpoints (trending/
/// popular/top_rated/now_playing/upcoming/airing_today/on_the_air) have no
/// server-side content-language filter, and are globally-weighted/
/// English-dominated -- a first attempt at this (client-side filtering,
/// even backfilled across multiple pages) still left Lobby rails
/// near-empty for a real regional-language lock (dev-reported: TMDB's
/// trending/now-playing charts can go 100+ items deep with zero matches
/// for a language that isn't globally chart-topping). Fixed at the
/// repository layer instead: [MovieRepository]'s 9 fixed-list methods each
/// accept an optional `originalLanguage`, and when set, [TmdbMovieRepository]
/// routes through `/discover` with `with_original_language` applied
/// server-side (the same mechanism Search/Browse's [discoverMediaProvider]
/// already used correctly) -- TMDB does the real filtering, so every item
/// returned already matches; a genuinely thin rail for a niche
/// language+filter combination is an honest result, not a bug to backfill
/// around.
final trendingMoviesProvider = FutureProvider<List<MediaItem>>((ref) async {
  final repo = ref.watch(movieRepositoryProvider);
  final lockedLanguageCode = ref.watch(activeHallSpaceProvider).lockedLanguageCode;
  return repo.getTrendingMovies(originalLanguage: lockedLanguageCode);
});

final trendingTvShowsProvider = FutureProvider<List<MediaItem>>((ref) async {
  final repo = ref.watch(movieRepositoryProvider);
  final lockedLanguageCode = ref.watch(activeHallSpaceProvider).lockedLanguageCode;
  return repo.getTrendingTvShows(originalLanguage: lockedLanguageCode);
});

final popularMoviesProvider = FutureProvider<List<MediaItem>>((ref) async {
  final repo = ref.watch(movieRepositoryProvider);
  final lockedLanguageCode = ref.watch(activeHallSpaceProvider).lockedLanguageCode;
  return repo.getPopularMovies(originalLanguage: lockedLanguageCode);
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
  final lockedLanguageCode = ref.watch(activeHallSpaceProvider).lockedLanguageCode;
  return repo.getTopRatedMovies(originalLanguage: lockedLanguageCode);
});

final topRatedTvShowsProvider = FutureProvider<List<MediaItem>>((ref) async {
  final repo = ref.watch(movieRepositoryProvider);
  final lockedLanguageCode = ref.watch(activeHallSpaceProvider).lockedLanguageCode;
  return repo.getTopRatedTvShows(originalLanguage: lockedLanguageCode);
});

final nowPlayingMoviesProvider = FutureProvider<List<MediaItem>>((ref) async {
  final repo = ref.watch(movieRepositoryProvider);
  final country = ref.watch(mediaProvider.select((s) => s.watchProvidersCountry));
  final lockedLanguageCode = ref.watch(activeHallSpaceProvider).lockedLanguageCode;
  return repo.getNowPlayingMovies(region: country, originalLanguage: lockedLanguageCode);
});

final airingTodayTvShowsProvider = FutureProvider<List<MediaItem>>((ref) async {
  final repo = ref.watch(movieRepositoryProvider);
  final lockedLanguageCode = ref.watch(activeHallSpaceProvider).lockedLanguageCode;
  return repo.getAiringTodayTvShows(originalLanguage: lockedLanguageCode);
});

final upcomingMoviesProvider = FutureProvider<List<MediaItem>>((ref) async {
  final repo = ref.watch(movieRepositoryProvider);
  final lockedLanguageCode = ref.watch(activeHallSpaceProvider).lockedLanguageCode;
  return repo.getUpcomingMovies(originalLanguage: lockedLanguageCode);
});

final onTheAirTvShowsProvider = FutureProvider<List<MediaItem>>((ref) async {
  final repo = ref.watch(movieRepositoryProvider);
  final lockedLanguageCode = ref.watch(activeHallSpaceProvider).lockedLanguageCode;
  return repo.getOnTheAirTvShows(originalLanguage: lockedLanguageCode);
});

final tvSeasonDetailsProvider =
    FutureProvider.family<TvSeason?, ({String tvId, int seasonNumber})>(
        (ref, arg) async {
  final repo = ref.watch(movieRepositoryProvider);
  return repo.getTvSeasonDetails(arg.tvId, arg.seasonNumber);
});

/// E4/CO-8: lightweight offline episode-skeleton cache. See
/// EpisodeSkeletonCacheService's doc comment for why this is a separate
/// store from the generic TmdbLocalCacheService.
final episodeSkeletonCacheServiceProvider =
    Provider<EpisodeSkeletonCacheService>((ref) {
  return EpisodeSkeletonCacheService(prefs: ref.watch(sharedPreferencesProvider));
});

final tvShowSeasonsProvider =
    FutureProvider.family<List<TvSeason>, MediaItem>((ref, item) async {
  final repo = ref.watch(movieRepositoryProvider);
  // TV-1: lightweight MediaItem objects from search/discover/trending
  // often arrive with seasonsCount == null. Defaulting that straight to 1
  // silently truncated every multi-season show to Season 1 only, so once
  // Season 1 was fully watched, getNextUnwatchedEpisode had nothing left
  // to advance to and TvContinueWatchingCard showed a false "Done". Fetch
  // full details first to get the real season count before looping --
  // gated to TV items only, since this provider is also watched
  // unconditionally from DetailScreen's status toggles for movies, which
  // never have a seasonsCount and would otherwise trigger a pointless
  // getMediaDetails call on every item.
  var seasonsCount = item.seasonsCount;
  if (seasonsCount == null && item.type == MediaType.tv) {
    final fullDetails = await repo.getMediaDetails(item.id);
    seasonsCount = fullDetails?.seasonsCount ?? 1;
  }
  seasonsCount ??= 1;
  // PERF-SEASONS-1: bounded-concurrent instead of one-at-a-time -- a
  // sequential await-in-a-loop here meant every TV detail screen (and every
  // Continue Watching card) blocked on N full network round trips for an
  // N-season show before this provider resolved.
  final seasonNumbers = List.generate(seasonsCount, (i) => i + 1);
  final fetchedSeasons = await mapBounded(
    seasonNumbers,
    (s) => repo.getTvSeasonDetails(item.id, s),
  );
  final seasons = [
    for (final season in fetchedSeasons)
      if (season != null && season.episodes.isNotEmpty) season
  ];

  final mediaState = ref.read(mediaProvider);
  final isTracked = mediaState.watchingList.containsKey(item.id) ||
      mediaState.onHoldList.containsKey(item.id) ||
      mediaState.droppedList.containsKey(item.id);
  final skeletonService = ref.watch(episodeSkeletonCacheServiceProvider);

  if (seasons.isNotEmpty) {
    // E4/CO-8: refresh the offline skeleton whenever real season data is
    // fetched online, for shows the user is actually tracking -- so a
    // specific episode can still be marked watched later without
    // connectivity, using the real per-season structure rather than the
    // single-season guess below.
    if (isTracked) {
      unawaited(skeletonService.saveSkeleton(item.id, seasons));
    }
    return seasons;
  }

  // Real fetch came back empty (most commonly: offline). Fall back to a
  // previously-saved skeleton before the cruder single-season synthesis.
  if (isTracked) {
    final skeleton = skeletonService.getSkeleton(item.id);
    if (skeleton != null && skeleton.isNotEmpty) {
      return skeleton;
    }
  }

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

/// LANG-2: unlike the fixed-list endpoints above, `/discover` genuinely
/// supports `with_original_language` server-side (see
/// [DiscoverFilterParams.originalLanguage]), so a Hall lock is applied by
/// overriding that param at the query rather than filtering results after
/// the fact -- also pre-empting wasted network calls for excluded titles.
/// The override takes precedence over the user's own language chip
/// selection in the Search/Browse filter sheet, matching "pre-set and lock"
/// from the Hall Architecture triage's LANG-2 spec.
DiscoverFilterParams applyHallLanguageLock(DiscoverFilterParams params, String? lockedLanguageCode) {
  if (lockedLanguageCode == null || lockedLanguageCode.isEmpty) return params;
  return params.copyWith(originalLanguage: lockedLanguageCode);
}

final discoverMediaProvider =
    FutureProvider.family<List<MediaItem>, bool>((ref, isMovies) async {
  final repo = ref.watch(movieRepositoryProvider);
  final filterParams = ref.watch(discoverFilterProvider);
  final lockedLanguageCode = ref.watch(activeHallSpaceProvider).lockedLanguageCode;
  final effectiveParams = applyHallLanguageLock(filterParams, lockedLanguageCode);
  return repo.discoverMedia(isMovies: isMovies, params: effectiveParams);
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



