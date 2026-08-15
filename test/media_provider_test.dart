import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:the_lounge/providers/media_provider.dart';
import 'package:the_lounge/models/media_item.dart';
import 'package:the_lounge/repositories/mock_movie_repository.dart';

class TestMovieRepository extends MockMovieRepository {
  @override
  Future<TvSeason?> getTvSeasonDetails(String tvId, int seasonNumber) async {
    final now = DateTime.now();
    return TvSeason(
      id: 1,
      seasonNumber: 1,
      name: 'Season 1',
      episodes: [
        TvEpisode(
          id: 1,
          episodeNumber: 1,
          seasonNumber: 1,
          name: 'Released Ep',
          airDate: now.subtract(const Duration(days: 1)),
        ),
        TvEpisode(
          id: 2,
          episodeNumber: 2,
          seasonNumber: 1,
          name: 'Unreleased Ep',
          airDate: now.add(const Duration(days: 1)),
        ),
      ],
    );
  }
}

void main() {
  group('MediaNotifier logic tests', () {
    late ProviderContainer container;
    const testItem = MediaItem(
      id: 'movie-100',
      title: 'Inception',
      type: MediaType.movie,
      rating: 8.8,
      overview: 'A thief who steals corporate secrets...',
      genres: ['Sci-Fi', 'Action'],
    );

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('addToWatchedList adds to watchedList and removes from watchlist and maybeList', () {
      final notifier = container.read(mediaProvider.notifier);

      // Pre-add item to watchlist
      notifier.addToWatchlist(testItem);

      var state = container.read(mediaProvider);
      expect(state.watchlist.containsKey(testItem.id), isTrue);
      expect(state.maybeList.containsKey(testItem.id), isFalse);
      expect(state.watchedList.containsKey(testItem.id), isFalse);

      // Add to watchedList
      notifier.addToWatchedList(testItem);
      state = container.read(mediaProvider);

      expect(state.watchedList.containsKey(testItem.id), isTrue);
      expect(state.watchlist.containsKey(testItem.id), isFalse);
      expect(state.maybeList.containsKey(testItem.id), isFalse);
    });

    test('toggleWatched removes from watchlist and maybeList when marking as watched', () {
      final notifier = container.read(mediaProvider.notifier);

      notifier.addToWatchlist(testItem);

      var state = container.read(mediaProvider);
      expect(state.watchlist.containsKey(testItem.id), isTrue);

      // Toggle watched on
      notifier.toggleWatched(testItem);
      state = container.read(mediaProvider);

      expect(state.watchedList.containsKey(testItem.id), isTrue);
      expect(state.watchlist.containsKey(testItem.id), isFalse);
      expect(state.maybeList.containsKey(testItem.id), isFalse);
    });

    test('un-marking watched does NOT restore prior state in watchlist or maybeList', () {
      final notifier = container.read(mediaProvider.notifier);

      notifier.addToWatchlist(testItem);

      // Mark as watched
      notifier.addToWatchedList(testItem);
      var state = container.read(mediaProvider);
      expect(state.watchedList.containsKey(testItem.id), isTrue);

      // Un-mark watched
      notifier.removeFromWatchedList(testItem.id);
      state = container.read(mediaProvider);

      expect(state.watchedList.containsKey(testItem.id), isFalse);
      expect(state.watchlist.containsKey(testItem.id), isFalse);
      expect(state.maybeList.containsKey(testItem.id), isFalse);
    });

    test('removeFromAllLists clears item from all lists', () {
      final notifier = container.read(mediaProvider.notifier);

      notifier.addToWatchlist(testItem);
      notifier.addToWatchedList(testItem);

      notifier.removeFromAllLists(testItem.id);
      final state = container.read(mediaProvider);

      expect(state.watchlist.containsKey(testItem.id), isFalse);
      expect(state.maybeList.containsKey(testItem.id), isFalse);
      expect(state.watchedList.containsKey(testItem.id), isFalse);
    });

    const tvShowItem = MediaItem(
      id: 'tv-200',
      title: 'Breaking Bad',
      type: MediaType.tv,
      rating: 9.5,
      overview: 'A chemistry teacher...',
      genres: ['Drama'],
    );

    test('toggleEpisodeWatched updates watchedEpisodes state and syncs show watch status when all episodes watched', () {
      final notifier = container.read(mediaProvider.notifier);

      expect(notifier.isEpisodeWatched(tvShowItem.id, 1, 1), isFalse);

      // Toggle watched on S1E1 with totalEpisodeCount: 2 (partial watched)
      notifier.toggleEpisodeWatched(
        showId: tvShowItem.id,
        seasonNumber: 1,
        episodeNumber: 1,
        showItem: tvShowItem,
        totalEpisodeCount: 2,
      );

      var state = container.read(mediaProvider);
      expect(notifier.isEpisodeWatched(tvShowItem.id, 1, 1), isTrue);
      expect(state.watchedEpisodes[tvShowItem.id], contains('S1E1'));
      // Show is not added to watchedList yet because only 1 of 2 episodes is watched
      expect(state.watchedList.containsKey(tvShowItem.id), isFalse);

      // Toggle watched on S1E2 (all episodes watched)
      notifier.toggleEpisodeWatched(
        showId: tvShowItem.id,
        seasonNumber: 1,
        episodeNumber: 2,
        showItem: tvShowItem,
        totalEpisodeCount: 2,
      );

      state = container.read(mediaProvider);
      expect(notifier.isEpisodeWatched(tvShowItem.id, 1, 2), isTrue);
      expect(state.watchedList.containsKey(tvShowItem.id), isTrue);

      // Toggle off S1E2 (partial watched again) -> show should be removed from watchedList, progress kept in watchedEpisodes
      notifier.toggleEpisodeWatched(
        showId: tvShowItem.id,
        seasonNumber: 1,
        episodeNumber: 2,
        showItem: tvShowItem,
        totalEpisodeCount: 2,
      );

      state = container.read(mediaProvider);
      expect(notifier.isEpisodeWatched(tvShowItem.id, 1, 2), isFalse);
      expect(state.watchedEpisodes[tvShowItem.id], contains('S1E1'));
      expect(state.watchedList.containsKey(tvShowItem.id), isFalse);
    });

    test('getNextUnwatchedEpisode returns first unwatched TvEpisode sequentially', () {
      final notifier = container.read(mediaProvider.notifier);

      const season1 = TvSeason(
        id: 101,
        seasonNumber: 1,
        name: 'Season 1',
        episodes: [
          TvEpisode(id: 1001, episodeNumber: 1, seasonNumber: 1, name: 'Pilot'),
          TvEpisode(id: 1002, episodeNumber: 2, seasonNumber: 1, name: 'Cat\'s in the Bag...'),
        ],
      );

      const season2 = TvSeason(
        id: 102,
        seasonNumber: 2,
        name: 'Season 2',
        episodes: [
          TvEpisode(id: 1003, episodeNumber: 1, seasonNumber: 2, name: 'Seven Thirty-Seven'),
        ],
      );

      final seasons = [season1, season2];

      // Initially next unwatched is S1E1
      var nextEp = notifier.getNextUnwatchedEpisode(showId: tvShowItem.id, seasons: seasons);
      expect(nextEp?.name, 'Pilot');

      // Watch S1E1
      notifier.toggleEpisodeWatched(
        showId: tvShowItem.id,
        seasonNumber: 1,
        episodeNumber: 1,
        showItem: tvShowItem,
      );

      nextEp = notifier.getNextUnwatchedEpisode(showId: tvShowItem.id, seasons: seasons);
      expect(nextEp?.name, 'Cat\'s in the Bag...');

      // Watch S1E2
      notifier.toggleEpisodeWatched(
        showId: tvShowItem.id,
        seasonNumber: 1,
        episodeNumber: 2,
        showItem: tvShowItem,
      );

      nextEp = notifier.getNextUnwatchedEpisode(showId: tvShowItem.id, seasons: seasons);
      expect(nextEp?.name, 'Seven Thirty-Seven');

      // Watch S2E1
      notifier.toggleEpisodeWatched(
        showId: tvShowItem.id,
        seasonNumber: 2,
        episodeNumber: 1,
        showItem: tvShowItem,
      );

      nextEp = notifier.getNextUnwatchedEpisode(showId: tvShowItem.id, seasons: seasons);
      expect(nextEp, isNull);
    });

    test('removeFromWatchedList and removeFromAllLists clear watchedEpisodes', () {
      final notifier = container.read(mediaProvider.notifier);

      notifier.toggleEpisodeWatched(
        showId: tvShowItem.id,
        seasonNumber: 1,
        episodeNumber: 1,
        showItem: tvShowItem,
      );

      expect(notifier.isEpisodeWatched(tvShowItem.id, 1, 1), isTrue);

      notifier.removeFromWatchedList(tvShowItem.id);
      var state = container.read(mediaProvider);
      expect(state.watchedEpisodes.containsKey(tvShowItem.id), isFalse);

      notifier.toggleEpisodeWatched(
        showId: tvShowItem.id,
        seasonNumber: 1,
        episodeNumber: 1,
        showItem: tvShowItem,
      );
      expect(notifier.isEpisodeWatched(tvShowItem.id, 1, 1), isTrue);

      notifier.removeFromAllLists(tvShowItem.id);
      state = container.read(mediaProvider);
      expect(state.watchedEpisodes.containsKey(tvShowItem.id), isFalse);
    });

    test('watchingList manual toggle adds/removes item and removes from other lists', () {
      final notifier = container.read(mediaProvider.notifier);

      notifier.addToWatchlist(testItem);

      var state = container.read(mediaProvider);
      expect(state.watchlist.containsKey(testItem.id), isTrue);
      expect(state.watchingList.containsKey(testItem.id), isFalse);

      // Toggle watching on
      notifier.toggleWatching(testItem);
      state = container.read(mediaProvider);

      expect(state.watchingList.containsKey(testItem.id), isTrue);
      expect(state.watchlist.containsKey(testItem.id), isFalse);
      expect(state.maybeList.containsKey(testItem.id), isFalse);
      expect(state.watchedList.containsKey(testItem.id), isFalse);

      // Toggle watching off
      notifier.toggleWatching(testItem);
      state = container.read(mediaProvider);
      expect(state.watchingList.containsKey(testItem.id), isFalse);
    });

    test('toggleEpisodeWatched automatically manages watchingList and watchedList based on total episode count', () {
      final notifier = container.read(mediaProvider.notifier);

      // Partial watch -> show moves to watchingList
      notifier.toggleEpisodeWatched(
        showId: tvShowItem.id,
        seasonNumber: 1,
        episodeNumber: 1,
        showItem: tvShowItem,
        totalEpisodeCount: 2,
      );

      var state = container.read(mediaProvider);
      expect(state.watchingList.containsKey(tvShowItem.id), isTrue);
      expect(state.watchedList.containsKey(tvShowItem.id), isFalse);

      // All episodes watched -> show moves to watchedList and removes from watchingList
      notifier.toggleEpisodeWatched(
        showId: tvShowItem.id,
        seasonNumber: 1,
        episodeNumber: 2,
        showItem: tvShowItem,
        totalEpisodeCount: 2,
      );

      state = container.read(mediaProvider);
      expect(state.watchingList.containsKey(tvShowItem.id), isFalse);
      expect(state.watchedList.containsKey(tvShowItem.id), isTrue);

      // Unwatch an episode -> show returns to watchingList from watchedList
      notifier.toggleEpisodeWatched(
        showId: tvShowItem.id,
        seasonNumber: 1,
        episodeNumber: 2,
        showItem: tvShowItem,
        totalEpisodeCount: 2,
      );

      state = container.read(mediaProvider);
      expect(state.watchingList.containsKey(tvShowItem.id), isTrue);
      expect(state.watchedList.containsKey(tvShowItem.id), isFalse);

      // Unwatch remaining episode -> show is removed from watchingList and watchedList
      notifier.toggleEpisodeWatched(
        showId: tvShowItem.id,
        seasonNumber: 1,
        episodeNumber: 1,
        showItem: tvShowItem,
        totalEpisodeCount: 2,
      );

      state = container.read(mediaProvider);
      expect(state.watchingList.containsKey(tvShowItem.id), isFalse);
      expect(state.watchedList.containsKey(tvShowItem.id), isFalse);
    });

    test('addToWatchedList guards against unreleased episodes', () async {
      final mockRepo = TestMovieRepository();
      final localContainer = ProviderContainer(
        overrides: [
          movieRepositoryProvider.overrideWithValue(mockRepo),
        ],
      );
      final notifier = localContainer.read(mediaProvider.notifier);
      
      const mixedShow = MediaItem(
        id: 'tv-mixed',
        title: 'Mixed Release Show',
        type: MediaType.tv,
        seasonsCount: 1,
        genres: [],
        overview: '',
        rating: 0.0,
      );

      // 1. With seasons passed
      final now = DateTime.now();
      final season = TvSeason(
        id: 1,
        seasonNumber: 1,
        name: 'Season 1',
        episodes: [
          TvEpisode(id: 1, episodeNumber: 1, seasonNumber: 1, name: 'Released', airDate: now.subtract(const Duration(days: 1))),
          TvEpisode(id: 2, episodeNumber: 2, seasonNumber: 1, name: 'Unreleased', airDate: now.add(const Duration(days: 1))),
        ],
      );
      notifier.addToWatchedList(mixedShow, seasons: [season]);
      var state = localContainer.read(mediaProvider);

      expect(state.watchedEpisodes['tv-mixed']?.contains('S1E1'), isTrue);
      expect(state.watchedEpisodes['tv-mixed']?.contains('S1E2'), isFalse);

      // B2: a show may never rest in Watched while unreleased episodes
      // remain — it should have landed in Watching instead.
      expect(state.watchingList.containsKey('tv-mixed'), isTrue);
      expect(state.watchedList.containsKey('tv-mixed'), isFalse);

      // Cleanup for second part (item may be in watchingList, not watchedList)
      notifier.removeFromAllLists(mixedShow.id);

      // 2. With seasons being null (triggers async pruning)
      notifier.addToWatchedList(mixedShow, seasons: null);
      // Wait for async task to complete
      await Future.delayed(const Duration(milliseconds: 100));

      state = localContainer.read(mediaProvider);
      expect(state.watchedEpisodes['tv-mixed']?.contains('S1E1'), isTrue);
      expect(state.watchedEpisodes['tv-mixed']?.contains('S1E2'), isFalse);
      expect(state.watchingList.containsKey('tv-mixed'), isTrue);
      expect(state.watchedList.containsKey('tv-mixed'), isFalse);
    });
  });
}
