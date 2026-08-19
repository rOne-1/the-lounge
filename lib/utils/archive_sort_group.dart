import '../models/media_item.dart';
import '../models/watch_record.dart';
import 'weighted_rating.dart';

/// PERS-SORT-1 / SORT-1: sort options offered on archive shelf screens (Watchlist/Saved/Watched/etc).
enum ArchiveSortOption {
  dateAdded('Date Added'),
  lastAdded('Last Added'),
  weightedRating('Top Rated'),
  releaseDate('Release Date');

  final String label;
  const ArchiveSortOption(this.label);
}

/// PERS-SORT-1: group options offered on archive shelf screens.
enum ArchiveGroupOption {
  none('None'),
  genre('Genre'),
  ratingBand('Rating Band'),
  language('Language');

  final String label;
  const ArchiveGroupOption(this.label);
}

/// SORT-2: Aggregates the latest added or released timestamp for a collection cluster.
DateTime getCollectionLastAdded(List<MediaItem> items) {
  if (items.isEmpty) return DateTime.fromMillisecondsSinceEpoch(0);
  return items
      .map((i) => i.addedDate ?? i.releaseOrAirDate ?? DateTime.fromMillisecondsSinceEpoch(0))
      .reduce((max, date) => date.isAfter(max) ? date : max);
}

/// `m` in the weighted-rating formula for archive shelf sorting -- deliberately a
/// modest floor (unlike Discover's stricter curation bar), since a shelf is
/// the user's own saved titles, not a discovery feed being filtered for
/// quality.
const double _archiveWeightedRatingMinVotes = 50.0;

/// Sorts [items] per [option]. [items] is assumed to already be in the
/// shelf's natural insertion order (oldest-added-first, the order
/// `Map<String, MediaItem>.values` yields for the app's LinkedHashMap-backed
/// status shelves) -- `dateAdded` uses that directly rather than needing a
/// separate persisted timestamp per title.
List<MediaItem> sortArchiveShelf(List<MediaItem> items, ArchiveSortOption option) {
  switch (option) {
    case ArchiveSortOption.dateAdded:
      return items.reversed.toList(); // most-recently-added first
    case ArchiveSortOption.lastAdded:
      final sorted = List<MediaItem>.from(items)
        ..sort((a, b) {
          final ad = a.addedDate ?? a.releaseOrAirDate;
          final bd = b.addedDate ?? b.releaseOrAirDate;
          if (ad == null && bd == null) return 0;
          if (ad == null) return 1;
          if (bd == null) return -1;
          return bd.compareTo(ad); // newest timestamp first
        });
      return sorted;
    case ArchiveSortOption.weightedRating:
      final poolMean = meanRatingOf(items);
      final sorted = List<MediaItem>.from(items)
        ..sort((a, b) => weightedRatingOf(
              b,
              poolMean: poolMean,
              minVotes: _archiveWeightedRatingMinVotes,
            ).compareTo(weightedRatingOf(
              a,
              poolMean: poolMean,
              minVotes: _archiveWeightedRatingMinVotes,
            )));
      return sorted;
    case ArchiveSortOption.releaseDate:
      final sorted = List<MediaItem>.from(items)
        ..sort((a, b) {
          final ad = a.releaseOrAirDate;
          final bd = b.releaseOrAirDate;
          if (ad == null && bd == null) return 0;
          if (ad == null) return 1;
          if (bd == null) return -1;
          return bd.compareTo(ad); // newest release first
        });
      return sorted;
  }
}

/// Multi-membership: a title with several genres appears in every matching
/// group, per the locked spec.
Map<String, List<MediaItem>> groupByGenre(List<MediaItem> items) {
  final Map<String, List<MediaItem>> result = {};
  for (final item in items) {
    if (item.genres.isEmpty) {
      result.putIfAbsent('Other', () => []).add(item);
      continue;
    }
    for (final genre in item.genres) {
      result.putIfAbsent(genre, () => []).add(item);
    }
  }
  return result;
}

/// Whole-point rating bands (e.g. "9-10", "8-9" ... "0-1"), based on the
/// TMDB weighted rating axis, not personal rating. Unrated titles (rating
/// <= 0) land in "Unrated".
Map<String, List<MediaItem>> groupByRatingBand(List<MediaItem> items) {
  String bandFor(double rating) {
    if (rating <= 0) return 'Unrated';
    final band = rating.floor().clamp(0, 9);
    return '$band-${band + 1}';
  }

  final Map<String, List<MediaItem>> result = {};
  for (final item in items) {
    result.putIfAbsent(bandFor(item.rating), () => []).add(item);
  }
  return result;
}

/// Groups by [MediaItem.originalLanguageDisplay] (e.g. "English", "Korean"),
/// the same display string already shown in the language meta badge and
/// used by the language filter elsewhere in the app. Titles with no known
/// language land in "Unknown".
Map<String, List<MediaItem>> groupByLanguage(List<MediaItem> items) {
  final Map<String, List<MediaItem>> result = {};
  for (final item in items) {
    final display = item.originalLanguageDisplay;
    final key = (display == null || display.isEmpty) ? 'Unknown' : display;
    result.putIfAbsent(key, () => []).add(item);
  }
  return result;
}

/// PERS-SORT-1: sorts Watched-archive items by personal rating tier (Loved ->
/// Liked -> Okay -> Not for me -> Unrated last) -- the one shelf where a
/// personal-rating sort is meaningful. Looks at the overall (not per-season)
/// first-watch record, matching [findPrimaryWatchRecord]'s notion of "the"
/// personal rating for a title.
List<MediaItem> personalRatingSort(
  List<MediaItem> items,
  Map<String, List<WatchRecord>> watchHistory,
) {
  int tierRank(MediaItem item) {
    final records = watchHistory[item.id];
    if (records == null) return -1;
    for (final r in records) {
      if (r.seasonNumber == null && r.isFirstWatch) {
        return r.rating?.ordinal ?? -1;
      }
    }
    return -1;
  }

  final sorted = List<MediaItem>.from(items)
    ..sort((a, b) => tierRank(b).compareTo(tierRank(a)));
  return sorted;
}
