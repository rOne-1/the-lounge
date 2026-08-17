/// PERS-FOLDERS-1: a status-independent, user-authored curated playlist. A
/// title can belong to any number of folders regardless of which status
/// pile (Watchlist/Saved/Watching/Watched/On-Hold/Dropped) it's in, or none.
class UserFolder {
  final String id; // UUID
  final String name; // e.g. "Spooky Season", "Nolan Marathons"
  final DateTime createdAt;
  final List<String> mediaIds; // Ordered list of media IDs

  UserFolder({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.mediaIds,
  });

  UserFolder copyWith({
    String? name,
    List<String>? mediaIds,
  }) {
    return UserFolder(
      id: id,
      name: name ?? this.name,
      createdAt: createdAt,
      mediaIds: mediaIds ?? this.mediaIds,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'createdAt': createdAt.toIso8601String(),
        'mediaIds': mediaIds,
      };

  factory UserFolder.fromJson(Map<String, dynamic> json) => UserFolder(
        id: json['id'] as String,
        name: json['name'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
        mediaIds: List<String>.from(json['mediaIds'] as List? ?? []),
      );
}
