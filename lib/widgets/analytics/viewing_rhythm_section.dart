import 'package:flutter/material.dart';
import '../../constants.dart';
import '../../utils/analytics_engine.dart';
import '../archive_summary_card.dart';

/// EXP-RHYTHM-1/2: which days of the week account for the most watch
/// activity, and how the user's watched-movie runtimes skew (sub-90-minute
/// features vs. 2.5h+ epics).
class ViewingRhythmSection extends StatelessWidget {
  final DayOfWeekDistribution dayOfWeek;
  final RuntimePreferences runtimePreferences;

  const ViewingRhythmSection({
    super.key,
    required this.dayOfWeek,
    required this.runtimePreferences,
  });

  static const _dayLabels = {
    DateTime.monday: 'Mon',
    DateTime.tuesday: 'Tue',
    DateTime.wednesday: 'Wed',
    DateTime.thursday: 'Thu',
    DateTime.friday: 'Fri',
    DateTime.saturday: 'Sat',
    DateTime.sunday: 'Sun',
  };

  String _formatRuntime(double minutes) {
    final total = minutes.round();
    final h = total ~/ 60;
    final m = total % 60;
    if (h == 0) return '${m}m';
    return '${h}h ${m}m';
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.ambianceColors;
    final hasDayData =
        dayOfWeek.movieCounts.isNotEmpty || dayOfWeek.tvCounts.isNotEmpty;
    final avgRuntime = runtimePreferences.averageMinutes;

    // Bug caught live: this must be the max of each day's COMBINED
    // (movie+TV) total, not the max of movie-only/TV-only values taken
    // separately -- a day with a high count in BOTH would otherwise size
    // its two bar segments against two different (smaller) maxes and their
    // combined width could exceed the row, overflowing the RenderFlex.
    final allDays = {...dayOfWeek.movieCounts.keys, ...dayOfWeek.tvCounts.keys};
    final maxDayCount = hasDayData
        ? allDays
            .map((day) =>
                (dayOfWeek.movieCounts[day] ?? 0) +
                (dayOfWeek.tvCounts[day] ?? 0))
            .reduce((a, b) => a > b ? a : b)
        : 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (avgRuntime != null) ...[
          ArchiveSummaryCard(
            label: 'Movie Pacing',
            subtitle: 'average runtime watched',
            count: avgRuntime.round(),
            countLabelOverride: _formatRuntime(avgRuntime),
            icon: Icons.timer_outlined,
            statusColor: colors.acc,
            onTap: () {},
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _RuntimePill(
                  label: 'Sub-90 min', count: runtimePreferences.shortCount),
              const SizedBox(width: 8),
              _RuntimePill(
                  label: '90-150 min', count: runtimePreferences.standardCount),
              const SizedBox(width: 8),
              _RuntimePill(label: '2.5h+', count: runtimePreferences.epicCount),
            ],
          ),
          const SizedBox(height: 20),
        ],
        if (hasDayData) ...[
          Text(
            'Day of Week',
            style: AppThemes.safeGeist(
                fontSize: 13, fontWeight: FontWeight.w600, color: colors.sub),
          ),
          const SizedBox(height: 10),
          for (final day in [
            DateTime.monday,
            DateTime.tuesday,
            DateTime.wednesday,
            DateTime.thursday,
            DateTime.friday,
            DateTime.saturday,
            DateTime.sunday,
          ])
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _DayRow(
                label: _dayLabels[day]!,
                movieCount: dayOfWeek.movieCounts[day] ?? 0,
                tvCount: dayOfWeek.tvCounts[day] ?? 0,
                maxCount: maxDayCount,
              ),
            ),
        ] else if (avgRuntime == null)
          Text(
            'Watch a few more titles to see your viewing rhythm.',
            style: AppThemes.safeGeist(fontSize: 13, color: colors.sub),
          ),
      ],
    );
  }
}

class _RuntimePill extends StatelessWidget {
  final String label;
  final int count;

  const _RuntimePill({required this.label, required this.count});

  @override
  Widget build(BuildContext context) {
    final colors = context.ambianceColors;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: colors.card2,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colors.lineRgba),
        ),
        child: Column(
          children: [
            Text(
              '$count',
              style: AppThemes.safeGeist(
                  fontSize: 16, fontWeight: FontWeight.w700, color: colors.acc),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: AppThemes.safeGeist(fontSize: 10.5, color: colors.sub),
            ),
          ],
        ),
      ),
    );
  }
}

class _DayRow extends StatelessWidget {
  final String label;
  final int movieCount;
  final int tvCount;
  final int maxCount;

  const _DayRow({
    required this.label,
    required this.movieCount,
    required this.tvCount,
    required this.maxCount,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.ambianceColors;
    final total = movieCount + tvCount;

    return Row(
      children: [
        SizedBox(
          width: 32,
          child: Text(label,
              style: AppThemes.safeGeist(fontSize: 12, color: colors.ink)),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final maxWidth = constraints.maxWidth;
              final movieWidth =
                  maxCount == 0 ? 0.0 : (movieCount / maxCount) * maxWidth;
              final tvWidth =
                  maxCount == 0 ? 0.0 : (tvCount / maxCount) * maxWidth;
              return SizedBox(
                height: 10,
                child: Row(
                  children: [
                    Container(
                      width: movieWidth,
                      decoration: BoxDecoration(
                        color: colors.acc,
                        borderRadius: BorderRadius.horizontal(
                          left: const Radius.circular(3),
                          right: tvCount == 0
                              ? const Radius.circular(3)
                              : Radius.zero,
                        ),
                      ),
                    ),
                    Container(
                      width: tvWidth,
                      decoration: BoxDecoration(
                        color: colors.acc.withValues(alpha: 0.45),
                        borderRadius: BorderRadius.horizontal(
                          right: const Radius.circular(3),
                          left: movieCount == 0
                              ? const Radius.circular(3)
                              : Radius.zero,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 20,
          child: Text(
            '$total',
            textAlign: TextAlign.right,
            style: AppThemes.safeGeist(fontSize: 11, color: colors.sub),
          ),
        ),
      ],
    );
  }
}
