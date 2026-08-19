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
}
