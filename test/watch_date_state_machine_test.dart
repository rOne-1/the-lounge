import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:the_lounge/models/media_item.dart';
import 'package:the_lounge/providers/media_provider.dart';
import 'package:the_lounge/providers/ambiance_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const movie1 = MediaItem(
    id: 'movie_1',
    title: 'Movie 1',
    type: MediaType.movie,
    rating: 8.0,
    overview: 'Overview 1',
    genres: ['Action'],
  );

  const tvShow = MediaItem(
    id: 'tv_1',
    title: 'TV Show 1',
    type: MediaType.tv,
    rating: 9.0,
    overview: 'Overview TV 1',
    genres: ['Drama'],
    seasonsCount: 1,
  );

  const tvShowTwoSeasons = MediaItem(
    id: 'tv_2',
    title: 'TV Show 2',
    type: MediaType.tv,
    rating: 8.5,
    overview: 'Overview TV 2',
    genres: ['Sci-Fi'],
    seasonsCount: 2,
  );

  TvSeason fullyReleasedSeason(int seasonNumber, {int episodeCount = 2}) {
    final now = DateTime.now();
    return TvSeason(
      id: seasonNumber,
      seasonNumber: seasonNumber,
      name: 'Season $seasonNumber',
      episodes: List.generate(
        episodeCount,
        (i) => TvEpisode(
          id: seasonNumber * 100 + i,
          episodeNumber: i + 1,
          seasonNumber: seasonNumber,
          name: 'Ep ${i + 1}',
          airDate: now.subtract(Duration(days: 30 - i)),
        ),
      ),
    );
  }

  TvSeason midAirSeason(int seasonNumber) {
    final now = DateTime.now();
    return TvSeason(
      id: seasonNumber,
      seasonNumber: seasonNumber,
      name: 'Season $seasonNumber',
      episodes: [
        TvEpisode(
          id: seasonNumber * 100 + 1,
          episodeNumber: 1,
          seasonNumber: seasonNumber,
          name: 'Released',
          airDate: now.subtract(const Duration(days: 1)),
        ),
        TvEpisode(
          id: seasonNumber * 100 + 2,
          episodeNumber: 2,
          seasonNumber: seasonNumber,
          name: 'Unreleased',
          airDate: now.add(const Duration(days: 30)),
        ),
      ],
    );
  }

  late SharedPreferences prefs;
  late ProviderContainer container;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    container = ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    );
  });

  tearDown(() => container.dispose());

  group('PERS-DATE-1: movie start/end dates', () {
    test('addToWatchingList records startDate', () {
      final notifier = container.read(mediaProvider.notifier);
      notifier.addToWatchingList(movie1);

      expect(container.read(mediaProvider).startDates[movie1.id], isNotNull);
      expect(container.read(mediaProvider).endDates[movie1.id], isNull);
    });

    test('addToWatchedList sets both startDate and endDate for a movie', () {
      final notifier = container.read(mediaProvider.notifier);
      notifier.addToWatchedList(movie1);

      final state = container.read(mediaProvider);
      expect(state.startDates[movie1.id], isNotNull);
      expect(state.endDates[movie1.id], isNotNull);
    });

    test('startDate set by Watching is preserved once the movie is marked Watched', () {
      final notifier = container.read(mediaProvider.notifier);
      notifier.addToWatchingList(movie1);
      final originalStart = container.read(mediaProvider).startDates[movie1.id];

      notifier.addToWatchedList(movie1);

      expect(container.read(mediaProvider).startDates[movie1.id], originalStart);
    });

    test('removeFromWatchedList clears the movie endDate and startDate', () {
      final notifier = container.read(mediaProvider.notifier);
      notifier.addToWatchedList(movie1);

      notifier.removeFromWatchedList(movie1.id);

      final state = container.read(mediaProvider);
      expect(state.startDates.containsKey(movie1.id), isFalse);
      expect(state.endDates.containsKey(movie1.id), isFalse);
    });
  });

  group('PERS-DATE-1: TV per-episode & per-season dates', () {
    test('toggleEpisodeWatched records startDate and seasonStartDate on first watched episode', () {
      final notifier = container.read(mediaProvider.notifier);
      final season = fullyReleasedSeason(1);

      notifier.toggleEpisodeWatched(
        showId: tvShow.id,
        seasonNumber: 1,
        episodeNumber: 1,
        showItem: tvShow,
        seasons: [season],
      );

      final state = container.read(mediaProvider);
      expect(state.startDates[tvShow.id], isNotNull);
      expect(state.seasonStartDates[tvShow.id]?[1], isNotNull);
    });

    test('completing every released episode of a single-season show sets seasonEndDate and overall endDate', () {
      final notifier = container.read(mediaProvider.notifier);
      final season = fullyReleasedSeason(1, episodeCount: 2);

      notifier.toggleEpisodeWatched(
        showId: tvShow.id,
        seasonNumber: 1,
        episodeNumber: 1,
        showItem: tvShow,
        seasons: [season],
      );
      notifier.toggleEpisodeWatched(
        showId: tvShow.id,
        seasonNumber: 1,
        episodeNumber: 2,
        showItem: tvShow,
        seasons: [season],
      );

      final state = container.read(mediaProvider);
      expect(state.watchedList.containsKey(tvShow.id), isTrue);
      expect(state.seasonEndDates[tvShow.id]?[1], isNotNull);
      expect(state.endDates[tvShow.id], isNotNull);
    });

    test('airing guard: a show with an unreleased episode in another season never gets an overall endDate', () {
      final notifier = container.read(mediaProvider.notifier);
      final season1 = fullyReleasedSeason(1, episodeCount: 1);
      final season2 = midAirSeason(2);
      final seasons = [season1, season2];

      notifier.toggleEpisodeWatched(
        showId: tvShowTwoSeasons.id,
        seasonNumber: 1,
        episodeNumber: 1,
        showItem: tvShowTwoSeasons,
        seasons: seasons,
      );
      notifier.toggleEpisodeWatched(
        showId: tvShowTwoSeasons.id,
        seasonNumber: 2,
        episodeNumber: 1,
        showItem: tvShowTwoSeasons,
        seasons: seasons,
      );

      final state = container.read(mediaProvider);
      // Season 1 is complete (its own episodes all released & watched) even
      // though the show overall isn't -- season-level completion is scoped
      // to that season's own episodes only.
      expect(state.seasonEndDates[tvShowTwoSeasons.id]?[1], isNotNull);
      expect(state.watchedList.containsKey(tvShowTwoSeasons.id), isFalse);
      expect(state.endDates.containsKey(tvShowTwoSeasons.id), isFalse);
    });

    test('startDate is never overwritten when a new season reopens an already-Watched show', () {
      final notifier = container.read(mediaProvider.notifier);
      final season1 = fullyReleasedSeason(1, episodeCount: 1);

      notifier.toggleEpisodeWatched(
        showId: tvShow.id,
        seasonNumber: 1,
        episodeNumber: 1,
        showItem: tvShow,
        seasons: [season1],
      );
      final originalStart = container.read(mediaProvider).startDates[tvShow.id];
      expect(container.read(mediaProvider).watchedList.containsKey(tvShow.id), isTrue);

      // A new season 2 arrives, mid-air: reevaluateShowCompletion reopens
      // the show to Watching.
      final season2 = midAirSeason(2);
      notifier.reevaluateShowCompletion(
        showId: tvShow.id,
        seasons: [season1, season2],
      );

      final state = container.read(mediaProvider);
      expect(state.watchingList.containsKey(tvShow.id), isTrue);
      expect(state.watchedList.containsKey(tvShow.id), isFalse);
      // startDate immutability invariant: unchanged by the automated reopen.
      expect(state.startDates[tvShow.id], originalStart);
      // Airing guard: no longer "resting in Watched", so endDate is cleared.
      expect(state.endDates.containsKey(tvShow.id), isFalse);
    });

    test('un-watching the last episode leaves startDate/endDate cleared alongside watchedEpisodes wipe', () {
      final notifier = container.read(mediaProvider.notifier);
      final season = fullyReleasedSeason(1, episodeCount: 1);

      notifier.toggleEpisodeWatched(
        showId: tvShow.id,
        seasonNumber: 1,
        episodeNumber: 1,
        showItem: tvShow,
        seasons: [season],
      );
      expect(container.read(mediaProvider).watchedList.containsKey(tvShow.id), isTrue);

      notifier.removeFromWatchedList(tvShow.id);

      final state = container.read(mediaProvider);
      expect(state.startDates.containsKey(tvShow.id), isFalse);
      expect(state.endDates.containsKey(tvShow.id), isFalse);
      expect(state.seasonStartDates.containsKey(tvShow.id), isFalse);
      expect(state.seasonEndDates.containsKey(tvShow.id), isFalse);
    });
  });

  group('PERS-DATE-1: persistence', () {
    test('start/end/season dates persist to SharedPreferences and survive a reload', () async {
      final notifier = container.read(mediaProvider.notifier);
      final season = fullyReleasedSeason(1, episodeCount: 1);
      notifier.toggleEpisodeWatched(
        showId: tvShow.id,
        seasonNumber: 1,
        episodeNumber: 1,
        showItem: tvShow,
        seasons: [season],
      );
      await notifier.saveToPrefs();

      final restartedContainer = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      );
      addTearDown(restartedContainer.dispose);

      final state = restartedContainer.read(mediaProvider);
      expect(state.startDates[tvShow.id], isNotNull);
      expect(state.endDates[tvShow.id], isNotNull);
      expect(state.seasonStartDates[tvShow.id]?[1], isNotNull);
      expect(state.seasonEndDates[tvShow.id]?[1], isNotNull);
    });
  });
}
