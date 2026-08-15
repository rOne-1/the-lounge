// Regression coverage for B2/E5: the unreleased-episode + new-season status
// state machine (see local-notes/the_lounge_consolidated_triage_reviewed.md).
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:the_lounge/providers/media_provider.dart';
import 'package:the_lounge/providers/ambiance_provider.dart';
import 'package:the_lounge/models/media_item.dart';
import 'package:the_lounge/repositories/mock_movie_repository.dart';

class SeasonedMockRepository extends MockMovieRepository {
  final Map<String, List<TvSeason>> seasonsMap;
  final Map<String, MediaItem> mediaDetailsMap;

  SeasonedMockRepository({
    this.seasonsMap = const {},
    this.mediaDetailsMap = const {},
  });

  @override
  Future<TvSeason?> getTvSeasonDetails(String tvId, int seasonNumber) async {
    final list = seasonsMap[tvId];
    if (list == null) return null;
    for (final season in list) {
      if (season.seasonNumber == seasonNumber) return season;
    }
    return null;
  }

  @override
  Future<MediaItem?> getMediaDetails(String id) async => mediaDetailsMap[id];
}

TvEpisode _ep(int season, int number, {DateTime? airDate}) => TvEpisode(
      id: season * 100 + number,
      episodeNumber: number,
      seasonNumber: season,
      name: 'S${season}E$number',
      airDate: airDate,
    );

void main() {
  final now = DateTime.now();
  final past = now.subtract(const Duration(days: 10));
  final future = now.add(const Duration(days: 10));

  const show = MediaItem(
    id: 'tv-b2',
    title: 'Test Show',
    type: MediaType.tv,
    seasonsCount: 1,
    genres: [],
    overview: '',
    rating: 0.0,
  );

  group('addToWatchedList — never rest in Watched with unreleased episodes',
      () {
    test('with mixed released/unreleased seasons, show goes to Watching, not Watched', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(mediaProvider.notifier);

      final season = TvSeason(
        id: 1,
        seasonNumber: 1,
        name: 'Season 1',
        episodes: [
          _ep(1, 1, airDate: past),
          _ep(1, 2, airDate: future),
        ],
      );

      notifier.addToWatchedList(show, seasons: [season]);
      final state = container.read(mediaProvider);

      expect(state.watchingList.containsKey(show.id), isTrue);
      expect(state.watchedList.containsKey(show.id), isFalse);
      expect(state.watchedEpisodes[show.id], contains('S1E1'));
      expect(state.watchedEpisodes[show.id], isNot(contains('S1E2')));
    });

    test('with all episodes released, show lands in Watched', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(mediaProvider.notifier);

      final season = TvSeason(
        id: 1,
        seasonNumber: 1,
        name: 'Season 1',
        episodes: [
          _ep(1, 1, airDate: past),
          _ep(1, 2, airDate: past),
        ],
      );

      notifier.addToWatchedList(show, seasons: [season]);
      final state = container.read(mediaProvider);

      expect(state.watchedList.containsKey(show.id), isTrue);
      expect(state.watchingList.containsKey(show.id), isFalse);
    });

    test('async fallback path (no seasons passed) corrects Watched -> Watching once real data arrives', () async {
      final repo = SeasonedMockRepository(seasonsMap: {
        show.id: [
          TvSeason(
            id: 1,
            seasonNumber: 1,
            name: 'Season 1',
            episodes: [
              _ep(1, 1, airDate: past),
              _ep(1, 2, airDate: future),
            ],
          ),
        ],
      });
      final container = ProviderContainer(overrides: [
        movieRepositoryProvider.overrideWithValue(repo),
      ]);
      addTearDown(container.dispose);
      final notifier = container.read(mediaProvider.notifier);

      notifier.addToWatchedList(show, seasons: null);

      // Immediately after the synchronous call, the estimate-based path
      // optimistically places the show in Watched.
      var state = container.read(mediaProvider);
      expect(state.watchedList.containsKey(show.id), isTrue);

      await Future.delayed(const Duration(milliseconds: 100));

      state = container.read(mediaProvider);
      expect(state.watchingList.containsKey(show.id), isTrue);
      expect(state.watchedList.containsKey(show.id), isFalse);
    });
  });

  group('toggleEpisodeWatched — real season data as completion threshold (O1)',
      () {
    test('marking every released episode watched does not reach Watched while an unreleased episode remains', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(mediaProvider.notifier);

      final seasons = [
        TvSeason(
          id: 1,
          seasonNumber: 1,
          name: 'Season 1',
          episodes: [
            _ep(1, 1, airDate: past),
            _ep(1, 2, airDate: future),
          ],
        ),
      ];

      notifier.toggleEpisodeWatched(
        showId: show.id,
        seasonNumber: 1,
        episodeNumber: 1,
        showItem: show,
        totalEpisodeCount: 2, // stale header count would say "2 total"
        seasons: seasons,
      );

      final state = container.read(mediaProvider);
      expect(state.watchingList.containsKey(show.id), isTrue);
      expect(state.watchedList.containsKey(show.id), isFalse);
    });

    test('marking the last released episode watched with nothing unreleased reaches Watched', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(mediaProvider.notifier);

      final seasons = [
        TvSeason(
          id: 1,
          seasonNumber: 1,
          name: 'Season 1',
          episodes: [
            _ep(1, 1, airDate: past),
            _ep(1, 2, airDate: past),
          ],
        ),
      ];

      notifier.toggleEpisodeWatched(
        showId: show.id,
        seasonNumber: 1,
        episodeNumber: 1,
        showItem: show,
        seasons: seasons,
      );
      notifier.toggleEpisodeWatched(
        showId: show.id,
        seasonNumber: 1,
        episodeNumber: 2,
        showItem: show,
        seasons: seasons,
      );

      final state = container.read(mediaProvider);
      expect(state.watchedList.containsKey(show.id), isTrue);
      expect(state.watchingList.containsKey(show.id), isFalse);
    });
  });

  group('incomplete season data must never be read as fully released', () {
    // Regression for a real bug found via live browser testing: a single
    // flaky/rate-limited season fetch silently drops that season from the
    // list (no exception, no null — just an empty episode list), rather
    // than surfacing an error. Without an explicit completeness check, the
    // classifier reasons only from whatever seasons it did receive and can
    // confidently declare a show fully released when a whole season's
    // worth of (possibly unreleased) content was simply never fetched.
    final twoSeasonShow = show.copyWith(seasonsCount: 2);

    test('addToWatchedList: fewer seasons than seasonsCount blocks Watched even if all provided episodes are released', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(mediaProvider.notifier);

      // Only season 1 came back, even though the show reports 2 seasons.
      final incompleteSeasons = [
        TvSeason(
          id: 1,
          seasonNumber: 1,
          name: 'Season 1',
          episodes: [_ep(1, 1, airDate: past), _ep(1, 2, airDate: past)],
        ),
      ];

      notifier.addToWatchedList(twoSeasonShow, seasons: incompleteSeasons);
      final state = container.read(mediaProvider);

      expect(state.watchingList.containsKey(show.id), isTrue);
      expect(state.watchedList.containsKey(show.id), isFalse);
    });

    test('toggleEpisodeWatched: fewer seasons than seasonsCount blocks Watched even once every provided episode is watched', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(mediaProvider.notifier);

      final incompleteSeasons = [
        TvSeason(
          id: 1,
          seasonNumber: 1,
          name: 'Season 1',
          episodes: [_ep(1, 1, airDate: past)],
        ),
      ];

      notifier.toggleEpisodeWatched(
        showId: show.id,
        seasonNumber: 1,
        episodeNumber: 1,
        showItem: twoSeasonShow,
        seasons: incompleteSeasons,
      );

      final state = container.read(mediaProvider);
      expect(state.watchingList.containsKey(show.id), isTrue);
      expect(state.watchedList.containsKey(show.id), isFalse);
    });

    test('_enrichWatchedTvShow fallback path: a season that fetches empty keeps the show in Watching, not Watched', () async {
      final repo = SeasonedMockRepository(seasonsMap: {
        show.id: [
          TvSeason(
            id: 1,
            seasonNumber: 1,
            name: 'Season 1',
            episodes: [_ep(1, 1, airDate: past), _ep(1, 2, airDate: past)],
          ),
          // Season 2 "fetches" as present but with zero episodes — the
          // exact shape of the live flaky-fetch failure mode (not a null
          // season, not an exception, just an empty episode list).
          TvSeason(id: 2, seasonNumber: 2, name: 'Season 2', episodes: []),
        ],
      });
      final container = ProviderContainer(overrides: [
        movieRepositoryProvider.overrideWithValue(repo),
      ]);
      addTearDown(container.dispose);
      final notifier = container.read(mediaProvider.notifier);

      notifier.addToWatchedList(twoSeasonShow, seasons: null);
      await Future.delayed(const Duration(milliseconds: 100));

      final state = container.read(mediaProvider);
      expect(state.watchingList.containsKey(show.id), isTrue);
      expect(state.watchedList.containsKey(show.id), isFalse);
    });
  });

  group('null/TBA air dates — unreleased by default, trusted once the user watches them',
      () {
    test('addToWatchedList: an unwatched null-dated episode blocks Watched, same as a future date', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(mediaProvider.notifier);

      final season = TvSeason(
        id: 1,
        seasonNumber: 1,
        name: 'Season 1',
        episodes: [
          _ep(1, 1, airDate: past),
          _ep(1, 2), // TBA, no air date at all
        ],
      );

      notifier.addToWatchedList(show, seasons: [season]);
      final state = container.read(mediaProvider);

      expect(state.watchingList.containsKey(show.id), isTrue);
      expect(state.watchedList.containsKey(show.id), isFalse);
      expect(state.watchedEpisodes[show.id], contains('S1E1'));
      expect(state.watchedEpisodes[show.id], isNot(contains('S1E2')));
    });

    test('toggleEpisodeWatched: explicitly marking a null-dated episode watched lets the show reach Watched', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(mediaProvider.notifier);

      final seasons = [
        TvSeason(
          id: 1,
          seasonNumber: 1,
          name: 'Season 1',
          episodes: [
            _ep(1, 1, airDate: past),
            _ep(1, 2), // TBA
          ],
        ),
      ];

      notifier.toggleEpisodeWatched(
        showId: show.id,
        seasonNumber: 1,
        episodeNumber: 1,
        showItem: show,
        seasons: seasons,
      );
      // Still incomplete: S1E2 hasn't been explicitly confirmed yet.
      var state = container.read(mediaProvider);
      expect(state.watchingList.containsKey(show.id), isTrue);
      expect(state.watchedList.containsKey(show.id), isFalse);

      // The user explicitly marks the TBA episode watched — trusted over
      // TMDB's missing date.
      notifier.toggleEpisodeWatched(
        showId: show.id,
        seasonNumber: 1,
        episodeNumber: 2,
        showItem: show,
        seasons: seasons,
      );
      state = container.read(mediaProvider);
      expect(state.watchedList.containsKey(show.id), isTrue);
      expect(state.watchingList.containsKey(show.id), isFalse);
    });

    test('async fallback path does not trust its own coarse guess for a null-dated episode', () async {
      // Regression guard: addToWatchedList's no-seasons fallback branch
      // optimistically guesses every episode number up to an estimated
      // total is watched. That guess must NOT be treated as a genuine
      // per-episode confirmation once _enrichWatchedTvShow corrects the
      // state with real (TBA) season data — otherwise the null-date trust
      // exception would defeat itself via the very guess it's supposed to
      // correct.
      final repo = SeasonedMockRepository(seasonsMap: {
        show.id: [
          TvSeason(
            id: 1,
            seasonNumber: 1,
            name: 'Season 1',
            episodes: [
              _ep(1, 1, airDate: past),
              _ep(1, 2), // TBA — would be included in the naive count guess
            ],
          ),
        ],
      });
      final container = ProviderContainer(overrides: [
        movieRepositoryProvider.overrideWithValue(repo),
      ]);
      addTearDown(container.dispose);
      final notifier = container.read(mediaProvider.notifier);

      notifier.addToWatchedList(show, seasons: null);
      await Future.delayed(const Duration(milliseconds: 100));

      final state = container.read(mediaProvider);
      expect(state.watchingList.containsKey(show.id), isTrue);
      expect(state.watchedList.containsKey(show.id), isFalse);
      expect(state.watchedEpisodes[show.id], contains('S1E1'));
      expect(state.watchedEpisodes[show.id], isNot(contains('S1E2')));
    });
  });

  group('reevaluateShowCompletion — new-season transitions for Watched shows',
      () {
    ProviderContainer setupWatchedShow(List<TvSeason> initialSeasons) {
      final container = ProviderContainer();
      final notifier = container.read(mediaProvider.notifier);
      notifier.addToWatchedList(show, seasons: initialSeasons);
      expect(
        container.read(mediaProvider).watchedList.containsKey(show.id),
        isTrue,
        reason: 'test setup must start from a genuinely Watched show',
      );
      return container;
    }

    test('mid-air new season (some released, some not) moves Watched -> Watching', () {
      final container = setupWatchedShow([
        TvSeason(
          id: 1,
          seasonNumber: 1,
          name: 'Season 1',
          episodes: [_ep(1, 1, airDate: past)],
        ),
      ]);
      addTearDown(container.dispose);
      final notifier = container.read(mediaProvider.notifier);

      final refreshedSeasons = [
        TvSeason(
          id: 1,
          seasonNumber: 1,
          name: 'Season 1',
          episodes: [_ep(1, 1, airDate: past)],
        ),
        TvSeason(
          id: 2,
          seasonNumber: 2,
          name: 'Season 2',
          episodes: [
            _ep(2, 1, airDate: past),
            _ep(2, 2, airDate: future),
          ],
        ),
      ];

      notifier.reevaluateShowCompletion(showId: show.id, seasons: refreshedSeasons);
      final state = container.read(mediaProvider);
      expect(state.watchingList.containsKey(show.id), isTrue);
      expect(state.watchedList.containsKey(show.id), isFalse);
    });

    test('fully-aired new season (released but unwatched) moves Watched -> Watchlist', () {
      final container = setupWatchedShow([
        TvSeason(
          id: 1,
          seasonNumber: 1,
          name: 'Season 1',
          episodes: [_ep(1, 1, airDate: past)],
        ),
      ]);
      addTearDown(container.dispose);
      final notifier = container.read(mediaProvider.notifier);

      final refreshedSeasons = [
        TvSeason(
          id: 1,
          seasonNumber: 1,
          name: 'Season 1',
          episodes: [_ep(1, 1, airDate: past)],
        ),
        TvSeason(
          id: 2,
          seasonNumber: 2,
          name: 'Season 2',
          episodes: [
            _ep(2, 1, airDate: past),
            _ep(2, 2, airDate: past),
          ],
        ),
      ];

      notifier.reevaluateShowCompletion(showId: show.id, seasons: refreshedSeasons);
      final state = container.read(mediaProvider);
      expect(state.watchlist.containsKey(show.id), isTrue);
      expect(state.watchedList.containsKey(show.id), isFalse);
      expect(state.watchingList.containsKey(show.id), isFalse);
    });

    test('announced/not-started new season moves Watched -> Watchlist', () {
      final container = setupWatchedShow([
        TvSeason(
          id: 1,
          seasonNumber: 1,
          name: 'Season 1',
          episodes: [_ep(1, 1, airDate: past)],
        ),
      ]);
      addTearDown(container.dispose);
      final notifier = container.read(mediaProvider.notifier);

      final refreshedSeasons = [
        TvSeason(
          id: 1,
          seasonNumber: 1,
          name: 'Season 1',
          episodes: [_ep(1, 1, airDate: past)],
        ),
        TvSeason(
          id: 2,
          seasonNumber: 2,
          name: 'Season 2',
          episodes: [_ep(2, 1, airDate: future)],
        ),
      ];

      notifier.reevaluateShowCompletion(showId: show.id, seasons: refreshedSeasons);
      final state = container.read(mediaProvider);
      expect(state.watchlist.containsKey(show.id), isTrue);
      expect(state.watchedList.containsKey(show.id), isFalse);
    });

    test('no new content leaves a Watched show untouched', () {
      final seasons = [
        TvSeason(
          id: 1,
          seasonNumber: 1,
          name: 'Season 1',
          episodes: [_ep(1, 1, airDate: past), _ep(1, 2, airDate: past)],
        ),
      ];
      final container = setupWatchedShow(seasons);
      addTearDown(container.dispose);
      final notifier = container.read(mediaProvider.notifier);

      notifier.reevaluateShowCompletion(showId: show.id, seasons: seasons);
      final state = container.read(mediaProvider);
      expect(state.watchedList.containsKey(show.id), isTrue);
    });
  });

  group('refreshWatchedShowsIfDue — monthly refresh gating', () {
    // Seeded as genuinely Watched with only season 1 known (seasonsCount: 1,
    // matching the one complete season provided) — the "before" state. The
    // refresh must re-fetch fresh show metadata (now reporting 2 seasons)
    // before it can discover season 2 at all; see media_provider.dart's
    // refreshWatchedShowsIfDue for why relying on the stored MediaItem's
    // stale seasonsCount alone would never surface a wholly new season.
    final seasonOneOnly = [
      TvSeason(
        id: 1,
        seasonNumber: 1,
        name: 'Season 1',
        episodes: [_ep(1, 1, airDate: past)],
      ),
    ];

    test('runs and applies transitions when never run before', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      final freshDetails = show.copyWith(seasonsCount: 2);
      final repo = SeasonedMockRepository(
        seasonsMap: {
          show.id: [
            ...seasonOneOnly,
            TvSeason(
              id: 2,
              seasonNumber: 2,
              name: 'Season 2',
              episodes: [_ep(2, 1, airDate: past), _ep(2, 2, airDate: future)],
            ),
          ],
        },
        mediaDetailsMap: {show.id: freshDetails},
      );

      final container = ProviderContainer(overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        movieRepositoryProvider.overrideWithValue(repo),
      ]);
      addTearDown(container.dispose);
      final notifier = container.read(mediaProvider.notifier);

      notifier.addToWatchedList(show, seasons: seasonOneOnly);
      expect(container.read(mediaProvider).watchedList.containsKey(show.id), isTrue);

      await notifier.refreshWatchedShowsIfDue();

      final state = container.read(mediaProvider);
      expect(state.watchingList.containsKey(show.id), isTrue,
          reason: 'season 2 is mid-air, so the refresh should move it to Watching');
      expect(prefs.getInt('the_lounge_last_monthly_refresh'), isNotNull);
    });

    test('is a no-op when the last run was recent', () async {
      SharedPreferences.setMockInitialValues({
        'the_lounge_last_monthly_refresh':
            DateTime.now().millisecondsSinceEpoch,
      });
      final prefs = await SharedPreferences.getInstance();

      final freshDetails = show.copyWith(seasonsCount: 2);
      final repo = SeasonedMockRepository(
        seasonsMap: {
          show.id: [
            ...seasonOneOnly,
            TvSeason(
              id: 2,
              seasonNumber: 2,
              name: 'Season 2',
              episodes: [_ep(2, 1, airDate: past)],
            ),
          ],
        },
        mediaDetailsMap: {show.id: freshDetails},
      );

      final container = ProviderContainer(overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        movieRepositoryProvider.overrideWithValue(repo),
      ]);
      addTearDown(container.dispose);
      final notifier = container.read(mediaProvider.notifier);

      notifier.addToWatchedList(show, seasons: seasonOneOnly);
      expect(container.read(mediaProvider).watchedList.containsKey(show.id), isTrue);

      await notifier.refreshWatchedShowsIfDue();

      // Recent timestamp means the gate short-circuits before touching
      // any show, even though season 2 (now fully released) would
      // otherwise move it to Watchlist.
      final state = container.read(mediaProvider);
      expect(state.watchedList.containsKey(show.id), isTrue);
    });
  });
}
