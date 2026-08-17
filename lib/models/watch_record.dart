import 'personal_rating.dart';

/// A single logged watch of a title (or a TV season) -- first watch or a
/// rewatch. Multiple records may exist per media ID; `recordedAt` (a
/// system-generated, immutable timestamp) is the stable identity used to
/// address an individual record within a media ID's history list, since two
/// records are otherwise only distinguished by their (user-editable) date.
class WatchRecord {
  final DateTime? date; // User-declared watch date (editable, skippable, backdateable)
  final PersonalRating? rating; // 4-tier rating
  final int? seasonNumber; // null for movies; for TV: 1..N (null = entire series)
  final bool isFirstWatch; // true for exactly one record per title / season
  final DateTime recordedAt; // SYSTEM-generated, immutable timestamp (for Analytics groundwork)

  WatchRecord({
    this.date,
    this.rating,
    this.seasonNumber,
    this.isFirstWatch = false,
    DateTime? recordedAt,
  }) : recordedAt = recordedAt ?? DateTime.now();

  WatchRecord copyWith({
    DateTime? date,
    bool clearDate = false,
    PersonalRating? rating,
    bool clearRating = false,
    int? seasonNumber,
  }) {
    return WatchRecord(
      date: clearDate ? null : (date ?? this.date),
      rating: clearRating ? null : (rating ?? this.rating),
      seasonNumber: seasonNumber ?? this.seasonNumber,
      isFirstWatch: isFirstWatch,
      recordedAt: recordedAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'date': date?.toIso8601String(),
        'rating': rating?.ordinal,
        'seasonNumber': seasonNumber,
        'isFirstWatch': isFirstWatch,
        'recordedAt': recordedAt.toIso8601String(),
      };

  factory WatchRecord.fromJson(Map<String, dynamic> json) => WatchRecord(
        date: json['date'] != null
            ? DateTime.tryParse(json['date'] as String)
            : null,
        rating: PersonalRating.fromOrdinal(json['rating'] as int?),
        seasonNumber: json['seasonNumber'] as int?,
        isFirstWatch: json['isFirstWatch'] as bool? ?? false,
        recordedAt: json['recordedAt'] != null
            ? DateTime.tryParse(json['recordedAt'] as String) ?? DateTime.now()
            : DateTime.now(),
      );
}
