import 'package:flutter/material.dart';
import '../../constants.dart';
import '../../providers/analytics_provider.dart';

/// EXP-FRANCHISE-1: completion standing for the 5 most-recently-watched
/// distinct collections/franchises among watched titles. The only
/// Analytics metric that depends on a live network fetch (see
/// `AnalyticsNotifier._fetchCollectionCompletions`) -- a collection that
/// failed to fetch simply isn't in this list, not shown as an error.
class CollectionCompletionSection extends StatelessWidget {
  final List<CollectionCompletion> completions;

  const CollectionCompletionSection({super.key, required this.completions});

  @override
  Widget build(BuildContext context) {
    final colors = context.ambianceColors;

    if (completions.isEmpty) {
      return Text(
        'Watch titles from the same collection/franchise to see completion '
        'here.',
        style: AppThemes.safeGeist(fontSize: 13, color: colors.sub),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final completion in completions)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        completion.collectionName,
                        style: AppThemes.safeGeist(
                            fontSize: 13, color: colors.ink),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${completion.watchedCount}/${completion.totalCount}'
                      ' (${((completion.watchedCount / completion.totalCount) * 100).round()}%)',
                      style: AppThemes.safeGeist(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: colors.acc,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: SizedBox(
                    height: 5,
                    child: Stack(
                      children: [
                        Container(color: colors.lineRgba),
                        FractionallySizedBox(
                          widthFactor:
                              (completion.watchedCount / completion.totalCount)
                                  .clamp(0.0, 1.0),
                          child: Container(color: colors.acc),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
