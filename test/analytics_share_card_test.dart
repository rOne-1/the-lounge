import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:the_lounge/utils/analytics_engine.dart';
import 'package:the_lounge/widgets/analytics/analytics_share_card.dart';

void main() {
  Future<void> pump(WidgetTester tester, AnalyticsResult result) async {
    // AnalyticsShareCard is a fixed 800x1000 -- in production it's always
    // rendered inside a Stack/Positioned with no width/height constraint
    // (loose constraints), never squeezed by a viewport. Match that here
    // instead of the default ~800x600 test surface, which would otherwise
    // clamp the card's height and overflow.
    tester.view.physicalSize = const Size(900, 1100);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(home: Scaffold(body: AnalyticsShareCard(result: result))),
    );
    await tester.pumpAndSettle();
  }

  testWidgets(
      'renders total hours, titles watched, top genre, top director, top '
      'actor, favorite era, top studio, and avg. binge pace', (tester) async {
    await pump(
      tester,
      const AnalyticsResult(
        heatmap: HeatmapData({}),
        timeInvestment: TimeInvestment(
            movieMinutes: 120, tvMinutes: 60, movieCount: 1, tvCount: 1),
        bingeVelocity: BingeVelocity(averageDays: 2.5, perSeason: []),
        castRanking: [NameCount(name: 'Alice', count: 3)],
        directorRanking: [NameCount(name: 'Nolan', count: 2)],
        ratingDivergence: [],
        genreFrequency: {'Drama': 4, 'Comedy': 1},
        keywordAffinity: {},
        decadeDistribution: DecadeDistribution({'2010s': 3, '2000s': 1}),
        temporalDistanceIndex: TemporalDistanceIndex(null),
        languageDistribution: LanguageDistribution({}),
        dayOfWeekDistribution:
            DayOfWeekDistribution(movieCounts: {}, tvCounts: {}),
        runtimePreferences: RuntimePreferences(
            averageMinutes: null,
            shortCount: 0,
            standardCount: 0,
            epicCount: 0),
        discoverSwipeRatio: DiscoverSwipeRatio(
            skippedCount: 0, watchlistedCount: 0, savedCount: 0),
        studioAffinity: StudioAffinity([NameCount(name: 'A24', count: 2)]),
        watchlistFunnel: WatchlistFunnel(
            convertedCount: 0, averageBacklogDays: null, pendingCount: 0),
        abandonedShows: [],
      ),
    );

    expect(find.text('THE LOUNGE'), findsOneWidget);
    expect(find.text('My Watching Habits'), findsOneWidget);
    expect(find.text('3'), findsOneWidget); // (120+60)/60 = 3 total hours
    expect(find.text('Hours Watched'), findsOneWidget);
    expect(find.text('2'), findsOneWidget); // movieCount + tvCount
    expect(find.text('Titles Watched'), findsOneWidget);
    expect(find.text('Drama'), findsOneWidget);
    expect(find.text('Top Genre'), findsOneWidget);
    expect(find.text('Nolan'), findsOneWidget);
    expect(find.text('Top Director'), findsOneWidget);
    expect(find.text('Alice'), findsOneWidget);
    expect(find.text('Top Actor'), findsOneWidget);
    expect(find.text('2010s'), findsOneWidget);
    expect(find.text('Favorite Era'), findsOneWidget);
    expect(find.text('A24'), findsOneWidget);
    expect(find.text('Top Studio'), findsOneWidget);
    expect(find.text('2.5d'), findsOneWidget);
    expect(find.text('Avg. Binge Pace'), findsOneWidget);

    // Regression guard: the on-device attribution footer was removed.
    expect(find.textContaining('Generated on-device'), findsNothing);
  });

  testWidgets('omits rows with no data instead of showing blank/null values',
      (tester) async {
    await pump(
      tester,
      const AnalyticsResult(
        heatmap: HeatmapData({}),
        timeInvestment: TimeInvestment(
            movieMinutes: 0, tvMinutes: 0, movieCount: 0, tvCount: 0),
        bingeVelocity: BingeVelocity(averageDays: null, perSeason: []),
        castRanking: [],
        directorRanking: [],
        ratingDivergence: [],
        genreFrequency: {},
        keywordAffinity: {},
        decadeDistribution: DecadeDistribution({}),
        temporalDistanceIndex: TemporalDistanceIndex(null),
        languageDistribution: LanguageDistribution({}),
        dayOfWeekDistribution:
            DayOfWeekDistribution(movieCounts: {}, tvCounts: {}),
        runtimePreferences: RuntimePreferences(
            averageMinutes: null,
            shortCount: 0,
            standardCount: 0,
            epicCount: 0),
        discoverSwipeRatio: DiscoverSwipeRatio(
            skippedCount: 0, watchlistedCount: 0, savedCount: 0),
        studioAffinity: StudioAffinity([]),
        watchlistFunnel: WatchlistFunnel(
            convertedCount: 0, averageBacklogDays: null, pendingCount: 0),
        abandonedShows: [],
      ),
    );

    expect(find.text('Hours Watched'), findsOneWidget);
    expect(find.text('Titles Watched'), findsOneWidget);
    expect(find.text('Top Genre'), findsNothing);
    expect(find.text('Top Director'), findsNothing);
    expect(find.text('Top Actor'), findsNothing);
    expect(find.text('Favorite Era'), findsNothing);
    expect(find.text('Top Studio'), findsNothing);
    expect(find.text('Avg. Binge Pace'), findsNothing);
  });
}
