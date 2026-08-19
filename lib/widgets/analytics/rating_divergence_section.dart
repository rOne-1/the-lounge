import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../constants.dart';
import '../../utils/analytics_engine.dart';

/// ANLY-TASTE-2: compares personal rating (mapped onto weightedRatingOf's
/// 0-10 scale via AnalyticsConstants.personalRatingPoints) against the
/// app's Bayesian weightedRating, for the titles that diverge from
/// consensus the most in either direction.
class RatingDivergenceSection extends StatelessWidget {
  final List<RatingDivergencePoint> points;

  const RatingDivergenceSection({super.key, required this.points});

  static const int _topN = 10;

  @override
  Widget build(BuildContext context) {
    final colors = context.ambianceColors;

    if (points.isEmpty) {
      return Text(
        'Rate a few watched titles to see how your taste compares to '
        'the consensus.',
        style: AppThemes.safeGeist(fontSize: 13, color: colors.sub),
      );
    }

    final sorted = List<RatingDivergencePoint>.from(points)
      ..sort((a, b) => b.delta.abs().compareTo(a.delta.abs()));
    final top = sorted.take(_topN).toList();
    final maxAbs = top
        .map((p) => p.delta.abs())
        .reduce((a, b) => a > b ? a : b)
        .clamp(1.0, double.infinity);

    return SizedBox(
      height: 240,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          minY: -maxAbs * 1.2,
          maxY: maxAbs * 1.2,
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (_) => colors.card2,
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                final point = top[group.x.toInt()];
                final direction = point.delta >= 0 ? 'above' : 'below';
                return BarTooltipItem(
                  '${point.title}\n${point.delta.abs().toStringAsFixed(1)} '
                  'pts $direction consensus',
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
                  value.toStringAsFixed(0),
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
                  if (idx < 0 || idx >= top.length) return const SizedBox.shrink();
                  final title = top[idx].title;
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
                FlLine(color: colors.lineRgba, strokeWidth: value == 0 ? 1.5 : 1),
          ),
          borderData: FlBorderData(show: false),
          barGroups: [
            for (var i = 0; i < top.length; i++)
              BarChartGroupData(
                x: i,
                barRods: [
                  BarChartRodData(
                    toY: top[i].delta,
                    color: colors.acc,
                    width: 14,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ],
              ),
          ],
        ),
        duration: AppPhysics.houseSpringDuration,
        curve: AppPhysics.houseSpringCurve,
      ),
    );
  }
}
