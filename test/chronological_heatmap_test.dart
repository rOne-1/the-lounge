import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:the_lounge/utils/analytics_engine.dart';
import 'package:the_lounge/widgets/analytics/chronological_heatmap.dart';

void main() {
  Future<void> pump(WidgetTester tester, HeatmapData data) async {
    await tester.pumpWidget(
      MaterialApp(home: Scaffold(body: ChronologicalHeatmap(data: data))),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('renders the Less/More legend', (tester) async {
    await pump(tester, const HeatmapData({}));
    expect(find.text('Less'), findsOneWidget);
    expect(find.text('More'), findsOneWidget);
  });

  testWidgets('a day with activity carries a tooltip with the right count', (tester) async {
    final today = DateTime.now();
    final day = DateTime(today.year, today.month, today.day);
    await pump(tester, HeatmapData({day: 3}));

    expect(
      find.byTooltip(
        '${_monthAbbrev(day.month)} ${day.day} -- 3 titles watched',
      ),
      findsOneWidget,
    );
  });

  testWidgets('renders without crashing for an empty dataset', (tester) async {
    await pump(tester, const HeatmapData({}));
    expect(find.byType(ChronologicalHeatmap), findsOneWidget);
  });
}

String _monthAbbrev(int month) {
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  return months[month - 1];
}
