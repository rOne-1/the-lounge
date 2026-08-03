import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:the_lounge/providers/media_provider.dart';
import 'package:the_lounge/models/media_item.dart';

void main() {
  group('MediaNotifier Status Toggles Independence', () {
    late ProviderContainer container;
    const item = MediaItem(
      id: 'item-1',
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
        'adding to watchlist and then to maybe-list leaves the item in BOTH lists',
        () {
      final notifier = container.read(mediaProvider.notifier);

      notifier.addToWatchlist(item);
      var state = container.read(mediaProvider);
      expect(state.watchlist.containsKey(item.id), isTrue);
      expect(state.maybeList.containsKey(item.id), isFalse);
      expect(state.watchedList.containsKey(item.id), isFalse);

      notifier.addToMaybeList(item);
      state = container.read(mediaProvider);
      expect(state.watchlist.containsKey(item.id), isTrue,
          reason: 'Item must remain in watchlist when added to maybe-list');
      expect(state.maybeList.containsKey(item.id), isTrue,
          reason: 'Item must be in maybe-list');
      expect(state.watchedList.containsKey(item.id), isFalse);
    });

    test('toggling watchlist off leaves maybe-list intact', () {
      final notifier = container.read(mediaProvider.notifier);

      notifier.addToWatchlist(item);
      notifier.addToMaybeList(item);

      var state = container.read(mediaProvider);
      expect(state.watchlist.containsKey(item.id), isTrue);
      expect(state.maybeList.containsKey(item.id), isTrue);

      // Toggle watchlist off
      notifier.toggleWatchlist(item);
      state = container.read(mediaProvider);

      expect(state.watchlist.containsKey(item.id), isFalse,
          reason: 'Watchlist should be toggled off');
      expect(state.maybeList.containsKey(item.id), isTrue,
          reason: 'Maybe-list must remain unaffected when toggling watchlist off');
      expect(state.watchedList.containsKey(item.id), isFalse);
    });

    test('toggling watched clears watchlist and maybe-list', () {
      final notifier = container.read(mediaProvider.notifier);

      // Start with item in both watchlist and maybe-list
      notifier.toggleWatchlist(item);
      notifier.toggleMaybe(item);

      var state = container.read(mediaProvider);
      expect(state.watchlist.containsKey(item.id), isTrue);
      expect(state.maybeList.containsKey(item.id), isTrue);
      expect(state.watchedList.containsKey(item.id), isFalse);

      // Toggle watched on -> should clear watchlist and maybe-list
      notifier.toggleWatched(item);
      state = container.read(mediaProvider);
      expect(state.watchlist.containsKey(item.id), isFalse,
          reason: 'Watchlist must be cleared when toggling watched on');
      expect(state.maybeList.containsKey(item.id), isFalse,
          reason: 'Maybe-list must be cleared when toggling watched on');
      expect(state.watchedList.containsKey(item.id), isTrue,
          reason: 'Watched must be active');

      // Toggle watched off -> watchlist and maybe-list should NOT be restored
      notifier.toggleWatched(item);
      state = container.read(mediaProvider);
      expect(state.watchlist.containsKey(item.id), isFalse,
          reason: 'Watchlist must remain cleared when toggling watched off');
      expect(state.maybeList.containsKey(item.id), isFalse,
          reason: 'Maybe-list must remain cleared when toggling watched off');
      expect(state.watchedList.containsKey(item.id), isFalse,
          reason: 'Watched must be toggled off');
    });

    test('addToWatchedList clears watchlist and maybe-list', () {
      final notifier = container.read(mediaProvider.notifier);

      notifier.addToWatchlist(item);
      notifier.addToMaybeList(item);

      var state = container.read(mediaProvider);
      expect(state.watchlist.containsKey(item.id), isTrue);
      expect(state.maybeList.containsKey(item.id), isTrue);

      notifier.addToWatchedList(item);
      state = container.read(mediaProvider);
      expect(state.watchedList.containsKey(item.id), isTrue);
      expect(state.watchlist.containsKey(item.id), isFalse,
          reason: 'addToWatchedList must clear watchlist');
      expect(state.maybeList.containsKey(item.id), isFalse,
          reason: 'addToWatchedList must clear maybeList');

      // Unmarking watched does not restore prior state
      notifier.removeFromWatchedList(item.id);
      state = container.read(mediaProvider);
      expect(state.watchedList.containsKey(item.id), isFalse);
      expect(state.watchlist.containsKey(item.id), isFalse);
      expect(state.maybeList.containsKey(item.id), isFalse);
    });

    test('removeFromAllLists clears item from all active lists', () {
      final notifier = container.read(mediaProvider.notifier);

      notifier.addToWatchlist(item);
      notifier.addToMaybeList(item);

      var state = container.read(mediaProvider);
      expect(state.watchlist.containsKey(item.id), isTrue);
      expect(state.maybeList.containsKey(item.id), isTrue);

      notifier.removeFromAllLists(item.id);
      state = container.read(mediaProvider);
      expect(state.watchlist.containsKey(item.id), isFalse);
      expect(state.maybeList.containsKey(item.id), isFalse);
      expect(state.watchedList.containsKey(item.id), isFalse);
    });
  });
}
