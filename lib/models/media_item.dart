enum MediaType {
  movie,
  tv,
}

class TvEpisode {
  final int id;
  final int episodeNumber;
  final int seasonNumber;
  final String name;
  final String? overview;
  final String? stillUrl;
  final DateTime? airDate;
  final double? voteAverage;
  final int? runtime;

  const TvEpisode({
    required this.id,
    required this.episodeNumber,
    required this.seasonNumber,
    required this.name,
    this.overview,
    this.stillUrl,
    this.airDate,
    this.voteAverage,
    this.runtime,
  });

  TvEpisode copyWith({
    int? id,
    int? episodeNumber,
    int? seasonNumber,
    String? name,
    String? overview,
    String? stillUrl,
    DateTime? airDate,
    double? voteAverage,
    int? runtime,
  }) {
    return TvEpisode(
      id: id ?? this.id,
      episodeNumber: episodeNumber ?? this.episodeNumber,
      seasonNumber: seasonNumber ?? this.seasonNumber,
      name: name ?? this.name,
      overview: overview ?? this.overview,
      stillUrl: stillUrl ?? this.stillUrl,
      airDate: airDate ?? this.airDate,
      voteAverage: voteAverage ?? this.voteAverage,
      runtime: runtime ?? this.runtime,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TvEpisode &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          episodeNumber == other.episodeNumber &&
          seasonNumber == other.seasonNumber &&
          name == other.name;

  @override
  int get hashCode =>
      id.hashCode ^ episodeNumber.hashCode ^ seasonNumber.hashCode ^ name.hashCode;
}

class TvSeason {
  final int id;
  final int seasonNumber;
  final String name;
  final String? overview;
  final String? posterUrl;
  final DateTime? airDate;
  final List<TvEpisode> episodes;

  const TvSeason({
    required this.id,
    required this.seasonNumber,
    required this.name,
    this.overview,
    this.posterUrl,
    this.airDate,
    this.episodes = const [],
  });

  TvSeason copyWith({
    int? id,
    int? seasonNumber,
    String? name,
    String? overview,
    String? posterUrl,
    DateTime? airDate,
    List<TvEpisode>? episodes,
  }) {
    return TvSeason(
      id: id ?? this.id,
      seasonNumber: seasonNumber ?? this.seasonNumber,
      name: name ?? this.name,
      overview: overview ?? this.overview,
      posterUrl: posterUrl ?? this.posterUrl,
      airDate: airDate ?? this.airDate,
      episodes: episodes ?? this.episodes,
    );
  }
}


class CastMember {
  final String id;
  final String name;
  final String? character;
  final String? profileUrl;

  const CastMember({
    required this.id,
    required this.name,
    this.character,
    this.profileUrl,
  });

  CastMember copyWith({
    String? id,
    String? name,
    String? character,
    String? profileUrl,
  }) {
    return CastMember(
      id: id ?? this.id,
      name: name ?? this.name,
      character: character ?? this.character,
      profileUrl: profileUrl ?? this.profileUrl,
    );
  }
}

class WatchProviderInfo {
  final String providerName;
  final String category; // 'Stream', 'Rent', 'Buy'

  const WatchProviderInfo({
    required this.providerName,
    required this.category,
  });

  WatchProviderInfo copyWith({
    String? providerName,
    String? category,
  }) {
    return WatchProviderInfo(
      providerName: providerName ?? this.providerName,
      category: category ?? this.category,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WatchProviderInfo &&
          runtimeType == other.runtimeType &&
          providerName == other.providerName &&
          category == other.category;

  @override
  int get hashCode => providerName.hashCode ^ category.hashCode;
}

class MediaCollection {
  final int id;
  final String name;
  final String? posterUrl;
  final String? backdropUrl;

  const MediaCollection({
    required this.id,
    required this.name,
    this.posterUrl,
    this.backdropUrl,
  });

  MediaCollection copyWith({
    int? id,
    String? name,
    String? posterUrl,
    String? backdropUrl,
  }) {
    return MediaCollection(
      id: id ?? this.id,
      name: name ?? this.name,
      posterUrl: posterUrl ?? this.posterUrl,
      backdropUrl: backdropUrl ?? this.backdropUrl,
    );
  }
}

class MediaNetwork {
  final int id;
  final String name;
  final String? logoUrl;

  const MediaNetwork({
    required this.id,
    required this.name,
    this.logoUrl,
  });

  MediaNetwork copyWith({
    int? id,
    String? name,
    String? logoUrl,
  }) {
    return MediaNetwork(
      id: id ?? this.id,
      name: name ?? this.name,
      logoUrl: logoUrl ?? this.logoUrl,
    );
  }
}

class MediaKeyword {
  final int id;
  final String name;

  const MediaKeyword({
    required this.id,
    required this.name,
  });

  MediaKeyword copyWith({
    int? id,
    String? name,
  }) {
    return MediaKeyword(
      id: id ?? this.id,
      name: name ?? this.name,
    );
  }
}

class ProductionCompany {
  final int id;
  final String name;
  final String? logoUrl;

  const ProductionCompany({
    required this.id,
    required this.name,
    this.logoUrl,
  });

  ProductionCompany copyWith({
    int? id,
    String? name,
    String? logoUrl,
  }) {
    return ProductionCompany(
      id: id ?? this.id,
      name: name ?? this.name,
      logoUrl: logoUrl ?? this.logoUrl,
    );
  }
}

class MediaVideo {
  final String id;
  final String key;
  final String name;
  final String type;
  final String site;
  final bool official;

  const MediaVideo({
    required this.id,
    required this.key,
    required this.name,
    required this.type,
    required this.site,
    this.official = false,
  });

  MediaVideo copyWith({
    String? id,
    String? key,
    String? name,
    String? type,
    String? site,
    bool? official,
  }) {
    return MediaVideo(
      id: id ?? this.id,
      key: key ?? this.key,
      name: name ?? this.name,
      type: type ?? this.type,
      site: site ?? this.site,
      official: official ?? this.official,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MediaVideo &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          key == other.key &&
          name == other.name &&
          type == other.type &&
          site == other.site &&
          official == other.official;

  @override
  int get hashCode =>
      id.hashCode ^
      key.hashCode ^
      name.hashCode ^
      type.hashCode ^
      site.hashCode ^
      official.hashCode;
}

class MediaItem {
  final String id;
  final String title;
  final MediaType type;
  final double rating;
  final DateTime? releaseOrAirDate;
  final String overview;
  final List<String> genres;
  final String? posterUrl;
  final String? detailPosterUrl;
  final String? backdropUrl;
  final int? runtime;
  final int? seasonsCount;
  final int? episodesCount;
  final List<String>? episodesList;
  final DateTime? nextEpisodeAirDate;
  final Duration? airCountdown;
  final bool hasTrailer;
  final String? trailerVideoId;
  final List<MediaVideo>? trailers;
  final bool imageLoadWillFail;
  final List<String> watchProviders;
  final Map<String, List<WatchProviderInfo>> watchProvidersByCountry;
  final List<String> cast;
  final List<CastMember> castMembers;
  final String? tagline;
  final String? director;
  final String? certification;
  final MediaCollection? belongsToCollection;
  final List<String>? createdBy;
  final List<MediaNetwork>? networks;
  final int? voteCount;
  final List<MediaKeyword>? keywords;
  final String? imdbId;
  final List<ProductionCompany>? productionCompanies;
  final String? originalLanguage;
  final List<String>? spokenLanguages;
  final String? status;

  const MediaItem({
    required this.id,
    required this.title,
    required this.type,
    required this.rating,
    this.releaseOrAirDate,
    required this.overview,
    required this.genres,
    this.posterUrl,
    this.detailPosterUrl,
    this.backdropUrl,
    this.runtime,
    this.seasonsCount,
    this.episodesCount,
    this.episodesList,
    this.nextEpisodeAirDate,
    this.airCountdown,
    this.hasTrailer = false,
    this.trailerVideoId,
    this.trailers,
    this.imageLoadWillFail = false,
    this.watchProviders = const [],
    this.watchProvidersByCountry = const {},
    this.cast = const [],
    this.castMembers = const [],
    this.tagline,
    this.director,
    this.certification,
    this.belongsToCollection,
    this.createdBy,
    this.networks,
    this.voteCount,
    this.keywords,
    this.imdbId,
    this.productionCompanies,
    this.originalLanguage,
    this.spokenLanguages,
    this.status,
  });

  /// Helper getter returning user-facing display string for original language.
  String? get originalLanguageDisplay {
    if (spokenLanguages != null && spokenLanguages!.isNotEmpty) {
      final first = spokenLanguages!.first.trim();
      if (first.isNotEmpty) return first;
    }
    if (originalLanguage == null || originalLanguage!.trim().isEmpty) {
      return null;
    }
    final raw = originalLanguage!.trim();
    const map = {
      'en': 'English',
      'ja': 'Japanese',
      'fr': 'French',
      'es': 'Spanish',
      'de': 'German',
      'ko': 'Korean',
      'it': 'Italian',
      'zh': 'Chinese',
      'ru': 'Russian',
      'pt': 'Portuguese',
      'hi': 'Hindi',
      'sv': 'Swedish',
      'da': 'Danish',
      'no': 'Norwegian',
      'nl': 'Dutch',
      'pl': 'Polish',
      'tr': 'Turkish',
      'ar': 'Arabic',
      'fi': 'Finnish',
    };
    final lower = raw.toLowerCase();
    if (map.containsKey(lower)) {
      return map[lower];
    }
    return raw.length <= 3 ? raw.toUpperCase() : raw;
  }

  /// Returns watch providers for specified country, falling back to legacy US watchProviders list.
  List<WatchProviderInfo> getWatchProvidersForCountry(String countryCode) {
    final list = watchProvidersByCountry[countryCode];
    if (list != null && list.isNotEmpty) {
      return list;
    }
    if (countryCode == 'US' && watchProviders.isNotEmpty) {
      return watchProviders
          .map((p) => WatchProviderInfo(providerName: p, category: 'Stream'))
          .toList();
    }
    return const [];
  }

  /// Convenience getter for poster in detail view.
  String? get effectiveDetailPosterUrl => detailPosterUrl ?? posterUrl;

  /// Convenience getter for release date / air date.
  DateTime? get releaseDate => releaseOrAirDate;

  /// Returns the name of the collection if present and non-empty.
  String? get collectionName {
    final name = belongsToCollection?.name;
    if (name != null && name.trim().isNotEmpty) {
      return name.trim();
    }
    return null;
  }

  /// Returns the ID strictly type-prefixed (e.g. "movie_123" or "tv_123").
  String get prefixedId {
    if (id.startsWith('movie_') || id.startsWith('tv_')) {
      return id;
    }
    return '${type == MediaType.tv ? 'tv' : 'movie'}_$id';
  }

  MediaItem copyWith({
    String? id,
    String? title,
    MediaType? type,
    double? rating,
    DateTime? releaseOrAirDate,
    String? overview,
    List<String>? genres,
    String? posterUrl,
    String? detailPosterUrl,
    String? backdropUrl,
    int? runtime,
    int? seasonsCount,
    int? episodesCount,
    List<String>? episodesList,
    DateTime? nextEpisodeAirDate,
    Duration? airCountdown,
    bool? hasTrailer,
    String? trailerVideoId,
    List<MediaVideo>? trailers,
    bool? imageLoadWillFail,
    List<String>? watchProviders,
    Map<String, List<WatchProviderInfo>>? watchProvidersByCountry,
    List<String>? cast,
    List<CastMember>? castMembers,
    String? tagline,
    String? director,
    String? certification,
    MediaCollection? belongsToCollection,
    List<String>? createdBy,
    List<MediaNetwork>? networks,
    int? voteCount,
    List<MediaKeyword>? keywords,
    String? imdbId,
    List<ProductionCompany>? productionCompanies,
    String? originalLanguage,
    List<String>? spokenLanguages,
    String? status,
  }) {
    return MediaItem(
      id: id ?? this.id,
      title: title ?? this.title,
      type: type ?? this.type,
      rating: rating ?? this.rating,
      releaseOrAirDate: releaseOrAirDate ?? this.releaseOrAirDate,
      overview: overview ?? this.overview,
      genres: genres ?? this.genres,
      posterUrl: posterUrl ?? this.posterUrl,
      detailPosterUrl: detailPosterUrl ?? this.detailPosterUrl,
      backdropUrl: backdropUrl ?? this.backdropUrl,
      runtime: runtime ?? this.runtime,
      seasonsCount: seasonsCount ?? this.seasonsCount,
      episodesCount: episodesCount ?? this.episodesCount,
      episodesList: episodesList ?? this.episodesList,
      nextEpisodeAirDate: nextEpisodeAirDate ?? this.nextEpisodeAirDate,
      airCountdown: airCountdown ?? this.airCountdown,
      hasTrailer: hasTrailer ?? this.hasTrailer,
      trailerVideoId: trailerVideoId ?? this.trailerVideoId,
      trailers: trailers ?? this.trailers,
      imageLoadWillFail: imageLoadWillFail ?? this.imageLoadWillFail,
      watchProviders: watchProviders ?? this.watchProviders,
      watchProvidersByCountry:
          watchProvidersByCountry ?? this.watchProvidersByCountry,
      cast: cast ?? this.cast,
      castMembers: castMembers ?? this.castMembers,
      tagline: tagline ?? this.tagline,
      director: director ?? this.director,
      certification: certification ?? this.certification,
      belongsToCollection: belongsToCollection ?? this.belongsToCollection,
      createdBy: createdBy ?? this.createdBy,
      networks: networks ?? this.networks,
      voteCount: voteCount ?? this.voteCount,
      keywords: keywords ?? this.keywords,
      imdbId: imdbId ?? this.imdbId,
      productionCompanies: productionCompanies ?? this.productionCompanies,
      originalLanguage: originalLanguage ?? this.originalLanguage,
      spokenLanguages: spokenLanguages ?? this.spokenLanguages,
      status: status ?? this.status,
    );
  }

  /// Serializes lightweight snapshot of [MediaItem] for local persistence.
  Map<String, dynamic> toMinimalJson() {
    return {
      'id': id,
      'title': title,
      'type': type.name,
      'posterUrl': posterUrl,
      'rating': rating,
      if (belongsToCollection != null) ...{
        'collectionId': belongsToCollection!.id,
        'collectionName': belongsToCollection!.name,
      },
    };
  }

  /// Restores a thin [MediaItem] snapshot from lightweight local persistence JSON.
  factory MediaItem.fromMinimalJson(Map<String, dynamic> json) {
    final typeStr = json['type'] as String?;
    final mediaType = typeStr == 'tv' ? MediaType.tv : MediaType.movie;
    double ratingVal = 0.0;
    final r = json['rating'];
    if (r is num) {
      ratingVal = r.toDouble();
    } else if (r is String) {
      ratingVal = double.tryParse(r) ?? 0.0;
    }

    final colName = json['collectionName'] as String?;
    final colId = (json['collectionId'] as num?)?.toInt();
    MediaCollection? col;
    if (colName != null && colName.isNotEmpty) {
      col = MediaCollection(id: colId ?? 0, name: colName);
    }

    return MediaItem(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      type: mediaType,
      rating: ratingVal,
      posterUrl: json['posterUrl'] as String?,
      overview: '',
      genres: const [],
      belongsToCollection: col,
    );
  }
}
