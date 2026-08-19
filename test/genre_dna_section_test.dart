import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:the_lounge/widgets/analytics/genre_dna_section.dart';

void main() {
  Future<void> pump(WidgetTester tester, Map<String, int> genreFrequency) async {
    await tester.pumpWidget(
      MaterialApp(home: Scaffold(body: GenreDnaSection(genreFrequency: genreFrequency))),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('shows an empty-state message when there is no genre data', (tester) async {
    await pump(tester, const {});
    expect(find.text('Watch a few more titles to see your genre profile.'), findsOneWidget);
    expect(find.byType(RadarChart), findsNothing);
  });

  testWidgets(
      'falls back to a pill list (not a crashing radar) for fewer than 3 genres',
      (tester) async {
    // Regression: fl_chart's RadarDataSet asserts dataEntries.length >= 3
    // (unless empty) -- a real user with only 1-2 distinct watched genres
    // would crash this screen without this fallback.
    await pump(tester, const {'Drama': 2});

    expect(find.byType(RadarChart), findsNothing);
    expect(find.text('Drama · 2'), findsOneWidget);
  });

  testWidgets('renders a radar chart with one entry per genre', (tester) async {
    await pump(tester, const {'Action': 5, 'Drama': 3, 'Comedy': 1});

    expect(find.byType(RadarChart), findsOneWidget);
    final radar = tester.widget<RadarChart>(find.byType(RadarChart));
    expect(radar.data.dataSets.single.dataEntries, hasLength(3));
  });

  testWidgets('caps the radar to the top 8 genres', (tester) async {
    final freq = {for (var i = 0; i < 12; i++) 'Genre $i': 12 - i};
    await pump(tester, freq);

    final radar = tester.widget<RadarChart>(find.byType(RadarChart));
    expect(radar.data.dataSets.single.dataEntries, hasLength(8));
  });
}
