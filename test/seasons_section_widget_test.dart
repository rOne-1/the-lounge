import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:the_lounge/screens/detail_screen.dart';
import 'package:the_lounge/providers/media_provider.dart';
import 'package:the_lounge/providers/ambiance_provider.dart';
import 'package:the_lounge/models/media_item.dart';
import 'package:the_lounge/repositories/mock_movie_repository.dart';

class _SeasonsTestRepository extends MockMovieRepository {
  final Map<String, MediaItem> items;
  final Map<int, TvSeason> seasonsByNumber;
  _SeasonsTestRepository(this.items, this.seasonsByNumber);

  @override
  Future<MediaItem?> getMediaDetails(String id, {String? region}) async => items[id];

  @override
  Future<TvSeason?> getTvSeasonDetails(String tvId, int seasonNumber) async =>
      seasonsByNumber[seasonNumber];
}

void main() {
  setUp(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  // Pre-normalized (already 'tv_'-prefixed) id: toggleEpisodeWatched/
  // markSeasonWatched normalize showItem.id before storing into
  // watchedEpisodes/seasonEndDates, but isEpisodeWatched's showId param
  // isn't normalized on the read side -- a raw, unprefixed test id here
  // would silently desync from what got written (matches the class of
  // issue fixed for item 61; real production ids are always already
  // normalized via TmdbMovieRepository._mapJsonToMediaItem, so this is a
  // test-fixture concern only, not a production bug).
  const show = MediaItem(
    id: 'tv_seasons1',
    title: 'Seasons Show',
    type: MediaType.tv,
    rating: 8.0,
    overview: '',
    genres: [],
    seasonsCount: 2,
  );

  final season1 = TvSeason(
    id: 1,
    seasonNumber: 1,
    name: 'Season 1',
    episodes: [
      TvEpisode(id: 1, episodeNumber: 1, seasonNumber: 1, name: 'Pilot', runtime: 42, airDate: DateTime(2020, 1, 1)),
      TvEpisode(id: 2, episodeNumber: 2, seasonNumber: 1, name: 'The Box', runtime: 44, airDate: DateTime(2020, 1, 8)),
    ],
  );
  final season2 = TvSeason(
    id: 2,
    seasonNumber: 2,
    name: 'Season 2',
    episodes: [
      TvEpisode(id: 3, episodeNumber: 1, seasonNumber: 2, name: 'Return', runtime: 45, airDate: DateTime(2021, 1, 1)),
    ],
  );

  Future<ProviderContainer> pumpDetail(WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        movieRepositoryProvider.overrideWithValue(
          _SeasonsTestRepository({show.id: show}, {1: season1, 2: season2}),
        ),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(home: DetailScreen(id: show.id, initialItem: show)),
      ),
    );
    await tester.pumpAndSettle();
    return container;
  }

  Future<void> scrollToSeasons(WidgetTester tester, Finder target) async {
    await tester.scrollUntilVisible(target, 200, scrollable: find.byType(Scrollable).first);
    await tester.pumpAndSettle();
  }

  group('CRAFT-EPISODE-1: episode carousel', () {
    testWidgets('renders each episode as a 16:9 card with number, title, runtime, and air date',
        (tester) async {
      await pumpDetail(tester);
      await scrollToSeasons(tester, find.text('Seasons & Episodes'));

      expect(find.text('E1'), findsOneWidget);
      expect(find.text('E2'), findsOneWidget);
      expect(find.text('Pilot'), findsOneWidget);
      expect(find.text('The Box'), findsOneWidget);
      expect(find.text('42 min · Jan 1'), findsOneWidget);
      expect(find.text('44 min · Jan 8'), findsOneWidget);
    });

    testWidgets('the episode carousel scrolls horizontally, not vertically', (tester) async {
      await pumpDetail(tester);
      await scrollToSeasons(tester, find.text('Seasons & Episodes'));

      final carousel = find.ancestor(
        of: find.text('E1'),
        matching: find.byType(ListView),
      );
      expect(carousel, findsOneWidget);
      expect(tester.widget<ListView>(carousel).scrollDirection, Axis.horizontal);
    });

    testWidgets('tapping an episode card toggles watched and shows the gold checkmark badge',
        (tester) async {
      final container = await pumpDetail(tester);
      await scrollToSeasons(tester, find.text('E1'));

      expect(find.byIcon(Icons.check), findsNothing);

      await tester.tap(find.text('E1'));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.check), findsOneWidget);
      final state = container.read(mediaProvider);
      expect(state.watchedEpisodes[show.prefixedId]?.contains('S1E1'), isTrue);
    });

    testWidgets('tapping an already-watched episode card unmarks it', (tester) async {
      final container = await pumpDetail(tester);
      await scrollToSeasons(tester, find.text('E1'));

      await tester.tap(find.text('E1'));
      await tester.pumpAndSettle();
      expect(container.read(mediaProvider).watchedEpisodes[show.prefixedId]?.contains('S1E1'), isTrue);

      await tester.tap(find.text('E1'));
      await tester.pumpAndSettle();
      expect(container.read(mediaProvider).watchedEpisodes[show.prefixedId]?.contains('S1E1') ?? false, isFalse);
    });
  });

  group('CRAFT-EPISODE-2: long-press season pill marks complete', () {
    testWidgets(
        'long-pressing a season pill marks its released episodes watched and shows a confirmation toast',
        (tester) async {
      final container = await pumpDetail(tester);
      await scrollToSeasons(tester, find.text('Season 2'));

      await tester.longPress(find.text('Season 2'));
      await tester.pump();

      expect(find.text('Season 2 marked complete.'), findsOneWidget);
      final state = container.read(mediaProvider);
      expect(state.watchedEpisodes[show.prefixedId]?.contains('S2E1'), isTrue);

      // Drain the toast's own auto-dismiss timer so it doesn't leave a
      // pending Timer at teardown.
      await tester.pump(const Duration(seconds: 4));
    });

    testWidgets(
        'long-pressing an already-complete season pill does not re-fire the completion',
        (tester) async {
      final container = await pumpDetail(tester);
      await scrollToSeasons(tester, find.text('Season 2'));

      await tester.longPress(find.text('Season 2'));
      await tester.pump();
      final completedAt =
          container.read(mediaProvider).seasonEndDates[show.prefixedId]?[2];
      expect(completedAt, isNotNull);

      // canLongPressComplete gates onLongPress to null once a season is
      // already complete -- verified via the underlying state staying
      // untouched (idempotent), not via toast presence/absence, which is
      // timing-fragile to assert against directly.
      await tester.longPress(find.text('Season 2'));
      await tester.pump();
      expect(
        container.read(mediaProvider).seasonEndDates[show.prefixedId]?[2],
        completedAt,
      );

      await tester.pump(const Duration(seconds: 4));
    });
  });
}
