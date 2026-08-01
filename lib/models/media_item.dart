enum MediaType {
  movie,
  tv,
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
  final String? backdropUrl;
  final int? runtime;
  final int? seasonsCount;
  final int? episodesCount;
  final List<String>? episodesList;
  final DateTime? nextEpisodeAirDate;
  final Duration? airCountdown;
  final bool hasTrailer;
  final bool imageLoadWillFail;
  final List<String> watchProviders;
  final List<String> cast;

  const MediaItem({
    required this.id,
    required this.title,
    required this.type,
    required this.rating,
    this.releaseOrAirDate,
    required this.overview,
    required this.genres,
    this.posterUrl,
    this.backdropUrl,
    this.runtime,
    this.seasonsCount,
    this.episodesCount,
    this.episodesList,
    this.nextEpisodeAirDate,
    this.airCountdown,
    this.hasTrailer = false,
    this.imageLoadWillFail = false,
    this.watchProviders = const [],
    this.cast = const [],
  });

  MediaItem copyWith({
    String? id,
    String? title,
    MediaType? type,
    double? rating,
    DateTime? releaseOrAirDate,
    String? overview,
    List<String>? genres,
    String? posterUrl,
    String? backdropUrl,
    int? runtime,
    int? seasonsCount,
    int? episodesCount,
    List<String>? episodesList,
    DateTime? nextEpisodeAirDate,
    Duration? airCountdown,
    bool? hasTrailer,
    bool? imageLoadWillFail,
    List<String>? watchProviders,
    List<String>? cast,
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
      backdropUrl: backdropUrl ?? this.backdropUrl,
      runtime: runtime ?? this.runtime,
      seasonsCount: seasonsCount ?? this.seasonsCount,
      episodesCount: episodesCount ?? this.episodesCount,
      episodesList: episodesList ?? this.episodesList,
      nextEpisodeAirDate: nextEpisodeAirDate ?? this.nextEpisodeAirDate,
      airCountdown: airCountdown ?? this.airCountdown,
      hasTrailer: hasTrailer ?? this.hasTrailer,
      imageLoadWillFail: imageLoadWillFail ?? this.imageLoadWillFail,
      watchProviders: watchProviders ?? this.watchProviders,
      cast: cast ?? this.cast,
    );
  }
}
