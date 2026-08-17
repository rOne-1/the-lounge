import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:the_lounge/models/media_item.dart';
import 'package:the_lounge/providers/media_provider.dart';
import 'package:the_lounge/providers/ambiance_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Local Persistence - Section 1: Minimal Persistable Snapshot', () {
    test('toMinimalJson serializes required fields', () {
      const item = MediaItem(
        id: 'movie_100',
        title: 'Inception',
        type: MediaType.movie,
        rating: 8.8,
        overview: 'A thief who steals corporate secrets...',
        genres: ['Sci-Fi', 'Action'],
        posterUrl: 'https://image.tmdb.org/t/p/w500/poster.jpg',
      );

      final json = item.toMinimalJson();
      expect(json['id'], equals('movie_100'));
      expect(json['title'], equals('Inception'));
      expect(json['type'], equals('movie'));
      expect(json['posterUrl'], equals('https://image.tmdb.org/t/p/w500/poster.jpg'));
      expect(json['rating'], equals(8.8));
    });

    test('fromMinimalJson restores thin MediaItem snapshot', () {
      final json = {
        'id': 'tv_200',
        'title': 'Breaking Bad',
        'type': 'tv',
        'posterUrl': 'https://image.tmdb.org/t/p/w500/bb.jpg',
        'rating': 9.5,
      };

      final restored = MediaItem.fromMinimalJson(json);
      expect(restored.id, equals('tv_200'));
      expect(restored.title, equals('Breaking Bad'));
      expect(restored.type, equals(MediaType.tv));
      expect(restored.posterUrl, equals('https://image.tmdb.org/t/p/w500/bb.jpg'));
      expect(restored.rating, equals(9.5));
      expect(restored.overview, isEmpty);
      expect(restored.genres, isEmpty);
      expect(restored.prefixedId, equals('tv_200'));
    });

    test('fromMinimalJson defensively handles string rating and null fields', () {
      final json = {
        'id': 'movie_300',
        'title': 'The Matrix',
        'type': 'movie',
        'rating': '8.7',
      };

      final restored = MediaItem.fromMinimalJson(json);
      expect(restored.id, equals('movie_300'));
      expect(restored.title, equals('The Matrix'));
      expect(restored.type, equals(MediaType.movie));
      expect(restored.rating, equals(8.7));
      expect(restored.posterUrl, isNull);
    });

    test(
        'toMinimalJson/fromMinimalJson round-trips genres, originalLanguage, '
        'releaseOrAirDate, and voteCount', () {
      // Regression: these 4 fields were previously dropped entirely by
      // toMinimalJson, so every item silently lost them on the next app
      // restart -- breaking pile sort-by-release-date (all-null comparisons
      // are a no-op), sort-by-rating (voteCount-less items all weight to
      // exactly 0), and group-by-genre/-language (always "Other"/"Unknown").
      final item = MediaItem(
        id: 'movie_400',
        title: 'Round Trip',
        type: MediaType.movie,
        rating: 7.4,
        overview: 'Something with real metadata.',
        genres: const ['Drama', 'Thriller'],
        originalLanguage: 'ko',
        releaseOrAirDate: DateTime(2019, 5, 30),
        voteCount: 4200,
      );

      final restored = MediaItem.fromMinimalJson(item.toMinimalJson());

      expect(restored.genres, ['Drama', 'Thriller']);
      expect(restored.originalLanguage, 'ko');
      expect(restored.releaseOrAirDate, DateTime(2019, 5, 30));
      expect(restored.voteCount, 4200);
    });
  });

  group('Local Persistence - Section 2: Persist and Restore 4 Status Maps & Episode Progress', () {
    late SharedPreferences prefs;

    const movie1 = MediaItem(
      id: 'movie_1',
      title: 'Movie 1',
      type: MediaType.movie,
      rating: 8.0,
      overview: 'Overview 1',
      genres: ['Action'],
    );

    const tvShow1 = MediaItem(
      id: 'tv_1',
      title: 'TV Show 1',
      type: MediaType.tv,
      rating: 9.0,
      overview: 'Overview TV 1',
      genres: ['Drama'],
      episodesCount: 10,
      seasonsCount: 1,
    );

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
    });

    test('mutations automatically write to SharedPreferences', () async {
      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
      );
      final notifier = container.read(mediaProvider.notifier);

      // 1. Toggle Watchlist
      notifier.toggleWatchlist(movie1);
      await notifier.saveToPrefs();
      final watchlistJson = prefs.getString('the_lounge_watchlist');
      expect(watchlistJson, isNotNull);
      expect(watchlistJson, contains('movie_1'));

      // 2. Toggle Maybe
      notifier.toggleMaybe(movie1);
      await notifier.saveToPrefs();
      final maybeJson = prefs.getString('the_lounge_maybe_list');
      expect(maybeJson, isNotNull);
      expect(maybeJson, contains('movie_1'));
      expect(prefs.getString('the_lounge_watchlist'), contains('{}'));

      // 3. Toggle Watching
      notifier.toggleWatching(movie1);
      await notifier.saveToPrefs();
      final watchingJson = prefs.getString('the_lounge_watching_list');
      expect(watchingJson, isNotNull);
      expect(watchingJson, contains('movie_1'));

      // 4. Add to WatchedList
      notifier.addToWatchedList(movie1);
      await notifier.saveToPrefs();
      final watchedJson = prefs.getString('the_lounge_watched_list');
      expect(watchedJson, isNotNull);
      expect(watchedJson, contains('movie_1'));

      // 5. Remove from WatchedList
      notifier.removeFromWatchedList(movie1.id);
      await notifier.saveToPrefs();
      expect(prefs.getString('the_lounge_watched_list'), contains('{}'));

      // 6. Toggle Episode Watched
      notifier.toggleEpisodeWatched(
        showId: tvShow1.id,
        seasonNumber: 1,
        episodeNumber: 1,
        showItem: tvShow1,
      );
      await notifier.saveToPrefs();
      final epJson = prefs.getString('the_lounge_watched_episodes');
      expect(epJson, isNotNull);
      expect(epJson, contains('S1E1'));

      container.dispose();
    });

    test('restores state from SharedPreferences on provider initialization', () async {
      final watchlistData = jsonEncode({
        'movie_1': movie1.toMinimalJson(),
      });
      final watchedEpData = jsonEncode({
        'tv_1': ['S1E1', 'S1E2'],
      });

      SharedPreferences.setMockInitialValues({
        'the_lounge_watchlist': watchlistData,
        'the_lounge_watched_episodes': watchedEpData,
      });
      prefs = await SharedPreferences.getInstance();

      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
      );

      final state = container.read(mediaProvider);
      expect(state.watchlist.containsKey('movie_1'), isTrue);
      expect(state.watchlist['movie_1']?.title, equals('Movie 1'));

      expect(state.watchedEpisodes.containsKey('tv_1'), isTrue);
      expect(state.watchedEpisodes['tv_1'], containsAll(['S1E1', 'S1E2']));

      container.dispose();
    });
  });

  group('Local Persistence - Section 3: Defensive Parsing & Error Handling', () {
    late SharedPreferences prefs;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
    });

    test('handles missing, null, empty or corrupted JSON gracefully without crashing', () async {
      SharedPreferences.setMockInitialValues({
        'the_lounge_watchlist': 'invalid-json-string{',
        'the_lounge_maybe_list': '',
        'the_lounge_watching_list': '12345',
        'the_lounge_watched_list': '{"movie_1": "not-a-map"}',
        'the_lounge_watched_episodes': '{"tv_1": "not-a-list"}',
      });
      prefs = await SharedPreferences.getInstance();

      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
      );

      expect(() => container.read(mediaProvider), returnsNormally);
      final state = container.read(mediaProvider);

      expect(state.watchlist, isEmpty);
      expect(state.maybeList, isEmpty);
      expect(state.watchingList, isEmpty);
      expect(state.watchedList, isEmpty);
      expect(state.watchedEpisodes, isEmpty);

      container.dispose();
    });

    test('skips malformed items while loading valid items in map', () async {
      final mixedData = jsonEncode({
        'valid_1': {
          'id': 'valid_1',
          'title': 'Valid Title',
          'type': 'movie',
          'rating': 7.5,
        },
        'invalid_2': 'corrupted-item-string',
      });

      SharedPreferences.setMockInitialValues({
        'the_lounge_watchlist': mixedData,
      });
      prefs = await SharedPreferences.getInstance();

      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
      );

      final state = container.read(mediaProvider);
      expect(state.watchlist.length, equals(1));
      expect(state.watchlist.containsKey('valid_1'), isTrue);
      expect(state.watchlist['valid_1']?.title, equals('Valid Title'));

      container.dispose();
    });
  });
}
