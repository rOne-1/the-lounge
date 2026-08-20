import 'package:flutter/foundation.dart';

import '../constants/analytics_constants.dart';
import '../models/media_item.dart';
import '../models/personal_rating.dart';
import '../models/watch_record.dart';
import 'weighted_rating.dart';

/// ANLY-ENGINE-1: plain data-transfer input for [computeAnalytics], gathered
/// on the main isolate from `mediaProvider` before crossing into
/// `compute()`. No Flutter/BuildContext/provider types anywhere in this
/// file -- everything here must stay isolate-safe.
class AnalyticsInput {
  final Map<String, MediaItem> watchedList;
  final Map<String, List<WatchRecord>> watchHistory;
  final Map<String, Set<String>> watchedEpisodes;
  final Map<String, Map<int, DateTime>> seasonStartDates;
  final Map<String, Map<int, DateTime>> seasonEndDates;

  /// EXP-FUNNEL-2: plain counts, not the full skip/watchlist/maybe maps --
  /// Discover Swipe Ratio only ever needs totals, and keeping AnalyticsInput
  /// to primitives+MediaItem/WatchRecord types is cheaper to hand across
  /// the `compute()` isolate boundary than carrying whole extra maps over.
  final int skippedCount;
  final int watchlistCount;
  final int maybeListCount;

  const AnalyticsInput({
    required this.watchedList,
    required this.watchHistory,
    required this.watchedEpisodes,
    required this.seasonStartDates,
    required this.seasonEndDates,
    this.skippedCount = 0,
    this.watchlistCount = 0,
    this.maybeListCount = 0,
  });
}

/// ANLY-TEMPORAL-1: per-calendar-day watch-activity tally.
class HeatmapData {
  final Map<DateTime, int> dailyCounts;
  const HeatmapData(this.dailyCounts);
}

/// ANLY-TEMPORAL-2: total minutes watched, movies and TV kept separate.
/// TV is a documented estimate (SP-3) -- see [computeTimeInvestment].
class TimeInvestment {
  final int movieMinutes;
  final int tvMinutes;

  const TimeInvestment({required this.movieMinutes, required this.tvMinutes});

  int get totalMinutes => movieMinutes + tvMinutes;
}

/// ANLY-TEMPORAL-3: one show's single-season completion velocity.
class ShowBingeVelocity {
  final String showId;
  final String showTitle;
  final int seasonNumber;
  final double days;

  const ShowBingeVelocity({
    required this.showId,
    required this.showTitle,
    required this.seasonNumber,
    required this.days,
  });
}

/// ANLY-TEMPORAL-3: aggregate binge-velocity result. `averageDays` is null
/// when no show has a complete (start AND end) season-date pair yet.
class BingeVelocity {
  final double? averageDays;
  final List<ShowBingeVelocity> perSeason;

  const BingeVelocity({required this.averageDays, required this.perSeason});
}

/// ANLY-TASTE-1: a ranked name (cast member or director) with its watched
/// count.
class NameCount {
  final String name;
  final int count;

  const NameCount({required this.name, required this.count});
}

/// ANLY-TASTE-1: cast and director rankings, kept as separate lists (both
/// sorted descending by count).
class CastAndDirectorRankings {
  final List<NameCount> cast;
  final List<NameCount> directors;

  const CastAndDirectorRankings({required this.cast, required this.directors});
}

/// ANLY-TASTE-2: one title's personal-rating point vs. the app's Bayesian
/// weighted rating.
class RatingDivergencePoint {
  final String mediaId;
  final String title;
  final double personalPoint;
  final double weightedRatingValue;

  const RatingDivergencePoint({
    required this.mediaId,
    required this.title,
    required this.personalPoint,
    required this.weightedRatingValue,
  });

  double get delta => personalPoint - weightedRatingValue;
}

/// EXP-ERA-1: watched-title counts bucketed by decade of
/// `releaseOrAirDate`. Keys are display-ready labels ("Pre-1970s", "1990s",
/// ...); titles with no release date are excluded entirely, not bucketed
/// under a misleading "Unknown" (SP-3).
class DecadeDistribution {
  final Map<String, int> counts;
  const DecadeDistribution(this.counts);
}

/// EXP-ERA-2: average days between a title's release and when it was
/// actually (first) watched. Null when no watched title has both a
/// `releaseOrAirDate` and a real first-watch record.
class TemporalDistanceIndex {
  final double? averageDays;
  const TemporalDistanceIndex(this.averageDays);
}

/// EXP-GLOBAL-1: watched-title counts by `originalLanguage` code (e.g.
/// "en", "ko"). Titles with no language recorded are excluded, not
/// bucketed under "Unknown" (SP-3).
class LanguageDistribution {
  final Map<String, int> counts;
  const LanguageDistribution(this.counts);
}

/// EXP-RHYTHM-1: watch-log counts by weekday (1=Monday..7=Sunday, matching
/// `DateTime.weekday`), movies and TV-episode-logging kept separate since
/// they're different kinds of activity.
class DayOfWeekDistribution {
  final Map<int, int> movieCounts;
  final Map<int, int> tvCounts;

  const DayOfWeekDistribution({
    required this.movieCounts,
    required this.tvCounts,
  });
}

/// EXP-RHYTHM-2: movie runtime stats. `averageMinutes` is null when no
/// watched movie has a `runtime`. The 3 buckets are mutually exclusive and
/// only count movies with a real runtime -- they never sum to the full
/// watched-movie count if some are missing runtime.
class RuntimePreferences {
  final double? averageMinutes;
  final int shortCount; // < 90 min
  final int standardCount; // 90-150 min
  final int epicCount; // > 150 min (2.5h+)

  const RuntimePreferences({
    required this.averageMinutes,
    required this.shortCount,
    required this.standardCount,
    required this.epicCount,
  });
}

/// EXP-GLOBAL-3: a recurring production company/studio with its watched
/// count.
class StudioAffinity {
  final List<NameCount> studios;
  const StudioAffinity(this.studios);
}

/// EXP-FUNNEL-2: Discover deck interaction breakdown. A title can appear in
/// more than one bucket over its lifetime (skipped once, later
/// watchlisted) -- this is a snapshot of current standing, not a strict
/// partition, so percentages are relative to [totalInteractions], not a
/// claim that every Discover card falls into exactly one bucket forever.
class DiscoverSwipeRatio {
  final int skippedCount;
  final int watchlistedCount;
  final int savedCount;

  const DiscoverSwipeRatio({
    required this.skippedCount,
    required this.watchlistedCount,
    required this.savedCount,
  });

  int get totalInteractions => skippedCount + watchlistedCount + savedCount;
}

/// ANLY-ENGINE-1: the full computed result surfaced by the Analytics screen.
class AnalyticsResult {
  final HeatmapData heatmap;
  final TimeInvestment timeInvestment;
  final BingeVelocity bingeVelocity;
  final List<NameCount> castRanking;
  final List<NameCount> directorRanking;
  final List<RatingDivergencePoint> ratingDivergence;
  final Map<String, int> genreFrequency;
  final DecadeDistribution decadeDistribution;
  final TemporalDistanceIndex temporalDistanceIndex;
  final LanguageDistribution languageDistribution;
  final DayOfWeekDistribution dayOfWeekDistribution;
  final RuntimePreferences runtimePreferences;
  final DiscoverSwipeRatio discoverSwipeRatio;
  final StudioAffinity studioAffinity;

  const AnalyticsResult({
    required this.heatmap,
    required this.timeInvestment,
    required this.bingeVelocity,
    required this.castRanking,
    required this.directorRanking,
    required this.ratingDivergence,
    required this.genreFrequency,
    required this.decadeDistribution,
    required this.temporalDistanceIndex,
    required this.languageDistribution,
    required this.dayOfWeekDistribution,
    required this.runtimePreferences,
    required this.discoverSwipeRatio,
    required this.studioAffinity,
  });
}

/// ANLY-TEMPORAL-1: tallies `WatchRecord.date ?? recordedAt` per calendar
/// day (time-of-day stripped) across every logged watch, first watches and
/// rewatches alike.
HeatmapData computeHeatmap(AnalyticsInput input) {
  final counts = <DateTime, int>{};
  for (final records in input.watchHistory.values) {
    for (final record in records) {
      final date = record.date ?? record.recordedAt;
      final day = DateTime(date.year, date.month, date.day);
      counts[day] = (counts[day] ?? 0) + 1;
    }
  }
  return HeatmapData(counts);
}

/// ANLY-TEMPORAL-2: movies sum `item.runtime` directly (an exact figure --
/// one explicit user action per movie). TV sums
/// `watchedEpisodeCount * item.runtime`, which is a stated ESTIMATE (SP-3):
/// `runtime` for a TV item is TMDB's `episode_run_time[0]`, a single value
/// captured once at fetch time, not a true per-episode average.
TimeInvestment computeTimeInvestment(AnalyticsInput input) {
  var movieMinutes = 0;
  var tvMinutes = 0;
  for (final entry in input.watchedList.entries) {
    final item = entry.value;
    final runtime = item.runtime;
    if (runtime == null || runtime <= 0) continue;
    if (item.type == MediaType.movie) {
      movieMinutes += runtime;
    } else {
      final watchedCount = input.watchedEpisodes[entry.key]?.length ?? 0;
      tvMinutes += watchedCount * runtime;
    }
  }
  return TimeInvestment(movieMinutes: movieMinutes, tvMinutes: tvMinutes);
}

/// ANLY-TEMPORAL-3: per show, per season, `seasonEndDates - seasonStartDates`
/// in days. Seasons missing either half of the pair are excluded entirely
/// (not counted as 0), so the average only reflects genuinely-complete
/// data.
BingeVelocity computeBingeVelocity(AnalyticsInput input) {
  final perSeason = <ShowBingeVelocity>[];
  for (final entry in input.watchedList.entries) {
    final id = entry.key;
    final item = entry.value;
    if (item.type != MediaType.tv) continue;

    final starts = input.seasonStartDates[id];
    final ends = input.seasonEndDates[id];
    if (starts == null || ends == null) continue;

    for (final seasonEntry in ends.entries) {
      final seasonNumber = seasonEntry.key;
      final endDate = seasonEntry.value;
      final startDate = starts[seasonNumber];
      if (startDate == null) continue;

      final days = endDate.difference(startDate).inHours / 24.0;
      if (days < 0) continue;

      perSeason.add(ShowBingeVelocity(
        showId: id,
        showTitle: item.title,
        seasonNumber: seasonNumber,
        days: days,
      ));
    }
  }

  final averageDays = perSeason.isEmpty
      ? null
      : perSeason.map((e) => e.days).reduce((a, b) => a + b) / perSeason.length;

  return BingeVelocity(averageDays: averageDays, perSeason: perSeason);
}

List<NameCount> _tally(Iterable<String> names) {
  final counts = <String, int>{};
  for (final name in names) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) continue;
    counts[trimmed] = (counts[trimmed] ?? 0) + 1;
  }
  final result = counts.entries
      .map((e) => NameCount(name: e.key, count: e.value))
      .toList();
  result.sort((a, b) => b.count.compareTo(a.count));
  return result;
}

/// ANLY-TASTE-1: tallies `cast`/`director` across every watched title.
/// Reflects only the top-billed cast/primary director captured per saved
/// title, not full credits -- a real scope limit of the stored data, not a
/// bug.
CastAndDirectorRankings computeCastAndDirectorRankings(AnalyticsInput input) {
  final castNames = <String>[];
  final directorNames = <String>[];
  for (final item in input.watchedList.values) {
    castNames.addAll(item.cast);
    final director = item.director;
    if (director != null) directorNames.add(director);
  }
  return CastAndDirectorRankings(
    cast: _tally(castNames),
    directors: _tally(directorNames),
  );
}

/// ANLY-TASTE-2: for every watched title with both a real overall
/// (season-null) first-watch [PersonalRating] and a positive `voteCount`,
/// maps the personal tier onto [AnalyticsConstants.personalRatingPoints]
/// and compares it against [weightedRatingOf] (reused directly from
/// `weighted_rating.dart`, not reimplemented).
List<RatingDivergencePoint> computeRatingDivergence(AnalyticsInput input) {
  final qualifying = <MapEntry<String, MediaItem>>[];
  final personalPoints = <String, double>{};

  for (final historyEntry in input.watchHistory.entries) {
    final id = historyEntry.key;
    final item = input.watchedList[id];
    if (item == null || (item.voteCount ?? 0) <= 0) continue;

    WatchRecord? overallFirstWatch;
    for (final record in historyEntry.value) {
      if (record.seasonNumber == null && record.isFirstWatch) {
        overallFirstWatch = record;
        break;
      }
    }

    final tier = overallFirstWatch?.rating;
    final point =
        tier == null ? null : AnalyticsConstants.personalRatingPoints[tier];
    if (point == null) continue;

    personalPoints[id] = point;
    qualifying.add(MapEntry(id, item));
  }

  final poolMean = meanRatingOf(qualifying.map((e) => e.value));

  return qualifying.map((entry) {
    final wr = weightedRatingOf(
      entry.value,
      poolMean: poolMean,
      minVotes: AnalyticsConstants.ratingDivergenceMinVotes,
    );
    return RatingDivergencePoint(
      mediaId: entry.key,
      title: entry.value.title,
      personalPoint: personalPoints[entry.key]!,
      weightedRatingValue: wr,
    );
  }).toList();
}

/// ANLY-TASTE-3: tallies `item.genres` across every watched title
/// (multi-membership -- a title with N genres counts toward all N),
/// mirroring `groupByGenre`'s convention in `archive_sort_group.dart`.
Map<String, int> computeGenreFrequency(AnalyticsInput input) {
  final counts = <String, int>{};
  for (final item in input.watchedList.values) {
    for (final genre in item.genres) {
      final trimmed = genre.trim();
      if (trimmed.isEmpty) continue;
      counts[trimmed] = (counts[trimmed] ?? 0) + 1;
    }
  }
  return counts;
}

/// EXP-ERA-1: buckets watched titles by decade of `releaseOrAirDate`.
DecadeDistribution computeDecadeDistribution(AnalyticsInput input) {
  final counts = <String, int>{};
  for (final item in input.watchedList.values) {
    final year = item.releaseOrAirDate?.year;
    if (year == null) continue;
    final label = year < 1970 ? 'Pre-1970s' : '${(year ~/ 10) * 10}s';
    counts[label] = (counts[label] ?? 0) + 1;
  }
  return DecadeDistribution(counts);
}

/// Earliest first-watch record for a title, mirroring
/// [computeRatingDivergence]'s own first-watch lookup convention.
WatchRecord? _overallFirstWatch(List<WatchRecord> records) {
  for (final record in records) {
    if (record.seasonNumber == null && record.isFirstWatch) return record;
  }
  return null;
}

/// EXP-ERA-2: average days between release and actual (first) watch.
TemporalDistanceIndex computeTemporalDistanceIndex(AnalyticsInput input) {
  final deltas = <double>[];
  for (final entry in input.watchHistory.entries) {
    final item = input.watchedList[entry.key];
    final releaseDate = item?.releaseOrAirDate;
    if (item == null || releaseDate == null) continue;

    final firstWatch = _overallFirstWatch(entry.value);
    final watchDate = firstWatch?.date ?? firstWatch?.recordedAt;
    if (watchDate == null) continue;

    final days = watchDate.difference(releaseDate).inHours / 24.0;
    deltas.add(days);
  }
  if (deltas.isEmpty) return const TemporalDistanceIndex(null);
  return TemporalDistanceIndex(deltas.reduce((a, b) => a + b) / deltas.length);
}

/// EXP-GLOBAL-1: watched-title counts by `originalLanguage`.
LanguageDistribution computeLanguageDistribution(AnalyticsInput input) {
  final counts = <String, int>{};
  for (final item in input.watchedList.values) {
    final lang = item.originalLanguage?.trim();
    if (lang == null || lang.isEmpty) continue;
    counts[lang] = (counts[lang] ?? 0) + 1;
  }
  return LanguageDistribution(counts);
}

/// EXP-RHYTHM-1: tallies every logged watch (first watches + rewatches) by
/// weekday, split by the title's media type.
DayOfWeekDistribution computeDayOfWeekDistribution(AnalyticsInput input) {
  final movieCounts = <int, int>{};
  final tvCounts = <int, int>{};
  for (final entry in input.watchHistory.entries) {
    final item = input.watchedList[entry.key];
    if (item == null) continue;
    final target = item.type == MediaType.movie ? movieCounts : tvCounts;
    for (final record in entry.value) {
      final date = record.date ?? record.recordedAt;
      target[date.weekday] = (target[date.weekday] ?? 0) + 1;
    }
  }
  return DayOfWeekDistribution(movieCounts: movieCounts, tvCounts: tvCounts);
}

/// EXP-RHYTHM-2: average + bucketed distribution of watched-movie runtimes.
RuntimePreferences computeRuntimePreferences(AnalyticsInput input) {
  final runtimes = <int>[];
  for (final item in input.watchedList.values) {
    if (item.type != MediaType.movie) continue;
    final runtime = item.runtime;
    if (runtime == null || runtime <= 0) continue;
    runtimes.add(runtime);
  }

  final shortCount = runtimes.where((r) => r < 90).length;
  final epicCount = runtimes.where((r) => r > 150).length;
  final standardCount = runtimes.length - shortCount - epicCount;
  final average = runtimes.isEmpty
      ? null
      : runtimes.reduce((a, b) => a + b) / runtimes.length;

  return RuntimePreferences(
    averageMinutes: average,
    shortCount: shortCount,
    standardCount: standardCount,
    epicCount: epicCount,
  );
}

/// EXP-GLOBAL-3: tallies `productionCompanyNames` across every watched
/// title, reusing the same [_tally] helper as cast/director rankings.
StudioAffinity computeStudioAffinity(AnalyticsInput input) {
  final names = <String>[];
  for (final item in input.watchedList.values) {
    names.addAll(item.productionCompanyNames);
  }
  return StudioAffinity(_tally(names));
}

/// EXP-FUNNEL-2: Discover deck interaction breakdown from already-tracked
/// counts (skip history, Watchlist/Maybe pile sizes) -- no new tracking.
DiscoverSwipeRatio computeDiscoverSwipeRatio(AnalyticsInput input) {
  return DiscoverSwipeRatio(
    skippedCount: input.skippedCount,
    watchlistedCount: input.watchlistCount,
    savedCount: input.maybeListCount,
  );
}

/// ANLY-ENGINE-1: the single top-level function passed to `compute()`.
/// Must stay a plain, isolate-safe, top-level function -- no closures over
/// BuildContext/providers/Flutter framework types.
AnalyticsResult computeAnalytics(AnalyticsInput input) {
  final rankings = computeCastAndDirectorRankings(input);
  return AnalyticsResult(
    heatmap: computeHeatmap(input),
    timeInvestment: computeTimeInvestment(input),
    bingeVelocity: computeBingeVelocity(input),
    castRanking: rankings.cast,
    directorRanking: rankings.directors,
    ratingDivergence: computeRatingDivergence(input),
    genreFrequency: computeGenreFrequency(input),
    decadeDistribution: computeDecadeDistribution(input),
    temporalDistanceIndex: computeTemporalDistanceIndex(input),
    languageDistribution: computeLanguageDistribution(input),
    dayOfWeekDistribution: computeDayOfWeekDistribution(input),
    runtimePreferences: computeRuntimePreferences(input),
    discoverSwipeRatio: computeDiscoverSwipeRatio(input),
    studioAffinity: computeStudioAffinity(input),
  );
}

/// ANLY-ENGINE-1 / SP-1: runs [computeAnalytics] on a background isolate via
/// `compute()`. This is the only entry point [AnalyticsNotifier.generate]
/// should call -- never call [computeAnalytics] directly on the main
/// isolate from provider/widget code.
Future<AnalyticsResult> runAnalyticsCompute(AnalyticsInput input) {
  return compute(computeAnalytics, input);
}
