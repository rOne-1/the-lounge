import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:the_lounge/utils/analytics_engine.dart';
import 'package:the_lounge/widgets/analytics/rating_divergence_section.dart';

void main() {
  Future<void> pump(WidgetTester tester, List<RatingDivergencePoint> points) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(child: RatingDivergenceSection(points: points)),
        ),
      ),
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
  });

  testWidgets('renders horizontal rows sorted by absolute divergence, most divergent first',
      (tester) async {
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

    expect(find.text('Small Gap'), findsOneWidget);
    expect(find.text('Big Gap'), findsOneWidget);
    // Delta labels: Big Gap = +5.0, Small Gap = +0.5.
    expect(find.text('+5.0'), findsOneWidget);
    expect(find.text('+0.5'), findsOneWidget);

    // Biggest absolute delta (Big Gap) renders above the smaller one.
    final bigGapY = tester.getTopLeft(find.text('Big Gap')).dy;
    final smallGapY = tester.getTopLeft(find.text('Small Gap')).dy;
    expect(bigGapY, lessThan(smallGapY));
  });

  testWidgets('caps the list to the 7 largest divergences', (tester) async {
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

    // delta = i + 1, so the 7 largest are Movie 14 down through Movie 8.
    for (var i = 8; i <= 14; i++) {
      expect(find.text('Movie $i'), findsOneWidget);
    }
    for (var i = 0; i <= 7; i++) {
      expect(find.text('Movie $i'), findsNothing);
    }
  });
}
