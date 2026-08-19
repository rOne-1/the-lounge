import 'package:flutter/material.dart';
import '../constants.dart';
import 'media_item.dart';
import 'user_folder.dart';
import 'watch_record.dart';
import '../providers/navigation_provider.dart';

/// PROF-1 / NOMEN-1: High-level media domain in the 3x3 Domain Matrix.
enum MediumDomain {
  movies,
  tv,
  anime;

  String get label {
    switch (this) {
      case MediumDomain.movies:
        return 'Movies';
      case MediumDomain.tv:
        return 'TV';
      case MediumDomain.anime:
        return 'Anime';
    }
  }

  String get singularLabel {
    switch (this) {
      case MediumDomain.movies:
        return 'Movie';
      case MediumDomain.tv:
        return 'TV Show';
      case MediumDomain.anime:
        return 'Anime';
    }
  }

  String get pluralLabel {
    switch (this) {
      case MediumDomain.movies:
        return 'Movies';
      case MediumDomain.tv:
        return 'TV Shows';
      case MediumDomain.anime:
        return 'Anime Series';
    }
  }

  static MediumDomain fromMediaTypeToggle(MediaTypeToggle toggle) {
    switch (toggle) {
      case MediaTypeToggle.movies:
        return MediumDomain.movies;
      case MediaTypeToggle.tv:
        return MediumDomain.tv;
    }
  }

  static MediumDomain fromMediaType(MediaType type) {
    switch (type) {
      case MediaType.movie:
        return MediumDomain.movies;
      case MediaType.tv:
        return MediumDomain.tv;
    }
  }

  MediaTypeToggle toMediaTypeToggle() {
    switch (this) {
      case MediumDomain.movies:
        return MediaTypeToggle.movies;
      case MediumDomain.tv:
      case MediumDomain.anime:
        return MediaTypeToggle.tv;
    }
  }
}

/// PROF-1 / NOMEN-2: The 6 archive shelves inside a media domain.
enum ArchiveShelfKind {
  watchlist,
  saved,
  watching,
  onHold,
  dropped,
  watched;

  String get label {
    switch (this) {
      case ArchiveShelfKind.watchlist:
        return 'Watchlist';
      case ArchiveShelfKind.saved:
        return 'Saved';
      case ArchiveShelfKind.watching:
        return 'Watching';
      case ArchiveShelfKind.onHold:
        return 'On-Hold';
      case ArchiveShelfKind.dropped:
        return 'Dropped';
      case ArchiveShelfKind.watched:
        return 'Watched';
    }
  }

  String get shelfLabel {
    switch (this) {
      case ArchiveShelfKind.watchlist:
        return 'Watchlist Shelf';
      case ArchiveShelfKind.saved:
        return 'Saved Shelf';
      case ArchiveShelfKind.watching:
        return 'Watching Shelf';
      case ArchiveShelfKind.onHold:
        return 'On-Hold Shelf';
      case ArchiveShelfKind.dropped:
        return 'Dropped Shelf';
      case ArchiveShelfKind.watched:
        return 'Watched Shelf';
    }
  }

  String? get subtitle {
    switch (this) {
      case ArchiveShelfKind.watchlist:
        return 'Committed watchlist of titles you plan to watch soon.';
      case ArchiveShelfKind.saved:
        return 'Soft, non-committal bookmarks for titles you might want to check out later.';
      case ArchiveShelfKind.watching:
        return 'Titles you\'re actively watching right now.';
      case ArchiveShelfKind.onHold:
        return 'Paused for now -- pick back up whenever you\'re ready.';
      case ArchiveShelfKind.dropped:
        return 'Titles you stopped watching.';
      case ArchiveShelfKind.watched:
        return null;
    }
  }

  Color get statusColor {
    switch (this) {
      case ArchiveShelfKind.watchlist:
        return AppStatusColors.watchlist;
      case ArchiveShelfKind.saved:
        return AppStatusColors.save;
      case ArchiveShelfKind.watching:
        return AppStatusColors.watching;
      case ArchiveShelfKind.onHold:
        return AppStatusColors.onHold;
      case ArchiveShelfKind.dropped:
        return AppStatusColors.dropped;
      case ArchiveShelfKind.watched:
        return AppStatusColors.watched;
    }
  }

  IconData get icon {
    switch (this) {
      case ArchiveShelfKind.watchlist:
        return Icons.bookmark_rounded;
      case ArchiveShelfKind.saved:
        return Icons.archive_rounded;
      case ArchiveShelfKind.watching:
        return Icons.play_circle_fill_rounded;
      case ArchiveShelfKind.onHold:
        return Icons.pause_circle_filled_rounded;
      case ArchiveShelfKind.dropped:
        return Icons.remove_circle_rounded;
      case ArchiveShelfKind.watched:
        return Icons.check_circle_rounded;
    }
  }

  Map<String, MediaItem> mapFrom(dynamic mediaState) {
    switch (this) {
      case ArchiveShelfKind.watchlist:
        return mediaState.watchlist as Map<String, MediaItem>;
      case ArchiveShelfKind.saved:
        return mediaState.maybeList as Map<String, MediaItem>;
      case ArchiveShelfKind.watching:
        return mediaState.watchingList as Map<String, MediaItem>;
      case ArchiveShelfKind.onHold:
        return mediaState.onHoldList as Map<String, MediaItem>;
      case ArchiveShelfKind.dropped:
        return mediaState.droppedList as Map<String, MediaItem>;
      case ArchiveShelfKind.watched:
        return mediaState.watchedList as Map<String, MediaItem>;
    }
  }
}

/// Backward compatibility alias for [ArchiveShelfKind].
typedef ArchiveBucket = ArchiveShelfKind;
typedef ArchiveBucketKind = ArchiveShelfKind;
typedef PileKind = ArchiveShelfKind;

/// PROF-1 / NOMEN-2: Holds all 6 archive shelves and episode completion records for a single medium domain.
class DomainArchive {
  final Map<String, MediaItem> watching;
  final Map<String, MediaItem> watchlist;
  final Map<String, MediaItem> watched;
  final Map<String, MediaItem> saved;
  final Map<String, MediaItem> onHold;
  final Map<String, MediaItem> dropped;
  final Map<String, Set<String>> watchedEpisodes;
  final Map<String, DateTime> startDates;
  final Map<String, DateTime> endDates;
  final Map<String, Map<int, DateTime>> seasonStartDates;
  final Map<String, Map<int, DateTime>> seasonEndDates;

  const DomainArchive({
    this.watching = const {},
    this.watchlist = const {},
    this.watched = const {},
    this.saved = const {},
    this.onHold = const {},
    this.dropped = const {},
    this.watchedEpisodes = const {},
    this.startDates = const {},
    this.endDates = const {},
    this.seasonStartDates = const {},
    this.seasonEndDates = const {},
  });

  bool get isEmpty =>
      watching.isEmpty &&
      watchlist.isEmpty &&
      watched.isEmpty &&
      saved.isEmpty &&
      onHold.isEmpty &&
      dropped.isEmpty;

  bool get isNotEmpty => !isEmpty;

  int get totalCount =>
      watching.length +
      watchlist.length +
      watched.length +
      saved.length +
      onHold.length +
      dropped.length;

  Map<String, MediaItem> shelf(ArchiveShelfKind s) {
    switch (s) {
      case ArchiveShelfKind.watching:
        return watching;
      case ArchiveShelfKind.watchlist:
        return watchlist;
      case ArchiveShelfKind.watched:
        return watched;
      case ArchiveShelfKind.saved:
        return saved;
      case ArchiveShelfKind.onHold:
        return onHold;
      case ArchiveShelfKind.dropped:
        return dropped;
    }
  }

  /// Backward compatibility alias for [shelf].
  Map<String, MediaItem> bucket(ArchiveShelfKind b) => shelf(b);

  DomainArchive copyWith({
    Map<String, MediaItem>? watching,
    Map<String, MediaItem>? watchlist,
    Map<String, MediaItem>? watched,
    Map<String, MediaItem>? saved,
    Map<String, MediaItem>? onHold,
    Map<String, MediaItem>? dropped,
    Map<String, Set<String>>? watchedEpisodes,
    Map<String, DateTime>? startDates,
    Map<String, DateTime>? endDates,
    Map<String, Map<int, DateTime>>? seasonStartDates,
    Map<String, Map<int, DateTime>>? seasonEndDates,
  }) {
    return DomainArchive(
      watching: watching ?? this.watching,
      watchlist: watchlist ?? this.watchlist,
      watched: watched ?? this.watched,
      saved: saved ?? this.saved,
      onHold: onHold ?? this.onHold,
      dropped: dropped ?? this.dropped,
      watchedEpisodes: watchedEpisodes ?? this.watchedEpisodes,
      startDates: startDates ?? this.startDates,
      endDates: endDates ?? this.endDates,
      seasonStartDates: seasonStartDates ?? this.seasonStartDates,
      seasonEndDates: seasonEndDates ?? this.seasonEndDates,
    );
  }

  Map<String, dynamic> toJson() => {
        'watching': watching.map((k, v) => MapEntry(k, v.toJson())),
        'watchlist': watchlist.map((k, v) => MapEntry(k, v.toJson())),
        'watched': watched.map((k, v) => MapEntry(k, v.toJson())),
        'saved': saved.map((k, v) => MapEntry(k, v.toJson())),
        'onHold': onHold.map((k, v) => MapEntry(k, v.toJson())),
        'dropped': dropped.map((k, v) => MapEntry(k, v.toJson())),
        'watchedEpisodes':
            watchedEpisodes.map((k, v) => MapEntry(k, v.toList())),
        'startDates':
            startDates.map((k, v) => MapEntry(k, v.toIso8601String())),
        'endDates': endDates.map((k, v) => MapEntry(k, v.toIso8601String())),
        'seasonStartDates': seasonStartDates.map(
          (k, v) => MapEntry(
            k,
            v.map((sk, sv) => MapEntry(sk.toString(), sv.toIso8601String())),
          ),
        ),
        'seasonEndDates': seasonEndDates.map(
          (k, v) => MapEntry(
            k,
            v.map((sk, sv) => MapEntry(sk.toString(), sv.toIso8601String())),
          ),
        ),
      };

  factory DomainArchive.fromJson(Map<String, dynamic> json) {
    Map<String, MediaItem> parseMap(dynamic mapRaw) {
      if (mapRaw is! Map) return {};
      final out = <String, MediaItem>{};
      for (final entry in mapRaw.entries) {
        if (entry.value is Map<String, dynamic>) {
          out[entry.key.toString()] =
              MediaItem.fromJson(entry.value as Map<String, dynamic>);
        } else if (entry.value is Map) {
          out[entry.key.toString()] = MediaItem.fromJson(
              Map<String, dynamic>.from(entry.value as Map));
        }
      }
      return out;
    }

    Map<String, Set<String>> parseEpisodes(dynamic mapRaw) {
      if (mapRaw is! Map) return {};
      final out = <String, Set<String>>{};
      for (final entry in mapRaw.entries) {
        if (entry.value is List) {
          out[entry.key.toString()] =
              (entry.value as List).map((e) => e.toString()).toSet();
        }
      }
      return out;
    }

    Map<String, DateTime> parseDates(dynamic mapRaw) {
      if (mapRaw is! Map) return {};
      final out = <String, DateTime>{};
      for (final entry in mapRaw.entries) {
        final parsed = DateTime.tryParse(entry.value.toString());
        if (parsed != null) out[entry.key.toString()] = parsed;
      }
      return out;
    }

    Map<String, Map<int, DateTime>> parseSeasonDates(dynamic mapRaw) {
      if (mapRaw is! Map) return {};
      final out = <String, Map<int, DateTime>>{};
      for (final entry in mapRaw.entries) {
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
    }

    return DomainArchive(
      watching: parseMap(json['watching']),
      watchlist: parseMap(json['watchlist']),
      watched: parseMap(json['watched']),
      saved: parseMap(json['saved'] ?? json['maybeList']),
      onHold: parseMap(json['onHold']),
      dropped: parseMap(json['dropped']),
      watchedEpisodes: parseEpisodes(json['watchedEpisodes']),
      startDates: parseDates(json['startDates']),
      endDates: parseDates(json['endDates']),
      seasonStartDates: parseSeasonDates(json['seasonStartDates']),
      seasonEndDates: parseSeasonDates(json['seasonEndDates']),
    );
  }
}

const _sentinel = Object();

/// PROF-1 / NOMEN-1: 2D Partitioned Hall Space containing data across the 3 domains (Movies, TV, Anime).
class HallSpace {
  final String id;
  final String name;
  final String iconKey;
  final bool isCommon;
  final String? themeId;
  final String? lockedLanguageCode;
  final String? lockedLanguageName;
  final Map<MediumDomain, DomainArchive> domains;
  final List<UserFolder> customFolders;
  final Map<String, List<WatchRecord>> watchHistory;

  const HallSpace({
    required this.id,
    required this.name,
    this.iconKey = 'arch',
    this.isCommon = false,
    this.themeId,
    this.lockedLanguageCode,
    this.lockedLanguageName,
    this.domains = const {},
    this.customFolders = const [],
    this.watchHistory = const {},
  });

  DomainArchive domainArchive(MediumDomain domain) {
    return domains[domain] ?? const DomainArchive();
  }

  DomainArchive archiveFor(MediumDomain domain) => domainArchive(domain);

  // lockedLanguageCode/lockedLanguageName use the sentinel pattern (like
  // DiscoverFilterParams.copyWith) rather than plain `?? this.x` -- the
  // Language Lock picker needs to be able to explicitly clear a hall back
  // to "All Languages / Unrestricted" (pass null), which `?? this.x` can
  // never express since null always falls through to the existing value.
  HallSpace copyWith({
    String? id,
    String? name,
    String? iconKey,
    bool? isCommon,
    String? themeId,
    Object? lockedLanguageCode = _sentinel,
    Object? lockedLanguageName = _sentinel,
    Map<MediumDomain, DomainArchive>? domains,
    List<UserFolder>? customFolders,
    Map<String, List<WatchRecord>>? watchHistory,
  }) {
    return HallSpace(
      id: id ?? this.id,
      name: name ?? this.name,
      iconKey: iconKey ?? this.iconKey,
      isCommon: isCommon ?? this.isCommon,
      themeId: themeId ?? this.themeId,
      lockedLanguageCode: lockedLanguageCode == _sentinel
          ? this.lockedLanguageCode
          : lockedLanguageCode as String?,
      lockedLanguageName: lockedLanguageName == _sentinel
          ? this.lockedLanguageName
          : lockedLanguageName as String?,
      domains: domains ?? this.domains,
      customFolders: customFolders ?? this.customFolders,
      watchHistory: watchHistory ?? this.watchHistory,
    );
  }

  HallSpace updateDomain(MediumDomain domain, DomainArchive archive) {
    final updated = Map<MediumDomain, DomainArchive>.from(domains);
    updated[domain] = archive;
    return copyWith(domains: updated);
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'iconKey': iconKey,
        'isCommon': isCommon,
        if (themeId != null) 'themeId': themeId,
        if (lockedLanguageCode != null) 'lockedLanguageCode': lockedLanguageCode,
        if (lockedLanguageName != null) 'lockedLanguageName': lockedLanguageName,
        'domains': domains.map((k, v) => MapEntry(k.name, v.toJson())),
        'customFolders': customFolders.map((f) => f.toJson()).toList(),
        'watchHistory': watchHistory.map(
          (k, v) => MapEntry(k, v.map((r) => r.toJson()).toList()),
        ),
      };

  factory HallSpace.fromJson(Map<String, dynamic> json) {
    final domainMap = <MediumDomain, DomainArchive>{};
    if (json['domains'] is Map) {
      final rawDomains = json['domains'] as Map;
      for (final domain in MediumDomain.values) {
        if (rawDomains.containsKey(domain.name)) {
          final raw = rawDomains[domain.name];
          if (raw is Map<String, dynamic>) {
            domainMap[domain] = DomainArchive.fromJson(raw);
          } else if (raw is Map) {
            domainMap[domain] =
                DomainArchive.fromJson(Map<String, dynamic>.from(raw));
          }
        }
      }
    }

    final folders = <UserFolder>[];
    if (json['customFolders'] is List) {
      for (final f in json['customFolders'] as List) {
        if (f is Map<String, dynamic>) {
          folders.add(UserFolder.fromJson(f));
        } else if (f is Map) {
          folders.add(UserFolder.fromJson(Map<String, dynamic>.from(f)));
        }
      }
    }

    final history = <String, List<WatchRecord>>{};
    if (json['watchHistory'] is Map) {
      final rawHist = json['watchHistory'] as Map;
      for (final entry in rawHist.entries) {
        if (entry.value is List) {
          final recs = <WatchRecord>[];
          for (final item in entry.value as List) {
            if (item is Map<String, dynamic>) {
              recs.add(WatchRecord.fromJson(item));
            } else if (item is Map) {
              recs.add(WatchRecord.fromJson(Map<String, dynamic>.from(item)));
            }
          }
          history[entry.key.toString()] = recs;
        }
      }
    }

    final id = json['id'] as String? ?? 'common';
    final rawName = json['name'] as String?;
    final isCommon = json['isCommon'] as bool? ?? (id == 'common');

    // Upgrade legacy persona names if matching old defaults
    String resolvedName;
    if (rawName == null || rawName.isEmpty) {
      resolvedName = isCommon
          ? 'The Grand Hall'
          : (id == 'custom_1' ? 'The Mezzanine Hall' : 'The Private Screening Hall');
    } else if (rawName == 'Common Space' || rawName == 'Common') {
      resolvedName = 'The Grand Hall';
    } else if (rawName == 'Persona 1') {
      resolvedName = 'The Mezzanine Hall';
    } else if (rawName == 'Persona 2') {
      resolvedName = 'The Private Screening Hall';
    } else {
      resolvedName = rawName;
    }

    final rawIcon = json['iconKey'] as String?;
    String resolvedIcon;
    if (rawIcon == null || rawIcon == 'star') {
      resolvedIcon = isCommon ? 'arch' : (id == 'custom_1' ? 'reel' : 'curtain');
    } else if (rawIcon == 'popcorn') {
      resolvedIcon = 'reel';
    } else if (rawIcon == 'sparkles') {
      resolvedIcon = 'curtain';
    } else {
      resolvedIcon = rawIcon;
    }

    return HallSpace(
      id: id,
      name: resolvedName,
      iconKey: resolvedIcon,
      isCommon: isCommon,
      themeId: json['themeId'] as String? ??
          (id == 'common' ? 'screening_room' : (id == 'custom_1' ? 'midnight_cinema' : 'reading_room')),
      lockedLanguageCode: json['lockedLanguageCode'] as String?,
      lockedLanguageName: json['lockedLanguageName'] as String?,
      domains: domainMap,
      customFolders: folders,
      watchHistory: history,
    );
  }

  static HallSpace defaultGrandHall() {
    return const HallSpace(
      id: 'common',
      name: 'The Grand Hall',
      iconKey: 'arch',
      isCommon: true,
      themeId: 'screening_room',
      domains: {
        MediumDomain.movies: DomainArchive(),
        MediumDomain.tv: DomainArchive(),
        MediumDomain.anime: DomainArchive(),
      },
    );
  }

  static HallSpace defaultMezzanineHall() {
    return const HallSpace(
      id: 'custom_1',
      name: 'The Mezzanine Hall',
      iconKey: 'reel',
      isCommon: false,
      themeId: 'midnight_cinema',
      domains: {
        MediumDomain.movies: DomainArchive(),
        MediumDomain.tv: DomainArchive(),
        MediumDomain.anime: DomainArchive(),
      },
    );
  }

  static HallSpace defaultPrivateScreeningHall() {
    return const HallSpace(
      id: 'custom_2',
      name: 'The Private Screening Hall',
      iconKey: 'curtain',
      isCommon: false,
      themeId: 'reading_room',
      domains: {
        MediumDomain.movies: DomainArchive(),
        MediumDomain.tv: DomainArchive(),
        MediumDomain.anime: DomainArchive(),
      },
    );
  }

  /// Backward compatibility aliases
  static HallSpace defaultCommon() => defaultGrandHall();
  static HallSpace defaultCustom1() => defaultMezzanineHall();
  static HallSpace defaultCustom2() => defaultPrivateScreeningHall();
}

/// Backward compatibility alias for [HallSpace].
typedef ProfileSpace = HallSpace;
