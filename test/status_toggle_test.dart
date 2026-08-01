import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:the_lounge/providers/media_provider.dart';
import 'package:the_lounge/models/media_item.dart';

void main() {
  group('MediaNotifier Status Toggles', () {
    late ProviderContainer container;
    const item = MediaItem(
      id: '1',
      title: 'Test Movie',
      type: MediaType.movie,
      rating: 8.0,
      overview: 'Test overview',
      genres: ['Action'],
    );

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('adding to watchlist removes from other lists', () {
      final notifier = container.read(mediaProvider.notifier);

      notifier.addToMaybeList(item);
      var state = container.read(mediaProvider);
      expect(state.maybeList.containsKey(item.id), isTrue);

      notifier.addToWatchlist(item);
      state = container.read(mediaProvider);

      expect(state.watchlist.containsKey(item.id), isTrue);
      expect(state.maybeList.containsKey(item.id), isFalse);
      expect(state.watchedList.containsKey(item.id), isFalse);
    });

    test('adding to watched list removes from other lists', () {
      final notifier = container.read(mediaProvider.notifier);

      notifier.addToWatchlist(item);
      var state = container.read(mediaProvider);
      expect(state.watchlist.containsKey(item.id), isTrue);

      notifier.addToWatchedList(item);
      state = container.read(mediaProvider);

      expect(state.watchedList.containsKey(item.id), isTrue);
      expect(state.watchlist.containsKey(item.id), isFalse);
      expect(state.maybeList.containsKey(item.id), isFalse);
    });

    test('adding to maybe list removes from other lists', () {
      final notifier = container.read(mediaProvider.notifier);

      notifier.addToWatchedList(item);
      var state = container.read(mediaProvider);
      expect(state.watchedList.containsKey(item.id), isTrue);

      notifier.addToMaybeList(item);
      state = container.read(mediaProvider);

      expect(state.maybeList.containsKey(item.id), isTrue);
      expect(state.watchlist.containsKey(item.id), isFalse);
      expect(state.watchedList.containsKey(item.id), isFalse);
    });
  });
}
