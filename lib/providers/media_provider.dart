import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/media_item.dart';
import 'ambiance_provider.dart';

class MediaState {
  final Map<String, MediaItem> watchlist;
  final Map<String, MediaItem> maybeList; // 'Save for later' / Maybe
  final Map<String, MediaItem> watchedList;
  final List<MediaItem> discoverPool;
  final String watchProvidersCountry;

  const MediaState({
    this.watchlist = const {},
    this.maybeList = const {},
    this.watchedList = const {},
    this.discoverPool = const [],
    this.watchProvidersCountry = 'US',
  });

  MediaState copyWith({
    Map<String, MediaItem>? watchlist,
    Map<String, MediaItem>? maybeList,
    Map<String, MediaItem>? watchedList,
    List<MediaItem>? discoverPool,
    String? watchProvidersCountry,
  }) {
    return MediaState(
      watchlist: watchlist ?? this.watchlist,
      maybeList: maybeList ?? this.maybeList,
      watchedList: watchedList ?? this.watchedList,
      discoverPool: discoverPool ?? this.discoverPool,
      watchProvidersCountry:
          watchProvidersCountry ?? this.watchProvidersCountry,
    );
  }
}

class MediaNotifier extends Notifier<MediaState> {
  static const _watchProvidersCountryKey = 'watch_providers_country';

  @override
  MediaState build() {
    String initialCountry = 'US';
    try {
      final prefs = ref.watch(sharedPreferencesProvider);
      final stored = prefs.getString(_watchProvidersCountryKey);
      if (stored != null && stored.isNotEmpty) {
        initialCountry = stored;
      }
    } catch (_) {
      // Defensively catch missing SharedPreferences override in unit tests
    }
    return MediaState(watchProvidersCountry: initialCountry);
  }

  void addToWatchlist(MediaItem item) {
    if (state.watchlist.containsKey(item.id)) return;

    final newWatchlist = Map<String, MediaItem>.from(state.watchlist)
      ..[item.id] = item;

    state = state.copyWith(watchlist: newWatchlist);
  }

  void removeFromWatchlist(String id) {
    if (!state.watchlist.containsKey(id)) return;

    final newWatchlist = Map<String, MediaItem>.from(state.watchlist)
      ..remove(id);

    state = state.copyWith(watchlist: newWatchlist);
  }

  void toggleWatchlist(MediaItem item) {
    if (state.watchlist.containsKey(item.id)) {
      removeFromWatchlist(item.id);
    } else {
      addToWatchlist(item);
    }
  }

  void addToMaybeList(MediaItem item) {
    if (state.maybeList.containsKey(item.id)) return;

    final newMaybeList = Map<String, MediaItem>.from(state.maybeList)
      ..[item.id] = item;

    state = state.copyWith(maybeList: newMaybeList);
  }

  void removeFromMaybeList(String id) {
    if (!state.maybeList.containsKey(id)) return;

    final newMaybeList = Map<String, MediaItem>.from(state.maybeList)
      ..remove(id);

    state = state.copyWith(maybeList: newMaybeList);
  }

  void toggleMaybe(MediaItem item) {
    if (state.maybeList.containsKey(item.id)) {
      removeFromMaybeList(item.id);
    } else {
      addToMaybeList(item);
    }
  }

  void toggleMaybeList(MediaItem item) => toggleMaybe(item);

  void addToWatchedList(MediaItem item) {
    if (state.watchedList.containsKey(item.id)) return;

    final newWatchedList = Map<String, MediaItem>.from(state.watchedList)
      ..[item.id] = item;

    state = state.copyWith(watchedList: newWatchedList);
  }

  void removeFromWatchedList(String id) {
    if (!state.watchedList.containsKey(id)) return;

    final newWatchedList = Map<String, MediaItem>.from(state.watchedList)
      ..remove(id);

    state = state.copyWith(watchedList: newWatchedList);
  }

  void toggleWatched(MediaItem item) {
    if (state.watchedList.containsKey(item.id)) {
      removeFromWatchedList(item.id);
    } else {
      addToWatchedList(item);
    }
  }

  void toggleWatchedList(MediaItem item) => toggleWatched(item);

  void removeFromAllLists(String id) {
    final newWatchlist = Map<String, MediaItem>.from(state.watchlist)
      ..remove(id);
    final newMaybeList = Map<String, MediaItem>.from(state.maybeList)
      ..remove(id);
    final newWatchedList = Map<String, MediaItem>.from(state.watchedList)
      ..remove(id);

    state = state.copyWith(
      watchlist: newWatchlist,
      maybeList: newMaybeList,
      watchedList: newWatchedList,
    );
  }

  void setDiscoverPool(List<MediaItem> items) {
    state = state.copyWith(discoverPool: items);
  }

  void popFromDiscoverPool() {
    if (state.discoverPool.isNotEmpty) {
      final newPool = List<MediaItem>.from(state.discoverPool)..removeAt(0);
      state = state.copyWith(discoverPool: newPool);
    }
  }

  Future<void> setWatchProvidersCountry(String countryCode) async {
    state = state.copyWith(watchProvidersCountry: countryCode);
    try {
      final prefs = ref.read(sharedPreferencesProvider);
      await prefs.setString(_watchProvidersCountryKey, countryCode);
    } catch (_) {
      // Defensively catch missing SharedPreferences override in unit tests
    }
  }
}

final mediaProvider = NotifierProvider<MediaNotifier, MediaState>(() {
  return MediaNotifier();
});
