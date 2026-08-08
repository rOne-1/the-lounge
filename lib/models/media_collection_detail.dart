import 'media_item.dart';

class MediaCollectionDetail {
  final int id;
  final String name;
  final String? overview;
  final String? posterUrl;
  final String? backdropUrl;
  final List<MediaItem> parts;

  const MediaCollectionDetail({
    required this.id,
    required this.name,
    this.overview,
    this.posterUrl,
    this.backdropUrl,
    this.parts = const [],
  });

  MediaCollectionDetail copyWith({
    int? id,
    String? name,
    String? overview,
    String? posterUrl,
    String? backdropUrl,
    List<MediaItem>? parts,
  }) {
    return MediaCollectionDetail(
      id: id ?? this.id,
      name: name ?? this.name,
      overview: overview ?? this.overview,
      posterUrl: posterUrl ?? this.posterUrl,
      backdropUrl: backdropUrl ?? this.backdropUrl,
      parts: parts ?? this.parts,
    );
  }
}
