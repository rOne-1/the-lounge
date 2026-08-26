import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:the_lounge/widgets/continue_watching_hero_card.dart';
import 'package:the_lounge/screens/detail_screen.dart';
import 'package:the_lounge/providers/media_provider.dart';
import 'package:the_lounge/providers/ambiance_provider.dart';
import 'package:the_lounge/models/media_item.dart';
import 'package:the_lounge/repositories/mock_movie_repository.dart';

/// Returns canned per-show season data keyed by 'showId:seasonNumber' --
/// MockMovieRepository's own getTvSeasonDetails only knows its internal
/// _mockData catalog, so a custom test-fixture show needs this override.
class _TestRepository extends MockMovieRepository {
  final Map<String, TvSeason> seasonsByKey;
  _TestRepository(this.seasonsByKey);

  @override
  Future<TvSeason?> getTvSeasonDetails(String tvId, int seasonNumber) async {
    return seasonsByKey['$tvId:$seasonNumber'];
  }
}

void main() {
  setUp(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  const show = MediaItem(
    id: 'tv_continue_1',
    title: 'Continuing Show',
    type: MediaType.tv,
    rating: 8.0,
    overview: '',
    genres: [],
    seasonsCount: 1,
  );

  final season1 = TvSeason(
    id: 1,
    seasonNumber: 1,
    name: 'Season 1',
    episodes: [
      TvEpisode(
          id: 1,
          episodeNumber: 1,
          seasonNumber: 1,
          name: 'Pilot',
          airDate: DateTime(2020, 1, 1)),
      TvEpisode(
          id: 2,
          episodeNumber: 2,
          seasonNumber: 1,
          name: 'The Box',
          airDate: DateTime(2020, 1, 8)),
      TvEpisode(
          id: 3,
          episodeNumber: 3,
          seasonNumber: 1,
          name: 'Finale',
          airDate: DateTime(2020, 1, 15)),
    ],
  );

  Future<ProviderContainer> pumpHero(
    WidgetTester tester, {
    Map<String, TvSeason> seasons = const {},
  }) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        movieRepositoryProvider.overrideWithValue(_TestRepository(seasons)),
      ],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: Scaffold(body: ContinueWatchingHeroCard()),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return container;
  }

  group('CRAFT-HERO-1: ContinueWatchingHeroCard', () {
    testWidgets('collapses to nothing when no TV show is in Watching',
        (tester) async {
      await pumpHero(tester);

      expect(find.byType(ContinueWatchingHeroCard), findsOneWidget);
      expect(find.text('CONTINUE WATCHING'), findsNothing);
    });

    testWidgets(
        'renders title, next-episode label, and episode progress for an in-progress show',
        (tester) async {
      final container =
          await pumpHero(tester, seasons: {'${show.id}:1': season1});
      final notifier = container.read(mediaProvider.notifier);
      notifier.addToWatchingList(show);
      notifier.toggleEpisodeWatched(
        showId: show.id,
        seasonNumber: 1,
        episodeNumber: 1,
        showItem: show,
        seasons: [season1],
      );

      await container.rePump(tester);

      expect(find.text('CONTINUE WATCHING'), findsOneWidget);
      expect(find.text(show.title), findsOneWidget);
      expect(find.text('S1 · E2 "The Box"'), findsOneWidget);
      expect(find.text('1 of 3 episodes · 33%'), findsOneWidget);
      expect(find.text('Quick Watch'), findsOneWidget);
      // A single in-progress show gets no pagination dots.
      expect(find.byKey(ValueKey('continue_watching_dot_${show.id}')),
          findsNothing);
    });

    testWidgets(
        'tapping Quick Watch advances the next-unwatched-episode indicator',
        (tester) async {
      final container =
          await pumpHero(tester, seasons: {'${show.id}:1': season1});
      final notifier = container.read(mediaProvider.notifier);
      notifier.addToWatchingList(show);
      notifier.toggleEpisodeWatched(
        showId: show.id,
        seasonNumber: 1,
        episodeNumber: 1,
        showItem: show,
        seasons: [season1],
      );
      await container.rePump(tester);

      expect(find.text('S1 · E2 "The Box"'), findsOneWidget);

      await tester.tap(find.text('Quick Watch'));
      await tester.pumpAndSettle();

      expect(find.text('S1 · E3 "Finale"'), findsOneWidget);
      expect(find.text('2 of 3 episodes · 67%'), findsOneWidget);
    });

    testWidgets(
        'a show that finishes its last episode graduates out of Watching and the card collapses',
        (tester) async {
      // Marking the final released episode watched drives
      // _applyWatchedEpisodesCompletion to move the show from Watching to
      // Watched (the existing state-machine transition, not something this
      // widget invents) -- so it should vanish from Continue Watching
      // entirely rather than linger showing a stale "All episodes watched"
      // card, matching the AC's "hides when no TV shows in Watching" case.
      final container =
          await pumpHero(tester, seasons: {'${show.id}:1': season1});
      final notifier = container.read(mediaProvider.notifier);
      notifier.addToWatchingList(show);
      for (final ep in season1.episodes) {
        notifier.toggleEpisodeWatched(
          showId: show.id,
          seasonNumber: 1,
          episodeNumber: ep.episodeNumber,
          showItem: show,
          seasons: [season1],
        );
      }

      await container.rePump(tester);

      expect(find.text('CONTINUE WATCHING'), findsNothing);
      expect(find.text(show.title), findsNothing);
    });

    testWidgets(
        'multiple in-progress shows render pagination dots, tapping one switches the card',
        (tester) async {
      const secondShow = MediaItem(
        id: 'tv_continue_2',
        title: 'Second Show',
        type: MediaType.tv,
        rating: 7.0,
        overview: '',
        genres: [],
        seasonsCount: 1,
      );
      final season1b = TvSeason(
        id: 2,
        seasonNumber: 1,
        name: 'Season 1',
        episodes: [
          TvEpisode(
              id: 11,
              episodeNumber: 1,
              seasonNumber: 1,
              name: 'Start',
              airDate: DateTime(2019, 1, 1)),
        ],
      );
      final container = await pumpHero(tester, seasons: {
        '${show.id}:1': season1,
        '${secondShow.id}:1': season1b,
      });
      final notifier = container.read(mediaProvider.notifier);
      notifier.addToWatchingList(secondShow);
      notifier.addToWatchingList(show);

      await container.rePump(tester);

      // Two pagination dots for two in-progress shows, one per show id.
      expect(find.byKey(ValueKey('continue_watching_dot_${show.id}')),
          findsOneWidget);
      expect(find.byKey(ValueKey('continue_watching_dot_${secondShow.id}')),
          findsOneWidget);

      // Exactly one of the two titles shows initially -- which one is a
      // startDates-timestamp tiebreak, not something this test pins down.
      final showVisible = find.text(show.title).evaluate().isNotEmpty;
      final secondVisible = find.text(secondShow.title).evaluate().isNotEmpty;
      expect(showVisible ^ secondVisible, isTrue);

      // Tapping the *other* show's dot switches the card to it.
      final otherKey = showVisible
          ? ValueKey('continue_watching_dot_${secondShow.id}')
          : ValueKey('continue_watching_dot_${show.id}');
      await tester.tap(find.byKey(otherKey));
      await tester.pumpAndSettle();

      expect(find.text(show.title).evaluate().isNotEmpty, !showVisible);
      expect(find.text(secondShow.title).evaluate().isNotEmpty, !secondVisible);
    });

    testWidgets(
        'ITEM-1: swiping the card horizontally pages between multiple in-progress shows',
        (tester) async {
      const secondShow = MediaItem(
        id: 'tv_continue_2',
        title: 'Second Show',
        type: MediaType.tv,
        rating: 7.0,
        overview: '',
        genres: [],
        seasonsCount: 1,
      );
      final season1b = TvSeason(
        id: 2,
        seasonNumber: 1,
        name: 'Season 1',
        episodes: [
          TvEpisode(
              id: 11,
              episodeNumber: 1,
              seasonNumber: 1,
              name: 'Start',
              airDate: DateTime(2019, 1, 1)),
        ],
      );
      final container = await pumpHero(tester, seasons: {
        '${show.id}:1': season1,
        '${secondShow.id}:1': season1b,
      });
      final notifier = container.read(mediaProvider.notifier);
      notifier.addToWatchingList(secondShow);
      notifier.addToWatchingList(show);
      await container.rePump(tester);

      final showVisible = find.text(show.title).evaluate().isNotEmpty;

      // Dragging left pages forward (to index 1). If the card already
      // started on the last show, this drag hits the clamp and nothing
      // changes -- then a rightward drag must page it back to index 0
      // instead, proving the gesture works in both directions regardless
      // of which show the startDates tiebreak happened to surface first.
      await tester.drag(
          find.byType(ContinueWatchingHeroCard), const Offset(-100, 0));
      await tester.pumpAndSettle();

      final afterLeftShowVisible = find.text(show.title).evaluate().isNotEmpty;
      if (afterLeftShowVisible == showVisible) {
        await tester.drag(
            find.byType(ContinueWatchingHeroCard), const Offset(100, 0));
        await tester.pumpAndSettle();
        expect(find.text(show.title).evaluate().isNotEmpty, !showVisible);
      } else {
        expect(afterLeftShowVisible, !showVisible);
      }
    });

    testWidgets(
        'tapping the card body (not Quick Watch) navigates to DetailScreen',
        (tester) async {
      final container =
          await pumpHero(tester, seasons: {'${show.id}:1': season1});
      final notifier = container.read(mediaProvider.notifier);
      notifier.addToWatchingList(show);
      await container.rePump(tester);

      await tester.tap(find.text(show.title));
      await tester.pumpAndSettle();

      expect(find.byType(DetailScreen), findsOneWidget);
    });
  });
}

extension on ProviderContainer {
  /// Re-pumps the already-built widget tree so a provider mutation made
  /// directly on the notifier (no intervening user gesture) is reflected,
  /// matching the pump-after-mutate pattern already used across this
  /// project's other provider-driven widget tests.
  Future<void> rePump(WidgetTester tester) async {
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: this,
        child: const MaterialApp(
          home: Scaffold(body: ContinueWatchingHeroCard()),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }
}
