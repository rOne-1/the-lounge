import 'package:flutter/material.dart';
import '../../constants.dart';
import '../../utils/analytics_engine.dart';
import '../archive_summary_card.dart';

/// EXP-FUNNEL-1: honest counts instead of a percentage the current data
/// can't fully back -- see [WatchlistFunnel]'s own doc comment.
class WatchlistFunnelSection extends StatelessWidget {
  final WatchlistFunnel funnel;

  const WatchlistFunnelSection({super.key, required this.funnel});

  @override
  Widget build(BuildContext context) {
    final colors = context.ambianceColors;
    final avgDays = funnel.averageBacklogDays;

    if (funnel.convertedCount == 0 && funnel.pendingCount == 0) {
      return Text(
        'Add a few titles to your Watchlist to see your backlog rhythm.',
        style: AppThemes.safeGeist(fontSize: 13, color: colors.sub),
      );
    }

    return Row(
      children: [
        Expanded(
          child: ArchiveSummaryCard(
            label: 'Converted',
            subtitle: avgDays == null
                ? 'from Watchlist to Watched'
                : '~${avgDays.round()}d avg. in backlog',
            count: funnel.convertedCount,
            icon: Icons.check_circle_outline_rounded,
            statusColor: colors.acc,
            onTap: () {},
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ArchiveSummaryCard(
            label: 'Pending',
            subtitle: 'still in your backlog',
            count: funnel.pendingCount,
            icon: Icons.hourglass_empty_rounded,
            statusColor: colors.acc,
            onTap: () {},
          ),
        ),
      ],
    );
  }
}
