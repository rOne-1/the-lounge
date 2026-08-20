import 'package:flutter/material.dart';
import '../../constants.dart';
import '../../utils/analytics_engine.dart';

/// EXP-FUNNEL-2: how Discover deck interactions split across skip / save /
/// watchlist. Built entirely from already-tracked counts (no new
/// tracking) -- see [DiscoverSwipeRatio] for why this is a snapshot, not a
/// strict partition.
class DiscoverFunnelSection extends StatelessWidget {
  final DiscoverSwipeRatio swipeRatio;

  const DiscoverFunnelSection({super.key, required this.swipeRatio});

  @override
  Widget build(BuildContext context) {
    final colors = context.ambianceColors;
    final total = swipeRatio.totalInteractions;

    if (total == 0) {
      return Text(
        'Swipe through a few Discover cards to see your selectivity rate.',
        style: AppThemes.safeGeist(fontSize: 13, color: colors.sub),
      );
    }

    final entries = [
      (label: 'Skipped', count: swipeRatio.skippedCount, color: colors.sub),
      (
        label: 'Watchlisted',
        count: swipeRatio.watchlistedCount,
        color: colors.acc
      ),
      (
        label: 'Saved',
        count: swipeRatio.savedCount,
        color: colors.acc.withValues(alpha: 0.55)
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: SizedBox(
            height: 10,
            child: Row(
              children: [
                for (final entry in entries)
                  if (entry.count > 0)
                    Expanded(
                      flex: entry.count,
                      child: Container(color: entry.color),
                    ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        for (final entry in entries)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration:
                      BoxDecoration(shape: BoxShape.circle, color: entry.color),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    entry.label,
                    style: AppThemes.safeGeist(fontSize: 13, color: colors.ink),
                  ),
                ),
                Text(
                  '${entry.count} (${((entry.count / total) * 100).round()}%)',
                  style: AppThemes.safeGeist(fontSize: 12, color: colors.sub),
                ),
              ],
            ),
          ),
        const SizedBox(height: 4),
        Text(
          'Skips older than ~6 months (and not repeatedly skipped) age out, '
          'so this reflects recent activity, not a lifetime total.',
          style: AppThemes.safeGeist(fontSize: 11, color: colors.sub),
        ),
      ],
    );
  }
}
