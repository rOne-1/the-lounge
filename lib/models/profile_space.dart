import 'media_item.dart';
import 'user_folder.dart';
import 'watch_record.dart';
import '../providers/navigation_provider.dart';

/// PROF-1: High-level media domain in the 3x3 Domain Matrix.
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
        return MediaTypeToggle.tv;
      case MediumDomain.anime:
        return MediaTypeToggle.tv;
    }
  }
}

/// PROF-1: The 6 archive buckets inside a domain.
enum ArchiveBucket {
  watching,
  watchlist,
  watched,
  saved,
  onHold,
  dropped;

  String get label {
    switch (this) {
      case ArchiveBucket.watching:
        return 'Watching';
      case ArchiveBucket.watchlist:
        return 'Watchlist';
      case ArchiveBucket.watched:
        return 'Watched';
      case ArchiveBucket.saved:
        return 'Saved';
      case ArchiveBucket.onHold:
        return 'On-Hold';
      case ArchiveBucket.dropped:
        return 'Dropped';
    }
  }
}

/// PROF-1: Holds all 6 archive buckets and episode completion records for a single medium domain.
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

  Map<String, MediaItem> bucket(ArchiveBucket b) {
    switch (b) {
      case ArchiveBucket.watching:
        return watching;
      case ArchiveBucket.watchlist:
        return watchlist;
      case ArchiveBucket.watched:
        return watched;
      case ArchiveBucket.saved:
        return saved;
      case ArchiveBucket.onHold:
        return onHold;
      case ArchiveBucket.dropped:
        return dropped;
    }
  }

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

/// PROF-1: 2D Partitioned Profile Space containing data across the 3 domains (Movies, TV, Anime).
class ProfileSpace {
  final String id;
  final String name;
  final String iconKey;
  final bool isCommon;
  final Map<MediumDomain, DomainArchive> domains;
  final List<UserFolder> customFolders;
  final Map<String, List<WatchRecord>> watchHistory;

  const ProfileSpace({
    required this.id,
    required this.name,
    this.iconKey = 'star',
    this.isCommon = false,
    this.domains = const {},
    this.customFolders = const [],
    this.watchHistory = const {},
  });

  DomainArchive domainArchive(MediumDomain domain) {
    return domains[domain] ?? const DomainArchive();
  }

  ProfileSpace copyWith({
    String? id,
    String? name,
    String? iconKey,
    bool? isCommon,
    Map<MediumDomain, DomainArchive>? domains,
    List<UserFolder>? customFolders,
    Map<String, List<WatchRecord>>? watchHistory,
  }) {
    return ProfileSpace(
      id: id ?? this.id,
      name: name ?? this.name,
      iconKey: iconKey ?? this.iconKey,
      isCommon: isCommon ?? this.isCommon,
      domains: domains ?? this.domains,
      customFolders: customFolders ?? this.customFolders,
      watchHistory: watchHistory ?? this.watchHistory,
    );
  }

  ProfileSpace updateDomain(MediumDomain domain, DomainArchive archive) {
    final updated = Map<MediumDomain, DomainArchive>.from(domains);
    updated[domain] = archive;
    return copyWith(domains: updated);
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'iconKey': iconKey,
        'isCommon': isCommon,
        'domains': domains.map((k, v) => MapEntry(k.name, v.toJson())),
        'customFolders': customFolders.map((f) => f.toJson()).toList(),
        'watchHistory': watchHistory.map(
          (k, v) => MapEntry(k, v.map((r) => r.toJson()).toList()),
        ),
      };

  factory ProfileSpace.fromJson(Map<String, dynamic> json) {
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

    return ProfileSpace(
      id: json['id'] as String? ?? 'common',
      name: json['name'] as String? ?? 'Common',
      iconKey: json['iconKey'] as String? ?? 'star',
      isCommon: json['isCommon'] as bool? ?? false,
      domains: domainMap,
      customFolders: folders,
      watchHistory: history,
    );
  }

  static ProfileSpace defaultCommon() {
    return const ProfileSpace(
      id: 'common',
      name: 'Common Space',
      iconKey: 'star',
      isCommon: true,
      domains: {
        MediumDomain.movies: DomainArchive(),
        MediumDomain.tv: DomainArchive(),
        MediumDomain.anime: DomainArchive(),
      },
    );
  }

  static ProfileSpace defaultCustom1() {
    return const ProfileSpace(
      id: 'custom_1',
      name: 'Persona 1',
      iconKey: 'popcorn',
      isCommon: false,
      domains: {
        MediumDomain.movies: DomainArchive(),
        MediumDomain.tv: DomainArchive(),
        MediumDomain.anime: DomainArchive(),
      },
    );
  }

  static ProfileSpace defaultCustom2() {
    return const ProfileSpace(
      id: 'custom_2',
      name: 'Persona 2',
      iconKey: 'sparkles',
      isCommon: false,
      domains: {
        MediumDomain.movies: DomainArchive(),
        MediumDomain.tv: DomainArchive(),
        MediumDomain.anime: DomainArchive(),
      },
    );
  }
}
