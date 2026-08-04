import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/media_item.dart';
import 'ambiance_provider.dart';
export 'repository_provider.dart';

class MediaState {
  final Map<String, MediaItem> watchlist;
  final Map<String, MediaItem> maybeList; // 'Save for later' / Maybe
  final Map<String, MediaItem> watchedList;
  final Map<String, Set<String>> watchedEpisodes; // showId -> set of "S1E1" episode keys
  final List<MediaItem> discoverPool;
  final String watchProvidersCountry;

  const MediaState({
    this.watchlist = const {},
    this.maybeList = const {},
    this.watchedList = const {},
    this.watchedEpisodes = const {},
    this.discoverPool = const [],
    this.watchProvidersCountry = 'US',
  });

  MediaState copyWith({
    Map<String, MediaItem>? watchlist,
    Map<String, MediaItem>? maybeList,
    Map<String, MediaItem>? watchedList,
    Map<String, Set<String>>? watchedEpisodes,
    List<MediaItem>? discoverPool,
    String? watchProvidersCountry,
  }) {
    return MediaState(
      watchlist: watchlist ?? this.watchlist,
      maybeList: maybeList ?? this.maybeList,
      watchedList: watchedList ?? this.watchedList,
      watchedEpisodes: watchedEpisodes ?? this.watchedEpisodes,
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
    if (state.watchedList.containsKey(item.id) &&
        !state.watchlist.containsKey(item.id) &&
        !state.maybeList.containsKey(item.id)) {
      return;
    }

    final newWatchedList = Map<String, MediaItem>.from(state.watchedList)
      ..[item.id] = item;
    final newWatchlist = Map<String, MediaItem>.from(state.watchlist)
      ..remove(item.id);
    final newMaybeList = Map<String, MediaItem>.from(state.maybeList)
      ..remove(item.id);

    state = state.copyWith(
      watchlist: newWatchlist,
      maybeList: newMaybeList,
      watchedList: newWatchedList,
    );
  }

  void removeFromWatchedList(String id) {
    if (!state.watchedList.containsKey(id) &&
        !state.watchedEpisodes.containsKey(id)) {
      return;
    }

    final newWatchedList = Map<String, MediaItem>.from(state.watchedList)
      ..remove(id);
    final newWatchedEpisodes = Map<String, Set<String>>.from(
      state.watchedEpisodes.map((k, v) => MapEntry(k, Set<String>.from(v))),
    )..remove(id);

    state = state.copyWith(
      watchedList: newWatchedList,
      watchedEpisodes: newWatchedEpisodes,
    );
  }

  void toggleWatched(MediaItem item) {
    if (state.watchedList.containsKey(item.id)) {
      removeFromWatchedList(item.id);
    } else {
      addToWatchedList(item);
    }
  }

  void toggleWatchedList(MediaItem item) => toggleWatched(item);

  void toggleEpisodeWatched({
    required String showId,
    required int seasonNumber,
    required int episodeNumber,
    required MediaItem showItem,
    int? totalEpisodeCount,
    List<TvSeason>? seasons,
  }) {
    final key = 'S${seasonNumber}E$episodeNumber';
    final currentMap = Map<String, Set<String>>.from(
      state.watchedEpisodes.map((k, v) => MapEntry(k, Set<String>.from(v))),
    );

    final showEpisodes = Set<String>.from(currentMap[showId] ?? {});
    if (showEpisodes.contains(key)) {
      showEpisodes.remove(key);
    } else {
      showEpisodes.add(key);
    }

    if (showEpisodes.isEmpty) {
      currentMap.remove(showId);
    } else {
      currentMap[showId] = showEpisodes;
    }

    int totalCount = totalEpisodeCount ?? 0;
    if (totalCount == 0 && seasons != null && seasons.isNotEmpty) {
      totalCount = seasons.fold<int>(0, (sum, s) => sum + s.episodes.length);
    }
    if (totalCount == 0 && showItem.episodesCount != null && showItem.episodesCount! > 0) {
      totalCount = showItem.episodesCount!;
    }
    if (totalCount == 0 && showItem.episodesList != null && showItem.episodesList!.isNotEmpty) {
      totalCount = showItem.episodesList!.length * (showItem.seasonsCount ?? 1);
    }

    final newWatchedList = Map<String, MediaItem>.from(state.watchedList);
    final newWatchlist = Map<String, MediaItem>.from(state.watchlist);
    final newMaybeList = Map<String, MediaItem>.from(state.maybeList);

    if (totalCount > 0 && showEpisodes.length == totalCount) {
      newWatchedList[showItem.id] = showItem;
      newWatchlist.remove(showItem.id);
      newMaybeList.remove(showItem.id);
    } else {
      newWatchedList.remove(showItem.id);
    }

    state = state.copyWith(
      watchedEpisodes: currentMap,
      watchedList: newWatchedList,
      watchlist: newWatchlist,
      maybeList: newMaybeList,
    );
  }

  bool isEpisodeWatched(String showId, int seasonNumber, int episodeNumber) {
    final key = 'S${seasonNumber}E$episodeNumber';
    final episodes = state.watchedEpisodes[showId];
    return episodes?.contains(key) ?? false;
  }

  TvEpisode? getNextUnwatchedEpisode({
    required String showId,
    required List<TvSeason> seasons,
  }) {
    final sortedSeasons = List<TvSeason>.from(seasons)
      ..sort((a, b) {
        if (a.seasonNumber == 0) return 1;
        if (b.seasonNumber == 0) return -1;
        return a.seasonNumber.compareTo(b.seasonNumber);
      });

    for (final season in sortedSeasons) {
      final sortedEpisodes = List<TvEpisode>.from(season.episodes)
        ..sort((a, b) => a.episodeNumber.compareTo(b.episodeNumber));

      for (final episode in sortedEpisodes) {
        if (!isEpisodeWatched(showId, season.seasonNumber, episode.episodeNumber)) {
          return episode;
        }
      }
    }
    return null;
  }

  void removeFromAllLists(String id) {
    final newWatchlist = Map<String, MediaItem>.from(state.watchlist)
      ..remove(id);
    final newMaybeList = Map<String, MediaItem>.from(state.maybeList)
      ..remove(id);
    final newWatchedList = Map<String, MediaItem>.from(state.watchedList)
      ..remove(id);
    final newWatchedEpisodes = Map<String, Set<String>>.from(
      state.watchedEpisodes.map((k, v) => MapEntry(k, Set<String>.from(v))),
    )..remove(id);

    state = state.copyWith(
      watchlist: newWatchlist,
      maybeList: newMaybeList,
      watchedList: newWatchedList,
      watchedEpisodes: newWatchedEpisodes,
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
