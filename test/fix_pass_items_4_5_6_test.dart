import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:the_lounge/models/media_item.dart';
import 'package:the_lounge/providers/media_provider.dart';
import 'package:the_lounge/repositories/mock_movie_repository.dart';
import 'package:the_lounge/screens/your_space_screen.dart';

class TestRecommendationRepository extends MockMovieRepository {
  final List<MediaItem> recommendationList;
  TestRecommendationRepository({required this.recommendationList});

  @override
  Future<List<MediaItem>> getRecommendations(String mediaId) async {
    return recommendationList;
  }

  @override
  Future<List<MediaItem>> getSimilarMedia(String mediaId) async {
    return recommendationList;
  }
}

void main() {
  final testMovie1 = const MediaItem(
    id: 'movie-1',
    title: 'Inception',
    type: MediaType.movie,
    rating: 8.8,
    overview: 'Inception overview',
    genres: ['Action', 'Sci-Fi'],
  );

  final testMovie2 = const MediaItem(
    id: 'movie-2',
    title: 'Interstellar',
    type: MediaType.movie,
    rating: 8.6,
    overview: 'Interstellar overview',
    genres: ['Sci-Fi', 'Drama'],
  );

  final testMovie3 = const MediaItem(
    id: 'movie-3',
    title: 'Dunkirk',
    type: MediaType.movie,
    rating: 7.9,
    overview: 'Dunkirk overview',
    genres: ['War', 'Action'],
  );

  final testTvShow = const MediaItem(
    id: 'tv-100',
    title: 'Severance',
    type: MediaType.tv,
    rating: 8.7,
    overview: 'Severance overview',
    genres: ['Sci-Fi', 'Thriller'],
    seasonsCount: 2,
    episodesCount: 18,
  );

  group('Fix Pass Item 4: Recommendation Surface Exclusion', () {
    test('mediaRecommendationsProvider and similarMediaProvider exclude watchedList and droppedList', () async {
      final repo = TestRecommendationRepository(
        recommendationList: [testMovie1, testMovie2, testMovie3],
      );

      final container = ProviderContainer(
        overrides: [
          movieRepositoryProvider.overrideWithValue(repo),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(mediaProvider.notifier);
      // Mark testMovie1 as watched, testMovie2 as dropped
      notifier.addToWatchedList(testMovie1);
      notifier.addToDroppedList(testMovie2);

      final recs = await container.read(mediaRecommendationsProvider('movie-99').future);
      expect(recs.map((m) => m.id), contains('movie-3'));
      expect(recs.map((m) => m.id), isNot(contains('movie-1')));
      expect(recs.map((m) => m.id), isNot(contains('movie-2')));

      final similar = await container.read(similarMediaProvider('movie-99').future);
      expect(similar.map((m) => m.id), contains('movie-3'));
      expect(similar.map((m) => m.id), isNot(contains('movie-1')));
      expect(similar.map((m) => m.id), isNot(contains('movie-2')));
    });
  });

  group('Fix Pass Item 5: Mark TV Show Watched -> Mark All Released Episodes', () {
    test('addToWatchedList for TV show populates all episode keys and isEpisodeWatched returns true', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(mediaProvider.notifier);
      notifier.addToWatchedList(testTvShow);

      final state = container.read(mediaProvider);
      expect(state.watchedList.containsKey('tv-100'), isTrue);
      expect(state.watchedEpisodes.containsKey('tv-100'), isTrue);

      final epSet = state.watchedEpisodes['tv-100']!;
      expect(epSet, contains('S1E1'));
      expect(epSet, contains('S1E9'));
      expect(epSet, contains('S2E1'));
      expect(epSet, contains('S2E9'));

      expect(notifier.isEpisodeWatched('tv-100', 1, 1), isTrue);
      expect(notifier.isEpisodeWatched('tv-100', 2, 9), isTrue);
    });
  });

  group('Fix Pass Item 6: Rename Maybe to Saved & Guidance Subtitles', () {
    testWidgets('YourSpaceScreen displays Saved tab header and guidance subtitles for Watchlist and Saved', (WidgetTester tester) async {
      final container = ProviderContainer(
        overrides: [
          movieRepositoryProvider.overrideWithValue(MockMovieRepository()),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(
              body: YourSpaceScreen(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Check tab names
      expect(find.text('Watchlist'), findsAtLeast(1));
      expect(find.text('Saved'), findsAtLeast(1));
      expect(find.text('In Progress'), findsAtLeast(1));
      expect(find.text('Watched'), findsAtLeast(1));

      // Guidance subtitle for Watchlist
      expect(
        find.text('Committed watchlist of titles you plan to watch soon.'),
        findsOneWidget,
      );

      // Switch to Saved tab
      await tester.tap(find.text('Saved').first);
      await tester.pumpAndSettle();

      // Guidance subtitle for Saved
      expect(
        find.text('Soft, non-committal bookmarks for titles you might want to check out later.'),
        findsOneWidget,
      );
    });
  });

  group('Fix Pass Item 7: New Statuses: Dropped and On-Hold & Auto-Revival', () {
    test('toggleOnHold and toggleDropped toggle states and maintain mutual exclusivity', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(mediaProvider.notifier);

      // Add to On-Hold
      notifier.toggleOnHold(testMovie1);
      expect(container.read(mediaProvider).onHoldList.containsKey('movie-1'), isTrue);
      expect(container.read(mediaProvider).watchlist.containsKey('movie-1'), isFalse);
      expect(container.read(mediaProvider).droppedList.containsKey('movie-1'), isFalse);

      // Toggle to Dropped (should move from On-Hold to Dropped)
      notifier.toggleDropped(testMovie1);
      expect(container.read(mediaProvider).droppedList.containsKey('movie-1'), isTrue);
      expect(container.read(mediaProvider).onHoldList.containsKey('movie-1'), isFalse);
    });

    test('Auto-Revival: toggleEpisodeWatched revives show from droppedList/onHoldList to watchingList', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(mediaProvider.notifier);

      // Mark TV show as Dropped
      notifier.addToDroppedList(testTvShow);
      expect(container.read(mediaProvider).droppedList.containsKey('tv-100'), isTrue);

      // Toggle episode 1 watched
      notifier.toggleEpisodeWatched(
        showId: 'tv-100',
        seasonNumber: 1,
        episodeNumber: 1,
        showItem: testTvShow,
      );

      final state = container.read(mediaProvider);
      expect(state.droppedList.containsKey('tv-100'), isFalse);
      expect(state.onHoldList.containsKey('tv-100'), isFalse);
      expect(state.watchingList.containsKey('tv-100'), isTrue);
    });
  });
}
