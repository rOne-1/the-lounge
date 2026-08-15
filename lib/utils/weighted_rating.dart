import '../models/media_item.dart';

/// IMDb-style Bayesian weighted rating (SP-3 / E2 in the triage report).
///
/// `WR = (v / (v + m)) * R + (m / (v + m)) * C`
///
/// - [r] is the title's own average rating.
/// - [v] is the number of votes the title has received.
/// - [m] is the minimum-votes threshold for full weight — a title needs
///   roughly this many votes before its own average is trusted at close to
///   face value.
/// - [c] is the mean rating across the candidate pool being ranked (see
///   [meanRatingOf]).
///
/// This is the single formula every consumer must share — implement once,
/// consume everywhere ratings rank or filter content. `m` and the pool used
/// for `C` are expected to vary per context (a Discover deck wants a higher
/// bar than a broad Browse filter); the formula itself does not.
double weightedRating({
  required double r,
  required int v,
  required double m,
  required double c,
}) {
  final totalWeight = v + m;
  if (totalWeight <= 0) return c;
  return (v / totalWeight) * r + (m / totalWeight) * c;
}

/// Mean rating (`C`) across a candidate pool. Unvoted items (voteCount null
/// or 0) are excluded so a flood of unvoted titles can't drag the baseline
/// down artificially — an unvoted title has no rating signal to average in.
double meanRatingOf(Iterable<MediaItem> pool) {
  final rated = pool.where((item) => (item.voteCount ?? 0) > 0);
  if (rated.isEmpty) return 0.0;
  final sum = rated.fold<double>(0.0, (total, item) => total + item.rating);
  return sum / rated.length;
}

/// Convenience wrapper computing [item]'s weighted rating against a
/// pre-computed pool mean [poolMean] (see [meanRatingOf]) and a [minVotes]
/// threshold (`m`).
double weightedRatingOf(
  MediaItem item, {
  required double poolMean,
  required double minVotes,
}) {
  return weightedRating(
    r: item.rating,
    v: item.voteCount ?? 0,
    m: minVotes,
    c: poolMean,
  );
}
