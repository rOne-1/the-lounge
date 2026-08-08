import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/media_item.dart';
import 'ambiance_provider.dart';
export 'repository_provider.dart';

class MediaState {
  final Map<String, MediaItem> watchlist;
  final Map<String, MediaItem> maybeList; // 'Save for later' / Saved / Maybe
  final Map<String, MediaItem> watchingList; // Explicit 4th State: Watching
  final Map<String, MediaItem> watchedList;
  final Map<String, MediaItem> droppedList;
  final Map<String, MediaItem> onHoldList;
  final Map<String, Set<String>> watchedEpisodes; // showId -> set of "S1E1" episode keys
  final List<MediaItem> discoverPool;
  final String watchProvidersCountry;

  const MediaState({
    this.watchlist = const {},
    this.maybeList = const {},
    this.watchingList = const {},
    this.watchedList = const {},
    this.droppedList = const {},
    this.onHoldList = const {},
    this.watchedEpisodes = const {},
    this.discoverPool = const [],
    this.watchProvidersCountry = 'US',
  });

  MediaState copyWith({
    Map<String, MediaItem>? watchlist,
    Map<String, MediaItem>? maybeList,
    Map<String, MediaItem>? watchingList,
    Map<String, MediaItem>? watchedList,
    Map<String, MediaItem>? droppedList,
    Map<String, MediaItem>? onHoldList,
    Map<String, Set<String>>? watchedEpisodes,
    List<MediaItem>? discoverPool,
    String? watchProvidersCountry,
  }) {
    return MediaState(
      watchlist: watchlist ?? this.watchlist,
      maybeList: maybeList ?? this.maybeList,
      watchingList: watchingList ?? this.watchingList,
      watchedList: watchedList ?? this.watchedList,
      droppedList: droppedList ?? this.droppedList,
      onHoldList: onHoldList ?? this.onHoldList,
      watchedEpisodes: watchedEpisodes ?? this.watchedEpisodes,
      discoverPool: discoverPool ?? this.discoverPool,
      watchProvidersCountry:
          watchProvidersCountry ?? this.watchProvidersCountry,
    );
  }
}

class MediaNotifier extends Notifier<MediaState> {
  static const _watchProvidersCountryKey = 'watch_providers_country';
  static const _watchlistKey = 'the_lounge_watchlist';
  static const _maybeListKey = 'the_lounge_maybe_list';
  static const _watchingListKey = 'the_lounge_watching_list';
  static const _watchedListKey = 'the_lounge_watched_list';
  static const _droppedListKey = 'the_lounge_dropped_list';
  static const _onHoldListKey = 'the_lounge_on_hold_list';
  static const _watchedEpisodesKey = 'the_lounge_watched_episodes';

  @override
  MediaState build() {
    String initialCountry = 'US';
    Map<String, MediaItem> watchlist = const {};
    Map<String, MediaItem> maybeList = const {};
    Map<String, MediaItem> watchingList = const {};
    Map<String, MediaItem> watchedList = const {};
    Map<String, MediaItem> droppedList = const {};
    Map<String, MediaItem> onHoldList = const {};
    Map<String, Set<String>> watchedEpisodes = const {};

    try {
      final prefs = ref.watch(sharedPreferencesProvider);
      final stored = prefs.getString(_watchProvidersCountryKey);
      if (stored != null && stored.isNotEmpty) {
        initialCountry = stored;
      }
      watchlist = _parseMediaMap(prefs, _watchlistKey);
      maybeList = _parseMediaMap(prefs, _maybeListKey);
      watchingList = _parseMediaMap(prefs, _watchingListKey);
      watchedList = _parseMediaMap(prefs, _watchedListKey);
      droppedList = _parseMediaMap(prefs, _droppedListKey);
      onHoldList = _parseMediaMap(prefs, _onHoldListKey);
      watchedEpisodes = _parseWatchedEpisodes(prefs, _watchedEpisodesKey);
    } catch (_) {
      // Defensively catch missing SharedPreferences override in unit tests
    }

    return MediaState(
      watchProvidersCountry: initialCountry,
      watchlist: watchlist,
      maybeList: maybeList,
      watchingList: watchingList,
      watchedList: watchedList,
      droppedList: droppedList,
      onHoldList: onHoldList,
      watchedEpisodes: watchedEpisodes,
    );
  }

  Future<void> _loadFromPrefs() async {
    try {
      final prefs = ref.read(sharedPreferencesProvider);
      final watchlist = _parseMediaMap(prefs, _watchlistKey);
      final maybeList = _parseMediaMap(prefs, _maybeListKey);
      final watchingList = _parseMediaMap(prefs, _watchingListKey);
      final watchedList = _parseMediaMap(prefs, _watchedListKey);
      final droppedList = _parseMediaMap(prefs, _droppedListKey);
      final onHoldList = _parseMediaMap(prefs, _onHoldListKey);
      final watchedEpisodes =
          _parseWatchedEpisodes(prefs, _watchedEpisodesKey);

      state = state.copyWith(
        watchlist: watchlist,
        maybeList: maybeList,
        watchingList: watchingList,
        watchedList: watchedList,
        droppedList: droppedList,
        onHoldList: onHoldList,
        watchedEpisodes: watchedEpisodes,
      );
    } catch (_) {
      // Defensively catch missing SharedPreferences override in unit tests
    }
  }

  Future<void> loadFromPrefs() => _loadFromPrefs();

  Future<void> _saveToPrefs() async {
    try {
      final prefs = ref.read(sharedPreferencesProvider);
      await Future.wait([
        prefs.setString(
          _watchlistKey,
          jsonEncode(
              state.watchlist.map((k, v) => MapEntry(k, v.toMinimalJson()))),
        ),
        prefs.setString(
          _maybeListKey,
          jsonEncode(
              state.maybeList.map((k, v) => MapEntry(k, v.toMinimalJson()))),
        ),
        prefs.setString(
          _watchingListKey,
          jsonEncode(
              state.watchingList.map((k, v) => MapEntry(k, v.toMinimalJson()))),
        ),
        prefs.setString(
          _watchedListKey,
          jsonEncode(
              state.watchedList.map((k, v) => MapEntry(k, v.toMinimalJson()))),
        ),
        prefs.setString(
          _droppedListKey,
          jsonEncode(
              state.droppedList.map((k, v) => MapEntry(k, v.toMinimalJson()))),
        ),
        prefs.setString(
          _onHoldListKey,
          jsonEncode(
              state.onHoldList.map((k, v) => MapEntry(k, v.toMinimalJson()))),
        ),
        prefs.setString(
          _watchedEpisodesKey,
          jsonEncode(
            state.watchedEpisodes.map((k, v) => MapEntry(k, v.toList())),
          ),
        ),
      ]);
    } catch (_) {
      // Defensively catch missing SharedPreferences override or save errors in unit tests
    }
  }

  Future<void> saveToPrefs() => _saveToPrefs();

  Map<String, MediaItem> _parseMediaMap(SharedPreferences prefs, String key) {
    try {
      final rawJson = prefs.getString(key);
      if (rawJson == null || rawJson.trim().isEmpty) {
        return {};
      }
      final decoded = jsonDecode(rawJson);
      final Map<String, MediaItem> result = {};
      if (decoded is Map<String, dynamic>) {
        decoded.forEach((k, v) {
          try {
            if (v is Map<String, dynamic>) {
              result[k] = MediaItem.fromMinimalJson(v);
            }
          } catch (_) {}
        });
      } else if (decoded is List) {
        for (final itemJson in decoded) {
          try {
            if (itemJson is Map<String, dynamic>) {
              final item = MediaItem.fromMinimalJson(itemJson);
              if (item.id.isNotEmpty) {
                result[item.id] = item;
              }
            }
          } catch (_) {}
        }
      }
      return result;
    } catch (_) {
      return {};
    }
  }

  Map<String, Set<String>> _parseWatchedEpisodes(
      SharedPreferences prefs, String key) {
    try {
      final rawJson = prefs.getString(key);
      if (rawJson == null || rawJson.trim().isEmpty) {
        return {};
      }
      final decoded = jsonDecode(rawJson);
      final Map<String, Set<String>> result = {};
      if (decoded is Map<String, dynamic>) {
        decoded.forEach((showId, epList) {
          try {
            if (epList is List) {
              final epSet = epList.map((e) => e.toString()).toSet();
              if (epSet.isNotEmpty) {
                result[showId] = epSet;
              }
            }
          } catch (_) {}
        });
      }
      return result;
    } catch (_) {
      return {};
    }
  }

  void addToWatchlist(MediaItem item) {
    if (state.watchlist.containsKey(item.id) &&
        !state.maybeList.containsKey(item.id) &&
        !state.watchingList.containsKey(item.id) &&
        !state.watchedList.containsKey(item.id) &&
        !state.droppedList.containsKey(item.id) &&
        !state.onHoldList.containsKey(item.id)) {
      return;
    }

    final newWatchlist = Map<String, MediaItem>.from(state.watchlist)
      ..[item.id] = item;
    final newMaybeList = Map<String, MediaItem>.from(state.maybeList)
      ..remove(item.id);
    final newWatchingList = Map<String, MediaItem>.from(state.watchingList)
      ..remove(item.id);
    final newWatchedList = Map<String, MediaItem>.from(state.watchedList)
      ..remove(item.id);
    final newDroppedList = Map<String, MediaItem>.from(state.droppedList)
      ..remove(item.id);
    final newOnHoldList = Map<String, MediaItem>.from(state.onHoldList)
      ..remove(item.id);

    state = state.copyWith(
      watchlist: newWatchlist,
      maybeList: newMaybeList,
      watchingList: newWatchingList,
      watchedList: newWatchedList,
      droppedList: newDroppedList,
      onHoldList: newOnHoldList,
    );
    _saveToPrefs();
  }

  void removeFromWatchlist(String id) {
    if (!state.watchlist.containsKey(id)) return;

    final newWatchlist = Map<String, MediaItem>.from(state.watchlist)
      ..remove(id);

    state = state.copyWith(watchlist: newWatchlist);
    _saveToPrefs();
  }

  void toggleWatchlist(MediaItem item) {
    if (state.watchlist.containsKey(item.id)) {
      removeFromWatchlist(item.id);
    } else {
      addToWatchlist(item);
    }
  }

  void addToMaybeList(MediaItem item) {
    if (state.maybeList.containsKey(item.id) &&
        !state.watchlist.containsKey(item.id) &&
        !state.watchingList.containsKey(item.id) &&
        !state.watchedList.containsKey(item.id) &&
        !state.droppedList.containsKey(item.id) &&
        !state.onHoldList.containsKey(item.id)) {
      return;
    }

    final newMaybeList = Map<String, MediaItem>.from(state.maybeList)
      ..[item.id] = item;
    final newWatchlist = Map<String, MediaItem>.from(state.watchlist)
      ..remove(item.id);
    final newWatchingList = Map<String, MediaItem>.from(state.watchingList)
      ..remove(item.id);
    final newWatchedList = Map<String, MediaItem>.from(state.watchedList)
      ..remove(item.id);
    final newDroppedList = Map<String, MediaItem>.from(state.droppedList)
      ..remove(item.id);
    final newOnHoldList = Map<String, MediaItem>.from(state.onHoldList)
      ..remove(item.id);

    state = state.copyWith(
      watchlist: newWatchlist,
      maybeList: newMaybeList,
      watchingList: newWatchingList,
      watchedList: newWatchedList,
      droppedList: newDroppedList,
      onHoldList: newOnHoldList,
    );
    _saveToPrefs();
  }

  void removeFromMaybeList(String id) {
    if (!state.maybeList.containsKey(id)) return;

    final newMaybeList = Map<String, MediaItem>.from(state.maybeList)
      ..remove(id);

    state = state.copyWith(maybeList: newMaybeList);
    _saveToPrefs();
  }

  void toggleMaybe(MediaItem item) {
    if (state.maybeList.containsKey(item.id)) {
      removeFromMaybeList(item.id);
    } else {
      addToMaybeList(item);
    }
  }

  void toggleMaybeList(MediaItem item) => toggleMaybe(item);

  void addToWatchingList(MediaItem item) {
    if (state.watchingList.containsKey(item.id) &&
        !state.watchlist.containsKey(item.id) &&
        !state.maybeList.containsKey(item.id) &&
        !state.watchedList.containsKey(item.id) &&
        !state.droppedList.containsKey(item.id) &&
        !state.onHoldList.containsKey(item.id)) {
      return;
    }

    final newWatchingList = Map<String, MediaItem>.from(state.watchingList)
      ..[item.id] = item;
    final newWatchlist = Map<String, MediaItem>.from(state.watchlist)
      ..remove(item.id);
    final newMaybeList = Map<String, MediaItem>.from(state.maybeList)
      ..remove(item.id);
    final newWatchedList = Map<String, MediaItem>.from(state.watchedList)
      ..remove(item.id);
    final newDroppedList = Map<String, MediaItem>.from(state.droppedList)
      ..remove(item.id);
    final newOnHoldList = Map<String, MediaItem>.from(state.onHoldList)
      ..remove(item.id);

    state = state.copyWith(
      watchlist: newWatchlist,
      maybeList: newMaybeList,
      watchingList: newWatchingList,
      watchedList: newWatchedList,
      droppedList: newDroppedList,
      onHoldList: newOnHoldList,
    );
    _saveToPrefs();
  }

  void removeFromWatchingList(String id) {
    if (!state.watchingList.containsKey(id)) return;

    final newWatchingList = Map<String, MediaItem>.from(state.watchingList)
      ..remove(id);

    state = state.copyWith(watchingList: newWatchingList);
    _saveToPrefs();
  }

  void toggleWatching(MediaItem item) {
    if (state.watchingList.containsKey(item.id)) {
      removeFromWatchingList(item.id);
    } else {
      addToWatchingList(item);
    }
  }

  void toggleWatchingList(MediaItem item) => toggleWatching(item);

  void addToWatchedList(MediaItem item, {List<TvSeason>? seasons}) {
    if (state.watchedList.containsKey(item.id) &&
        !state.watchlist.containsKey(item.id) &&
        !state.maybeList.containsKey(item.id) &&
        !state.watchingList.containsKey(item.id) &&
        !state.droppedList.containsKey(item.id) &&
        !state.onHoldList.containsKey(item.id)) {
      return;
    }

    final newWatchedList = Map<String, MediaItem>.from(state.watchedList)
      ..[item.id] = item;
    final newWatchlist = Map<String, MediaItem>.from(state.watchlist)
      ..remove(item.id);
    final newMaybeList = Map<String, MediaItem>.from(state.maybeList)
      ..remove(item.id);
    final newWatchingList = Map<String, MediaItem>.from(state.watchingList)
      ..remove(item.id);
    final newDroppedList = Map<String, MediaItem>.from(state.droppedList)
      ..remove(item.id);
    final newOnHoldList = Map<String, MediaItem>.from(state.onHoldList)
      ..remove(item.id);

    final newWatchedEpisodes = Map<String, Set<String>>.from(
      state.watchedEpisodes.map((k, v) => MapEntry(k, Set<String>.from(v))),
    );

    if (item.type == MediaType.tv) {
      final epSet = <String>{};
      final now = DateTime.now();
      if (seasons != null && seasons.isNotEmpty) {
        for (final season in seasons) {
          for (final ep in season.episodes) {
            if (ep.airDate == null || !ep.airDate!.isAfter(now)) {
              epSet.add('S${season.seasonNumber}E${ep.episodeNumber}');
            }
          }
        }
      } else {
        final isShowUnreleased = item.releaseOrAirDate != null &&
            item.releaseOrAirDate!.isAfter(now);
        if (!isShowUnreleased) {
          final totalSeasons = item.seasonsCount ?? 1;
          if (item.episodesList != null && item.episodesList!.isNotEmpty) {
            for (int s = 1; s <= totalSeasons; s++) {
              for (int e = 1; e <= item.episodesList!.length; e++) {
                epSet.add('S${s}E$e');
              }
            }
          } else if (item.episodesCount != null && item.episodesCount! > 0) {
            final epsPerSeason = (item.episodesCount! / totalSeasons).ceil();
            for (int s = 1; s <= totalSeasons; s++) {
              for (int e = 1; e <= epsPerSeason; e++) {
                epSet.add('S${s}E$e');
              }
            }
          } else {
            for (int s = 1; s <= totalSeasons; s++) {
              for (int e = 1; e <= 10; e++) {
                epSet.add('S${s}E$e');
              }
            }
          }
        }
      }
      newWatchedEpisodes[item.id] = epSet;
    }

    state = state.copyWith(
      watchlist: newWatchlist,
      maybeList: newMaybeList,
      watchingList: newWatchingList,
      watchedList: newWatchedList,
      droppedList: newDroppedList,
      onHoldList: newOnHoldList,
      watchedEpisodes: newWatchedEpisodes,
    );
    _saveToPrefs();
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
    _saveToPrefs();
  }

  void toggleWatched(MediaItem item, {List<TvSeason>? seasons}) {
    if (state.watchedList.containsKey(item.id)) {
      removeFromWatchedList(item.id);
    } else {
      addToWatchedList(item, seasons: seasons);
    }
  }

  void toggleWatchedList(MediaItem item, {List<TvSeason>? seasons}) =>
      toggleWatched(item, seasons: seasons);

  void addToDroppedList(MediaItem item) {
    if (state.droppedList.containsKey(item.id) &&
        !state.watchlist.containsKey(item.id) &&
        !state.maybeList.containsKey(item.id) &&
        !state.watchingList.containsKey(item.id) &&
        !state.watchedList.containsKey(item.id) &&
        !state.onHoldList.containsKey(item.id)) {
      return;
    }

    final newDroppedList = Map<String, MediaItem>.from(state.droppedList)
      ..[item.id] = item;
    final newWatchlist = Map<String, MediaItem>.from(state.watchlist)
      ..remove(item.id);
    final newMaybeList = Map<String, MediaItem>.from(state.maybeList)
      ..remove(item.id);
    final newWatchingList = Map<String, MediaItem>.from(state.watchingList)
      ..remove(item.id);
    final newWatchedList = Map<String, MediaItem>.from(state.watchedList)
      ..remove(item.id);
    final newOnHoldList = Map<String, MediaItem>.from(state.onHoldList)
      ..remove(item.id);

    state = state.copyWith(
      watchlist: newWatchlist,
      maybeList: newMaybeList,
      watchingList: newWatchingList,
      watchedList: newWatchedList,
      droppedList: newDroppedList,
      onHoldList: newOnHoldList,
    );
    _saveToPrefs();
  }

  void removeFromDroppedList(String id) {
    if (!state.droppedList.containsKey(id)) return;

    final newDroppedList = Map<String, MediaItem>.from(state.droppedList)
      ..remove(id);

    state = state.copyWith(droppedList: newDroppedList);
    _saveToPrefs();
  }

  void toggleDropped(MediaItem item) {
    if (state.droppedList.containsKey(item.id)) {
      removeFromDroppedList(item.id);
    } else {
      addToDroppedList(item);
    }
  }

  void toggleDroppedList(MediaItem item) => toggleDropped(item);

  void addToOnHoldList(MediaItem item) {
    if (state.onHoldList.containsKey(item.id) &&
        !state.watchlist.containsKey(item.id) &&
        !state.maybeList.containsKey(item.id) &&
        !state.watchingList.containsKey(item.id) &&
        !state.watchedList.containsKey(item.id) &&
        !state.droppedList.containsKey(item.id)) {
      return;
    }

    final newOnHoldList = Map<String, MediaItem>.from(state.onHoldList)
      ..[item.id] = item;
    final newWatchlist = Map<String, MediaItem>.from(state.watchlist)
      ..remove(item.id);
    final newMaybeList = Map<String, MediaItem>.from(state.maybeList)
      ..remove(item.id);
    final newWatchingList = Map<String, MediaItem>.from(state.watchingList)
      ..remove(item.id);
    final newWatchedList = Map<String, MediaItem>.from(state.watchedList)
      ..remove(item.id);
    final newDroppedList = Map<String, MediaItem>.from(state.droppedList)
      ..remove(item.id);

    state = state.copyWith(
      watchlist: newWatchlist,
      maybeList: newMaybeList,
      watchingList: newWatchingList,
      watchedList: newWatchedList,
      droppedList: newDroppedList,
      onHoldList: newOnHoldList,
    );
    _saveToPrefs();
  }

  void removeFromOnHoldList(String id) {
    if (!state.onHoldList.containsKey(id)) return;

    final newOnHoldList = Map<String, MediaItem>.from(state.onHoldList)
      ..remove(id);

    state = state.copyWith(onHoldList: newOnHoldList);
    _saveToPrefs();
  }

  void toggleOnHold(MediaItem item) {
    if (state.onHoldList.containsKey(item.id)) {
      removeFromOnHoldList(item.id);
    } else {
      addToOnHoldList(item);
    }
  }

  void toggleOnHoldList(MediaItem item) => toggleOnHold(item);

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
    final now = DateTime.now();
    if (showEpisodes.contains(key)) {
      showEpisodes.remove(key);
    } else {
      if (seasons != null && seasons.isNotEmpty) {
        for (final season in seasons) {
          if (season.seasonNumber == seasonNumber) {
            for (final ep in season.episodes) {
              if (ep.episodeNumber == episodeNumber &&
                  ep.airDate != null &&
                  ep.airDate!.isAfter(now)) {
                return;
              }
            }
          }
        }
      } else if (showItem.releaseOrAirDate != null &&
          showItem.releaseOrAirDate!.isAfter(now)) {
        return;
      }
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
    final newWatchingList = Map<String, MediaItem>.from(state.watchingList);
    final newWatchlist = Map<String, MediaItem>.from(state.watchlist);
    final newMaybeList = Map<String, MediaItem>.from(state.maybeList);
    final newDroppedList = Map<String, MediaItem>.from(state.droppedList);
    final newOnHoldList = Map<String, MediaItem>.from(state.onHoldList);

    if (showEpisodes.isNotEmpty && (totalCount == 0 || showEpisodes.length < totalCount)) {
      newWatchingList[showItem.id] = showItem;
      newWatchedList.remove(showItem.id);
      newWatchlist.remove(showItem.id);
      newMaybeList.remove(showItem.id);
      newDroppedList.remove(showItem.id);
      newOnHoldList.remove(showItem.id);
    } else if (totalCount > 0 && showEpisodes.length == totalCount) {
      newWatchedList[showItem.id] = showItem;
      newWatchingList.remove(showItem.id);
      newWatchlist.remove(showItem.id);
      newMaybeList.remove(showItem.id);
      newDroppedList.remove(showItem.id);
      newOnHoldList.remove(showItem.id);
    } else {
      newWatchingList.remove(showItem.id);
      newWatchedList.remove(showItem.id);
    }

    state = state.copyWith(
      watchedEpisodes: currentMap,
      watchedList: newWatchedList,
      watchingList: newWatchingList,
      watchlist: newWatchlist,
      maybeList: newMaybeList,
      droppedList: newDroppedList,
      onHoldList: newOnHoldList,
    );
    _saveToPrefs();
  }

  bool isEpisodeWatched(String showId, int seasonNumber, int episodeNumber) {
    if (state.watchedList.containsKey(showId)) {
      return true;
    }
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

  void reevaluateShowCompletion({
    required String showId,
    required List<TvSeason> seasons,
  }) {
    final now = DateTime.now();
    int totalReleasedEpisodes = 0;
    for (final season in seasons) {
      for (final ep in season.episodes) {
        if (ep.airDate == null || !ep.airDate!.isAfter(now)) {
          totalReleasedEpisodes++;
        }
      }
    }

    if (totalReleasedEpisodes == 0) return;

    final watchedSet = state.watchedEpisodes[showId] ?? <String>{};

    if (state.watchedList.containsKey(showId) &&
        watchedSet.length < totalReleasedEpisodes) {
      final showItem = state.watchedList[showId]!;
      final newWatchedList = Map<String, MediaItem>.from(state.watchedList)
        ..remove(showId);
      final newWatchingList = Map<String, MediaItem>.from(state.watchingList)
        ..[showId] = showItem;

      state = state.copyWith(
        watchedList: newWatchedList,
        watchingList: newWatchingList,
      );
      _saveToPrefs();
    }
  }

  void removeFromAllLists(String id) {
    final newWatchlist = Map<String, MediaItem>.from(state.watchlist)
      ..remove(id);
    final newMaybeList = Map<String, MediaItem>.from(state.maybeList)
      ..remove(id);
    final newWatchingList = Map<String, MediaItem>.from(state.watchingList)
      ..remove(id);
    final newWatchedList = Map<String, MediaItem>.from(state.watchedList)
      ..remove(id);
    final newDroppedList = Map<String, MediaItem>.from(state.droppedList)
      ..remove(id);
    final newOnHoldList = Map<String, MediaItem>.from(state.onHoldList)
      ..remove(id);
    final newWatchedEpisodes = Map<String, Set<String>>.from(
      state.watchedEpisodes.map((k, v) => MapEntry(k, Set<String>.from(v))),
    )..remove(id);

    state = state.copyWith(
      watchlist: newWatchlist,
      maybeList: newMaybeList,
      watchingList: newWatchingList,
      watchedList: newWatchedList,
      droppedList: newDroppedList,
      onHoldList: newOnHoldList,
      watchedEpisodes: newWatchedEpisodes,
    );
    _saveToPrefs();
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

class SkippedMediaIdsNotifier extends Notifier<Set<String>> {
  @override
  Set<String> build() => {};

  void add(String id) {
    state = {...state, id};
  }

  void addAll(Iterable<String> ids) {
    state = {...state, ...ids};
  }

  void remove(String id) {
    final next = Set<String>.from(state);
    next.remove(id);
    state = next;
  }

  void clear() {
    state = {};
  }
}

final skippedMediaIdsProvider =
    NotifierProvider<SkippedMediaIdsNotifier, Set<String>>(() {
  return SkippedMediaIdsNotifier();
});

