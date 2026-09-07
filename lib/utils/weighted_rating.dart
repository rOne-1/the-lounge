import 'package:flutter_refined_kit/flutter_refined_kit.dart' as kit;
import '../models/media_item.dart';

/// IMDb-style Bayesian weighted rating (SP-3 / E2 in the triage report).
///
/// Re-exports flutter_refined_kit's domain-agnostic formula unchanged — see
/// that package for the `WR = (v/(v+m))*R + (m/(v+m))*C` derivation. Kept as
/// a re-export (not a direct `kit.weightedRating` call at every site) so
/// existing call sites in this app didn't need to change at all when this
/// module moved to the kit.
double weightedRating({
  required double r,
  required int v,
  required double m,
  required double c,
}) =>
    kit.weightedRating(r: r, v: v, m: m, c: c);

/// Mean rating (`C`) across a candidate pool of [MediaItem]s. Unvoted items
/// (voteCount null or 0) are excluded so a flood of unvoted titles can't
/// drag the baseline down artificially.
///
/// Thin [MediaItem]-specific wrapper over the kit's generic
/// `meanRatingOf<T>` — the kit version takes rating/vote-count extractor
/// callbacks instead of assuming a `MediaItem`, since it has no concept of
/// this app's data model. Kept here so this app's own call sites keep
/// passing a plain `Iterable<MediaItem>`.
double meanRatingOf(Iterable<MediaItem> pool) => kit.meanRatingOf<MediaItem>(
      pool,
      ratingOf: (item) => item.rating,
      voteCountOf: (item) => item.voteCount ?? 0,
    );

/// Convenience wrapper computing [item]'s weighted rating against a
/// pre-computed pool mean [poolMean] (see [meanRatingOf]) and a [minVotes]
/// threshold (`m`). Thin [MediaItem]-specific wrapper, same reasoning as
/// [meanRatingOf] above.
double weightedRatingOf(
  MediaItem item, {
  required double poolMean,
  required double minVotes,
}) =>
    kit.weightedRatingOf<MediaItem>(
      item,
      ratingOf: (i) => i.rating,
      voteCountOf: (i) => i.voteCount ?? 0,
      poolMean: poolMean,
      minVotes: minVotes,
    );
