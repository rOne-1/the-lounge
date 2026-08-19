import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../constants.dart';
import '../../utils/analytics_engine.dart';
import '../archive_summary_card.dart';

/// ANLY-TEMPORAL-3: average days to complete a TV season, plus a bar chart
/// of the fastest individual binges. Seasons missing either half of the
/// start/end date pair were already excluded upstream by
/// [computeBingeVelocity] -- this widget only ever sees complete data.
class BingeVelocitySection extends StatelessWidget {
  final BingeVelocity data;

  const BingeVelocitySection({super.key, required this.data});

  static const int _maxBars = 10;

  @override
  Widget build(BuildContext context) {
    final colors = context.ambianceColors;
    final average = data.averageDays;

    final sorted = List<ShowBingeVelocity>.from(data.perSeason)
      ..sort((a, b) => a.days.compareTo(b.days));
    final topShows = sorted.take(_maxBars).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ArchiveSummaryCard(
          label: 'Binge Velocity',
          subtitle: average == null
              ? 'Not enough season data yet'
              : average.round() == 1
                  ? 'avg. day per season'
                  : 'avg. days per season',
          count: average == null ? 0 : average.round(),
          icon: Icons.speed_rounded,
          statusColor: colors.acc,
          onTap: () {},
        ),
        if (topShows.isNotEmpty) ...[
          const SizedBox(height: 16),
          SizedBox(
            height: 220,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: topShows
                    .map((s) => s.days)
                    .reduce((a, b) => a > b ? a : b)
                    .clamp(1.0, double.infinity) *
                    1.2,
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (_) => colors.card2,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final show = topShows[group.x.toInt()];
                      return BarTooltipItem(
                        '${show.showTitle}\nSeason ${show.seasonNumber}: '
                        '${show.days.toStringAsFixed(1)} days',
                        AppThemes.safeGeist(fontSize: 12, color: colors.ink),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 32,
                      getTitlesWidget: (value, meta) => Text(
                        value.toInt().toString(),
                        style: AppThemes.safeGeist(fontSize: 10, color: colors.sub),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      getTitlesWidget: (value, meta) {
                        final idx = value.toInt();
                        if (idx < 0 || idx >= topShows.length) {
                          return const SizedBox.shrink();
                        }
                        final title = topShows[idx].showTitle;
                        final short = title.length > 8 ? '${title.substring(0, 7)}…' : title;
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            short,
                            style: AppThemes.safeGeist(fontSize: 9, color: colors.sub),
                          ),
                        );
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) =>
                      FlLine(color: colors.lineRgba, strokeWidth: 1),
                ),
                borderData: FlBorderData(show: false),
                barGroups: [
                  for (var i = 0; i < topShows.length; i++)
                    BarChartGroupData(
                      x: i,
                      barRods: [
                        BarChartRodData(
                          toY: topShows[i].days,
                          color: colors.acc,
                          width: 16,
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
      ],
    );
  }
}
