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

  static const int _maxBars = 7;

  @override
  Widget build(BuildContext context) {
    final colors = context.ambianceColors;
    final average = data.averageDays;

    final sorted = List<ShowBingeVelocity>.from(data.perSeason)
      ..sort((a, b) => a.days.compareTo(b.days));
    final topShows = sorted.take(_maxBars).toList();

    // SP-3: a genuine sub-day average (seasons binged within hours) still
    // rounds to a misleading bare "0" in days -- switch to hours for that
    // case instead of silently showing 0.
    final showAverageInHours = average != null && average < 1;
    final averageDisplayValue = average == null
        ? 0
        : showAverageInHours
            ? (average * 24).round()
            : average.round();

    // Even the hours fallback can round to a literal 0 for a genuinely
    // near-instant season (e.g. a handful of minutes between recorded
    // timestamps) -- a bare "0" here reads as broken/no-data even though a
    // real value was computed, so treat it the same as the null case rather
    // than displaying it.
    final hasNoMeaningfulAverage = average == null || averageDisplayValue == 0;

    // Explicit, clean-multiple interval instead of leaving fl_chart to
    // auto-compute one -- an un-intervaled axis can place its regular tick
    // step right next to the auto-added max-boundary tick, rendering the
    // same rounded number twice near the top. Forcing maxY to be an exact
    // multiple of interval makes the top gridline/tick coincide with the
    // real boundary instead.
    final rawMaxDays = topShows.isEmpty
        ? 1.0
        : topShows.map((s) => s.days).reduce((a, b) => a > b ? a : b).clamp(1.0, double.infinity);
    final tickInterval = (rawMaxDays / 4).ceilToDouble().clamp(1.0, double.infinity);
    final chartMaxY = tickInterval * 4;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ArchiveSummaryCard(
          label: 'Binge Velocity',
          subtitle: hasNoMeaningfulAverage
              ? 'Log season progress to calculate'
              : showAverageInHours
                  ? (averageDisplayValue == 1 ? 'avg. hour per season' : 'avg. hours per season')
                  : (averageDisplayValue == 1 ? 'avg. day per season' : 'avg. days per season'),
          count: averageDisplayValue,
          countLabelOverride: hasNoMeaningfulAverage ? '—' : null,
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
                maxY: chartMaxY,
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
                      interval: tickInterval,
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
                        final short = title.length > 10 ? '${title.substring(0, 9)}…' : title;
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
