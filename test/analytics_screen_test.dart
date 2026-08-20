import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:the_lounge/providers/ambiance_provider.dart';
import 'package:the_lounge/providers/analytics_provider.dart';
import 'package:the_lounge/providers/media_provider.dart';
import 'package:the_lounge/screens/analytics_screen.dart';
import 'package:the_lounge/utils/analytics_engine.dart';
import 'package:the_lounge/widgets/analytics/analytics_share_card.dart';
import 'package:the_lounge/widgets/analytics/binge_velocity_section.dart';
import 'package:the_lounge/widgets/analytics/cast_constellations_section.dart';
import 'package:the_lounge/widgets/analytics/chronological_heatmap.dart';
import 'package:the_lounge/widgets/analytics/discover_funnel_section.dart';
import 'package:the_lounge/widgets/analytics/era_distribution_section.dart';
import 'package:the_lounge/widgets/analytics/genre_dna_section.dart';
import 'package:the_lounge/widgets/analytics/language_distribution_section.dart';
import 'package:the_lounge/widgets/analytics/rating_divergence_section.dart';
import 'package:the_lounge/widgets/analytics/viewing_rhythm_section.dart';

// Note on strategy: the actual generate()/compute() round-trip (does it
// populate result/generatedAt correctly, does regeneration overwrite the
// previous result) is already covered end-to-end in
// analytics_provider_test.dart, via plain test() bodies that await the
// real isolate directly -- fast and reliable there. Combining a real
// compute() isolate with testWidgets()/pumpAndSettle() is a known bad mix
// (a CircularProgressIndicator's perpetual animation makes pumpAndSettle()
// never settle regardless of whether the isolate has actually finished,
// and this session's attempt at tester.runAsync() + a polling loop hung
// indefinitely rather than completing). So this file tests the screen in
// isolation from real async work: idle state, that tapping Generate/
// Regenerate transitions into the loading state (proving the UI is wired
// to the real notifier), and that the results state renders correctly
// given an already-populated AnalyticsState (injected directly via a
// provider override, bypassing compute() entirely).
void main() {
  setUp(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  Future<SharedPreferences> mockPrefs() async {
    SharedPreferences.setMockInitialValues({});
    return SharedPreferences.getInstance();
  }

  group('ANLY-HUB-2: idle state (SP-1)', () {
    testWidgets('shows the Generate button and no chart content on open',
        (tester) async {
      final prefs = await mockPrefs();
      final container = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: AnalyticsScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Generate Analytics'), findsOneWidget);
      expect(find.text('Ready when you are'), findsOneWidget);
      expect(find.text('Temporal'), findsNothing);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets(
        'BACKUP-2: withholds the Generate CTA while a backup import is in flight',
        (tester) async {
      final prefs = await mockPrefs();
      final container = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      );
      addTearDown(container.dispose);

      container.read(isDataImportingProvider.notifier).set(true);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: AnalyticsScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Generate Analytics'), findsNothing);
      expect(find.text('Hold on a moment'), findsOneWidget);

      container.read(isDataImportingProvider.notifier).set(false);
      await tester.pumpAndSettle();

      expect(find.text('Generate Analytics'), findsOneWidget);
      expect(find.text('Ready when you are'), findsOneWidget);
    });
  });

  group('ANLY-HUB-2: generation flow (UI wiring)', () {
    testWidgets('tapping Generate transitions into the loading state',
        (tester) async {
      final prefs = await mockPrefs();
      final container = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: AnalyticsScreen()),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Generate Analytics'));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(container.read(analyticsProvider).isGenerating, isTrue);
    });

    testWidgets('tapping Regenerate transitions back into the loading state',
        (tester) async {
      final prefs = await mockPrefs();
      final seeded = AnalyticsState(
        result: const AnalyticsResult(
          heatmap: HeatmapData({}),
          timeInvestment: TimeInvestment(movieMinutes: 0, tvMinutes: 0),
          bingeVelocity: BingeVelocity(averageDays: null, perSeason: []),
          castRanking: [],
          directorRanking: [],
          ratingDivergence: [],
          genreFrequency: {},
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
        generatedAt: DateTime(2026, 1, 1),
      );
      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          analyticsProvider.overrideWith(() => _SeededNotifier(seeded)),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: AnalyticsScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Regenerate'), findsOneWidget);

      await tester.tap(find.text('Regenerate'));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });

  group('ANLY-HUB-2: results state rendering', () {
    testWidgets(
        'renders Temporal section content from a seeded AnalyticsResult',
        (tester) async {
      final prefs = await mockPrefs();
      final seeded = AnalyticsState(
        result: const AnalyticsResult(
          heatmap: HeatmapData({}),
          timeInvestment: TimeInvestment(movieMinutes: 120, tvMinutes: 270),
          bingeVelocity: BingeVelocity(
            averageDays: 3.0,
            perSeason: [
              ShowBingeVelocity(
                showId: 'tv_1',
                showTitle: 'A Show',
                seasonNumber: 1,
                days: 3.0,
              ),
            ],
          ),
          castRanking: [NameCount(name: 'Alice', count: 2)],
          directorRanking: [NameCount(name: 'Nolan', count: 1)],
          ratingDivergence: [
            RatingDivergencePoint(
              mediaId: 'movie_1',
              title: 'A Movie',
              personalPoint: 9.0,
              weightedRatingValue: 6.0,
            ),
          ],
          genreFrequency: {'Drama': 2, 'Action': 1, 'Comedy': 1},
          decadeDistribution: DecadeDistribution({'2010s': 2, '2020s': 1}),
          temporalDistanceIndex: TemporalDistanceIndex(30.0),
          languageDistribution: LanguageDistribution({'en': 3}),
          dayOfWeekDistribution: DayOfWeekDistribution(
            movieCounts: {DateTime.monday: 2},
            tvCounts: {DateTime.tuesday: 1},
          ),
          runtimePreferences: RuntimePreferences(
            averageMinutes: 120.0,
            shortCount: 1,
            standardCount: 1,
            epicCount: 0,
          ),
          discoverSwipeRatio: DiscoverSwipeRatio(
            skippedCount: 5,
            watchlistedCount: 2,
            savedCount: 1,
          ),
          studioAffinity: StudioAffinity([NameCount(name: 'A24', count: 2)]),
          watchlistFunnel: WatchlistFunnel(
            convertedCount: 3,
            averageBacklogDays: 12.0,
            pendingCount: 2,
          ),
          abandonedShows: [
            AbandonedShow(
              showId: 'tv_2',
              showTitle: 'Stalled Show',
              watchedEpisodeCount: 2,
              totalEpisodes: 10,
            ),
          ],
        ),
        generatedAt: DateTime(2026, 1, 1),
      );
      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          analyticsProvider.overrideWith(() => _SeededNotifier(seeded)),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: AnalyticsScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Generate Analytics'), findsNothing);
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.text('Temporal'), findsOneWidget);
      expect(find.text('Movies'), findsOneWidget);
      expect(find.text('TV Shows'), findsOneWidget);
      expect(find.text('2 hours watched'), findsOneWidget);
      expect(find.text('~5 hours watched (estimate)'), findsOneWidget);
      expect(find.byType(ChronologicalHeatmap), findsOneWidget);
      expect(find.byType(BingeVelocitySection), findsOneWidget);
      expect(find.text('avg. days per season'), findsOneWidget);
      expect(find.text('Taste'), findsOneWidget);
      expect(find.byType(CastConstellationsSection), findsOneWidget);
      // Scoped to CastConstellationsSection: the offscreen AnalyticsShareCard
      // (ANLY-SHARE-1) is also always present once there's a result, and
      // its "Top Director" stat renders the same name.
      expect(
        find.descendant(
          of: find.byType(CastConstellationsSection),
          matching: find.text('Nolan'),
        ),
        findsOneWidget,
      );
      expect(find.byType(RatingDivergenceSection), findsOneWidget);
      expect(find.byType(GenreDnaSection), findsOneWidget);
      expect(find.byType(EraDistributionSection), findsOneWidget);
      expect(find.byType(ViewingRhythmSection), findsOneWidget);
      expect(find.byType(LanguageDistributionSection), findsOneWidget);
      expect(find.byType(DiscoverFunnelSection), findsOneWidget);
      expect(find.text('Era & Cinema History'), findsOneWidget);
      expect(find.text('Viewing Rhythm'), findsOneWidget);
      expect(find.text('Global Footprint'), findsOneWidget);
      expect(find.text('Discover Selectivity'), findsOneWidget);
    });

    testWidgets('EXP-LEGEND-1: Legend trigger opens a glossary sheet',
        (tester) async {
      final prefs = await mockPrefs();
      final seeded = AnalyticsState(
        result: const AnalyticsResult(
          heatmap: HeatmapData({}),
          timeInvestment: TimeInvestment(movieMinutes: 120, tvMinutes: 270),
          bingeVelocity: BingeVelocity(averageDays: 3.0, perSeason: []),
          castRanking: [],
          directorRanking: [],
          ratingDivergence: [],
          genreFrequency: {},
          decadeDistribution: DecadeDistribution({}),
          temporalDistanceIndex: TemporalDistanceIndex(null),
          languageDistribution: LanguageDistribution({}),
          dayOfWeekDistribution:
              DayOfWeekDistribution(movieCounts: {}, tvCounts: {}),
          runtimePreferences: RuntimePreferences(
            averageMinutes: 0.0,
            shortCount: 0,
            standardCount: 0,
            epicCount: 0,
          ),
          discoverSwipeRatio: DiscoverSwipeRatio(
            skippedCount: 0,
            watchlistedCount: 0,
            savedCount: 0,
          ),
          studioAffinity: StudioAffinity([]),
          watchlistFunnel: WatchlistFunnel(
            convertedCount: 0,
            averageBacklogDays: null,
            pendingCount: 0,
          ),
          abandonedShows: [],
        ),
        generatedAt: DateTime(2026, 1, 1),
      );
      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          analyticsProvider.overrideWith(() => _SeededNotifier(seeded)),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: AnalyticsScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('What these mean'), findsNothing);

      await tester.tap(find.text('Legend'));
      await tester.pumpAndSettle();

      expect(find.text('What these mean'), findsOneWidget);
      expect(find.text('Watchlist Funnel'), findsWidgets);
      expect(find.text('Shelf-Life Drop-Offs'), findsWidgets);

      await tester.tap(find.text('Got it'));
      await tester.pumpAndSettle();

      expect(find.text('What these mean'), findsNothing);
    });
  });

  group('ANLY-SHARE-1: image export', () {
    testWidgets(
        'the Share button and its offscreen capture target are present and correctly wired',
        (tester) async {
      final prefs = await mockPrefs();
      final seeded = AnalyticsState(
        result: const AnalyticsResult(
          heatmap: HeatmapData({}),
          timeInvestment: TimeInvestment(movieMinutes: 120, tvMinutes: 0),
          bingeVelocity: BingeVelocity(averageDays: null, perSeason: []),
          castRanking: [],
          directorRanking: [],
          ratingDivergence: [],
          genreFrequency: {},
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
        generatedAt: DateTime(2026, 1, 1),
      );
      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          analyticsProvider.overrideWith(() => _SeededNotifier(seeded)),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: AnalyticsScreen()),
        ),
      );
      await tester.pumpAndSettle();

      // The offscreen capture target (AnalyticsShareCard wrapped in the
      // RepaintBoundary _handleShare looks up) exists and is positioned
      // off-canvas, not visually shown but genuinely painted.
      expect(find.byType(AnalyticsShareCard), findsOneWidget);
      final positioned = tester.widget<Positioned>(
        find.ancestor(
          of: find.byType(AnalyticsShareCard),
          matching: find.byType(Positioned),
        ),
      );
      expect(positioned.left, lessThan(0));

      expect(find.text('Share'), findsOneWidget);

      // NOTE on scope, flagging honestly: this test deliberately does NOT
      // tap Share and drive the real capture through. Doing so calls the
      // real RenderRepaintBoundary.toImage(), which throws an uncaught
      // google_fonts "allowRuntimeFetching is false and font not found in
      // assets" error specifically during toImage()'s text-layout pass
      // (this project's tests always set allowRuntimeFetching: false to
      // avoid real network calls, and no font assets are bundled for
      // tests) -- a test-environment-only gap in this harness, not a
      // production bug (fonts load normally in the real app). The two
      // things a full round-trip would otherwise cover are independently
      // verified elsewhere instead: AnalyticsShareCard's data correctness
      // (analytics_share_card_test.dart) and shareImageFile's platform
      // wiring, which mirrors shareJsonFile's already-covered pattern
      // exactly (settings_screen_test.dart's "Share Backup" test).
    });
  });
}

/// Test-only notifier that starts with a fixed [AnalyticsState] instead of
/// the real idle default, so results-state rendering can be tested without
/// going through a real compute() isolate. generate() still delegates to
/// the real implementation (unused by these tests, but kept real rather
/// than stubbed in case a future test wants it).
class _SeededNotifier extends AnalyticsNotifier {
  final AnalyticsState seeded;
  _SeededNotifier(this.seeded);

  @override
  AnalyticsState build() => seeded;
}
