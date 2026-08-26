import '../models/personal_rating.dart';

/// ANLY / SP-5: centralized constants for the Analytics epic, kept in one
/// dedicated file rather than inline in analytics_engine.dart, matching the
/// project's existing convention of one constants file per locked design
/// decision (AppStatusColors, AppRatingColors).
class AnalyticsConstants {
  AnalyticsConstants._();

  /// ANLY-TASTE-2: maps the 4-tier [PersonalRating] onto representative
  /// points on weightedRatingOf's 0-10 scale, so Rating Divergence can
  /// compare personal taste against consensus on the same axis. Locked
  /// mapping, confirmed with the dev.
  static const Map<PersonalRating, double> personalRatingPoints = {
    PersonalRating.loved: 9.0,
    PersonalRating.liked: 7.0,
    PersonalRating.okay: 5.0,
    PersonalRating.notForMe: 2.5,
  };

  /// `m` in the weighted-rating formula for Rating Divergence's consensus
  /// side -- matches Search/Browse's convention (see
  /// search_screen.dart's `_minVotesForFullWeight`).
  static const double ratingDivergenceMinVotes = 50.0;

  /// Default lookback window for the Chronological Heatmap.
  static const int heatmapWindowMonths = 12;

  /// Cap on genres rendered on the Genre DNA radar chart, for legibility.
  static const int genreDnaTopN = 8;

  /// DATA-CONT-3: cap on keywords rendered on the Keyword DNA tag cloud.
  /// Higher than [genreDnaTopN] -- keywords are a much longer-tail
  /// taxonomy than TMDB's small fixed genre list, so a useful "taste"
  /// picture needs more entries to not look sparse.
  static const int keywordDnaTopN = 15;

  /// DATA-CONT-3: how many of the user's top watched-shelf keywords feed
  /// the Discover deck's keyword-overlap boost. Deliberately small --
  /// each one costs a real `/discover` request per `loadPool()` call (see
  /// DiscoverDeckNotifier.loadPool), and the boost is meant to nudge the
  /// deck toward a taste signal, not dominate it with an ever-widening
  /// keyword net.
  static const int discoverKeywordBoostTopN = 3;

  /// BUGFIX-7: per-title cutoff for computeCastAndDirectorRankings --
  /// `MediaItem.cast` holds the *entire* credited cast in TMDB's own
  /// billing order (DATA-CAST-3 removed the old display cap on this list,
  /// but never added a ranking-side one), so a frequency-only tally lets a
  /// prolific cameo actor who appears briefly across many titles (e.g. a
  /// producer's traditional one-scene cameo) outrank someone who's the
  /// clear lead in fewer titles. Only counting each title's top-billed
  /// slice keeps the ranking about who a title is actually *about*, not
  /// raw appearance count. Dev-reported, 2026-08-26 feedback doc item 12.
  static const int castRankingTopBilledCount = 10;
}
