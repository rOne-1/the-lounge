import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../constants.dart';
import '../../utils/analytics_engine.dart';
import '../archive_summary_card.dart';

/// EXP-ERA-1/2: release-decade breakdown of watched titles, plus the
/// average delta between release and when a title was actually watched.
class EraDistributionSection extends StatelessWidget {
  final DecadeDistribution decades;
  final TemporalDistanceIndex temporalDistance;

  const EraDistributionSection({
    super.key,
    required this.decades,
    required this.temporalDistance,
  });

  int _sortKey(String label) =>
      label == 'Pre-1970s' ? 0 : int.parse(label.replaceAll('s', ''));

  @override
  Widget build(BuildContext context) {
    final colors = context.ambianceColors;
    final avgDays = temporalDistance.averageDays;

    if (decades.counts.isEmpty) {
      return Text(
        'Watch a few more titles to see your release-era spread.',
        style: AppThemes.safeGeist(fontSize: 13, color: colors.sub),
      );
    }

    final sortedLabels = decades.counts.keys.toList()
      ..sort((a, b) => _sortKey(a).compareTo(_sortKey(b)));
    final maxCount = decades.counts.values.reduce((a, b) => a > b ? a : b);
    final tickInterval =
        (maxCount / 4).ceilToDouble().clamp(1.0, double.infinity);
    final chartMaxY = tickInterval * 4;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (avgDays != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: ArchiveSummaryCard(
              label: 'Temporal Distance',
              subtitle: (avgDays.abs().round() == 1)
                  ? (avgDays >= 0
                      ? 'day after release, on average'
                      : 'day before release (advance access)')
                  : (avgDays >= 0
                      ? 'days after release, on average'
                      : 'days before release (advance access)'),
              count: avgDays.abs().round(),
              icon: Icons.history_toggle_off_rounded,
              statusColor: colors.acc,
              onTap: () {},
            ),
          ),
        SizedBox(
          height: 200,
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: chartMaxY,
              barTouchData: BarTouchData(
                touchTooltipData: BarTouchTooltipData(
                  getTooltipColor: (_) => colors.card2,
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    final label = sortedLabels[group.x.toInt()];
                    return BarTooltipItem(
                      '$label\n${rod.toY.round()} titles',
                      AppThemes.safeGeist(fontSize: 12, color: colors.ink),
                    );
                  },
                ),
              ),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 28,
                    interval: tickInterval,
                    getTitlesWidget: (value, meta) => Text(
                      value.toInt().toString(),
                      style:
                          AppThemes.safeGeist(fontSize: 10, color: colors.sub),
                    ),
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 28,
                    getTitlesWidget: (value, meta) {
                      final idx = value.toInt();
                      if (idx < 0 || idx >= sortedLabels.length) {
                        return const SizedBox.shrink();
                      }
                      return Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          sortedLabels[idx].replaceAll('Pre-1970s', 'Pre-70s'),
                          style: AppThemes.safeGeist(
                              fontSize: 9, color: colors.sub),
                        ),
                      );
                    },
                  ),
                ),
                topTitles:
                    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles:
                    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                getDrawingHorizontalLine: (value) =>
                    FlLine(color: colors.lineRgba, strokeWidth: 1),
              ),
              borderData: FlBorderData(show: false),
              barGroups: [
                for (var i = 0; i < sortedLabels.length; i++)
                  BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: decades.counts[sortedLabels[i]]!.toDouble(),
                        color: colors.acc,
                        width: 18,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ],
                  ),
              ],
            ),
            duration: AppPhysics.houseSpringDuration,
            curve: AppPhysics.houseSpringCurve,
          ),
        ),
      ],
    );
  }
}
