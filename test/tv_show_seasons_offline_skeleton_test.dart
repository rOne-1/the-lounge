// Integration coverage for E4/CO-8: tvShowSeasonsProvider should persist a
// lightweight offline skeleton whenever real season data is fetched online
// for a show the user is actively tracking (Watching/On-Hold/Dropped), and
// fall back to that skeleton -- not TMDB, not the cruder single-season
// guess -- when the real fetch fails (e.g. offline), but ONLY for tracked
// shows.
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:the_lounge/models/media_item.dart';
import 'package:the_lounge/providers/ambiance_provider.dart';
import 'package:the_lounge/providers/media_provider.dart';
import 'package:the_lounge/repositories/mock_movie_repository.dart';
import 'package:the_lounge/services/episode_skeleton_cache_service.dart';

class _ToggleableRepository extends MockMovieRepository {
  bool online = true;
  final Map<String, List<TvSeason>> realSeasons;

  _ToggleableRepository(this.realSeasons);

  @override
  Future<TvSeason?> getTvSeasonDetails(String tvId, int seasonNumber) async {
    if (!online) return null;
    final seasons = realSeasons[tvId];
    if (seasons == null) return null;
    return seasons.where((s) => s.seasonNumber == seasonNumber).firstOrNull;
  }
}

/// PERF-STAMPEDE-1: counts calls instead of serving real data, so a test can
/// assert a movie never reaches either TV-specific method at all.
class _CountingRepository extends MockMovieRepository {
  int getTvSeasonDetailsCalls = 0;
  int getMediaDetailsCalls = 0;

  @override
  Future<TvSeason?> getTvSeasonDetails(String tvId, int seasonNumber) async {
    getTvSeasonDetailsCalls++;
    return null;
  }

  @override
  Future<MediaItem?> getMediaDetails(String id) async {
    getMediaDetailsCalls++;
    return super.getMediaDetails(id);
  }
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  const trackedShow = MediaItem(
    id: 'tv-tracked',
    title: 'Tracked Show',
    type: MediaType.tv,
    rating: 8.0,
    overview: '',
    genres: [],
    seasonsCount: 2,
  );

  const untrackedShow = MediaItem(
    id: 'tv-untracked',
    title: 'Untracked Show',
    type: MediaType.tv,
    rating: 8.0,
    overview: '',
    genres: [],
    seasonsCount: 1,
    episodesCount: 5,
  );

  const realSeason1 = TvSeason(
    id: 1,
    seasonNumber: 1,
    name: 'Season 1',
    episodes: [
      TvEpisode(id: 1, episodeNumber: 1, seasonNumber: 1, name: 'Real Ep 1'),
      TvEpisode(id: 2, episodeNumber: 2, seasonNumber: 1, name: 'Real Ep 2'),
    ],
  );
  const realSeason2 = TvSeason(
    id: 2,
    seasonNumber: 2,
    name: 'Season 2',
    episodes: [
      TvEpisode(id: 3, episodeNumber: 1, seasonNumber: 2, name: 'Real S2E1'),
    ],
  );

  test('online fetch for a tracked show saves a skeleton for later offline use',
      () async {
    final repo = _ToggleableRepository({
      'tv-tracked': [realSeason1, realSeason2],
    });
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(overrides: [
      movieRepositoryProvider.overrideWithValue(repo),
      sharedPreferencesProvider.overrideWithValue(prefs),
    ]);
    addTearDown(container.dispose);

    container.read(mediaProvider.notifier).addToWatchingList(trackedShow);

    final seasons =
        await container.read(tvShowSeasonsProvider(trackedShow).future);
    expect(seasons.length, 2);
    expect(seasons[0].episodes.map((e) => e.name), ['Real Ep 1', 'Real Ep 2']);

    final skeletonService = EpisodeSkeletonCacheService(prefs: prefs);
    final saved = skeletonService.getSkeleton('tv-tracked');
    expect(saved, isNotNull);
    expect(saved!.length, 2);
    expect(saved[0].episodes.map((e) => e.episodeNumber), [1, 2]);
    expect(saved[1].episodes.map((e) => e.episodeNumber), [1]);
  });

  test(
      'going offline afterwards falls back to the saved skeleton (real '
      'per-season structure), not the crude single-season guess', () async {
    final repo = _ToggleableRepository({
      'tv-tracked': [realSeason1, realSeason2],
    });
    final prefs = await SharedPreferences.getInstance();

    // First container: online, populates the skeleton (simulates an
    // earlier session where the user had connectivity).
    final onlineContainer = ProviderContainer(overrides: [
      movieRepositoryProvider.overrideWithValue(repo),
      sharedPreferencesProvider.overrideWithValue(prefs),
    ]);
    onlineContainer.read(mediaProvider.notifier).addToWatchingList(trackedShow);
    await onlineContainer.read(tvShowSeasonsProvider(trackedShow).future);
    onlineContainer.dispose();

    // Second container: offline, fresh provider graph but the SAME prefs
    // (persisted skeleton survives across sessions).
    repo.online = false;
    final offlineContainer = ProviderContainer(overrides: [
      movieRepositoryProvider.overrideWithValue(repo),
      sharedPreferencesProvider.overrideWithValue(prefs),
    ]);
    addTearDown(offlineContainer.dispose);
    offlineContainer
        .read(mediaProvider.notifier)
        .addToWatchingList(trackedShow);

    final seasons =
        await offlineContainer.read(tvShowSeasonsProvider(trackedShow).future);

    // Real per-season structure preserved (2 seasons, 2 then 1 episodes),
    // not collapsed into one synthesized "Season 1" of N episodes.
    expect(seasons.length, 2);
    expect(seasons[0].seasonNumber, 1);
    expect(seasons[0].episodes.length, 2);
    expect(seasons[1].seasonNumber, 2);
    expect(seasons[1].episodes.length, 1);
  });

  test(
      'an untracked show never gets a skeleton and falls back to the '
      'existing crude single-season guess when offline', () async {
    final repo = _ToggleableRepository({});
    repo.online = false;
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(overrides: [
      movieRepositoryProvider.overrideWithValue(repo),
      sharedPreferencesProvider.overrideWithValue(prefs),
    ]);
    addTearDown(container.dispose);

    // Deliberately NOT added to Watching/On-Hold/Dropped.

    final seasons =
        await container.read(tvShowSeasonsProvider(untrackedShow).future);

    expect(seasons.length, 1);
    expect(seasons[0].episodes.length, 5); // from episodesCount, old fallback
    expect(
        EpisodeSkeletonCacheService(prefs: prefs).getSkeleton('tv-untracked'),
        isNull);
  });

  test(
      'PERF-STAMPEDE-1: a movie never reaches getTvSeasonDetails or '
      'getMediaDetails -- this provider is watched unconditionally from '
      'every DetailScreen, movies included, so without an early bail-out '
      'every movie viewed would fire a getTvSeasonDetails(movieId, 1) call '
      'that can only ever 404 (movie and TV ids are separate TMDB id '
      'spaces); confirmed live in a real error log from a TV-free session',
      () async {
    final repo = _CountingRepository();
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(overrides: [
      movieRepositoryProvider.overrideWithValue(repo),
      sharedPreferencesProvider.overrideWithValue(prefs),
    ]);
    addTearDown(container.dispose);

    const movie = MediaItem(
      id: 'movie-1',
      title: 'A Movie',
      type: MediaType.movie,
      rating: 7.0,
      overview: '',
      genres: [],
    );

    final seasons = await container.read(tvShowSeasonsProvider(movie).future);

    expect(seasons, isEmpty);
    expect(repo.getTvSeasonDetailsCalls, 0);
    expect(repo.getMediaDetailsCalls, 0);
  });
}
