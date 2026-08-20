import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/media_item.dart';
import '../models/hall_space.dart';
import '../models/watch_record.dart';
import '../models/user_folder.dart';
import '../services/hall_storage_service.dart';
import 'ambiance_provider.dart';
import '../themes/theme_registry.dart';
import '../constants.dart';
import 'repository_provider.dart';
export 'repository_provider.dart';
import 'discover_deck_provider.dart';
export 'discover_deck_provider.dart';
export '../models/personal_rating.dart';
export '../models/watch_record.dart';
export '../models/user_folder.dart';

class MediaState {
  final Map<String, MediaItem> watchlist;
  final Map<String, MediaItem> maybeList; // 'Save for later' / Saved / Maybe
  final Map<String, MediaItem> watchingList; // Explicit 4th State: Watching
  final Map<String, MediaItem> watchedList;
  final Map<String, MediaItem> droppedList;
  final Map<String, MediaItem> onHoldList;
  final Map<String, Set<String>>
      watchedEpisodes; // showId -> set of "S1E1" episode keys
  final String watchProvidersCountry;

  /// PERS-DATA-1: unified per-title watch history log (first watches +
  /// rewatches), keyed by media ID. Source of truth for personal ratings.
  final Map<String, List<WatchRecord>> watchHistory;

  /// PERS-DATE-1: auto-derived start/end dates, keyed by media ID.
  /// `startDates` is immutable once set (never overwritten by automated
  /// status transitions). `endDates` is only populated once a title
  /// genuinely qualifies to rest in Watched (see `_setTvShowStatus`).
  final Map<String, DateTime> startDates;
  final Map<String, DateTime> endDates;

  /// Per-season start/end dates for TV shows: mediaId -> seasonNumber -> date.
  final Map<String, Map<int, DateTime>> seasonStartDates;
  final Map<String, Map<int, DateTime>> seasonEndDates;

  /// PERS-FOLDERS-1: status-independent custom folders, keyed by folder ID.
  final Map<String, UserFolder> customFolders;

  /// ORG-AGG-1: populated only for the Grand Hall (isCommon). Ids present in
  /// the shelves above only because they were aggregated in from the
  /// Mezzanine/Private Screening Halls, not because they were natively
  /// saved while inside the Grand Hall. Read-only from the Grand Hall's UI
  /// -- editing must happen from the title's actual owning Hall -- and
  /// excluded when persisting so aggregated titles never get silently
  /// duplicated into the Grand Hall's own native storage.
  final Set<String> readOnlyMediaIds;

  /// Maps a read-only aggregated id (see [readOnlyMediaIds]) to the display
  /// name of the Hall it actually lives in, for UI messaging.
  final Map<String, String> readOnlySourceHallName;

  const MediaState({
    this.watchlist = const {},
    this.maybeList = const {},
    this.watchingList = const {},
    this.watchedList = const {},
    this.droppedList = const {},
    this.onHoldList = const {},
    this.watchedEpisodes = const {},
    this.watchProvidersCountry = 'US',
    this.watchHistory = const {},
    this.startDates = const {},
    this.endDates = const {},
    this.seasonStartDates = const {},
    this.seasonEndDates = const {},
    this.customFolders = const {},
    this.readOnlyMediaIds = const {},
    this.readOnlySourceHallName = const {},
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
    Map<String, List<WatchRecord>>? watchHistory,
    Map<String, DateTime>? startDates,
    Map<String, DateTime>? endDates,
    Map<String, Map<int, DateTime>>? seasonStartDates,
    Map<String, Map<int, DateTime>>? seasonEndDates,
    Map<String, UserFolder>? customFolders,
    Set<String>? readOnlyMediaIds,
    Map<String, String>? readOnlySourceHallName,
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
      watchHistory: watchHistory ?? this.watchHistory,
      startDates: startDates ?? this.startDates,
      endDates: endDates ?? this.endDates,
      seasonStartDates: seasonStartDates ?? this.seasonStartDates,
      seasonEndDates: seasonEndDates ?? this.seasonEndDates,
      customFolders: customFolders ?? this.customFolders,
      readOnlyMediaIds: readOnlyMediaIds ?? this.readOnlyMediaIds,
      readOnlySourceHallName:
          readOnlySourceHallName ?? this.readOnlySourceHallName,
    );
  }
}

/// BACKUP-2: true while a backup import (or account reset) is actively
/// running, regardless of which import path handled it (legacy single-hall
/// or multi-hall). Analytics generation reads this to refuse computing
/// against data that's still mid-restore rather than silently generating a
/// misleading partial result.
class IsDataImportingNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void set(bool value) => state = value;
}

final isDataImportingProvider = NotifierProvider<IsDataImportingNotifier, bool>(
    IsDataImportingNotifier.new);

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
  static const _watchHistoryKey = 'the_lounge_watch_history';
  static const _startDatesKey = 'the_lounge_start_dates';
  static const _endDatesKey = 'the_lounge_end_dates';
  static const _seasonStartDatesKey = 'the_lounge_season_start_dates';
  static const _seasonEndDatesKey = 'the_lounge_season_end_dates';
  static const _customFoldersKey = 'the_lounge_custom_folders';

  HallStorageService get _storageService => HallStorageService();

  @override
  MediaState build() {
    String initialCountry = 'US';
    try {
      final prefs = ref.watch(sharedPreferencesProvider);
      final stored = prefs.getString(_watchProvidersCountryKey);
      if (stored != null && stored.isNotEmpty) {
        initialCountry = stored;
      }
      final activeHallId = _storageService.getActiveHallId(prefs);
      return _loadHallState(prefs, activeHallId, initialCountry);
    } catch (_) {
      // Defensively catch missing SharedPreferences override in unit tests
      return MediaState(watchProvidersCountry: initialCountry);
    }
  }

  /// ORG-AGG-1: the two non-Grand default Halls that get aggregated into
  /// the Grand Hall's view (id -> display name, for read-only UI messaging).
  /// Hardcoded rather than sourced from hall_provider.dart/HallSpace's
  /// dynamic hall list -- media_provider.dart deliberately does not import
  /// hall_provider.dart (see outstanding_issues_notepad.md items 32/33 on
  /// the existing circular-import caution between the two files), and these
  /// two ids are already load-bearing string literals baked into
  /// hall_space.dart's own defaultMezzanineHall()/defaultPrivateScreeningHall().
  static const Map<String, String> _aggregatedHallNames = {
    'custom_1': 'The Mezzanine Hall',
    'custom_2': 'The Private Screening Hall',
  };

  /// Loads and domain-combines (movies+tv+anime) one Hall's own archives,
  /// without touching aggregation. Shared by the "own" load below and by
  /// [_aggregateGrandHall] for each of the other Halls it pulls in.
  ({
    Map<String, MediaItem> watchlist,
    Map<String, MediaItem> maybeList,
    Map<String, MediaItem> watchingList,
    Map<String, MediaItem> watchedList,
    Map<String, MediaItem> droppedList,
    Map<String, MediaItem> onHoldList,
    Map<String, Set<String>> watchedEpisodes,
    Map<String, DateTime> startDates,
    Map<String, DateTime> endDates,
    Map<String, Map<int, DateTime>> seasonStartDates,
    Map<String, Map<int, DateTime>> seasonEndDates,
  }) _loadCombinedDomainArchive(SharedPreferences prefs, String hallId) {
    final movieKey =
        HallStorageService.domainStorageKey(hallId, MediumDomain.movies);
    final tvKey = HallStorageService.domainStorageKey(hallId, MediumDomain.tv);
    final animeKey =
        HallStorageService.domainStorageKey(hallId, MediumDomain.anime);

    DomainArchive parseDomain(String? raw) {
      if (raw == null || raw.isEmpty) return const DomainArchive();
      try {
        return DomainArchive.fromJson(
            Map<String, dynamic>.from(jsonDecode(raw) as Map));
      } catch (_) {
        return const DomainArchive();
      }
    }

    final movieArchive = parseDomain(prefs.getString(movieKey));
    final tvArchive = parseDomain(prefs.getString(tvKey));
    final animeArchive = parseDomain(prefs.getString(animeKey));

    Map<String, MediaItem> combineMaps(
        Map<String, MediaItem> Function(DomainArchive a) getter) {
      return {
        ...getter(movieArchive),
        ...getter(tvArchive),
        ...getter(animeArchive),
      };
    }

    return (
      watchlist: combineMaps((a) => a.watchlist),
      maybeList: combineMaps((a) => a.saved),
      watchingList: combineMaps((a) => a.watching),
      watchedList: combineMaps((a) => a.watched),
      droppedList: combineMaps((a) => a.dropped),
      onHoldList: combineMaps((a) => a.onHold),
      watchedEpisodes: <String, Set<String>>{
        ...movieArchive.watchedEpisodes,
        ...tvArchive.watchedEpisodes,
        ...animeArchive.watchedEpisodes,
      },
      startDates: <String, DateTime>{
        ...movieArchive.startDates,
        ...tvArchive.startDates,
        ...animeArchive.startDates,
      },
      endDates: <String, DateTime>{
        ...movieArchive.endDates,
        ...tvArchive.endDates,
        ...animeArchive.endDates,
      },
      seasonStartDates: <String, Map<int, DateTime>>{
        ...movieArchive.seasonStartDates,
        ...tvArchive.seasonStartDates,
        ...animeArchive.seasonStartDates,
      },
      seasonEndDates: <String, Map<int, DateTime>>{
        ...movieArchive.seasonEndDates,
        ...tvArchive.seasonEndDates,
        ...animeArchive.seasonEndDates,
      },
    );
  }

  /// ORG-AGG-1: the Grand Hall reads as the union of its own native saves
  /// plus the Mezzanine and Private Screening Halls' archives (own data
  /// always wins on an id conflict). Titles pulled in from the other two
  /// Halls are marked in [MediaState.readOnlyMediaIds] -- the Grand Hall UI
  /// treats them as view-only (see QuickStatusSheet), and [_saveToPrefs]
  /// excludes them when persisting so they never get duplicated into the
  /// Grand Hall's own native storage just because an unrelated save ran
  /// while they were sitting in the merged state.
  MediaState _aggregateGrandHall(SharedPreferences prefs, MediaState ownState) {
    final ownIds = <String>{
      ...ownState.watchlist.keys,
      ...ownState.maybeList.keys,
      ...ownState.watchingList.keys,
      ...ownState.watchedList.keys,
      ...ownState.droppedList.keys,
      ...ownState.onHoldList.keys,
    };

    final watchlist = Map<String, MediaItem>.of(ownState.watchlist);
    final maybeList = Map<String, MediaItem>.of(ownState.maybeList);
    final watchingList = Map<String, MediaItem>.of(ownState.watchingList);
    final watchedList = Map<String, MediaItem>.of(ownState.watchedList);
    final droppedList = Map<String, MediaItem>.of(ownState.droppedList);
    final onHoldList = Map<String, MediaItem>.of(ownState.onHoldList);
    final watchedEpisodes =
        Map<String, Set<String>>.of(ownState.watchedEpisodes);
    final startDates = Map<String, DateTime>.of(ownState.startDates);
    final endDates = Map<String, DateTime>.of(ownState.endDates);
    final seasonStartDates =
        Map<String, Map<int, DateTime>>.of(ownState.seasonStartDates);
    final seasonEndDates =
        Map<String, Map<int, DateTime>>.of(ownState.seasonEndDates);

    final readOnlyMediaIds = <String>{};
    final readOnlySourceHallName = <String, String>{};

    void mergeIn(Map<String, MediaItem> target, Map<String, MediaItem> source,
        String hallName) {
      for (final entry in source.entries) {
        if (target.containsKey(entry.key)) continue; // own data always wins
        target[entry.key] = entry.value;
        readOnlyMediaIds.add(entry.key);
        readOnlySourceHallName.putIfAbsent(entry.key, () => hallName);
      }
    }

    for (final other in _aggregatedHallNames.entries) {
      final combined = _loadCombinedDomainArchive(prefs, other.key);
      mergeIn(watchlist, combined.watchlist, other.value);
      mergeIn(maybeList, combined.maybeList, other.value);
      mergeIn(watchingList, combined.watchingList, other.value);
      mergeIn(watchedList, combined.watchedList, other.value);
      mergeIn(droppedList, combined.droppedList, other.value);
      mergeIn(onHoldList, combined.onHoldList, other.value);

      combined.watchedEpisodes.forEach((id, eps) {
        if (!ownIds.contains(id)) watchedEpisodes.putIfAbsent(id, () => eps);
      });
      combined.startDates.forEach((id, d) {
        if (!ownIds.contains(id)) startDates.putIfAbsent(id, () => d);
      });
      combined.endDates.forEach((id, d) {
        if (!ownIds.contains(id)) endDates.putIfAbsent(id, () => d);
      });
      combined.seasonStartDates.forEach((id, d) {
        if (!ownIds.contains(id)) seasonStartDates.putIfAbsent(id, () => d);
      });
      combined.seasonEndDates.forEach((id, d) {
        if (!ownIds.contains(id)) seasonEndDates.putIfAbsent(id, () => d);
      });
    }

    return ownState.copyWith(
      watchlist: watchlist,
      maybeList: maybeList,
      watchingList: watchingList,
      watchedList: watchedList,
      droppedList: droppedList,
      onHoldList: onHoldList,
      watchedEpisodes: watchedEpisodes,
      startDates: startDates,
      endDates: endDates,
      seasonStartDates: seasonStartDates,
      seasonEndDates: seasonEndDates,
      readOnlyMediaIds: readOnlyMediaIds,
      readOnlySourceHallName: readOnlySourceHallName,
    );
  }

  MediaState _loadHallState(
      SharedPreferences prefs, String hallId, String country) {
    final movieKey =
        HallStorageService.domainStorageKey(hallId, MediumDomain.movies);
    final tvKey = HallStorageService.domainStorageKey(hallId, MediumDomain.tv);
    final animeKey =
        HallStorageService.domainStorageKey(hallId, MediumDomain.anime);
    final foldersKey = HallStorageService.hallFoldersKey(hallId);
    final historyKey = HallStorageService.hallHistoryKey(hallId);

    final rawMovie = prefs.getString(movieKey);
    final rawTv = prefs.getString(tvKey);
    final rawAnime = prefs.getString(animeKey);

    if (rawMovie != null ||
        rawTv != null ||
        rawAnime != null ||
        hallId != 'common') {
      final combined = _loadCombinedDomainArchive(prefs, hallId);
      final customFolders = _parseCustomFolders(prefs, foldersKey);
      final watchHistory = _parseWatchHistory(prefs, historyKey);

      final ownState = MediaState(
        watchProvidersCountry: country,
        watchlist: combined.watchlist,
        maybeList: combined.maybeList,
        watchingList: combined.watchingList,
        watchedList: combined.watchedList,
        droppedList: combined.droppedList,
        onHoldList: combined.onHoldList,
        watchedEpisodes: combined.watchedEpisodes,
        watchHistory: watchHistory,
        startDates: combined.startDates,
        endDates: combined.endDates,
        seasonStartDates: combined.seasonStartDates,
        seasonEndDates: combined.seasonEndDates,
        customFolders: customFolders,
      );
      return hallId == 'common'
          ? _aggregateGrandHall(prefs, ownState)
          : ownState;
    }

    // Fallback: Legacy un-namespaced keys for the common Hall. This branch
    // is only ever reached when hallId == 'common' (see the condition
    // above), so it always aggregates before returning too.
    final watchlist = _parseMediaMap(prefs, _watchlistKey);
    final maybeList = _parseMediaMap(prefs, _maybeListKey);
    final watchingList = _parseMediaMap(prefs, _watchingListKey);
    final watchedList = _parseMediaMap(prefs, _watchedListKey);
    final droppedList = _parseMediaMap(prefs, _droppedListKey);
    final onHoldList = _parseMediaMap(prefs, _onHoldListKey);
    final watchedEpisodes = _parseWatchedEpisodes(prefs, _watchedEpisodesKey);
    final watchHistory = _parseWatchHistory(prefs, _watchHistoryKey);
    final startDates = _parseDateMap(prefs, _startDatesKey);
    final endDates = _parseDateMap(prefs, _endDatesKey);
    final seasonStartDates = _parseSeasonDateMap(prefs, _seasonStartDatesKey);
    final seasonEndDates = _parseSeasonDateMap(prefs, _seasonEndDatesKey);
    final customFolders = _parseCustomFolders(prefs, _customFoldersKey);

    final ownState = MediaState(
      watchProvidersCountry: country,
      watchlist: watchlist,
      maybeList: maybeList,
      watchingList: watchingList,
      watchedList: watchedList,
      droppedList: droppedList,
      onHoldList: onHoldList,
      watchedEpisodes: watchedEpisodes,
      watchHistory: watchHistory,
      startDates: startDates,
      endDates: endDates,
      seasonStartDates: seasonStartDates,
      seasonEndDates: seasonEndDates,
      customFolders: customFolders,
    );
    return _aggregateGrandHall(prefs, ownState);
  }

  Future<void> loadForHall(String hallId) async {
    try {
      final prefs = ref.read(sharedPreferencesProvider);
      final stored = prefs.getString(_watchProvidersCountryKey);
      final country = (stored != null && stored.isNotEmpty) ? stored : 'US';
      state = _loadHallState(prefs, hallId, country);
    } catch (_) {}
  }

  Future<void> _loadFromPrefs() async {
    try {
      final prefs = ref.read(sharedPreferencesProvider);
      final activeHallId = _storageService.getActiveHallId(prefs);
      final stored = prefs.getString(_watchProvidersCountryKey);
      final country = (stored != null && stored.isNotEmpty) ? stored : 'US';
      state = _loadHallState(prefs, activeHallId, country);
    } catch (_) {}
  }

  Future<void> loadFromPrefs() => _loadFromPrefs();

  Future<void> _saveToPrefs() async {
    try {
      final prefs = ref.read(sharedPreferencesProvider);
      final activeHallId = _storageService.getActiveHallId(prefs);

      // ORG-AGG-1: state.* may contain titles merged in read-only from the
      // Mezzanine/Private Screening Halls (see _aggregateGrandHall) when
      // activeHallId == 'common'. Those must never be written into the
      // Grand Hall's own native storage -- doing so on every unrelated save
      // would silently duplicate them there. Strip readOnlyMediaIds before
      // persisting anything below; this is a no-op for non-common Halls,
      // where readOnlyMediaIds is always empty.
      Map<String, V> stripReadOnly<V>(Map<String, V> map) {
        if (state.readOnlyMediaIds.isEmpty) return map;
        return Map.fromEntries(
            map.entries.where((e) => !state.readOnlyMediaIds.contains(e.key)));
      }

      final watchlist = stripReadOnly(state.watchlist);
      final maybeList = stripReadOnly(state.maybeList);
      final watchingList = stripReadOnly(state.watchingList);
      final watchedList = stripReadOnly(state.watchedList);
      final droppedList = stripReadOnly(state.droppedList);
      final onHoldList = stripReadOnly(state.onHoldList);
      final watchedEpisodes = stripReadOnly(state.watchedEpisodes);
      final startDates = stripReadOnly(state.startDates);
      final endDates = stripReadOnly(state.endDates);
      final seasonStartDates = stripReadOnly(state.seasonStartDates);
      final seasonEndDates = stripReadOnly(state.seasonEndDates);

      Map<String, MediaItem> filterType(
          Map<String, MediaItem> map, MediaType type) {
        return Map.fromEntries(map.entries.where((e) => e.value.type == type));
      }

      final movieArchive = DomainArchive(
        watchlist: filterType(watchlist, MediaType.movie),
        saved: filterType(maybeList, MediaType.movie),
        watching: filterType(watchingList, MediaType.movie),
        watched: filterType(watchedList, MediaType.movie),
        dropped: filterType(droppedList, MediaType.movie),
        onHold: filterType(onHoldList, MediaType.movie),
        startDates: startDates,
        endDates: endDates,
      );

      final tvArchive = DomainArchive(
        watchlist: filterType(watchlist, MediaType.tv),
        saved: filterType(maybeList, MediaType.tv),
        watching: filterType(watchingList, MediaType.tv),
        watched: filterType(watchedList, MediaType.tv),
        dropped: filterType(droppedList, MediaType.tv),
        onHold: filterType(onHoldList, MediaType.tv),
        watchedEpisodes: watchedEpisodes,
        startDates: startDates,
        endDates: endDates,
        seasonStartDates: seasonStartDates,
        seasonEndDates: seasonEndDates,
      );

      final movieKey = HallStorageService.domainStorageKey(
          activeHallId, MediumDomain.movies);
      final tvKey =
          HallStorageService.domainStorageKey(activeHallId, MediumDomain.tv);
      final foldersKey = HallStorageService.hallFoldersKey(activeHallId);
      final historyKey = HallStorageService.hallHistoryKey(activeHallId);

      await Future.wait([
        prefs.setString(movieKey, jsonEncode(movieArchive.toJson())),
        prefs.setString(tvKey, jsonEncode(tvArchive.toJson())),
        prefs.setString(
            foldersKey, jsonEncode(_customFoldersToJson(state.customFolders))),
        prefs.setString(
            historyKey, jsonEncode(_watchHistoryToJson(state.watchHistory))),
        if (activeHallId == 'common') ...[
          prefs.setString(
              _watchlistKey,
              jsonEncode(
                  watchlist.map((k, v) => MapEntry(k, v.toMinimalJson())))),
          prefs.setString(
              _maybeListKey,
              jsonEncode(
                  maybeList.map((k, v) => MapEntry(k, v.toMinimalJson())))),
          prefs.setString(
              _watchingListKey,
              jsonEncode(
                  watchingList.map((k, v) => MapEntry(k, v.toMinimalJson())))),
          prefs.setString(
              _watchedListKey,
              jsonEncode(
                  watchedList.map((k, v) => MapEntry(k, v.toMinimalJson())))),
          prefs.setString(
              _droppedListKey,
              jsonEncode(
                  droppedList.map((k, v) => MapEntry(k, v.toMinimalJson())))),
          prefs.setString(
              _onHoldListKey,
              jsonEncode(
                  onHoldList.map((k, v) => MapEntry(k, v.toMinimalJson())))),
          prefs.setString(
              _watchedEpisodesKey,
              jsonEncode(
                  watchedEpisodes.map((k, v) => MapEntry(k, v.toList())))),
          prefs.setString(_watchHistoryKey,
              jsonEncode(_watchHistoryToJson(state.watchHistory))),
          prefs.setString(
              _startDatesKey, jsonEncode(_dateMapToJson(startDates))),
          prefs.setString(_endDatesKey, jsonEncode(_dateMapToJson(endDates))),
          prefs.setString(_seasonStartDatesKey,
              jsonEncode(_seasonDateMapToJson(seasonStartDates))),
          prefs.setString(_seasonEndDatesKey,
              jsonEncode(_seasonDateMapToJson(seasonEndDates))),
          prefs.setString(_customFoldersKey,
              jsonEncode(_customFoldersToJson(state.customFolders))),
        ],
      ]);
    } catch (_) {
      // Defensively catch missing SharedPreferences override in unit tests
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

  Map<String, dynamic> _watchHistoryToJson(
      Map<String, List<WatchRecord>> history) {
    return history.map(
      (k, v) => MapEntry(k, v.map((r) => r.toJson()).toList()),
    );
  }

  Map<String, List<WatchRecord>> _parseWatchHistory(
      SharedPreferences prefs, String key) {
    try {
      final rawJson = prefs.getString(key);
      if (rawJson == null || rawJson.trim().isEmpty) return {};
      return _watchHistoryFromDynamic(jsonDecode(rawJson));
    } catch (_) {
      return {};
    }
  }

  Map<String, List<WatchRecord>> _watchHistoryFromDynamic(dynamic decoded) {
    final Map<String, List<WatchRecord>> result = {};
    if (decoded is Map<String, dynamic>) {
      decoded.forEach((mediaId, recordsJson) {
        try {
          if (recordsJson is List) {
            final records = recordsJson
                .whereType<Map<String, dynamic>>()
                .map((r) => WatchRecord.fromJson(r))
                .toList();
            if (records.isNotEmpty) {
              result[mediaId] = records;
            }
          }
        } catch (_) {}
      });
    }
    return result;
  }

  Map<String, dynamic> _dateMapToJson(Map<String, DateTime> map) {
    return map.map((k, v) => MapEntry(k, v.toIso8601String()));
  }

  Map<String, DateTime> _parseDateMap(SharedPreferences prefs, String key) {
    try {
      final rawJson = prefs.getString(key);
      if (rawJson == null || rawJson.trim().isEmpty) return {};
      return _dateMapFromDynamic(jsonDecode(rawJson));
    } catch (_) {
      return {};
    }
  }

  Map<String, DateTime> _dateMapFromDynamic(dynamic decoded) {
    final Map<String, DateTime> result = {};
    if (decoded is Map<String, dynamic>) {
      decoded.forEach((mediaId, dateStr) {
        final parsed = DateTime.tryParse(dateStr?.toString() ?? '');
        if (parsed != null) result[mediaId] = parsed;
      });
    }
    return result;
  }

  Map<String, dynamic> _seasonDateMapToJson(
      Map<String, Map<int, DateTime>> map) {
    return map.map((mediaId, seasonMap) => MapEntry(
          mediaId,
          seasonMap.map((season, date) =>
              MapEntry(season.toString(), date.toIso8601String())),
        ));
  }

  Map<String, Map<int, DateTime>> _parseSeasonDateMap(
      SharedPreferences prefs, String key) {
    try {
      final rawJson = prefs.getString(key);
      if (rawJson == null || rawJson.trim().isEmpty) return {};
      return _seasonDateMapFromDynamic(jsonDecode(rawJson));
    } catch (_) {
      return {};
    }
  }

  Map<String, Map<int, DateTime>> _seasonDateMapFromDynamic(dynamic decoded) {
    final Map<String, Map<int, DateTime>> result = {};
    if (decoded is Map<String, dynamic>) {
      decoded.forEach((mediaId, seasonJson) {
        if (seasonJson is Map<String, dynamic>) {
          final Map<int, DateTime> seasonMap = {};
          seasonJson.forEach((seasonStr, dateStr) {
            final seasonNum = int.tryParse(seasonStr);
            final parsed = DateTime.tryParse(dateStr?.toString() ?? '');
            if (seasonNum != null && parsed != null) {
              seasonMap[seasonNum] = parsed;
            }
          });
          if (seasonMap.isNotEmpty) result[mediaId] = seasonMap;
        }
      });
    }
    return result;
  }

  Map<String, dynamic> _customFoldersToJson(Map<String, UserFolder> folders) {
    return folders.map((k, v) => MapEntry(k, v.toJson()));
  }

  Map<String, UserFolder> _parseCustomFolders(
      SharedPreferences prefs, String key) {
    try {
      final rawJson = prefs.getString(key);
      if (rawJson == null || rawJson.trim().isEmpty) return {};
      return _customFoldersFromDynamic(jsonDecode(rawJson));
    } catch (_) {
      return {};
    }
  }

  Map<String, UserFolder> _customFoldersFromDynamic(dynamic decoded) {
    final Map<String, UserFolder> result = {};
    if (decoded is Map<String, dynamic>) {
      decoded.forEach((id, folderJson) {
        try {
          if (folderJson is Map<String, dynamic>) {
            result[id] = UserFolder.fromJson(folderJson);
          }
        } catch (_) {}
      });
    }
    return result;
  }

  /// Notepad item 15: keeps the Discover deck pools in sync with mutations
  /// from OUTSIDE Discover itself (Detail screen buttons, Browse's Quick
  /// Status Sheet), not just Discover's own swipe-triggered popCard(). Cheap
  /// local removal, no network re-fetch -- see
  /// DiscoverDeckNotifier.removeFromPoolIfPresent.
  ///
  /// Deliberately gated on `ref.exists(...)`: reading a NotifierProvider's
  /// `.notifier` for the very first time triggers its build(), and
  /// DiscoverDeckNotifier.build() unconditionally kicks off its own
  /// Future.microtask(loadPool) auto-load as a side effect. If Discover was
  /// never opened this session there's no already-loaded pool to keep in
  /// sync anyway -- but forcing that build (and its uncontrollable
  /// background fetch) here would run it in every caller of the six
  /// addTo*List methods regardless, including plain unit tests with no
  /// idea Discover exists, leaving that auto-load dangling past their
  /// ProviderContainer's disposal. Only touch the deck providers if they're
  /// already built.
  void _excludeFromDiscoverPools(String itemId) {
    try {
      if (ref.exists(discoverMoviesDeckProvider)) {
        ref
            .read(discoverMoviesDeckProvider.notifier)
            .removeFromPoolIfPresent(itemId);
      }
      if (ref.exists(discoverTvDeckProvider)) {
        ref
            .read(discoverTvDeckProvider.notifier)
            .removeFromPoolIfPresent(itemId);
      }
    } catch (_) {}
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

    // EXP-DATA-1: stamped once, never overwritten -- same convention as
    // startDates -- so "time added to Watchlist" (needed for the
    // Watchlist Funnel's conversion-rate/backlog-time metrics) is
    // actually recoverable. Only backfills when genuinely unset; an item
    // re-added after being removed keeps its original addedDate if the
    // caller already carried one forward.
    final stampedItem = item.addedDate == null
        ? item.copyWith(addedDate: DateTime.now())
        : item;

    final newWatchlist = Map<String, MediaItem>.from(state.watchlist)
      ..[item.id] = stampedItem;
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
    _excludeFromDiscoverPools(item.id);
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

    // EXP-DATA-1: same stamping convention as addToWatchlist above.
    final stampedItem = item.addedDate == null
        ? item.copyWith(addedDate: DateTime.now())
        : item;

    final newMaybeList = Map<String, MediaItem>.from(state.maybeList)
      ..[item.id] = stampedItem;
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
    _excludeFromDiscoverPools(item.id);
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

    final newStartDates = Map<String, DateTime>.from(state.startDates);
    newStartDates.putIfAbsent(item.id, () => DateTime.now());

    state = state.copyWith(
      watchlist: newWatchlist,
      maybeList: newMaybeList,
      watchingList: newWatchingList,
      watchedList: newWatchedList,
      droppedList: newDroppedList,
      onHoldList: newOnHoldList,
      startDates: newStartDates,
    );
    _saveToPrefs();
    _excludeFromDiscoverPools(item.id);
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

  /// Which season numbers in [seasons] are both fully released (every
  /// episode has an air date in the past) and fully watched (every episode
  /// key present in [watchedSet]) -- the per-season analogue of the overall
  /// "never rest in Watched while unreleased episodes remain" invariant.
  Set<int> _fullyCompletedSeasons(
      List<TvSeason> seasons, Set<String> watchedSet) {
    final now = DateTime.now();
    final result = <int>{};
    for (final season in seasons) {
      if (season.episodes.isEmpty) continue;
      final allReleased = season.episodes
          .every((ep) => ep.airDate != null && !ep.airDate!.isAfter(now));
      if (!allReleased) continue;
      final allWatched = season.episodes.every((ep) =>
          watchedSet.contains('S${season.seasonNumber}E${ep.episodeNumber}'));
      if (allWatched) result.add(season.seasonNumber);
    }
    return result;
  }

  /// Moves a show to exactly one of watched/watching/watchlist, clearing it
  /// from every other status list. Used by the B2 status state machine.
  ///
  /// PERS-DATE-1: also drives the TV date engine here, the one place every
  /// status-machine transition (manual toggle, per-episode completion,
  /// monthly refresh, new-season reopening) funnels through.
  /// - `startDate` is set (if absent) whenever a show settles into Watching
  ///   or Watched -- and, per the locked immutability invariant, never
  ///   overwritten once set, even when a later automated transition (e.g. a
  ///   new season reopening an already-Watched show) revisits this method.
  /// - `endDate` is only ever populated while the show is genuinely resting
  ///   in Watched (target == 'watched'); it's cleared whenever the show
  ///   moves away from Watched (the "airing guard" -- a newly-released
  ///   season un-qualifies a show from "finished", so its stale completion
  ///   date shouldn't linger) and recomputed as the latest per-season end
  ///   date once the show re-qualifies.
  void _setTvShowStatus(
    String id,
    MediaItem item,
    String target, {
    List<TvSeason>? seasons,
  }) {
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

    final now = DateTime.now();
    final newStartDates = Map<String, DateTime>.from(state.startDates);
    final newEndDates = Map<String, DateTime>.from(state.endDates);
    final newSeasonStartDates = _cloneSeasonDateMap(state.seasonStartDates);
    final newSeasonEndDates = _cloneSeasonDateMap(state.seasonEndDates);

    if (target == 'watching' || target == 'watched') {
      newStartDates.putIfAbsent(id, () => now);
    }

    // Per-season completion is independent of the show's overall status --
    // season 1 can genuinely be finished while season 4 is still airing (the
    // show itself stays 'watching' throughout), so this runs for either
    // target, not just once the whole show reaches 'watched'.
    if ((target == 'watching' || target == 'watched') &&
        seasons != null &&
        seasons.isNotEmpty) {
      final watchedSet = state.watchedEpisodes[id] ?? const <String>{};
      final completedSeasons = _fullyCompletedSeasons(seasons, watchedSet);
      for (final s in completedSeasons) {
        final seasonStarts = newSeasonStartDates.putIfAbsent(id, () => {});
        seasonStarts.putIfAbsent(s, () => now);
        final seasonEnds = newSeasonEndDates.putIfAbsent(id, () => {});
        seasonEnds.putIfAbsent(s, () => now);
      }
    }

    if (target == 'watched') {
      final seasonEndValues = newSeasonEndDates[id]?.values;
      if (seasonEndValues != null && seasonEndValues.isNotEmpty) {
        newEndDates[id] =
            seasonEndValues.reduce((a, b) => a.isAfter(b) ? a : b);
      } else {
        newEndDates.putIfAbsent(id, () => now);
      }
    } else {
      newEndDates.remove(id);
    }

    state = state.copyWith(
      watchlist: newWatchlist,
      maybeList: newMaybeList,
      watchingList: newWatchingList,
      watchedList: newWatchedList,
      droppedList: newDroppedList,
      onHoldList: newOnHoldList,
      startDates: newStartDates,
      endDates: newEndDates,
      seasonStartDates: newSeasonStartDates,
      seasonEndDates: newSeasonEndDates,
    );
    _saveToPrefs();
  }

  Map<String, Map<int, DateTime>> _cloneSeasonDateMap(
      Map<String, Map<int, DateTime>> source) {
    return source.map((k, v) => MapEntry(k, Map<int, DateTime>.from(v)));
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

    // PERS-RATE-1 bugfix: mirrors _setTvShowStatus's per-season completion
    // bookkeeping. Populated below only in the `seasons != null` branch --
    // the `else` branch's optimistic placement is corrected asynchronously
    // by _enrichWatchedTvShow, which itself finishes by calling
    // _setTvShowStatus (already covers seasonEndDates correctly). Without
    // this, a direct Watched toggle when season data happens to already be
    // loaded (e.g. the Seasons section already fetched it) left
    // seasonEndDates empty forever -- no season, not even the first, ever
    // became eligible for its own rating prompt/pill.
    final newSeasonStartDates = _cloneSeasonDateMap(state.seasonStartDates);
    final newSeasonEndDates = _cloneSeasonDateMap(state.seasonEndDates);

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

        final seasonNow = DateTime.now();
        final completedSeasons =
            _fullyCompletedSeasons(seasons, newWatchedEpisodes[item.id]!);
        for (final s in completedSeasons) {
          final seasonStarts =
              newSeasonStartDates.putIfAbsent(item.id, () => {});
          seasonStarts.putIfAbsent(s, () => seasonNow);
          final seasonEnds = newSeasonEndDates.putIfAbsent(item.id, () => {});
          seasonEnds.putIfAbsent(s, () => seasonNow);
        }
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

    // PERS-DATE-1: startDate is set (if absent) whenever a title first
    // settles into Watching or Watched. endDate for movies is an explicit,
    // single-shot user action (unlike TV's re-openable state machine), so
    // it's written directly each time rather than left immutable -- if the
    // user un-marks and re-marks a movie Watched later, the newer date is
    // the more accurate one. TV endDate here only covers the immediate
    // completion case (seasons already known to be fully released &
    // watched); anything still pending real season data is finalized by
    // _enrichWatchedTvShow/_setTvShowStatus once that data arrives.
    final now = DateTime.now();
    final newStartDates = Map<String, DateTime>.from(state.startDates);
    final newEndDates = Map<String, DateTime>.from(state.endDates);
    newStartDates.putIfAbsent(item.id, () => now);
    if (targetIsWatched) {
      if (item.type == MediaType.movie) {
        newEndDates[item.id] = now;
      } else {
        newEndDates.putIfAbsent(item.id, () => now);
      }
    } else {
      newEndDates.remove(item.id);
    }

    state = state.copyWith(
      watchlist: newWatchlist,
      maybeList: newMaybeList,
      watchingList: newWatchingList,
      watchedList: newWatchedList,
      droppedList: newDroppedList,
      onHoldList: newOnHoldList,
      watchedEpisodes: newWatchedEpisodes,
      startDates: newStartDates,
      endDates: newEndDates,
      seasonStartDates: newSeasonStartDates,
      seasonEndDates: newSeasonEndDates,
    );
    _saveToPrefs();
    _excludeFromDiscoverPools(item.id);

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
            final newWatchedList =
                Map<String, MediaItem>.from(state.watchedList)
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

    // This wipes ALL watch progress for the title (existing behavior, not
    // just the Watched flag -- see newWatchedEpisodes above), so the derived
    // start/end dates go with it. `watchHistory` (personal ratings/rewatch
    // log) is deliberately left untouched: those are user-authored memories,
    // not status-machine-derived state, and survive status changes.
    final newStartDates = Map<String, DateTime>.from(state.startDates)
      ..remove(id);
    final newEndDates = Map<String, DateTime>.from(state.endDates)..remove(id);
    final newSeasonStartDates = _cloneSeasonDateMap(state.seasonStartDates)
      ..remove(id);
    final newSeasonEndDates = _cloneSeasonDateMap(state.seasonEndDates)
      ..remove(id);

    state = state.copyWith(
      watchedList: newWatchedList,
      watchedEpisodes: newWatchedEpisodes,
      startDates: newStartDates,
      endDates: newEndDates,
      seasonStartDates: newSeasonStartDates,
      seasonEndDates: newSeasonEndDates,
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
    _excludeFromDiscoverPools(item.id);
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
    _excludeFromDiscoverPools(item.id);
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
        _enrichSingleEpisodeWatched(
            showId, seasonNumber, episodeNumber, showItem);
      }
    }

    if (showEpisodes.isEmpty) {
      currentMap.remove(showId);
    } else {
      currentMap[showId] = showEpisodes;
    }

    // PERS-DATE-1: record the moment this season was first started watching
    // (per-episode granularity, immutable once set) whenever an episode was
    // just added -- ahead of _setTvShowStatus below, which only reasons
    // about whole-season *completion*, not the first watched episode.
    final newSeasonStartDates = _cloneSeasonDateMap(state.seasonStartDates);
    final newStartDates = Map<String, DateTime>.from(state.startDates);
    if (showEpisodes.contains(key)) {
      newStartDates.putIfAbsent(showId, () => now);
      final seasonStarts = newSeasonStartDates.putIfAbsent(showId, () => {});
      seasonStarts.putIfAbsent(seasonNumber, () => now);
    }

    // Prefer real per-season episode data (O1 ground truth) so a show with
    // unreleased episodes never reaches "complete" just because a stale or
    // released-only header count matches the watched count.
    int releasedCount;
    bool hasUnreleased;
    if (seasons != null && seasons.isNotEmpty) {
      final classified = _classifyEpisodes(seasons, watchedKeys: showEpisodes);
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

    state = state.copyWith(
      watchedEpisodes: currentMap,
      startDates: newStartDates,
      seasonStartDates: newSeasonStartDates,
    );

    if (isFullyReleasedAndWatched) {
      _setTvShowStatus(showItem.id, showItem, 'watched', seasons: seasons);
    } else if (showEpisodes.isNotEmpty) {
      _setTvShowStatus(showItem.id, showItem, 'watching', seasons: seasons);
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
        if (!isEpisodeWatched(
            showId, season.seasonNumber, episode.episodeNumber)) {
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
    final isMidAir =
        newlyReleased.isNotEmpty && classified.unreleased.isNotEmpty;
    _setTvShowStatus(showId, showItem, isMidAir ? 'watching' : 'watchlist',
        seasons: seasons);
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
    final newStartDates = Map<String, DateTime>.from(state.startDates)
      ..remove(id);
    final newEndDates = Map<String, DateTime>.from(state.endDates)..remove(id);
    final newSeasonStartDates = _cloneSeasonDateMap(state.seasonStartDates)
      ..remove(id);
    final newSeasonEndDates = _cloneSeasonDateMap(state.seasonEndDates)
      ..remove(id);

    state = state.copyWith(
      watchlist: newWatchlist,
      maybeList: newMaybeList,
      watchingList: newWatchingList,
      watchedList: newWatchedList,
      droppedList: newDroppedList,
      onHoldList: newOnHoldList,
      watchedEpisodes: newWatchedEpisodes,
      startDates: newStartDates,
      endDates: newEndDates,
      seasonStartDates: newSeasonStartDates,
      seasonEndDates: newSeasonEndDates,
    );
    _saveToPrefs();
  }

  /// PERS-DATA-1: appends a new [WatchRecord] (first watch or rewatch) to
  /// [mediaId]'s history log. `record.recordedAt` is the record's stable
  /// identity for later `updateWatchRecord`/`deleteWatchRecord` calls.
  void addWatchRecord(String mediaId, WatchRecord record) {
    final newHistory = Map<String, List<WatchRecord>>.from(state.watchHistory);
    final records = List<WatchRecord>.from(newHistory[mediaId] ?? const []);
    records.add(record);
    newHistory[mediaId] = records;
    state = state.copyWith(watchHistory: newHistory);
    _saveToPrefs();
  }

  /// Replaces the record identified by [recordedAt] (its immutable,
  /// system-generated timestamp) with [updated]. No-op if not found.
  void updateWatchRecord(
      String mediaId, DateTime recordedAt, WatchRecord updated) {
    final newHistory = Map<String, List<WatchRecord>>.from(state.watchHistory);
    final records = newHistory[mediaId];
    if (records == null) return;
    final idx = records.indexWhere((r) => r.recordedAt == recordedAt);
    if (idx == -1) return;
    final newRecords = List<WatchRecord>.from(records);
    newRecords[idx] = updated;
    newHistory[mediaId] = newRecords;
    state = state.copyWith(watchHistory: newHistory);
    _saveToPrefs();
  }

  /// Removes the record identified by [recordedAt] from [mediaId]'s history.
  void deleteWatchRecord(String mediaId, DateTime recordedAt) {
    final newHistory = Map<String, List<WatchRecord>>.from(state.watchHistory);
    final records = newHistory[mediaId];
    if (records == null) return;
    final newRecords =
        records.where((r) => r.recordedAt != recordedAt).toList();
    if (newRecords.isEmpty) {
      newHistory.remove(mediaId);
    } else {
      newHistory[mediaId] = newRecords;
    }
    state = state.copyWith(watchHistory: newHistory);
    _saveToPrefs();
  }

  String _generateFolderId() {
    final random = Random();
    // Web bugfix: `1 << 32` truncates to 0 under dart2js/DDC's JS-backed int
    // shift semantics (fine on the Dart VM, where int is 64-bit) -- Random's
    // nextInt then throws "max must be in range 0 < max" on every call,
    // silently breaking folder creation on web only. `1 << 31` is safely
    // within Random.nextInt's 0 < max <= 2^32 requirement on every platform.
    return '${DateTime.now().microsecondsSinceEpoch}_${random.nextInt(1 << 31)}';
  }

  /// PERS-FOLDERS-1: creates a new empty folder and returns its ID.
  String createFolder(String name) {
    final id = _generateFolderId();
    final newFolders = Map<String, UserFolder>.from(state.customFolders);
    newFolders[id] = UserFolder(
      id: id,
      name: name,
      createdAt: DateTime.now(),
      mediaIds: const [],
    );
    state = state.copyWith(customFolders: newFolders);
    _saveToPrefs();
    return id;
  }

  void renameFolder(String folderId, String newName) {
    final folder = state.customFolders[folderId];
    if (folder == null) return;
    final newFolders = Map<String, UserFolder>.from(state.customFolders);
    newFolders[folderId] = folder.copyWith(name: newName);
    state = state.copyWith(customFolders: newFolders);
    _saveToPrefs();
  }

  void deleteFolder(String folderId) {
    if (!state.customFolders.containsKey(folderId)) return;
    final newFolders = Map<String, UserFolder>.from(state.customFolders)
      ..remove(folderId);
    state = state.copyWith(customFolders: newFolders);
    _saveToPrefs();
  }

  /// Replaces the folder's media ID ordering wholesale (drag-to-reorder).
  void reorderFolderItems(String folderId, List<String> newOrder) {
    final folder = state.customFolders[folderId];
    if (folder == null) return;
    final newFolders = Map<String, UserFolder>.from(state.customFolders);
    newFolders[folderId] = folder.copyWith(mediaIds: newOrder);
    state = state.copyWith(customFolders: newFolders);
    _saveToPrefs();
  }

  /// Adds [mediaId] to [folderId] if not already present. Status-independent
  /// by construction -- this never reads or touches any of the six status
  /// piles, so a folder's contents survive status changes, drops, or full
  /// removal from every pile.
  void addToFolder(String folderId, String mediaId) {
    final folder = state.customFolders[folderId];
    if (folder == null || folder.mediaIds.contains(mediaId)) return;
    final newFolders = Map<String, UserFolder>.from(state.customFolders);
    newFolders[folderId] =
        folder.copyWith(mediaIds: [...folder.mediaIds, mediaId]);
    state = state.copyWith(customFolders: newFolders);
    _saveToPrefs();
  }

  void removeFromFolder(String folderId, String mediaId) {
    final folder = state.customFolders[folderId];
    if (folder == null || !folder.mediaIds.contains(mediaId)) return;
    final newFolders = Map<String, UserFolder>.from(state.customFolders);
    newFolders[folderId] = folder.copyWith(
      mediaIds: folder.mediaIds.where((id) => id != mediaId).toList(),
    );
    state = state.copyWith(customFolders: newFolders);
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
            state.watchedEpisodes
                .map((k, v) => MapEntry(k, Set<String>.from(v))),
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
          _setTvShowStatus(item.id, currentItem, target, seasons: seasons);
        }
      }
    } catch (e, stack) {
      // Notepad item 2: this failure previously vanished with zero trace --
      // the optimistic "all episodes watched" placement from
      // addToWatchedList's fallback branch is left uncorrected until the
      // next refreshWatchedShowsIfDue pass (up to 30 days later), which is
      // the real, deliberately-scoped-out fix (would need a retry/backoff
      // scheduler or blocking the UI on the season fetch -- a bigger UX
      // change, see item 1). Logging at least makes the failure
      // diagnosable (via a future Sentry integration once E6 lands, or the
      // dev console today) instead of disappearing silently.
      developer.log(
        'Failed to enrich watched status for TV show ${item.id} -- optimistic '
        'placement stays uncorrected until the next monthly refresh.',
        name: 'MediaNotifier._enrichWatchedTvShow',
        error: e,
        stackTrace: stack,
      );
    }
  }

  /// ANLY-DATA-2: backfills `runtime`/`cast`/`director` for Watched titles
  /// that don't have them yet. This is a real, structural data gap, not a
  /// bug in ANLY-DATA-1's persistence fix: TMDB's search/discover/popular
  /// list endpoints never include `runtime`/`credits` in the first place --
  /// only the full Details endpoint does (see `getMediaDetails` in
  /// `tmdb_movie_repository.dart`). Any title marked Watched from a list/
  /// grid card (QuickStatusSheet, Discover swipe) rather than the Detail
  /// screen genuinely never had this data to persist. Mirrors
  /// `_enrichWatchedTvShow`'s fire-and-forget fetch-then-patch pattern, but
  /// runs on demand (called from `AnalyticsNotifier.generate()`, itself
  /// only ever triggered by an explicit user tap) rather than as an
  /// always-on background job -- consistent with the Analytics epic's own
  /// "never computes as a side effect" principle.
  ///
  /// [maxItems] bounds how many titles get fetched in one call, so a very
  /// large library backfills gradually across a few Generate taps instead
  /// of firing dozens of network requests at once. Already-enriched titles
  /// are skipped entirely (cheap to re-check on every call).
  Future<void> backfillMissingWatchedMetadata({int maxItems = 30}) async {
    // EXP-DATA-2: seasonsCount/episodesCount/productionCompanyNames added
    // alongside the original 3 fields -- same TMDB-Details-only
    // availability gap, needed by the TV Abandonment Rate and Studio
    // Affinity Analytics metrics.
    final missing = state.watchedList.values
        .where((item) =>
            item.runtime == null ||
            item.cast.isEmpty ||
            item.director == null ||
            (item.type == MediaType.tv &&
                (item.seasonsCount == null || item.episodesCount == null)) ||
            item.productionCompanyNames.isEmpty)
        .take(maxItems)
        .toList();
    if (missing.isEmpty) return;

    final repo = ref.read(movieRepositoryProvider);
    var patchedAny = false;
    final newWatchedList = Map<String, MediaItem>.from(state.watchedList);

    for (final item in missing) {
      try {
        final details = await repo.getMediaDetails(item.prefixedId);
        if (details == null) continue;
        // Re-check against the latest state -- the title may have been
        // unmarked Watched (or already enriched by a concurrent call)
        // while this fetch was in flight.
        final current = newWatchedList[item.id];
        if (current == null) continue;
        newWatchedList[item.id] = current.copyWith(
          runtime: current.runtime ?? details.runtime,
          cast: current.cast.isNotEmpty ? current.cast : details.cast,
          director: current.director ?? details.director,
          seasonsCount: current.seasonsCount ?? details.seasonsCount,
          episodesCount: current.episodesCount ?? details.episodesCount,
          productionCompanyNames: current.productionCompanyNames.isNotEmpty
              ? current.productionCompanyNames
              : details.productionCompanyNames,
        );
        patchedAny = true;
      } catch (e, stack) {
        developer.log(
          'Failed to backfill metadata for ${item.id} -- left unenriched '
          'until a future Generate tap retries it.',
          name: 'MediaNotifier.backfillMissingWatchedMetadata',
          error: e,
          stackTrace: stack,
        );
      }
    }

    if (patchedAny) {
      state = state.copyWith(watchedList: newWatchedList);
      await _saveToPrefs();
    }
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
              state.watchedEpisodes
                  .map((k, v) => MapEntry(k, Set<String>.from(v))),
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

  /// Backup schema version. Bumped to 3 for PERS-FOLDERS-1: adds
  /// `customFolders`. (Bumped to 2 for PERS-DATA-1/PERS-DATE-1: adds
  /// `watchHistory` and the derived start/end date maps.) `importBackupJson`
  /// still accepts version 1 and 2 backups -- fields introduced after a
  /// given backup's version simply come in defaulted to empty, same as a
  /// fresh install.
  static const int _backupSchemaVersion = 3;

  String exportBackupJson(String selectedAmbiance) {
    final backup = {
      'version': _backupSchemaVersion,
      'watchlist':
          state.watchlist.map((k, v) => MapEntry(k, v.toMinimalJson())),
      'maybeList':
          state.maybeList.map((k, v) => MapEntry(k, v.toMinimalJson())),
      'watchingList':
          state.watchingList.map((k, v) => MapEntry(k, v.toMinimalJson())),
      'watchedList':
          state.watchedList.map((k, v) => MapEntry(k, v.toMinimalJson())),
      'droppedList':
          state.droppedList.map((k, v) => MapEntry(k, v.toMinimalJson())),
      'onHoldList':
          state.onHoldList.map((k, v) => MapEntry(k, v.toMinimalJson())),
      'watchedEpisodes':
          state.watchedEpisodes.map((k, v) => MapEntry(k, v.toList())),
      'watchProvidersCountry': state.watchProvidersCountry,
      'selectedAmbiance': selectedAmbiance,
      'watchHistory': _watchHistoryToJson(state.watchHistory),
      'startDates': _dateMapToJson(state.startDates),
      'endDates': _dateMapToJson(state.endDates),
      'seasonStartDates': _seasonDateMapToJson(state.seasonStartDates),
      'seasonEndDates': _seasonDateMapToJson(state.seasonEndDates),
      'customFolders': _customFoldersToJson(state.customFolders),
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
      if (version != 1 && version != 2 && version != _backupSchemaVersion) {
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

      // v1 backups (pre-Personalization Epic) simply have no key for these --
      // the dynamic parsers below all default a missing/non-Map value to {}.
      final watchHistory = _watchHistoryFromDynamic(decoded['watchHistory']);
      final startDates = _dateMapFromDynamic(decoded['startDates']);
      final endDates = _dateMapFromDynamic(decoded['endDates']);
      final seasonStartDates =
          _seasonDateMapFromDynamic(decoded['seasonStartDates']);
      final seasonEndDates =
          _seasonDateMapFromDynamic(decoded['seasonEndDates']);
      final customFolders = _customFoldersFromDynamic(decoded['customFolders']);

      try {
        final repo = ref.read(movieRepositoryProvider);
        final now = DateTime.now();
        for (final showId in watchedEpisodes.keys.toList()) {
          final epSet = watchedEpisodes[showId]!;
          // REL-1: Group distinct season numbers for this show first so we fetch each
          // season at most ONCE, rather than firing a request per episode.
          final seasonsNeeded = <int>{};
          for (final epKey in epSet) {
            final match = RegExp(r'^S(\d+)E(\d+)$').firstMatch(epKey);
            if (match != null) {
              seasonsNeeded.add(int.parse(match.group(1)!));
            }
          }

          final fetchedSeasons = <int, TvSeason>{};
          for (final seasonNum in seasonsNeeded) {
            final season = await repo.getTvSeasonDetails(showId, seasonNum);
            if (season != null) {
              fetchedSeasons[seasonNum] = season;
            }
          }

          final epsToRemove = <String>[];
          for (final epKey in epSet) {
            final match = RegExp(r'^S(\d+)E(\d+)$').firstMatch(epKey);
            if (match != null) {
              final seasonNum = int.parse(match.group(1)!);
              final epNum = int.parse(match.group(2)!);
              final season = fetchedSeasons[seasonNum];
              if (season != null) {
                final ep = season.episodes.cast<TvEpisode?>().firstWhere(
                      (e) => e?.episodeNumber == epNum,
                      orElse: () => null,
                    );
                if (ep != null &&
                    ep.airDate != null &&
                    ep.airDate!.isAfter(now)) {
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
        watchHistory: watchHistory,
        startDates: startDates,
        endDates: endDates,
        seasonStartDates: seasonStartDates,
        seasonEndDates: seasonEndDates,
        customFolders: customFolders,
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
        prefs.remove(_watchHistoryKey),
        prefs.remove(_startDatesKey),
        prefs.remove(_endDatesKey),
        prefs.remove(_seasonStartDatesKey),
        prefs.remove(_seasonEndDatesKey),
        prefs.remove(_customFoldersKey),
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

// Discover deck state/providers (DiscoverDeckState, DiscoverDeckNotifier,
// discoverMoviesDeckProvider, discoverTvDeckProvider) live in
// discover_deck_provider.dart, imported/exported above.
