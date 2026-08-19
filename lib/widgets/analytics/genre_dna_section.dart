import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../constants.dart';
import '../../constants/analytics_constants.dart';

/// ANLY-TASTE-3: radar chart of genre frequency across completed watch
/// history, capped to the top N genres for axis legibility.
///
/// fl_chart's `RadarDataSet` asserts at least 3 entries -- a real user with
/// only 1-2 distinct watched genres would crash this screen with a bare
/// radar chart, so that case falls back to a simple pill list instead of a
/// meaningless (and crashing) 1-2-axis "radar".
class GenreDnaSection extends StatelessWidget {
  final Map<String, int> genreFrequency;

  const GenreDnaSection({super.key, required this.genreFrequency});

  @override
  Widget build(BuildContext context) {
    final colors = context.ambianceColors;

    if (genreFrequency.isEmpty) {
      return Text(
        'Watch a few more titles to see your genre profile.',
        style: AppThemes.safeGeist(fontSize: 13, color: colors.sub),
      );
    }

    final sorted = genreFrequency.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final top = sorted.take(AnalyticsConstants.genreDnaTopN).toList();

    if (top.length < 3) {
      return Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final entry in top)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: colors.acc.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                '${entry.key} · ${entry.value}',
                style: AppThemes.safeGeist(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: colors.acc,
                ),
              ),
            ),
        ],
      );
    }

    return SizedBox(
      height: 300,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 20),
        child: RadarChart(
          RadarChartData(
            radarShape: RadarShape.polygon,
            radarBackgroundColor: Colors.transparent,
            radarBorderData: BorderSide(color: colors.lineRgba),
            gridBorderData: BorderSide(color: colors.lineRgba, width: 1),
            tickBorderData: BorderSide(color: colors.lineRgba, width: 0.5),
            tickCount: 4,
            ticksTextStyle:
                const TextStyle(color: Colors.transparent, fontSize: 0),
            titleTextStyle:
                AppThemes.safeGeist(fontSize: 11, color: colors.sub),
            titlePositionPercentageOffset: 0.18,
            getTitle: (index, angle) {
              if (index < 0 || index >= top.length) {
                return const RadarChartTitle(text: '');
              }
              return RadarChartTitle(text: top[index].key);
            },
            dataSets: [
              RadarDataSet(
                fillColor: colors.acc.withValues(alpha: 0.22),
                borderColor: colors.acc,
                borderWidth: 2,
                entryRadius: 3,
                dataEntries: [
                  for (final entry in top)
                    RadarEntry(value: entry.value.toDouble()),
                ],
              ),
            ],
            radarTouchData: RadarTouchData(enabled: true),
          ),
          duration: AppPhysics.houseSpringDuration,
          curve: AppPhysics.houseSpringCurve,
        ),
      ),
    );
  }
}
