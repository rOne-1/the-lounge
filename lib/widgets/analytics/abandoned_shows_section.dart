import 'package:flutter/material.dart';
import '../../constants.dart';
import '../../utils/analytics_engine.dart';

/// EXP-FUNNEL-3: TV shows stalled in Watching status -- meaningfully behind
/// their known episode count, idle for 90+ days. See
/// [computeAbandonedShows] for the exact criteria.
class AbandonedShowsSection extends StatelessWidget {
  final List<AbandonedShow> shows;

  const AbandonedShowsSection({super.key, required this.shows});

  @override
  Widget build(BuildContext context) {
    final colors = context.ambianceColors;

    if (shows.isEmpty) {
      return Text(
        'Nothing looks abandoned -- everything in Watching is either '
        'recent or nearly finished.',
        style: AppThemes.safeGeist(fontSize: 13, color: colors.sub),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final show in shows)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        show.showTitle,
                        style: AppThemes.safeGeist(
                            fontSize: 13, color: colors.ink),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${show.watchedEpisodeCount}/${show.totalEpisodes} episodes',
                      style:
                          AppThemes.safeGeist(fontSize: 12, color: colors.sub),
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
                          widthFactor: show.completionFraction.clamp(0.0, 1.0),
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
