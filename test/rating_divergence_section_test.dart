import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:the_lounge/utils/analytics_engine.dart';
import 'package:the_lounge/widgets/analytics/rating_divergence_section.dart';

void main() {
  Future<void> pump(WidgetTester tester, List<RatingDivergencePoint> points) async {
    await tester.pumpWidget(
      MaterialApp(home: Scaffold(body: RatingDivergenceSection(points: points))),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('shows an empty-state message when there are no rated titles', (tester) async {
    await pump(tester, const []);
    expect(
      find.text('Rate a few watched titles to see how your taste compares to '
          'the consensus.'),
      findsOneWidget,
    );
    expect(find.byType(BarChart), findsNothing);
  });

  testWidgets('renders a bar chart sorted by absolute divergence', (tester) async {
    await pump(tester, const [
      RatingDivergencePoint(
        mediaId: 'movie_1',
        title: 'Small Gap',
        personalPoint: 7.0,
        weightedRatingValue: 6.5,
      ),
      RatingDivergencePoint(
        mediaId: 'movie_2',
        title: 'Big Gap',
        personalPoint: 9.0,
        weightedRatingValue: 4.0,
      ),
    ]);

    expect(find.byType(BarChart), findsOneWidget);
    final barChart = tester.widget<BarChart>(find.byType(BarChart));
    // Biggest absolute delta (Big Gap, 5.0) should be sorted first (x: 0).
    expect(barChart.data.barGroups.first.barRods.first.toY, 5.0);
  });

  testWidgets('caps the chart to the 10 largest divergences', (tester) async {
    final points = List.generate(
      15,
      (i) => RatingDivergencePoint(
        mediaId: 'movie_$i',
        title: 'Movie $i',
        personalPoint: 9.0,
        weightedRatingValue: 9.0 - (i + 1),
      ),
    );
    await pump(tester, points);

    final barChart = tester.widget<BarChart>(find.byType(BarChart));
    expect(barChart.data.barGroups, hasLength(10));
  });
}
