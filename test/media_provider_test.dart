import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:the_lounge/providers/media_provider.dart';
import 'package:the_lounge/models/media_item.dart';

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

      // Pre-add item to watchlist and maybeList
      notifier.addToWatchlist(testItem);
      notifier.addToMaybeList(testItem);

      var state = container.read(mediaProvider);
      expect(state.watchlist.containsKey(testItem.id), isTrue);
      expect(state.maybeList.containsKey(testItem.id), isTrue);
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
      notifier.addToMaybeList(testItem);

      var state = container.read(mediaProvider);
      expect(state.watchlist.containsKey(testItem.id), isTrue);
      expect(state.maybeList.containsKey(testItem.id), isTrue);

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
      notifier.addToMaybeList(testItem);

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
  });
}
