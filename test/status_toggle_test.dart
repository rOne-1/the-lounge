import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:the_lounge/providers/media_provider.dart';
import 'package:the_lounge/models/media_item.dart';

void main() {
  group('MediaNotifier Status Toggles Independence', () {
    late ProviderContainer container;
    const item = MediaItem(
      id: 'movie_item_1',
      title: 'Dune: Part Two',
      type: MediaType.movie,
      rating: 8.5,
      overview: 'Paul Atreides unites with Chani and the Fremen...',
      genres: ['Sci-Fi', 'Adventure'],
    );

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test(
        'adding to watchlist and then to maybe-list moves the item to maybe-list',
        () {
      final notifier = container.read(mediaProvider.notifier);

      notifier.addToWatchlist(item);
      var state = container.read(mediaProvider);
      expect(state.watchlist.containsKey(item.id), isTrue);
      expect(state.maybeList.containsKey(item.id), isFalse);
      expect(state.watchingList.containsKey(item.id), isFalse);
      expect(state.watchedList.containsKey(item.id), isFalse);

      notifier.addToMaybeList(item);
      state = container.read(mediaProvider);
      expect(state.watchlist.containsKey(item.id), isFalse,
          reason: 'Item must be removed from watchlist when added to maybe-list');
      expect(state.maybeList.containsKey(item.id), isTrue,
          reason: 'Item must be in maybe-list');
      expect(state.watchingList.containsKey(item.id), isFalse);
      expect(state.watchedList.containsKey(item.id), isFalse);
    });

    test('toggling watching clears watchlist, maybe-list, and watched-list', () {
      final notifier = container.read(mediaProvider.notifier);

      notifier.addToWatchlist(item);
      var state = container.read(mediaProvider);
      expect(state.watchlist.containsKey(item.id), isTrue);

      // Toggle watching on
      notifier.toggleWatching(item);
      state = container.read(mediaProvider);

      expect(state.watchingList.containsKey(item.id), isTrue,
          reason: 'Watching list must contain item');
      expect(state.watchlist.containsKey(item.id), isFalse,
          reason: 'Watchlist should be cleared when toggling watching on');
      expect(state.maybeList.containsKey(item.id), isFalse);
      expect(state.watchedList.containsKey(item.id), isFalse);
    });

    test('toggling watched clears watchlist, maybe-list, and watching-list', () {
      final notifier = container.read(mediaProvider.notifier);

      notifier.toggleWatching(item);

      var state = container.read(mediaProvider);
      expect(state.watchingList.containsKey(item.id), isTrue);

      // Toggle watched on -> should clear watchingList
      notifier.toggleWatched(item);
      state = container.read(mediaProvider);
      expect(state.watchlist.containsKey(item.id), isFalse);
      expect(state.maybeList.containsKey(item.id), isFalse);
      expect(state.watchingList.containsKey(item.id), isFalse,
          reason: 'WatchingList must be cleared when toggling watched on');
      expect(state.watchedList.containsKey(item.id), isTrue,
          reason: 'Watched must be active');

      // Toggle watched off
      notifier.toggleWatched(item);
      state = container.read(mediaProvider);
      expect(state.watchlist.containsKey(item.id), isFalse);
      expect(state.maybeList.containsKey(item.id), isFalse);
      expect(state.watchingList.containsKey(item.id), isFalse);
      expect(state.watchedList.containsKey(item.id), isFalse);
    });

    test('addToWatchedList clears all other lists', () {
      final notifier = container.read(mediaProvider.notifier);

      notifier.addToWatchlist(item);

      var state = container.read(mediaProvider);
      expect(state.watchlist.containsKey(item.id), isTrue);

      notifier.addToWatchedList(item);
      state = container.read(mediaProvider);
      expect(state.watchedList.containsKey(item.id), isTrue);
      expect(state.watchlist.containsKey(item.id), isFalse,
          reason: 'addToWatchedList must clear watchlist');
      expect(state.maybeList.containsKey(item.id), isFalse);
      expect(state.watchingList.containsKey(item.id), isFalse);

      // Unmarking watched does not restore prior state
      notifier.removeFromWatchedList(item.id);
      state = container.read(mediaProvider);
      expect(state.watchedList.containsKey(item.id), isFalse);
      expect(state.watchlist.containsKey(item.id), isFalse);
      expect(state.maybeList.containsKey(item.id), isFalse);
      expect(state.watchingList.containsKey(item.id), isFalse);
    });

    test('removeFromAllLists clears item from all active lists', () {
      final notifier = container.read(mediaProvider.notifier);

      notifier.addToWatchingList(item);

      var state = container.read(mediaProvider);
      expect(state.watchingList.containsKey(item.id), isTrue);

      notifier.removeFromAllLists(item.id);
      state = container.read(mediaProvider);
      expect(state.watchlist.containsKey(item.id), isFalse);
      expect(state.maybeList.containsKey(item.id), isFalse);
      expect(state.watchingList.containsKey(item.id), isFalse);
      expect(state.watchedList.containsKey(item.id), isFalse);
    });
  });
}
