import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:the_lounge/utils/analytics_engine.dart';
import 'package:the_lounge/widgets/analytics/viewing_rhythm_section.dart';

void main() {
  Future<void> pump(
    WidgetTester tester,
    DayOfWeekDistribution dayOfWeek,
    RuntimePreferences runtimePreferences,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: ViewingRhythmSection(
              dayOfWeek: dayOfWeek,
              runtimePreferences: runtimePreferences,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  const emptyRuntime = RuntimePreferences(
    averageMinutes: null,
    shortCount: 0,
    standardCount: 0,
    epicCount: 0,
  );

  testWidgets(
      'regression: a day with both a high movie count and a high TV count '
      'does not overflow the bar row', (tester) async {
    // Bug caught live in the browser: the bar-width calc previously used
    // the max of movie-only and TV-only counts SEPARATELY as the
    // normalizing denominator, then summed the two resulting widths as if
    // they were meant to be stacked -- a day strong in both media types
    // could produce a combined width exceeding the row's available space,
    // overflowing the RenderFlex. The correct denominator is the max of
    // each day's COMBINED (movie+TV) total.
    await pump(
      tester,
      const DayOfWeekDistribution(
        movieCounts: {DateTime.thursday: 3},
        tvCounts: {DateTime.thursday: 1, DateTime.tuesday: 3},
      ),
      emptyRuntime,
    );

    expect(tester.takeException(), isNull);
  });

  testWidgets('renders per-day totals correctly', (tester) async {
    await pump(
      tester,
      const DayOfWeekDistribution(
        movieCounts: {DateTime.monday: 2},
        tvCounts: {DateTime.monday: 1},
      ),
      emptyRuntime,
    );

    expect(find.text('Mon'), findsOneWidget);
    expect(find.text('3'), findsOneWidget); // 2 movies + 1 TV on Monday
  });

  testWidgets('shows the runtime pacing card and buckets when data exists',
      (tester) async {
    await pump(
      tester,
      const DayOfWeekDistribution(movieCounts: {}, tvCounts: {}),
      const RuntimePreferences(
        averageMinutes: 137.0,
        shortCount: 1,
        standardCount: 2,
        epicCount: 1,
      ),
    );

    expect(find.text('Movie Pacing'), findsOneWidget);
    expect(find.text('2h 17m'), findsOneWidget);
    expect(find.text('Sub-90 min'), findsOneWidget);
  });
}
