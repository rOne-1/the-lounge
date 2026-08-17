import '../providers/media_provider.dart';

/// PERS-DIFF-1: pure, testable computations behind Your Space's "Forgotten
/// Favorites" and "On This Day" memory surfacing. Kept separate from the
/// widgets that render them so the rewatch-window/anniversary logic has
/// direct unit test coverage, independent of pumping a widget tree.

/// A title with a first-watch "Loved it" record old enough, and never
/// rewatched since, to qualify as a "forgotten" favorite.
class ForgottenFavorite {
  final String mediaId;
  final DateTime ratedAt;

  const ForgottenFavorite({required this.mediaId, required this.ratedAt});
}

/// Titles rated `PersonalRating.loved` (first watch, any season) more than
/// a year ago that have no rewatch record (`isFirstWatch: false`) logged
/// against them at all. Oldest-loved-first, so the most overdue rewatch
/// surfaces first.
List<ForgottenFavorite> computeForgottenFavorites(MediaState state, {DateTime? now}) {
  final current = now ?? DateTime.now();
  final cutoff = current.subtract(const Duration(days: 365));
  final results = <ForgottenFavorite>[];

  state.watchHistory.forEach((mediaId, records) {
    final everRewatched = records.any((r) => !r.isFirstWatch);
    if (everRewatched) return;

    final lovedFirstWatches =
        records.where((r) => r.isFirstWatch && r.rating == PersonalRating.loved);
    if (lovedFirstWatches.isEmpty) return;

    final earliestLoved = lovedFirstWatches
        .map((r) => r.date ?? r.recordedAt)
        .reduce((a, b) => a.isBefore(b) ? a : b);
    if (earliestLoved.isBefore(cutoff)) {
      results.add(ForgottenFavorite(mediaId: mediaId, ratedAt: earliestLoved));
    }
  });

  results.sort((a, b) => a.ratedAt.compareTo(b.ratedAt));
  return results;
}

/// A title completed exactly [yearsAgo] years ago today.
class OnThisDayMemory {
  final String mediaId;
  final DateTime completedAt;
  final int yearsAgo;

  const OnThisDayMemory({
    required this.mediaId,
    required this.completedAt,
    required this.yearsAgo,
  });
}

/// Titles whose `endDates` completion date shares today's month/day, at
/// least a year in the past. Keyed off `endDates` rather than
/// `watchHistory` since completion (marking a title Watched) and personal
/// rating are separate, independently-optional actions -- this surfaces the
/// "you finished this" anniversary regardless of whether it was ever rated.
List<OnThisDayMemory> computeOnThisDay(MediaState state, {DateTime? now}) {
  final today = now ?? DateTime.now();
  final results = <OnThisDayMemory>[];

  state.endDates.forEach((mediaId, completedAt) {
    final yearsAgo = today.year - completedAt.year;
    if (yearsAgo < 1) return;
    if (completedAt.month == today.month && completedAt.day == today.day) {
      results.add(OnThisDayMemory(
        mediaId: mediaId,
        completedAt: completedAt,
        yearsAgo: yearsAgo,
      ));
    }
  });

  results.sort((a, b) => b.yearsAgo.compareTo(a.yearsAgo));
  return results;
}
