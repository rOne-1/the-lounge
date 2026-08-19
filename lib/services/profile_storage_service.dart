import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/media_item.dart';
import '../models/profile_space.dart';
import '../models/user_folder.dart';
import '../models/watch_record.dart';

/// PROF-2: Persistent Storage Engine with 2D namespaced keys (`profile_${profileId}_domain_${mediumDomain}`).
/// Handles hermetic profile data isolation, seamless legacy migration to the Common profile,
/// and v4 Multi-Profile backup JSON export/import.
class ProfileStorageService {
  static const String kLoungeProfilesManifestKey = 'lounge_profiles_manifest_v1';
  static const String kLoungeActiveProfileIdKey = 'lounge_active_profile_id';
  static const String kLoungeProfilesMigratedKey = 'lounge_profiles_migrated_v1';

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

  static String domainStorageKey(String profileId, MediumDomain domain) =>
      'profile_${profileId}_domain_${domain.name}';

  static String profileMetaKey(String profileId) => 'profile_${profileId}_meta';

  static String profileFoldersKey(String profileId) =>
      'profile_${profileId}_custom_folders';

  static String profileHistoryKey(String profileId) =>
      'profile_${profileId}_watch_history';

  /// Reads active profile ID, defaulting to 'common'.
  String getActiveProfileId(SharedPreferences prefs) {
    return prefs.getString(kLoungeActiveProfileIdKey) ?? 'common';
  }

  /// Sets active profile ID.
  Future<bool> saveActiveProfileId(
      SharedPreferences prefs, String profileId) async {
    return prefs.setString(kLoungeActiveProfileIdKey, profileId);
  }

  /// Loads all profiles from SharedPreferences synchronously.
  List<ProfileSpace> loadAllProfilesSync(SharedPreferences prefs) {
    final manifestJson = prefs.getString(kLoungeProfilesManifestKey);
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
        ProfileSpace.defaultCommon().toJson(),
        ProfileSpace.defaultCustom1().toJson(),
        ProfileSpace.defaultCustom2().toJson(),
      ];
    }

    final profiles = <ProfileSpace>[];
    for (final rawMeta in manifestList) {
      final id = rawMeta['id']?.toString() ?? 'common';
      final profile = loadProfileSync(prefs, id, defaultMeta: rawMeta);
      profiles.add(profile);
    }
    return profiles;
  }

  /// Loads all profiles from SharedPreferences. Runs migration if needed.
  Future<List<ProfileSpace>> loadAllProfiles(SharedPreferences prefs) async {
    final alreadyMigrated =
        prefs.getBool(kLoungeProfilesMigratedKey) ?? false;
    if (!alreadyMigrated) {
      await migrateLegacyToCommonIfNeeded(prefs);
    }

    final manifestJson = prefs.getString(kLoungeProfilesManifestKey);
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
      // Default 3 profiles: Common, Custom 1, Custom 2
      manifestList = [
        ProfileSpace.defaultCommon().toJson(),
        ProfileSpace.defaultCustom1().toJson(),
        ProfileSpace.defaultCustom2().toJson(),
      ];
      await prefs.setString(kLoungeProfilesManifestKey, jsonEncode(manifestList));
    }

    return loadAllProfilesSync(prefs);
  }

  /// Loads a single profile synchronously.
  ProfileSpace loadProfileSync(SharedPreferences prefs, String profileId,
      {Map<String, dynamic>? defaultMeta}) {
    String name = defaultMeta?['name']?.toString() ??
        (profileId == 'common' ? 'Common Space' : 'Persona $profileId');
    String iconKey = defaultMeta?['iconKey']?.toString() ?? 'star';
    bool isCommon = defaultMeta?['isCommon'] == true || profileId == 'common';

    // Override from profile meta key if present
    final metaJson = prefs.getString(profileMetaKey(profileId));
    if (metaJson != null) {
      try {
        final meta = jsonDecode(metaJson) as Map<String, dynamic>;
        name = meta['name']?.toString() ?? name;
        iconKey = meta['iconKey']?.toString() ?? iconKey;
        isCommon = meta['isCommon'] == true || isCommon;
      } catch (_) {}
    }

    final domains = <MediumDomain, DomainArchive>{};
    for (final domain in MediumDomain.values) {
      final domainJson = prefs.getString(domainStorageKey(profileId, domain));
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
    final foldersJson = prefs.getString(profileFoldersKey(profileId));
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
    final histJson = prefs.getString(profileHistoryKey(profileId));
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

    return ProfileSpace(
      id: profileId,
      name: name,
      iconKey: iconKey,
      isCommon: isCommon,
      domains: domains,
      customFolders: folders,
      watchHistory: history,
    );
  }

  /// Loads a single profile with all its partitioned domains.
  Future<ProfileSpace> loadProfile(SharedPreferences prefs, String profileId,
      {Map<String, dynamic>? defaultMeta}) async {
    return loadProfileSync(prefs, profileId, defaultMeta: defaultMeta);
  }

  /// Persists a profile space and all its 2D domain archives.
  Future<void> saveProfile(SharedPreferences prefs, ProfileSpace profile) async {
    // 1. Save metadata
    final meta = {
      'id': profile.id,
      'name': profile.name,
      'iconKey': profile.iconKey,
      'isCommon': profile.isCommon,
    };
    await prefs.setString(profileMetaKey(profile.id), jsonEncode(meta));

    // 2. Save domains
    for (final domain in MediumDomain.values) {
      final archive = profile.domainArchive(domain);
      await prefs.setString(
        domainStorageKey(profile.id, domain),
        jsonEncode(archive.toJson()),
      );
    }

    // 3. Save custom folders
    await prefs.setString(
      profileFoldersKey(profile.id),
      jsonEncode(profile.customFolders.map((f) => f.toJson()).toList()),
    );

    // 4. Save watch history
    final historyMap = profile.watchHistory.map(
      (k, v) => MapEntry(k, v.map((r) => r.toJson()).toList()),
    );
    await prefs.setString(profileHistoryKey(profile.id), jsonEncode(historyMap));

    // 5. Update manifest
    await _updateManifestMeta(prefs, profile);
  }

  Future<void> _updateManifestMeta(
      SharedPreferences prefs, ProfileSpace profile) async {
    final manifestJson = prefs.getString(kLoungeProfilesManifestKey);
    List<Map<String, dynamic>> manifestList = [];
    if (manifestJson != null && manifestJson.isNotEmpty) {
      try {
        final decoded = jsonDecode(manifestJson);
        if (decoded is List) {
          manifestList = decoded.map((e) => Map<String, dynamic>.from(e as Map)).toList();
        }
      } catch (_) {}
    }

    final index = manifestList.indexWhere((m) => m['id'] == profile.id);
    final metaEntry = {
      'id': profile.id,
      'name': profile.name,
      'iconKey': profile.iconKey,
      'isCommon': profile.isCommon,
    };

    if (index >= 0) {
      manifestList[index] = metaEntry;
    } else {
      manifestList.add(metaEntry);
    }

    await prefs.setString(kLoungeProfilesManifestKey, jsonEncode(manifestList));
  }

  /// Migrates legacy un-namespaced keys into the `common` profile space.
  Future<void> migrateLegacyToCommonIfNeeded(SharedPreferences prefs) async {
    final hasLegacyData = prefs.containsKey(_legacyWatchlistKey) ||
        prefs.containsKey(_legacyWatchedListKey) ||
        prefs.containsKey(_legacyWatchingListKey) ||
        prefs.containsKey(_legacyMaybeListKey);

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

      final commonProfile = ProfileSpace(
        id: 'common',
        name: 'Common Space',
        iconKey: 'star',
        isCommon: true,
        domains: {
          MediumDomain.movies: movieArchive,
          MediumDomain.tv: tvArchive,
          MediumDomain.anime: const DomainArchive(),
        },
        customFolders: folders,
        watchHistory: history,
      );

      await saveProfile(prefs, commonProfile);
    }

    await prefs.setBool(kLoungeProfilesMigratedKey, true);
  }

  /// Exports full multi-profile backup JSON (v4 schema).
  String exportFullBackupJson({
    required List<ProfileSpace> profiles,
    required String activeProfileId,
    required String themeId,
  }) {
    final payload = {
      'schema_version': 4,
      'exported_at': DateTime.now().toIso8601String(),
      'active_profile_id': activeProfileId,
      'theme_id': themeId,
      'profiles': profiles.map((p) => p.toJson()).toList(),
    };
    return const JsonEncoder.withIndent('  ').convert(payload);
  }

  /// Imports backup JSON supporting both legacy formats (v1-v3) and v4 multi-profile format.
  List<ProfileSpace> importBackupJson(String jsonString) {
    final decoded = jsonDecode(jsonString);
    if (decoded is! Map) return [];
    final json = Map<String, dynamic>.from(decoded);
    final version = json['schema_version'] as int? ?? 1;

    if (version >= 4 && json['profiles'] is List) {
      final profiles = <ProfileSpace>[];
      for (final p in json['profiles'] as List) {
        if (p is Map) {
          profiles.add(ProfileSpace.fromJson(Map<String, dynamic>.from(p)));
        }
      }
      return profiles;
    }

    // Legacy format (v1-v3): import as common profile
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
      ProfileSpace(
        id: 'common',
        name: 'Common Space',
        iconKey: 'star',
        isCommon: true,
        domains: {
          MediumDomain.movies: movieArchive,
          MediumDomain.tv: tvArchive,
          MediumDomain.anime: const DomainArchive(),
        },
      ),
      ProfileSpace.defaultCustom1(),
      ProfileSpace.defaultCustom2(),
    ];
  }
}
