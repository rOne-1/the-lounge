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

    test('toggling watched does not affect watchlist or maybe-list', () {
      final notifier = container.read(mediaProvider.notifier);

      // Start with item in both watchlist and maybe-list
      notifier.toggleWatchlist(item);
      notifier.toggleMaybe(item);

      var state = container.read(mediaProvider);
      expect(state.watchlist.containsKey(item.id), isTrue);
      expect(state.maybeList.containsKey(item.id), isTrue);
      expect(state.watchedList.containsKey(item.id), isFalse);

      // Toggle watched on -> all three should be active simultaneously
      notifier.toggleWatched(item);
      state = container.read(mediaProvider);
      expect(state.watchlist.containsKey(item.id), isTrue,
          reason: 'Watchlist must remain intact when toggling watched on');
      expect(state.maybeList.containsKey(item.id), isTrue,
          reason: 'Maybe-list must remain intact when toggling watched on');
      expect(state.watchedList.containsKey(item.id), isTrue,
          reason: 'Watched must be active');

      // Toggle watched off -> watchlist and maybe-list should still remain active
      notifier.toggleWatched(item);
      state = container.read(mediaProvider);
      expect(state.watchlist.containsKey(item.id), isTrue,
          reason: 'Watchlist must remain intact when toggling watched off');
      expect(state.maybeList.containsKey(item.id), isTrue,
          reason: 'Maybe-list must remain intact when toggling watched off');
      expect(state.watchedList.containsKey(item.id), isFalse,
          reason: 'Watched must be toggled off');
    });

    test('each state can be toggled independently in any order', () {
      final notifier = container.read(mediaProvider.notifier);

      // 1. Toggle Maybe ON
      notifier.toggleMaybe(item);
      var state = container.read(mediaProvider);
      expect(state.maybeList.containsKey(item.id), isTrue);
      expect(state.watchlist.containsKey(item.id), isFalse);
      expect(state.watchedList.containsKey(item.id), isFalse);

      // 2. Toggle Watched ON
      notifier.toggleWatched(item);
      state = container.read(mediaProvider);
      expect(state.maybeList.containsKey(item.id), isTrue);
      expect(state.watchlist.containsKey(item.id), isFalse);
      expect(state.watchedList.containsKey(item.id), isTrue);

      // 3. Toggle Watchlist ON (all 3 active)
      notifier.toggleWatchlist(item);
      state = container.read(mediaProvider);
      expect(state.maybeList.containsKey(item.id), isTrue);
      expect(state.watchlist.containsKey(item.id), isTrue);
      expect(state.watchedList.containsKey(item.id), isTrue);

      // 4. Toggle Maybe OFF
      notifier.toggleMaybe(item);
      state = container.read(mediaProvider);
      expect(state.maybeList.containsKey(item.id), isFalse);
      expect(state.watchlist.containsKey(item.id), isTrue);
      expect(state.watchedList.containsKey(item.id), isTrue);

      // 5. Toggle Watchlist OFF
      notifier.toggleWatchlist(item);
      state = container.read(mediaProvider);
      expect(state.maybeList.containsKey(item.id), isFalse);
      expect(state.watchlist.containsKey(item.id), isFalse);
      expect(state.watchedList.containsKey(item.id), isTrue);

      // 6. Toggle Watched OFF (all inactive)
      notifier.toggleWatched(item);
      state = container.read(mediaProvider);
      expect(state.maybeList.containsKey(item.id), isFalse);
      expect(state.watchlist.containsKey(item.id), isFalse);
      expect(state.watchedList.containsKey(item.id), isFalse);
    });

    test('removeFromAllLists clears item from all active lists', () {
      final notifier = container.read(mediaProvider.notifier);

      notifier.addToWatchlist(item);
      notifier.addToMaybeList(item);
      notifier.addToWatchedList(item);

      var state = container.read(mediaProvider);
      expect(state.watchlist.containsKey(item.id), isTrue);
      expect(state.maybeList.containsKey(item.id), isTrue);
      expect(state.watchedList.containsKey(item.id), isTrue);

      notifier.removeFromAllLists(item.id);
      state = container.read(mediaProvider);
      expect(state.watchlist.containsKey(item.id), isFalse);
      expect(state.maybeList.containsKey(item.id), isFalse);
      expect(state.watchedList.containsKey(item.id), isFalse);
    });
  });
}
