import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:the_lounge/utils/analytics_engine.dart';
import 'package:the_lounge/widgets/analytics/binge_velocity_section.dart';

void main() {
  Future<void> pump(WidgetTester tester, BingeVelocity data) async {
    await tester.pumpWidget(
      MaterialApp(home: Scaffold(body: BingeVelocitySection(data: data))),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('shows "not enough data" and no chart when there is no complete season data',
      (tester) async {
    await pump(tester, const BingeVelocity(averageDays: null, perSeason: []));

    expect(find.text('Log season progress to calculate'), findsOneWidget);
    expect(find.text('—'), findsOneWidget);
    expect(find.byType(BarChart), findsNothing);
  });

  testWidgets(
      'a genuinely near-instant average that rounds to a literal 0 hours shows the placeholder, not a bare 0',
      (tester) async {
    // Regression: dev feedback -- "0 avg. hours per season" reads as
    // broken even though a real (just extremely tiny) average was
    // computed. A handful of minutes between recorded timestamps rounds
    // to 0 hours, same as truly missing data -- both should read as "not
    // enough signal", not a literal zero.
    await pump(
      tester,
      const BingeVelocity(
        averageDays: 0.01, // ~14 minutes -- rounds to 0 hours
        perSeason: [
          ShowBingeVelocity(showId: 'tv_1', showTitle: 'Near Instant', seasonNumber: 1, days: 0.01),
        ],
      ),
    );

    // The headline numeral shows the placeholder dash, not a literal "0"
    // (the per-show chart's own Y-axis legitimately has a real "0" tick at
    // its origin, so this only checks the headline card specifically).
    expect(find.text('Log season progress to calculate'), findsOneWidget);
    expect(find.text('—'), findsOneWidget);
  });

  testWidgets('renders the rounded average and a bar per show', (tester) async {
    await pump(
      tester,
      const BingeVelocity(
        averageDays: 4.5,
        perSeason: [
          ShowBingeVelocity(showId: 'tv_1', showTitle: 'Fast Show', seasonNumber: 1, days: 2.0),
          ShowBingeVelocity(showId: 'tv_2', showTitle: 'Slow Show', seasonNumber: 1, days: 7.0),
        ],
      ),
    );

    expect(find.text('avg. days per season'), findsOneWidget);
    // 4.5 rounds to 5 (Dart's round() rounds half away from zero).
    expect(find.text('5'), findsOneWidget);
    expect(find.byType(BarChart), findsOneWidget);
  });

  testWidgets(
      'a genuine sub-day average shows hours instead of a misleading bare "0"',
      (tester) async {
    // Regression: a real user's first live test (seasons binged within
    // hours of each other) rounded to a bare "0" days, which read as
    // broken even though it was mathematically correct -- SP-3 (honest
    // math) means switching units, not just showing a technically-true 0.
    await pump(
      tester,
      const BingeVelocity(
        averageDays: 0.25, // 6 hours
        perSeason: [
          ShowBingeVelocity(showId: 'tv_1', showTitle: 'Binged Show', seasonNumber: 1, days: 0.25),
        ],
      ),
    );

    expect(find.text('avg. hours per season'), findsOneWidget);
    expect(find.text('6'), findsOneWidget);
    expect(find.text('Log season progress to calculate'), findsNothing);
  });

  testWidgets('caps the chart to the 7 fastest binges', (tester) async {
    final perSeason = List.generate(
      15,
      (i) => ShowBingeVelocity(
        showId: 'tv_$i',
        showTitle: 'Show $i',
        seasonNumber: 1,
        days: (i + 1).toDouble(),
      ),
    );
    await pump(tester, BingeVelocity(averageDays: 8.0, perSeason: perSeason));

    final barChart = tester.widget<BarChart>(find.byType(BarChart));
    expect(barChart.data.barGroups, hasLength(7));
  });
}
