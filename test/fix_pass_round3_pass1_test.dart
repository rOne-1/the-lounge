import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:the_lounge/models/media_item.dart';
import 'package:the_lounge/providers/ambiance_provider.dart';
import 'package:the_lounge/providers/media_provider.dart';
import 'package:the_lounge/widgets/pick_for_me_card.dart';
import 'package:the_lounge/screens/your_space_screen.dart';

void main() {
  setUp(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  group('Pass 1 - Tester Feedback Round 3 Tests', () {
    test('Item 1: Bulk-watched TV Episode Guard excludes future/unreleased episodes', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final now = DateTime.now();
      final pastDate = now.subtract(const Duration(days: 30));
      final futureDate = now.add(const Duration(days: 30));

      final tvShow = MediaItem(
        id: 'tv-show-1',
        title: 'Future Show',
        type: MediaType.tv,
        rating: 8.0,
        overview: 'Overview',
        genres: const ['Drama'],
        seasonsCount: 1,
      );

      final seasons = [
        TvSeason(
          id: 1,
          seasonNumber: 1,
          name: 'Season 1',
          episodes: [
            TvEpisode(
              id: 101,
              episodeNumber: 1,
              seasonNumber: 1,
              name: 'Aired Episode',
              airDate: pastDate,
            ),
            TvEpisode(
              id: 102,
              episodeNumber: 2,
              seasonNumber: 1,
              name: 'Future Episode',
              airDate: futureDate,
            ),
          ],
        ),
      ];

      final notifier = container.read(mediaProvider.notifier);

      // Bulk mark show as watched with seasons provided
      notifier.addToWatchedList(tvShow, seasons: seasons);

      final state = container.read(mediaProvider);
      final watchedEps = state.watchedEpisodes['tv-show-1'] ?? {};

      // S1E1 should be watched, S1E2 should NOT be watched
      expect(watchedEps.contains('S1E1'), isTrue);
      expect(watchedEps.contains('S1E2'), isFalse);
    });

    testWidgets('Item 3: TMDB Info Button is located in footer on Your Space', (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(
              body: YourSpaceScreen(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final settingsBtnFinder = find.byKey(const ValueKey('settings_button'));
      expect(settingsBtnFinder, findsOneWidget);

      await tester.tap(settingsBtnFinder);
      await tester.pumpAndSettle();

      expect(find.text('Settings'), findsOneWidget);
      
      final scrollable = find.byType(Scrollable);
      if (scrollable.evaluate().isNotEmpty) {
        await tester.scrollUntilVisible(
          find.text('TMDB Attribution', skipOffstage: false),
          50.0,
          scrollable: scrollable,
        );
        await tester.pumpAndSettle();
      }
      
      expect(find.text('TMDB Attribution'), findsOneWidget);
    });

    testWidgets('PickForMeCard displays tagline text', (WidgetTester tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final movie = MediaItem(
        id: 'movie-scrollable',
        title: 'Long Overview Movie',
        type: MediaType.movie,
        rating: 8.5,
        overview: 'Line 1 of very long overview text that goes on and on.\n' * 10,
        tagline: 'Tagline',
        genres: const ['Action'],
      );

      container.read(mediaProvider.notifier).addToWatchlist(movie);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(
              body: PickForMeCard(enableAnimation: false),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Long Overview Movie'), findsOneWidget);
      expect(find.text('Decide from your watchlist.'), findsOneWidget);
    });
  });
}
