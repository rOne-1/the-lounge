import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/media_item.dart';
import '../models/discover_filter_params.dart';
import 'ambiance_provider.dart';
import '../themes/theme_registry.dart';
import '../constants.dart';
import '../utils/weighted_rating.dart';
import 'repository_provider.dart';
export 'repository_provider.dart';

class MediaState {
  final Map<String, MediaItem> watchlist;
  final Map<String, MediaItem> maybeList; // 'Save for later' / Saved / Maybe
  final Map<String, MediaItem> watchingList; // Explicit 4th State: Watching
  final Map<String, MediaItem> watchedList;
  final Map<String, MediaItem> droppedList;
  final Map<String, MediaItem> onHoldList;
  final Map<String, Set<String>> watchedEpisodes; // showId -> set of "S1E1" episode keys
  final String watchProvidersCountry;

  const MediaState({
    this.watchlist = const {},
    this.maybeList = const {},
    this.watchingList = const {},
    this.watchedList = const {},
    this.droppedList = const {},
    this.onHoldList = const {},
    this.watchedEpisodes = const {},
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
  static const _lastMonthlyRefreshKey = 'the_lounge_last_monthly_refresh';

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

  /// Splits a show's episodes into released vs unreleased keys of the form
  /// "S{season}E{ep}". This is the ground-truth source for the B2 state
  /// machine (O1): real per-season episode data, not the TMDB summary
  /// `number_of_episodes` header field, which isn't reliably known to
  /// include unaired episodes.
  ///
  /// TMDB sometimes leaves an episode's air date null (an announced-but-
  /// unscheduled season, e.g.) rather than giving it a future date. A null
  /// date defaults to unreleased — the safer assumption, since the whole
  /// point of B2 is not falsely telling a user they're caught up. The one
  /// exception: if the user has already marked that episode watched
  /// (`watchedKeys`), their explicit action is trusted over TMDB's missing
  /// metadata, so a show can't get permanently stuck just because one
  /// episode never receives a date.
  ({Set<String> released, Set<String> unreleased}) _classifyEpisodes(
    List<TvSeason> seasons, {
    Set<String>? watchedKeys,
  }) {
    final now = DateTime.now();
    final released = <String>{};
    final unreleased = <String>{};
    for (final season in seasons) {
      for (final ep in season.episodes) {
        final key = 'S${season.seasonNumber}E${ep.episodeNumber}';
        final isDatedAndReleased =
            ep.airDate != null && !ep.airDate!.isAfter(now);
        final isUndatedButAlreadyWatched =
            ep.airDate == null && (watchedKeys?.contains(key) ?? false);
        if (isDatedAndReleased || isUndatedButAlreadyWatched) {
          released.add(key);
        } else {
          unreleased.add(key);
        }
      }
    }
    return (released: released, unreleased: unreleased);
  }

  /// Whether `seasons` actually covers every season the show is supposed to
  /// have (`item.seasonsCount`), not just however many happened to come
  /// back non-empty from the network this time. A single flaky/rate-limited
  /// fetch for one season silently drops it from the list with no error —
  /// which, left unguarded, lets the classifier reason from partial data
  /// and confidently (and wrongly) declare a show fully released. Missing
  /// data must never be read as "nothing more to release."
  bool _hasCompleteSeasonData(List<TvSeason> seasons, MediaItem item) {
    final expected = item.seasonsCount;
    if (expected == null) return true;
    return seasons.map((s) => s.seasonNumber).toSet().length >= expected;
  }

  /// Moves a show to exactly one of watched/watching/watchlist, clearing it
  /// from every other status list. Used by the B2 status state machine.
  void _setTvShowStatus(String id, MediaItem item, String target) {
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

    switch (target) {
      case 'watched':
        newWatchedList[id] = item;
        break;
      case 'watching':
        newWatchingList[id] = item;
        break;
      case 'watchlist':
        newWatchlist[id] = item;
        break;
    }

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

  void addToWatchedList(MediaItem item, {List<TvSeason>? seasons}) {
    if (state.watchedList.containsKey(item.id) &&
        !state.watchlist.containsKey(item.id) &&
        !state.maybeList.containsKey(item.id) &&
        !state.watchingList.containsKey(item.id) &&
        !state.droppedList.containsKey(item.id) &&
        !state.onHoldList.containsKey(item.id)) {
      return;
    }

    final newWatchlist = Map<String, MediaItem>.from(state.watchlist)
      ..remove(item.id);
    final newMaybeList = Map<String, MediaItem>.from(state.maybeList)
      ..remove(item.id);
    final newDroppedList = Map<String, MediaItem>.from(state.droppedList)
      ..remove(item.id);
    final newOnHoldList = Map<String, MediaItem>.from(state.onHoldList)
      ..remove(item.id);

    final newWatchedEpisodes = Map<String, Set<String>>.from(
      state.watchedEpisodes.map((k, v) => MapEntry(k, Set<String>.from(v))),
    );

    // A show can only rest in Watched once every episode is released.
    // Defaults to true for movies (no episode concept).
    bool targetIsWatched = true;

    if (item.type == MediaType.tv) {
      if (seasons != null && seasons.isNotEmpty) {
        final classified = _classifyEpisodes(
          seasons,
          watchedKeys: state.watchedEpisodes[item.id],
        );
        newWatchedEpisodes[item.id] = classified.released;
        targetIsWatched = classified.unreleased.isEmpty &&
            classified.released.isNotEmpty &&
            _hasCompleteSeasonData(seasons, item);
      } else {
        final epSet = <String>{};
        final now = DateTime.now();
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
        newWatchedEpisodes[item.id] = epSet;
        // Optimistic placement using estimated episode counts; corrected
        // below once real season data (incl. unreleased episodes) arrives.
        targetIsWatched = true;
        _enrichWatchedTvShow(item);
      }
    }

    final newWatchedList = Map<String, MediaItem>.from(state.watchedList);
    final newWatchingList = Map<String, MediaItem>.from(state.watchingList);
    if (targetIsWatched) {
      newWatchedList[item.id] = item;
      newWatchingList.remove(item.id);
    } else {
      newWatchingList[item.id] = item;
      newWatchedList.remove(item.id);
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

    if (item.type == MediaType.movie && item.belongsToCollection == null) {
      _enrichWatchedItemCollection(item.id);
    }
  }

  void _enrichWatchedItemCollection(String id) async {
    try {
      final repo = ref.read(movieRepositoryProvider);
      final details = await repo.getMediaDetails(id);
      if (details != null && details.belongsToCollection != null) {
        if (state.watchedList.containsKey(id)) {
          final currentItem = state.watchedList[id]!;
          if (currentItem.belongsToCollection == null) {
            final enrichedItem = currentItem.copyWith(
              belongsToCollection: details.belongsToCollection,
            );
            final newWatchedList = Map<String, MediaItem>.from(state.watchedList)
              ..[id] = enrichedItem;
            state = state.copyWith(watchedList: newWatchedList);
            _saveToPrefs();
          }
        }
      }
    } catch (_) {
      // Fail silently to prevent throwing during background calls
    }
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
      if (seasons == null || seasons.isEmpty) {
        _enrichSingleEpisodeWatched(showId, seasonNumber, episodeNumber, showItem);
      }
    }

    if (showEpisodes.isEmpty) {
      currentMap.remove(showId);
    } else {
      currentMap[showId] = showEpisodes;
    }

    // Prefer real per-season episode data (O1 ground truth) so a show with
    // unreleased episodes never reaches "complete" just because a stale or
    // released-only header count matches the watched count.
    int releasedCount;
    bool hasUnreleased;
    if (seasons != null && seasons.isNotEmpty) {
      final classified =
          _classifyEpisodes(seasons, watchedKeys: showEpisodes);
      releasedCount = classified.released.length;
      // Incomplete season data (a flaky fetch silently dropped one) must
      // never be read as "nothing more to release" — force hasUnreleased.
      hasUnreleased = classified.unreleased.isNotEmpty ||
          !_hasCompleteSeasonData(seasons, showItem);
    } else {
      int totalCount = totalEpisodeCount ?? 0;
      if (totalCount == 0 &&
          showItem.episodesCount != null &&
          showItem.episodesCount! > 0) {
        totalCount = showItem.episodesCount!;
      }
      if (totalCount == 0 &&
          showItem.episodesList != null &&
          showItem.episodesList!.isNotEmpty) {
        totalCount =
            showItem.episodesList!.length * (showItem.seasonsCount ?? 1);
      }
      releasedCount = totalCount;
      hasUnreleased = false;
    }

    final isFullyReleasedAndWatched = !hasUnreleased &&
        releasedCount > 0 &&
        showEpisodes.length >= releasedCount;

    state = state.copyWith(watchedEpisodes: currentMap);

    if (isFullyReleasedAndWatched) {
      _setTvShowStatus(showItem.id, showItem, 'watched');
    } else if (showEpisodes.isNotEmpty) {
      _setTvShowStatus(showItem.id, showItem, 'watching');
    } else {
      final newWatchedList = Map<String, MediaItem>.from(state.watchedList)
        ..remove(showItem.id);
      final newWatchingList = Map<String, MediaItem>.from(state.watchingList)
        ..remove(showItem.id);
      state = state.copyWith(
        watchedList: newWatchedList,
        watchingList: newWatchingList,
      );
      _saveToPrefs();
    }
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

  /// New-season/new-episode status transitions for an already-Watched show
  /// (B2/E5, locked spec). A Watched show's watchedEpisodes set is, by the
  /// "never rest in Watched" invariant enforced elsewhere, exactly its
  /// released-episode set at the time it became Watched — so any episode
  /// released or added since then shows up as a diff against fresh season
  /// data, with no separate "last known" snapshot needed.
  ///
  /// - Some newly-released episodes AND some still-unreleased ones (the new
  ///   season is mid-air) -> move to Watching.
  /// - Newly-released episodes with nothing left unreleased (new season
  ///   fully aired already), or only new unreleased episodes (announced,
  ///   not started) -> move to Watchlist.
  /// - No new content at all -> no change.
  ///
  /// A Watching show needs no action here: new episodes on an
  /// already-Watching show are absorbed by the normal watch flow.
  void reevaluateShowCompletion({
    required String showId,
    required List<TvSeason> seasons,
  }) {
    if (seasons.isEmpty) return;
    if (!state.watchedList.containsKey(showId)) return;

    final watchedSet = state.watchedEpisodes[showId] ?? <String>{};
    // No watchedKeys trust exception here, deliberately: for a genuinely
    // Watched show, watchedSet is already exactly its real released set
    // (by the "never rest in Watched" invariant), so the exception could
    // never add real coverage — but this method also fires reactively on
    // every media-provider state change (see SeasonsSectionWidget), which
    // can race addToWatchedList's optimistic fallback placement while
    // watchedSet is still a coarse, unconfirmed count-based guess rather
    // than real per-episode confirmation. Trusting it there previously let
    // a guessed episode number coincidentally "confirm" a same-numbered
    // undated real episode and misclassify it as released.
    final classified = _classifyEpisodes(seasons);
    final newlyReleased = classified.released.difference(watchedSet);

    if (newlyReleased.isEmpty && classified.unreleased.isEmpty) {
      return;
    }

    final showItem = state.watchedList[showId]!;
    final isMidAir = newlyReleased.isNotEmpty && classified.unreleased.isNotEmpty;
    _setTvShowStatus(showId, showItem, isMidAir ? 'watching' : 'watchlist');
  }

  /// Monthly refresh trigger (B2/E5): re-checks every Watched TV show for
  /// new seasons/episodes so the status state machine above also catches
  /// shows the user hasn't opened the detail page for recently. Gated by a
  /// stored timestamp so repeated calls (e.g. every Your Space open) only
  /// do real work once every 30 days.
  Future<void> refreshWatchedShowsIfDue() async {
    try {
      final prefs = ref.read(sharedPreferencesProvider);
      final lastMs = prefs.getInt(_lastMonthlyRefreshKey);
      final now = DateTime.now();
      if (lastMs != null) {
        final last = DateTime.fromMillisecondsSinceEpoch(lastMs);
        if (now.difference(last) < const Duration(days: 30)) return;
      }
      await prefs.setInt(_lastMonthlyRefreshKey, now.millisecondsSinceEpoch);

      final tvShows = state.watchedList.values
          .where((item) => item.type == MediaType.tv)
          .toList();
      final repo = ref.read(movieRepositoryProvider);

      for (final show in tvShows) {
        try {
          // Re-fetch the show's own metadata first: the stored MediaItem's
          // seasonsCount is a snapshot from whenever it was marked Watched,
          // and tvShowSeasonsProvider only fetches up to that count — so
          // without this, a wholly new season (not just new episodes within
          // an already-known one) would never even be requested.
          final freshDetails = await repo.getMediaDetails(show.id);
          final showForSeasons = freshDetails ?? show;
          final seasons =
              await ref.read(tvShowSeasonsProvider(showForSeasons).future);
          if (seasons.isNotEmpty) {
            reevaluateShowCompletion(showId: show.id, seasons: seasons);
          }
        } catch (_) {
          // Skip this show on failure; next monthly pass retries it.
        }
      }
    } catch (_) {
      // Defensively catch missing SharedPreferences override in unit tests
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

  Future<void> setWatchProvidersCountry(String countryCode) async {
    state = state.copyWith(watchProvidersCountry: countryCode);
    try {
      final prefs = ref.read(sharedPreferencesProvider);
      await prefs.setString(_watchProvidersCountryKey, countryCode);
    } catch (_) {
      // Defensively catch missing SharedPreferences override in unit tests
    }
  }

  Future<void> _enrichWatchedTvShow(MediaItem item) async {
    if (item.type != MediaType.tv) return;
    try {
      final repo = ref.read(movieRepositoryProvider);
      final seasonsCount = item.seasonsCount ?? 1;
      final List<TvSeason> seasons = [];
      for (int s = 1; s <= seasonsCount; s++) {
        final season = await repo.getTvSeasonDetails(item.id, s);
        if (season != null && season.episodes.isNotEmpty) {
          seasons.add(season);
        }
      }
      if (seasons.isNotEmpty) {
        // Deliberately no watchedKeys trust exception here: the episode set
        // currently in state for this item is still the coarse, count-based
        // guess from addToWatchedList's fallback branch (every episode
        // number up to an estimated total), not a real per-episode
        // confirmation — so it can't be trusted to decide whether an
        // undated episode is genuinely released.
        final classified = _classifyEpisodes(seasons);

        // Only correct the show we just optimistically placed above — not
        // any other show that happens to be Watched/Watching for unrelated
        // reasons.
        final currentItem =
            state.watchedList[item.id] ?? state.watchingList[item.id];
        if (currentItem != null) {
          final newWatchedEpisodes = Map<String, Set<String>>.from(
            state.watchedEpisodes.map((k, v) => MapEntry(k, Set<String>.from(v))),
          );
          newWatchedEpisodes[item.id] = classified.released;
          state = state.copyWith(watchedEpisodes: newWatchedEpisodes);

          // Never rest in Watched while unreleased episodes remain — or
          // while a season fetch came back incomplete (a flaky/rate-limited
          // request silently drops that season rather than erroring, so
          // missing data must default to "don't know, don't promote").
          final shouldBeWatched = classified.unreleased.isEmpty &&
              classified.released.isNotEmpty &&
              _hasCompleteSeasonData(seasons, item);
          final target = shouldBeWatched ? 'watched' : 'watching';
          _setTvShowStatus(item.id, currentItem, target);
        }
      }
    } catch (_) {}
  }

  Future<void> _enrichSingleEpisodeWatched(
    String showId,
    int seasonNumber,
    int episodeNumber,
    MediaItem showItem,
  ) async {
    try {
      final repo = ref.read(movieRepositoryProvider);
      final season = await repo.getTvSeasonDetails(showId, seasonNumber);
      if (season != null) {
        final now = DateTime.now();
        for (final ep in season.episodes) {
          if (ep.episodeNumber == episodeNumber &&
              ep.airDate != null &&
              ep.airDate!.isAfter(now)) {
            final currentMap = Map<String, Set<String>>.from(
              state.watchedEpisodes.map((k, v) => MapEntry(k, Set<String>.from(v))),
            );
            final showEpisodes = Set<String>.from(currentMap[showId] ?? {});
            final key = 'S${seasonNumber}E$episodeNumber';
            if (showEpisodes.contains(key)) {
              showEpisodes.remove(key);
              if (showEpisodes.isEmpty) {
                currentMap.remove(showId);
              } else {
                currentMap[showId] = showEpisodes;
              }
              state = state.copyWith(watchedEpisodes: currentMap);
              _saveToPrefs();
            }
            break;
          }
        }
      }
    } catch (_) {}
  }

  String exportBackupJson(String selectedAmbiance) {
    final backup = {
      'version': 1,
      'watchlist': state.watchlist.map((k, v) => MapEntry(k, v.toMinimalJson())),
      'maybeList': state.maybeList.map((k, v) => MapEntry(k, v.toMinimalJson())),
      'watchingList': state.watchingList.map((k, v) => MapEntry(k, v.toMinimalJson())),
      'watchedList': state.watchedList.map((k, v) => MapEntry(k, v.toMinimalJson())),
      'droppedList': state.droppedList.map((k, v) => MapEntry(k, v.toMinimalJson())),
      'onHoldList': state.onHoldList.map((k, v) => MapEntry(k, v.toMinimalJson())),
      'watchedEpisodes': state.watchedEpisodes.map((k, v) => MapEntry(k, v.toList())),
      'watchProvidersCountry': state.watchProvidersCountry,
      'selectedAmbiance': selectedAmbiance,
    };
    return jsonEncode(backup);
  }

  Future<bool> importBackupJson(String jsonString) async {
    try {
      final decoded = jsonDecode(jsonString);
      if (decoded is! Map<String, dynamic>) {
        return false;
      }
      final version = decoded['version'];
      if (version != 1) {
        return false;
      }

      Map<String, MediaItem> parseMediaMap(dynamic rawMap) {
        final Map<String, MediaItem> result = {};
        if (rawMap is Map<String, dynamic>) {
          rawMap.forEach((k, v) {
            try {
              if (v is Map<String, dynamic>) {
                result[k] = MediaItem.fromMinimalJson(v);
              }
            } catch (_) {}
          });
        }
        return result;
      }

      Map<String, Set<String>> parseWatchedEpisodes(dynamic rawMap) {
        final Map<String, Set<String>> result = {};
        if (rawMap is Map<String, dynamic>) {
          rawMap.forEach((showId, epList) {
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
      }

      final watchlist = parseMediaMap(decoded['watchlist']);
      final maybeList = parseMediaMap(decoded['maybeList']);
      final watchingList = parseMediaMap(decoded['watchingList']);
      final watchedList = parseMediaMap(decoded['watchedList']);
      final droppedList = parseMediaMap(decoded['droppedList']);
      final onHoldList = parseMediaMap(decoded['onHoldList']);
      final watchedEpisodes = parseWatchedEpisodes(decoded['watchedEpisodes']);
      
      try {
        final repo = ref.read(movieRepositoryProvider);
        final now = DateTime.now();
        for (final showId in watchedEpisodes.keys.toList()) {
          final epSet = watchedEpisodes[showId]!;
          final epsToRemove = <String>[];
          for (final epKey in epSet) {
            final match = RegExp(r'^S(\d+)E(\d+)$').firstMatch(epKey);
            if (match != null) {
              final seasonNum = int.parse(match.group(1)!);
              final epNum = int.parse(match.group(2)!);
              final season = await repo.getTvSeasonDetails(showId, seasonNum);
              if (season != null) {
                final ep = season.episodes.cast<TvEpisode?>().firstWhere(
                  (e) => e?.episodeNumber == epNum,
                  orElse: () => null,
                );
                if (ep != null && ep.airDate != null && ep.airDate!.isAfter(now)) {
                  epsToRemove.add(epKey);
                }
              }
            }
          }
          epSet.removeAll(epsToRemove);
          if (epSet.isEmpty) {
            watchedEpisodes.remove(showId);
          }
        }
      } catch (_) {}

      String country = 'US';
      if (decoded['watchProvidersCountry'] is String) {
        country = decoded['watchProvidersCountry'];
      }

      state = state.copyWith(
        watchlist: watchlist,
        maybeList: maybeList,
        watchingList: watchingList,
        watchedList: watchedList,
        droppedList: droppedList,
        onHoldList: onHoldList,
        watchedEpisodes: watchedEpisodes,
        watchProvidersCountry: country,
      );

      await _saveToPrefs();
      try {
        final prefs = ref.read(sharedPreferencesProvider);
        await prefs.setString(_watchProvidersCountryKey, country);
      } catch (_) {}

      final ambianceStr = decoded['selectedAmbiance'];
      if (ambianceStr is String) {
        String id = ambianceStr;
        if (id == 'screeningRoom') id = 'screening_room';
        if (id == 'readingRoom') id = 'reading_room';
        if (id == 'violetDusk') id = 'violet_dusk';
        final match = getThemeById(id);
        await ref.read(ambianceProvider.notifier).setAmbiance(match);
      }

      // Refresh both discover decks so newly-imported titles are evicted from
      // the in-memory pool. loadPool(isReload: false) clears the existing pool
      // and rebuilds it from page 1, re-snapshotting the updated exclusion IDs.
      try {
        ref.read(discoverMoviesDeckProvider.notifier).loadPool(isReload: false);
        ref.read(discoverTvDeckProvider.notifier).loadPool(isReload: false);
      } catch (_) {}

      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> clearAllData() async {
    state = const MediaState();
    try {
      final prefs = ref.read(sharedPreferencesProvider);
      await Future.wait([
        prefs.remove(_watchlistKey),
        prefs.remove(_maybeListKey),
        prefs.remove(_watchingListKey),
        prefs.remove(_watchedListKey),
        prefs.remove(_droppedListKey),
        prefs.remove(_onHoldListKey),
        prefs.remove(_watchedEpisodesKey),
      ]);
      ref.read(skippedMediaIdsProvider.notifier).clear();
    } catch (_) {
      // Ignore errors
    }

    // Same exclusion-refresh need as importBackupJson (B5/SP-1): a reset
    // clears the watchlist/watched/etc that the discover pool's exclusion
    // snapshot was built from, so without this, previously-excluded titles
    // stay excluded from the in-memory pool until the user happens to
    // reload it themselves.
    try {
      ref.read(discoverMoviesDeckProvider.notifier).loadPool(isReload: false);
      ref.read(discoverTvDeckProvider.notifier).loadPool(isReload: false);
    } catch (_) {}
  }
}

final mediaProvider = NotifierProvider<MediaNotifier, MediaState>(() {
  return MediaNotifier();
});

/// A title skipped more than this many times is excluded from Discover
/// permanently (B9) rather than aging out with the rest.
const int kPermanentSkipThreshold = 5;

/// How long a skip is remembered before it's pruned and the title can
/// reappear in Discover, unless it's crossed [kPermanentSkipThreshold] (B9;
/// extended from the previous 30 days per dev decision).
const Duration kSkipRetention = Duration(days: 182);

class SkipRecord {
  final DateTime lastSkippedAt;
  final int count;

  const SkipRecord({required this.lastSkippedAt, required this.count});

  bool get isPermanent => count > kPermanentSkipThreshold;

  Map<String, dynamic> toJson() => {
        'lastSkippedAt': lastSkippedAt.toIso8601String(),
        'count': count,
      };

  static SkipRecord? tryParse(dynamic json) {
    if (json is Map<String, dynamic>) {
      final dt = DateTime.tryParse(json['lastSkippedAt']?.toString() ?? '');
      final count = json['count'];
      if (dt != null && count is int) {
        return SkipRecord(lastSkippedAt: dt, count: count);
      }
    }
    return null;
  }
}

class SkippedMediaIdsNotifier extends Notifier<Map<String, SkipRecord>> {
  static const _key = 'the_lounge_skipped_media_v2';

  @override
  Map<String, SkipRecord> build() {
    Map<String, SkipRecord> loaded = {};
    try {
      final prefs = ref.watch(sharedPreferencesProvider);
      final stored = prefs.getString(_key);
      if (stored != null) {
        final decoded = jsonDecode(stored) as Map<String, dynamic>;
        final now = DateTime.now();
        final cutoff = now.subtract(kSkipRetention);
        decoded.forEach((k, v) {
          final record = SkipRecord.tryParse(v);
          if (record != null &&
              (record.isPermanent || record.lastSkippedAt.isAfter(cutoff))) {
            loaded[k] = record;
          }
        });
      }
    } catch (_) {}
    return loaded;
  }

  void _save() {
    try {
      final prefs = ref.read(sharedPreferencesProvider);
      final toSave = state.map((k, v) => MapEntry(k, v.toJson()));
      prefs.setString(_key, jsonEncode(toSave));
    } catch (_) {}
  }

  void add(String id) {
    final existing = state[id];
    state = {
      ...state,
      id: SkipRecord(
        lastSkippedAt: DateTime.now(),
        count: (existing?.count ?? 0) + 1,
      ),
    };
    _save();
  }

  void addAll(Iterable<String> ids) {
    final now = DateTime.now();
    final Map<String, SkipRecord> next = {...state};
    for (final id in ids) {
      next[id] = SkipRecord(
        lastSkippedAt: now,
        count: (state[id]?.count ?? 0) + 1,
      );
    }
    state = next;
    _save();
  }

  /// Reverts one skip (undo), decrementing the count rather than wiping the
  /// title's whole skip history -- so undoing the skip that just tipped a
  /// title into permanent correctly un-permanents it, without erasing the
  /// skips before it.
  void undoSkip(String id) {
    final existing = state[id];
    if (existing == null) return;
    final next = Map<String, SkipRecord>.from(state);
    if (existing.count <= 1) {
      next.remove(id);
    } else {
      next[id] = SkipRecord(
        lastSkippedAt: existing.lastSkippedAt,
        count: existing.count - 1,
      );
    }
    state = next;
    _save();
  }

  void clear() {
    state = {};
    _save();
  }
}

final skippedMediaIdsProvider =
    NotifierProvider<SkippedMediaIdsNotifier, Map<String, SkipRecord>>(() {
  return SkippedMediaIdsNotifier();
});

class SwipeRecord {
  final MediaItem item;
  final String direction;
  const SwipeRecord({required this.item, required this.direction});
}

class DiscoverDeckState {
  final List<MediaItem> pool;
  final SwipeRecord? lastSwipe;
  final bool isLoading;
  final Object? error;
  final int currentPage;
  final String? undoneMediaId;
  final String? undoneDirection;
  final DateTime? lastManualReloadAt;

  const DiscoverDeckState({
    this.pool = const [],
    this.lastSwipe,
    this.isLoading = false,
    this.error,
    this.currentPage = 1,
    this.undoneMediaId,
    this.undoneDirection,
    this.lastManualReloadAt,
  });

  /// B9: normal swipe-triggered pagination (see [DiscoverDeckNotifier.popCard])
  /// stays unlimited within a session -- this only gates the explicit
  /// "Reload deck" action offered once the pool is genuinely empty, to once
  /// per calendar day.
  bool get canManuallyReloadToday {
    final last = lastManualReloadAt;
    if (last == null) return true;
    final now = DateTime.now();
    return last.year != now.year ||
        last.month != now.month ||
        last.day != now.day;
  }

  DiscoverDeckState copyWith({
    List<MediaItem>? pool,
    SwipeRecord? lastSwipe,
    bool? isLoading,
    Object? error,
    int? currentPage,
    String? undoneMediaId,
    String? undoneDirection,
    bool clearUndone = false,
    DateTime? lastManualReloadAt,
  }) {
    return DiscoverDeckState(
      pool: pool ?? this.pool,
      lastSwipe: lastSwipe ?? this.lastSwipe,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      currentPage: currentPage ?? this.currentPage,
      undoneMediaId: clearUndone ? null : (undoneMediaId ?? this.undoneMediaId),
      undoneDirection: clearUndone ? null : (undoneDirection ?? this.undoneDirection),
      lastManualReloadAt: lastManualReloadAt ?? this.lastManualReloadAt,
    );
  }
}

abstract class DiscoverDeckNotifier extends Notifier<DiscoverDeckState> {
  bool get isMovies;

  /// Server-side floor (SP-3/E2, CO-9): only asks TMDB to exclude
  /// effectively-unvoted noise. The real quality bar is the weighted-rating
  /// threshold below, computed client-side once the candidate pool is in
  /// hand — a raw TMDB `vote_average.gte` floor let a 2-vote title occupy
  /// the same space as a 20,000-vote title of the same raw average.
  static const int _minVoteCountFloor = 50;

  /// `m` in the weighted-rating formula — how many votes a title needs
  /// before its own average is trusted close to face value. Deliberately
  /// higher than Browse's filter (see browse_screen.dart) since the deck is
  /// meant to read as curated, not just "everything above a bar."
  static const double _minVotesForFullWeight = 300.0;

  /// Weighted-rating cutoff a candidate must clear to enter the deck. Lower
  /// than the old raw 7.0 floor it replaces, because WR already discounts
  /// low-vote titles toward the pool mean — an absolute WR of 6.5 stays
  /// meaningfully selective without double-penalizing well-voted titles.
  static const double _weightedRatingThreshold = 6.5;

  String get _lastManualReloadKey =>
      'the_lounge_last_manual_reload_${isMovies ? 'movies' : 'tv'}';

  @override
  DiscoverDeckState build() {
    DateTime? lastManualReloadAt;
    try {
      final prefs = ref.watch(sharedPreferencesProvider);
      final stored = prefs.getString(_lastManualReloadKey);
      if (stored != null) {
        lastManualReloadAt = DateTime.tryParse(stored);
      }
    } catch (_) {}
    Future.microtask(() => loadPool());
    return DiscoverDeckState(
      isLoading: true,
      lastManualReloadAt: lastManualReloadAt,
    );
  }

  /// B9: the explicit "Reload deck" action, capped to once per calendar
  /// day (see [DiscoverDeckState.canManuallyReloadToday]). Returns false
  /// (and does nothing) if today's manual reload has already been used --
  /// callers show the "come back tomorrow" state in that case instead.
  Future<bool> manualReload() async {
    if (!state.canManuallyReloadToday) return false;
    final now = DateTime.now();
    state = state.copyWith(lastManualReloadAt: now);
    try {
      final prefs = ref.read(sharedPreferencesProvider);
      await prefs.setString(_lastManualReloadKey, now.toIso8601String());
    } catch (_) {}
    await loadPool(isReload: true);
    return true;
  }

  Future<void> loadPool({bool isReload = false}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      int page = isReload ? state.currentPage + 2 : 1;
      if (!isReload) {
        state = state.copyWith(pool: []);
      }
      
      final repo = ref.read(movieRepositoryProvider);
      final mediaState = ref.read(mediaProvider);
      final skippedIds = ref.read(skippedMediaIdsProvider);

      final excludedIds = <String>{
        ...mediaState.watchlist.keys,
        ...mediaState.maybeList.keys,
        ...mediaState.watchedList.keys,
        ...mediaState.watchingList.keys,
        ...mediaState.droppedList.keys,
        ...mediaState.onHoldList.keys,
        ...skippedIds.keys,
        ...state.pool.map((e) => e.id),
      };

      bool isExcluded(MediaItem item) {
        final cleanId = item.id.replaceFirst(RegExp(r'^(movie_|tv_)'), '');
        return excludedIds.contains(item.id) ||
            excludedIds.contains(item.prefixedId) ||
            excludedIds.contains(cleanId);
      }

      final discoverParams =
          DiscoverFilterParams(minVoteCount: _minVoteCountFloor);
      List<MediaItem> newItems = [];
      int attempts = 0;
      
      while (newItems.length < 5 && attempts < 5) {
        final List<MediaItem> rawList = [];
        final p1 = page;
        final p2 = page + 1;
        
        if (isMovies) {
          final d1 = await repo.discoverMedia(isMovies: true, params: discoverParams, page: p1);
          rawList.addAll(d1);
          try {
            final d2 = await repo.discoverMedia(isMovies: true, params: discoverParams, page: p2);
            rawList.addAll(d2);
          } catch (_) {}
          try { final pop1 = await repo.getPopularMovies(page: p1); rawList.addAll(pop1); } catch (_) {}
        } else {
          final d1 = await repo.discoverMedia(isMovies: false, params: discoverParams, page: p1);
          rawList.addAll(d1);
          try {
            final d2 = await repo.discoverMedia(isMovies: false, params: discoverParams, page: p2);
            rawList.addAll(d2);
          } catch (_) {}
          try { final top1 = await repo.getTopRatedTvShows(page: p1); rawList.addAll(top1); } catch (_) {}
        }
        
        final seen = <String>{...state.pool.map((e) => e.id), ...newItems.map((e) => e.id)};
        final poolMean = meanRatingOf(rawList);
        final filtered = rawList.where((item) {
          final wr = weightedRatingOf(
            item,
            poolMean: poolMean,
            minVotes: _minVotesForFullWeight,
          );
          return wr >= _weightedRatingThreshold &&
              !isExcluded(item) &&
              seen.add(item.id);
        }).toList();

        newItems.addAll(filtered);
        page += 2;
        attempts++;
      }
      
      state = state.copyWith(
        pool: isReload ? [...state.pool, ...newItems] : newItems,
        currentPage: page - 2,
        isLoading: false,
      );
    } catch (e) {
      state = DiscoverDeckState(pool: state.pool, isLoading: false, error: e, currentPage: state.currentPage);
    }
  }

  void popCard(MediaItem item, String direction) {
    if (state.pool.isNotEmpty) {
      final nextPool = List<MediaItem>.from(state.pool)..removeAt(0);
      state = state.copyWith(
        pool: nextPool,
        lastSwipe: SwipeRecord(item: item, direction: direction),
        clearUndone: true,
      );
      if (nextPool.isEmpty) {
        loadPool(isReload: true);
      }
    }
  }

  void undoLastSwipe() {
    final lastSwipe = state.lastSwipe;
    if (lastSwipe == null) return;

    final mediaNotifier = ref.read(mediaProvider.notifier);
    final skippedNotifier = ref.read(skippedMediaIdsProvider.notifier);

    switch (lastSwipe.direction) {
      case 'Left':
        skippedNotifier.undoSkip(lastSwipe.item.id);
        skippedNotifier.undoSkip(lastSwipe.item.prefixedId);
        break;
      case 'Right':
        mediaNotifier.removeFromMaybeList(lastSwipe.item.id);
        break;
      case 'Down':
        mediaNotifier.removeFromWatchlist(lastSwipe.item.id);
        break;
      case 'Up':
        mediaNotifier.removeFromWatchedList(lastSwipe.item.id);
        break;
    }

    state = DiscoverDeckState(
      pool: [lastSwipe.item, ...state.pool],
      lastSwipe: null,
      isLoading: state.isLoading,
      error: state.error,
      currentPage: state.currentPage,
      undoneMediaId: lastSwipe.item.id,
      undoneDirection: lastSwipe.direction,
    );
  }
}

class DiscoverMoviesDeckNotifier extends DiscoverDeckNotifier {
  @override
  bool get isMovies => true;
}

class DiscoverTvDeckNotifier extends DiscoverDeckNotifier {
  @override
  bool get isMovies => false;
}

final discoverMoviesDeckProvider =
    NotifierProvider<DiscoverMoviesDeckNotifier, DiscoverDeckState>(() {
  return DiscoverMoviesDeckNotifier();
});

final discoverTvDeckProvider =
    NotifierProvider<DiscoverTvDeckNotifier, DiscoverDeckState>(() {
  return DiscoverTvDeckNotifier();
});

