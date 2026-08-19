import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/media_item.dart';
import '../models/hall_space.dart';
import '../models/user_folder.dart';
import '../models/watch_record.dart';

/// PROF-2 / NOMEN-1: Persistent Storage Engine with 2D namespaced keys (`profile_${profileId}_domain_${mediumDomain}`).
/// Handles hermetic hall data isolation, seamless legacy migration to The Grand Hall,
/// and v4 Multi-Hall backup JSON export/import.
class HallStorageService {
  static const String kLoungeHallsManifestKey = 'lounge_profiles_manifest_v1';
  static const String kLoungeProfilesManifestKey = kLoungeHallsManifestKey;

  static const String kLoungeActiveHallIdKey = 'lounge_active_profile_id';
  static const String kLoungeActiveProfileIdKey = kLoungeActiveHallIdKey;

  static const String kLoungeHallsMigratedKey = 'lounge_profiles_migrated_v1';
  static const String kLoungeProfilesMigratedKey = kLoungeHallsMigratedKey;

  // Legacy un-namespaced storage keys for migration
  static const String _legacyWatchlistKey = 'watchlist';
  static const String _legacyMaybeListKey = 'maybe_list_v1';
  static const String _legacyWatchingListKey = 'watching_list_v1';
  static const String _legacyWatchedListKey = 'watched_items_v2';
  static const String _legacyDroppedListKey = 'dropped_items_v1';
  static const String _legacyOnHoldListKey = 'on_hold_items_v1';
  static const String _legacyWatchedEpisodesKey = 'watched_episodes';
  static const String _legacyWatchHistoryKey = 'watch_history_v1';
  static const String _legacyStartDatesKey = 'media_start_dates_v1';
  static const String _legacyEndDatesKey = 'media_end_dates_v1';
  static const String _legacySeasonStartDatesKey = 'season_start_dates_v1';
  static const String _legacySeasonEndDatesKey = 'season_end_dates_v1';
  static const String _legacyCustomFoldersKey = 'user_folders_v1';

  static String domainStorageKey(String hallId, MediumDomain domain) =>
      'profile_${hallId}_domain_${domain.name}';

  static String hallMetaKey(String hallId) => 'profile_${hallId}_meta';
  static String profileMetaKey(String hallId) => hallMetaKey(hallId);

  static String hallFoldersKey(String hallId) =>
      'profile_${hallId}_custom_folders';
  static String profileFoldersKey(String hallId) => hallFoldersKey(hallId);

  static String hallHistoryKey(String hallId) =>
      'profile_${hallId}_watch_history';
  static String profileHistoryKey(String hallId) => hallHistoryKey(hallId);

  /// Reads active hall ID, defaulting to 'common'.
  String getActiveHallId(SharedPreferences prefs) {
    return prefs.getString(kLoungeActiveHallIdKey) ?? 'common';
  }

  /// Backward compatibility alias for [getActiveHallId].
  String getActiveProfileId(SharedPreferences prefs) => getActiveHallId(prefs);

  /// Sets active hall ID.
  Future<bool> saveActiveHallId(
      SharedPreferences prefs, String hallId) async {
    return prefs.setString(kLoungeActiveHallIdKey, hallId);
  }

  /// Backward compatibility alias for [saveActiveHallId].
  Future<bool> saveActiveProfileId(
          SharedPreferences prefs, String profileId) async =>
      saveActiveHallId(prefs, profileId);

  /// Loads all halls from SharedPreferences synchronously.
  List<HallSpace> loadAllHallsSync(SharedPreferences prefs) {
    final manifestJson = prefs.getString(kLoungeHallsManifestKey);
    List<Map<String, dynamic>> manifestList = [];

    if (manifestJson != null && manifestJson.isNotEmpty) {
      try {
        final decoded = jsonDecode(manifestJson);
        if (decoded is List) {
          manifestList = decoded.map((e) => Map<String, dynamic>.from(e as Map)).toList();
        }
      } catch (_) {}
    }

    if (manifestList.isEmpty) {
      manifestList = [
        HallSpace.defaultGrandHall().toJson(),
        HallSpace.defaultMezzanineHall().toJson(),
        HallSpace.defaultPrivateScreeningHall().toJson(),
      ];
    }

    final halls = <HallSpace>[];
    for (final rawMeta in manifestList) {
      final id = rawMeta['id']?.toString() ?? 'common';
      final hall = loadHallSync(prefs, id, defaultMeta: rawMeta);
      halls.add(hall);
    }
    return halls;
  }

  /// Backward compatibility alias for [loadAllHallsSync].
  List<HallSpace> loadAllProfilesSync(SharedPreferences prefs) =>
      loadAllHallsSync(prefs);

  /// Loads all halls from SharedPreferences. Runs migration if needed.
  Future<List<HallSpace>> loadAllHalls(SharedPreferences prefs) async {
    final alreadyMigrated =
        prefs.getBool(kLoungeHallsMigratedKey) ?? false;
    if (!alreadyMigrated) {
      await migrateLegacyToCommonIfNeeded(prefs);
    }

    final manifestJson = prefs.getString(kLoungeHallsManifestKey);
    List<Map<String, dynamic>> manifestList = [];

    if (manifestJson != null && manifestJson.isNotEmpty) {
      try {
        final decoded = jsonDecode(manifestJson);
        if (decoded is List) {
          manifestList = decoded.map((e) => Map<String, dynamic>.from(e as Map)).toList();
        }
      } catch (_) {}
    }

    if (manifestList.isEmpty) {
      // Default 3 halls: Grand Hall, Mezzanine Hall, Private Screening Hall
      manifestList = [
        HallSpace.defaultGrandHall().toJson(),
        HallSpace.defaultMezzanineHall().toJson(),
        HallSpace.defaultPrivateScreeningHall().toJson(),
      ];
      await prefs.setString(kLoungeHallsManifestKey, jsonEncode(manifestList));
    }

    return loadAllHallsSync(prefs);
  }

  /// Backward compatibility alias for [loadAllHalls].
  Future<List<HallSpace>> loadAllProfiles(SharedPreferences prefs) =>
      loadAllHalls(prefs);

  /// Loads a single hall synchronously.
  HallSpace loadHallSync(SharedPreferences prefs, String hallId,
      {Map<String, dynamic>? defaultMeta}) {
    String name = defaultMeta?['name']?.toString() ??
        (hallId == 'common' ? 'The Grand Hall' : (hallId == 'custom_1' ? 'The Mezzanine Hall' : 'The Private Screening Hall'));
    String iconKey = defaultMeta?['iconKey']?.toString() ?? (hallId == 'common' ? 'arch' : (hallId == 'custom_1' ? 'reel' : 'curtain'));
    bool isCommon = defaultMeta?['isCommon'] == true || hallId == 'common';
    String? themeId = defaultMeta?['themeId']?.toString();
    String? lockedLanguageCode = defaultMeta?['lockedLanguageCode']?.toString();
    String? lockedLanguageName = defaultMeta?['lockedLanguageName']?.toString();

    // Override from hall meta key if present
    final metaJson = prefs.getString(hallMetaKey(hallId));
    if (metaJson != null) {
      try {
        final meta = jsonDecode(metaJson) as Map<String, dynamic>;
        name = meta['name']?.toString() ?? name;
        iconKey = meta['iconKey']?.toString() ?? iconKey;
        isCommon = meta['isCommon'] == true || isCommon;
        themeId = meta['themeId']?.toString() ?? themeId;
        lockedLanguageCode = meta['lockedLanguageCode']?.toString() ?? lockedLanguageCode;
        lockedLanguageName = meta['lockedLanguageName']?.toString() ?? lockedLanguageName;
      } catch (_) {}
    }

    themeId ??= (hallId == 'common'
        ? 'screening_room'
        : (hallId == 'custom_1' ? 'midnight_cinema' : 'reading_room'));

    // Upgrade old names if still legacy strings
    if (name == 'Common Space' || name == 'Common') {
      name = 'The Grand Hall';
    } else if (name == 'Persona 1') {
      name = 'The Mezzanine Hall';
    } else if (name == 'Persona 2') {
      name = 'The Private Screening Hall';
    }

    if (iconKey == 'star') {
      iconKey = isCommon ? 'arch' : (hallId == 'custom_1' ? 'reel' : 'curtain');
    } else if (iconKey == 'popcorn') {
      iconKey = 'reel';
    } else if (iconKey == 'sparkles') {
      iconKey = 'curtain';
    }

    final domains = <MediumDomain, DomainArchive>{};
    for (final domain in MediumDomain.values) {
      final domainJson = prefs.getString(domainStorageKey(hallId, domain));
      if (domainJson != null && domainJson.isNotEmpty) {
        try {
          final decoded = jsonDecode(domainJson) as Map<String, dynamic>;
          domains[domain] = DomainArchive.fromJson(decoded);
        } catch (_) {
          domains[domain] = const DomainArchive();
        }
      } else {
        domains[domain] = const DomainArchive();
      }
    }

    final folders = <UserFolder>[];
    final foldersJson = prefs.getString(hallFoldersKey(hallId));
    if (foldersJson != null && foldersJson.isNotEmpty) {
      try {
        final decoded = jsonDecode(foldersJson);
        if (decoded is List) {
          for (final item in decoded) {
            folders.add(UserFolder.fromJson(Map<String, dynamic>.from(item as Map)));
          }
        }
      } catch (_) {}
    }

    final history = <String, List<WatchRecord>>{};
    final histJson = prefs.getString(hallHistoryKey(hallId));
    if (histJson != null && histJson.isNotEmpty) {
      try {
        final decoded = jsonDecode(histJson) as Map<String, dynamic>;
        for (final entry in decoded.entries) {
          if (entry.value is List) {
            history[entry.key] = (entry.value as List)
                .map((r) => WatchRecord.fromJson(Map<String, dynamic>.from(r as Map)))
                .toList();
          }
        }
      } catch (_) {}
    }

    return HallSpace(
      id: hallId,
      name: name,
      iconKey: iconKey,
      isCommon: isCommon,
      themeId: themeId,
      lockedLanguageCode: lockedLanguageCode,
      lockedLanguageName: lockedLanguageName,
      domains: domains,
      customFolders: folders,
      watchHistory: history,
    );
  }

  /// Backward compatibility alias for [loadHallSync].
  HallSpace loadProfileSync(SharedPreferences prefs, String profileId,
          {Map<String, dynamic>? defaultMeta}) =>
      loadHallSync(prefs, profileId, defaultMeta: defaultMeta);

  /// Loads a single hall with all its partitioned domains.
  Future<HallSpace> loadHall(SharedPreferences prefs, String hallId,
      {Map<String, dynamic>? defaultMeta}) async {
    return loadHallSync(prefs, hallId, defaultMeta: defaultMeta);
  }

  /// Backward compatibility alias for [loadHall].
  Future<HallSpace> loadProfile(SharedPreferences prefs, String profileId,
          {Map<String, dynamic>? defaultMeta}) =>
      loadHall(prefs, profileId, defaultMeta: defaultMeta);

  /// Persists a hall space and all its 2D domain archives.
  Future<void> saveHall(SharedPreferences prefs, HallSpace hall) async {
    // 1. Save metadata
    final meta = {
      'id': hall.id,
      'name': hall.name,
      'iconKey': hall.iconKey,
      'isCommon': hall.isCommon,
      if (hall.themeId != null) 'themeId': hall.themeId,
      if (hall.lockedLanguageCode != null) 'lockedLanguageCode': hall.lockedLanguageCode,
      if (hall.lockedLanguageName != null) 'lockedLanguageName': hall.lockedLanguageName,
    };
    await prefs.setString(hallMetaKey(hall.id), jsonEncode(meta));

    // 2. Save domains
    for (final domain in MediumDomain.values) {
      final archive = hall.domainArchive(domain);
      await prefs.setString(
        domainStorageKey(hall.id, domain),
        jsonEncode(archive.toJson()),
      );
    }

    // 3. Save custom folders
    await prefs.setString(
      hallFoldersKey(hall.id),
      jsonEncode(hall.customFolders.map((f) => f.toJson()).toList()),
    );

    // 4. Save watch history
    final historyMap = hall.watchHistory.map(
      (k, v) => MapEntry(k, v.map((r) => r.toJson()).toList()),
    );
    await prefs.setString(hallHistoryKey(hall.id), jsonEncode(historyMap));

    // 5. Update manifest
    await _updateManifestMeta(prefs, hall);
  }

  /// Backward compatibility alias for [saveHall].
  Future<void> saveProfile(SharedPreferences prefs, HallSpace profile) =>
      saveHall(prefs, profile);

  Future<void> _updateManifestMeta(
      SharedPreferences prefs, HallSpace hall) async {
    final manifestJson = prefs.getString(kLoungeHallsManifestKey);
    List<Map<String, dynamic>> manifestList = [];
    if (manifestJson != null && manifestJson.isNotEmpty) {
      try {
        final decoded = jsonDecode(manifestJson);
        if (decoded is List) {
          manifestList = decoded.map((e) => Map<String, dynamic>.from(e as Map)).toList();
        }
      } catch (_) {}
    }

    final index = manifestList.indexWhere((m) => m['id'] == hall.id);
    final metaEntry = {
      'id': hall.id,
      'name': hall.name,
      'iconKey': hall.iconKey,
      'isCommon': hall.isCommon,
      if (hall.themeId != null) 'themeId': hall.themeId,
      if (hall.lockedLanguageCode != null) 'lockedLanguageCode': hall.lockedLanguageCode,
      if (hall.lockedLanguageName != null) 'lockedLanguageName': hall.lockedLanguageName,
    };

    if (index >= 0) {
      manifestList[index] = metaEntry;
    } else {
      manifestList.add(metaEntry);
    }

    await prefs.setString(kLoungeHallsManifestKey, jsonEncode(manifestList));
  }

  /// Migrates legacy un-namespaced keys into the `common` hall space.
  Future<void> migrateLegacyToCommonIfNeeded(SharedPreferences prefs) async {
    final hasLegacyData = prefs.containsKey(_legacyWatchlistKey) ||
        prefs.containsKey(_legacyWatchedListKey) ||
        prefs.containsKey(_legacyWatchingListKey) ||
        prefs.containsKey(_legacyMaybeListKey) ||
        prefs.containsKey(_legacyWatchedEpisodesKey) ||
        prefs.containsKey(_legacyDroppedListKey) ||
        prefs.containsKey(_legacyOnHoldListKey);

    if (hasLegacyData) {
      Map<String, MediaItem> parseMap(String key) {
        final raw = prefs.getString(key);
        if (raw == null || raw.isEmpty) return {};
        try {
          final decoded = jsonDecode(raw);
          if (decoded is! Map) return {};
          final out = <String, MediaItem>{};
          for (final entry in decoded.entries) {
            if (entry.value is Map) {
              out[entry.key.toString()] = MediaItem.fromJson(
                  Map<String, dynamic>.from(entry.value as Map));
            }
          }
          return out;
        } catch (_) {
          return {};
        }
      }

      Map<String, Set<String>> parseEpisodes(String key) {
        final raw = prefs.getString(key);
        if (raw == null || raw.isEmpty) return {};
        try {
          final decoded = jsonDecode(raw);
          if (decoded is! Map) return {};
          final out = <String, Set<String>>{};
          for (final entry in decoded.entries) {
            if (entry.value is List) {
              out[entry.key.toString()] =
                  (entry.value as List).map((e) => e.toString()).toSet();
            }
          }
          return out;
        } catch (_) {
          return {};
        }
      }

      Map<String, DateTime> parseDates(String key) {
        final raw = prefs.getString(key);
        if (raw == null || raw.isEmpty) return {};
        try {
          final decoded = jsonDecode(raw);
          if (decoded is! Map) return {};
          final out = <String, DateTime>{};
          for (final entry in decoded.entries) {
            final parsed = DateTime.tryParse(entry.value.toString());
            if (parsed != null) out[entry.key.toString()] = parsed;
          }
          return out;
        } catch (_) {
          return {};
        }
      }

      Map<String, Map<int, DateTime>> parseSeasonDates(String key) {
        final raw = prefs.getString(key);
        if (raw == null || raw.isEmpty) return {};
        try {
          final decoded = jsonDecode(raw);
          if (decoded is! Map) return {};
          final out = <String, Map<int, DateTime>>{};
          for (final entry in decoded.entries) {
            if (entry.value is Map) {
              final sub = <int, DateTime>{};
              for (final subEntry in (entry.value as Map).entries) {
                final sNum = int.tryParse(subEntry.key.toString());
                final sDate = DateTime.tryParse(subEntry.value.toString());
                if (sNum != null && sDate != null) {
                  sub[sNum] = sDate;
                }
              }
              out[entry.key.toString()] = sub;
            }
          }
          return out;
        } catch (_) {
          return {};
        }
      }

      final watchlist = parseMap(_legacyWatchlistKey);
      final maybeList = parseMap(_legacyMaybeListKey);
      final watchingList = parseMap(_legacyWatchingListKey);
      final watchedList = parseMap(_legacyWatchedListKey);
      final droppedList = parseMap(_legacyDroppedListKey);
      final onHoldList = parseMap(_legacyOnHoldListKey);
      final watchedEpisodes = parseEpisodes(_legacyWatchedEpisodesKey);
      final startDates = parseDates(_legacyStartDatesKey);
      final endDates = parseDates(_legacyEndDatesKey);
      final seasonStartDates = parseSeasonDates(_legacySeasonStartDatesKey);
      final seasonEndDates = parseSeasonDates(_legacySeasonEndDatesKey);

      // Partition movies vs TV into DomainArchive
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

      final folders = <UserFolder>[];
      final foldersRaw = prefs.getString(_legacyCustomFoldersKey);
      if (foldersRaw != null && foldersRaw.isNotEmpty) {
        try {
          final decoded = jsonDecode(foldersRaw);
          if (decoded is List) {
            for (final f in decoded) {
              folders.add(UserFolder.fromJson(Map<String, dynamic>.from(f as Map)));
            }
          }
        } catch (_) {}
      }

      final history = <String, List<WatchRecord>>{};
      final histRaw = prefs.getString(_legacyWatchHistoryKey);
      if (histRaw != null && histRaw.isNotEmpty) {
        try {
          final decoded = jsonDecode(histRaw) as Map<String, dynamic>;
          for (final entry in decoded.entries) {
            if (entry.value is List) {
              history[entry.key] = (entry.value as List)
                  .map((r) => WatchRecord.fromJson(Map<String, dynamic>.from(r as Map)))
                  .toList();
            }
          }
        } catch (_) {}
      }

      final grandHall = HallSpace(
        id: 'common',
        name: 'The Grand Hall',
        iconKey: 'arch',
        isCommon: true,
        domains: {
          MediumDomain.movies: movieArchive,
          MediumDomain.tv: tvArchive,
          MediumDomain.anime: const DomainArchive(),
        },
        customFolders: folders,
        watchHistory: history,
      );

      await saveHall(prefs, grandHall);
    }

    await prefs.setBool(kLoungeHallsMigratedKey, true);
  }

  /// Exports full multi-hall backup JSON (v4 schema).
  String exportFullBackupJson({
    List<HallSpace>? halls,
    List<HallSpace>? profiles,
    String? activeHallId,
    String? activeProfileId,
    required String themeId,
  }) {
    final resolvedHalls = halls ?? profiles ?? [];
    final resolvedActiveId = activeHallId ?? activeProfileId ?? 'common';
    final payload = {
      'schema_version': 4,
      'exported_at': DateTime.now().toIso8601String(),
      'active_profile_id': resolvedActiveId,
      'theme_id': themeId,
      'profiles': resolvedHalls.map((p) => p.toJson()).toList(),
    };
    return const JsonEncoder.withIndent('  ').convert(payload);
  }

  /// Imports backup JSON supporting both legacy formats (v1-v3) and v4 multi-hall format.
  List<HallSpace> importBackupJson(String jsonString) {
    final decoded = jsonDecode(jsonString);
    if (decoded is! Map) return [];
    final json = Map<String, dynamic>.from(decoded);
    final version = json['schema_version'] as int? ?? 1;

    if (version >= 4 && json['profiles'] is List) {
      final halls = <HallSpace>[];
      for (final p in json['profiles'] as List) {
        if (p is Map) {
          halls.add(HallSpace.fromJson(Map<String, dynamic>.from(p)));
        }
      }
      return halls;
    }

    // Legacy format (v1-v3): import as Grand Hall
    Map<String, MediaItem> parseMap(dynamic raw) {
      if (raw is! Map) return {};
      final out = <String, MediaItem>{};
      for (final entry in raw.entries) {
        if (entry.value is Map) {
          out[entry.key.toString()] =
              MediaItem.fromJson(Map<String, dynamic>.from(entry.value as Map));
        }
      }
      return out;
    }

    final watchlist = parseMap(json['watchlist']);
    final maybeList = parseMap(json['maybe_list'] ?? json['maybeList']);
    final watchingList = parseMap(json['watching_list'] ?? json['watchingList']);
    final watchedList = parseMap(json['watched_list'] ?? json['watched_items']);
    final droppedList = parseMap(json['dropped_list'] ?? json['dropped_items']);
    final onHoldList = parseMap(json['on_hold_list'] ?? json['on_hold_items']);

    Map<String, MediaItem> filterType(Map<String, MediaItem> map, MediaType type) {
      return Map.fromEntries(map.entries.where((e) => e.value.type == type));
    }

    final movieArchive = DomainArchive(
      watchlist: filterType(watchlist, MediaType.movie),
      saved: filterType(maybeList, MediaType.movie),
      watching: filterType(watchingList, MediaType.movie),
      watched: filterType(watchedList, MediaType.movie),
      dropped: filterType(droppedList, MediaType.movie),
      onHold: filterType(onHoldList, MediaType.movie),
    );

    final tvArchive = DomainArchive(
      watchlist: filterType(watchlist, MediaType.tv),
      saved: filterType(maybeList, MediaType.tv),
      watching: filterType(watchingList, MediaType.tv),
      watched: filterType(watchedList, MediaType.tv),
      dropped: filterType(droppedList, MediaType.tv),
      onHold: filterType(onHoldList, MediaType.tv),
    );

    return [
      HallSpace(
        id: 'common',
        name: 'The Grand Hall',
        iconKey: 'arch',
        isCommon: true,
        domains: {
          MediumDomain.movies: movieArchive,
          MediumDomain.tv: tvArchive,
          MediumDomain.anime: const DomainArchive(),
        },
      ),
      HallSpace.defaultMezzanineHall(),
      HallSpace.defaultPrivateScreeningHall(),
    ];
  }
}

/// Backward compatibility alias for [HallStorageService].
typedef ProfileStorageService = HallStorageService;
