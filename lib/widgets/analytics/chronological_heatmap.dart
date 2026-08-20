import 'package:flutter/material.dart';
import '../../constants.dart';
import '../../constants/analytics_constants.dart';
import '../../utils/analytics_engine.dart';

/// ANLY-TEMPORAL-1: GitHub-style daily contribution graph of watch
/// activity over the last [AnalyticsConstants.heatmapWindowMonths] months.
/// Hand-built (no charting library needed for a colored grid) -- cell
/// intensity comes from [context.ambianceColors.acc] at varying opacity
/// (SP-2: no hardcoded green), horizontally scrollable since a year of
/// weeks doesn't fit most viewport widths.
class ChronologicalHeatmap extends StatelessWidget {
  final HeatmapData data;

  const ChronologicalHeatmap({super.key, required this.data});

  static const double _cellSize = 12.0;
  static const double _cellGap = 3.0;

  @override
  Widget build(BuildContext context) {
    final colors = context.ambianceColors;
    final today = DateTime.now();
    final todayMidnight = DateTime(today.year, today.month, today.day);

    var windowStart = DateTime(
      todayMidnight.year,
      todayMidnight.month - AnalyticsConstants.heatmapWindowMonths,
      todayMidnight.day,
    );
    // Align to the Monday on/before windowStart so every week is a clean
    // 7-row column.
    windowStart = windowStart.subtract(Duration(days: windowStart.weekday - 1));

    final maxCount = data.dailyCounts.values.isEmpty
        ? 0
        : data.dailyCounts.values.reduce((a, b) => a > b ? a : b);

    final weeks = <List<DateTime>>[];
    var cursor = windowStart;
    while (!cursor.isAfter(todayMidnight)) {
      weeks.add(List.generate(7, (i) => cursor.add(Duration(days: i))));
      cursor = cursor.add(const Duration(days: 7));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          reverse: true,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: weeks
                .map((week) => Padding(
                      padding: const EdgeInsets.only(right: _cellGap),
                      child: Column(
                        children: week
                            .map((day) => Padding(
                                  padding:
                                      const EdgeInsets.only(bottom: _cellGap),
                                  child: _DayCell(
                                    day: day,
                                    count: data.dailyCounts[day] ?? 0,
                                    maxCount: maxCount,
                                    isFuture: day.isAfter(todayMidnight),
                                  ),
                                ))
                            .toList(),
                      ),
                    ))
                .toList(),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Less',
                style: AppThemes.safeGeist(fontSize: 11, color: colors.sub)),
            const SizedBox(width: 6),
            for (final alpha in [0.0, 0.35, 0.6, 0.85, 1.0])
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 1.5),
                child: Container(
                  width: _cellSize,
                  height: _cellSize,
                  decoration: BoxDecoration(
                    color: alpha == 0.0
                        ? colors.lineRgba
                        : colors.acc.withValues(alpha: alpha),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            const SizedBox(width: 6),
            Text('More',
                style: AppThemes.safeGeist(fontSize: 11, color: colors.sub)),
          ],
        ),
      ],
    );
  }
}

class _DayCell extends StatelessWidget {
  final DateTime day;
  final int count;
  final int maxCount;
  final bool isFuture;

  const _DayCell({
    required this.day,
    required this.count,
    required this.maxCount,
    required this.isFuture,
  });

  static const List<String> _months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  @override
  Widget build(BuildContext context) {
    final colors = context.ambianceColors;

    if (isFuture) {
      return const SizedBox(
        width: ChronologicalHeatmap._cellSize,
        height: ChronologicalHeatmap._cellSize,
      );
    }

    final Color color;
    if (count == 0 || maxCount <= 0) {
      color = colors.lineRgba;
    } else {
      final intensity = (count / maxCount).clamp(0.2, 1.0);
      color = colors.acc.withValues(alpha: intensity);
    }

    final label = '${_months[day.month - 1]} ${day.day}';
    final message = count == 0
        ? '$label -- nothing watched'
        : '$label -- $count ${count == 1 ? 'title' : 'titles'} watched';

    return Tooltip(
      message: message,
      // Stock Tooltip defaults to long-press on touch platforms -- a plain
      // tap (the only interaction most users try) never reveals it on
      // Android at all. Tap-to-show still leaves hover-to-show intact on
      // desktop/web (hover isn't governed by triggerMode).
      triggerMode: TooltipTriggerMode.tap,
      // SP-2: stock Tooltip defaults to Flutter's plain light Material
      // popup regardless of app theme -- jarring against this app's dark
      // luxury chrome. Themed to match the fl_chart tooltip convention
      // used elsewhere in Analytics (colors.card2 background, colors.ink
      // text).
      decoration: BoxDecoration(
        color: colors.card2,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colors.lineRgba),
      ),
      textStyle: AppThemes.safeGeist(fontSize: 12, color: colors.ink),
      child: Container(
        width: ChronologicalHeatmap._cellSize,
        height: ChronologicalHeatmap._cellSize,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(3),
        ),
      ),
    );
  }
}
