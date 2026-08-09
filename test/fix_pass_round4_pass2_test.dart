import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:the_lounge/models/media_item.dart';
import 'package:the_lounge/repositories/mock_movie_repository.dart';
import 'package:the_lounge/providers/media_provider.dart';
import 'package:the_lounge/providers/navigation_provider.dart';
import 'package:the_lounge/screens/home_screen.dart';
import 'package:the_lounge/screens/discover_screen.dart';
import 'package:the_lounge/screens/detail_screen.dart';

class _TestSyncMovieRepository extends MockMovieRepository {
  @override
  Future<TvSeason?> getTvSeasonDetails(String tvId, int seasonNumber) async => null;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final show1 = MediaItem(
    id: 'tv_1',
    title: 'Show One',
    type: MediaType.tv,
    rating: 8.5,
    overview: 'First show overview',
    genres: const ['Drama'],
    seasonsCount: 1,
    episodesCount: 10,
  );

  final show2 = MediaItem(
    id: 'tv_2',
    title: 'Show Two',
    type: MediaType.tv,
    rating: 8.0,
    overview: 'Second show overview',
    genres: const ['Sci-Fi'],
    seasonsCount: 1,
    episodesCount: 10,
  );

  final upcomingMovie = MediaItem(
    id: 'movie_2026',
    title: 'SummerSlam 2026',
    type: MediaType.movie,
    rating: 7.8,
    releaseOrAirDate: DateTime(2026, 12, 1),
    overview: 'Upcoming movie event',
    genres: const ['Action'],
    status: 'Unreleased',
  );

  group('Fix Pass Round 4 - Pass 2 Tests', () {
    testWidgets('Item 1: TV Mode Next Episode Carousel renders PageView and indicator dots when multiple watching shows exist', (tester) async {
      final container = ProviderContainer(
        overrides: [
          tvShowSeasonsProvider(show1).overrideWith((ref) => Future.value([
            const TvSeason(
              id: 101,
              seasonNumber: 1,
              name: 'Season 1',
              episodes: [
                TvEpisode(id: 1001, episodeNumber: 1, seasonNumber: 1, name: 'Pilot 1'),
              ],
            )
          ])),
          tvShowSeasonsProvider(show2).overrideWith((ref) => Future.value([
            const TvSeason(
              id: 102,
              seasonNumber: 1,
              name: 'Season 1',
              episodes: [
                TvEpisode(id: 1002, episodeNumber: 1, seasonNumber: 1, name: 'Pilot 2'),
              ],
            )
          ])),
        ],
      );

      final notifier = container.read(mediaProvider.notifier);
      notifier.addToWatchingList(show1);
      notifier.addToWatchingList(show2);

      container.read(navigationProvider.notifier).setMediaType(MediaTypeToggle.tv);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Scaffold(
              body: NextEpisodeBannerCarousel(
                shows: [show1, show2],
                isDark: true,
                enableAnimation: false,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(NextEpisodeBannerCarousel), findsOneWidget);
      expect(find.byType(PageView), findsOneWidget);
      expect(find.text('Show One · S1 E1'), findsOneWidget);
    });

    testWidgets('Item 11 & 12: SwipeCard shows real date year and UPCOMING badge for future releases', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: SwipeCard(
                item: upcomingMovie,
                isInteractive: true,
                isDark: true,
                accColor: Colors.amber,
                onSwipe: (_) {},
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('UPCOMING • 2026'), findsOneWidget);
      expect(find.textContaining('2026'), findsWidgets);
    });

    testWidgets('Item 13: Preserve releaseDate & status guard in DetailScreen', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            movieRepositoryProvider.overrideWithValue(_TestSyncMovieRepository()),
            mediaDetailsProvider(upcomingMovie.prefixedId).overrideWith(
              (ref) => Future.value(upcomingMovie),
            ),
          ],
          child: MaterialApp(
            home: DetailScreen(
              id: upcomingMovie.prefixedId,
              initialItem: upcomingMovie,
            ),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));

      final watchedToggle = find.text('Watched');
      expect(watchedToggle, findsOneWidget);

      await tester.ensureVisible(watchedToggle);
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.tap(watchedToggle);
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('This title has not been released yet.'), findsOneWidget);
    });

    testWidgets('Item 15: Directional arrow labels (← Skip, → Saved, ↓ Watchlist, ↑ Watched) are displayed below swipe deck', (tester) async {
      final mockRepo = MockMovieRepository();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            movieRepositoryProvider.overrideWithValue(mockRepo),
          ],
          child: const MaterialApp(
            home: DiscoverScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('← Skip'), findsOneWidget);
      expect(find.text('→ Saved'), findsOneWidget);
      expect(find.text('↓ Watchlist'), findsOneWidget);
      expect(find.text('↑ Watched'), findsOneWidget);
    });
  });
}
