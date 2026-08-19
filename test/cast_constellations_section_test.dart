import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:the_lounge/utils/analytics_engine.dart';
import 'package:the_lounge/widgets/analytics/cast_constellations_section.dart';

void main() {
  Future<void> pump(
    WidgetTester tester, {
    List<NameCount> directors = const [],
    List<NameCount> cast = const [],
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CastConstellationsSection(
            directorRanking: directors,
            castRanking: cast,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('shows an empty-state message when there is no ranking data', (tester) async {
    await pump(tester);
    expect(find.text('Watch a few more titles to see your most-watched people.'),
        findsOneWidget);
  });

  testWidgets('renders both ranked lists with names and counts', (tester) async {
    await pump(
      tester,
      directors: const [NameCount(name: 'Nolan', count: 3)],
      cast: const [NameCount(name: 'Alice', count: 5)],
    );

    expect(find.text('Top Directors'), findsOneWidget);
    expect(find.text('Top Actors'), findsOneWidget);
    expect(find.text('Nolan'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
    expect(find.text('Alice'), findsOneWidget);
    expect(find.text('5'), findsOneWidget);
  });

  testWidgets('caps each list to the top 8 entries', (tester) async {
    final directors = List.generate(
      12,
      (i) => NameCount(name: 'Director $i', count: 12 - i),
    );
    await pump(tester, directors: directors);

    expect(find.text('Director 0'), findsOneWidget);
    expect(find.text('Director 7'), findsOneWidget);
    expect(find.text('Director 8'), findsNothing);
  });
}
