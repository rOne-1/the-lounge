import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:the_lounge/models/media_item.dart';
import 'package:the_lounge/providers/media_provider.dart';
import 'package:the_lounge/screens/detail_screen.dart';
import 'package:the_lounge/screens/your_space_screen.dart';
import 'package:the_lounge/widgets/pick_for_me_card.dart';
import 'package:the_lounge/widgets/segmented_toggle.dart';
import 'package:the_lounge/repositories/mock_movie_repository.dart';

class _TestSyncMovieRepository extends MockMovieRepository {
  final List<TvSeason> seasons;
  _TestSyncMovieRepository({this.seasons = const []});

  @override
  Future<TvSeason?> getTvSeasonDetails(String tvId, int seasonNumber) async {
    return seasons.firstOrNull;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final testMovie = const MediaItem(
    id: 'movie-100',
    title: 'Inception',
    type: MediaType.movie,
    rating: 8.8,
    overview: 'Dream within a dream overview.',
    tagline: 'Your mind is the scene of the crime.',
    genres: ['Action', 'Sci-Fi'],
  );

  final testShow = const MediaItem(
    id: 'tv-200',
    title: 'Breaking Bad',
    type: MediaType.tv,
    rating: 9.5,
    overview: 'Chemistry teacher turns bad.',
    genres: ['Drama', 'Crime'],
    seasonsCount: 1,
    episodesCount: 7,
  );

  final testSeason = TvSeason(
    id: 1,
    seasonNumber: 1,
    name: 'Season 1',
    overview: 'Season 1 Overview',
    episodes: [
      TvEpisode(
        id: 101,
        episodeNumber: 1,
        seasonNumber: 1,
        name: 'Pilot',
        airDate: DateTime(2008, 1, 20),
      ),
    ],
  );

  final recItem = const MediaItem(
    id: 'movie-300',
    title: 'Interstellar',
    type: MediaType.movie,
    rating: 8.6,
    overview: 'Space journey.',
    genres: ['Sci-Fi'],
  );

  final simItem = const MediaItem(
    id: 'movie-400',
    title: 'Tenet',
    type: MediaType.movie,
    rating: 7.5,
    overview: 'Time inversion.',
    genres: ['Action'],
  );

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Fix Pass - Tester Feedback Round 5 (Items 1 - 4)', () {
    testWidgets('Item 1: Priority Swap for Similar / Recommendations in DetailScreen',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1000, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final container = ProviderContainer(
        overrides: [
          movieRepositoryProvider.overrideWithValue(_TestSyncMovieRepository()),
          mediaDetailsProvider('movie/movie-100')
              .overrideWith((ref) => Future.value(testMovie)),
          mediaDetailsProvider('movie_movie-100')
              .overrideWith((ref) => Future.value(testMovie)),
          mediaRecommendationsProvider('movie/movie-100')
              .overrideWith((ref) => Future.value([recItem])),
          mediaRecommendationsProvider('movie_movie-100')
              .overrideWith((ref) => Future.value([recItem])),
          similarMediaProvider('movie/movie-100')
              .overrideWith((ref) => Future.value([simItem])),
          similarMediaProvider('movie_movie-100')
              .overrideWith((ref) => Future.value([simItem])),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: DetailScreen(id: 'movie/movie-100'),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Interstellar'), findsAtLeastNWidgets(1));
      expect(find.text('Tenet'), findsNothing);
    });

    testWidgets('Item 2: Pass Seasons into toggleWatched on DetailScreen',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1000, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final container = ProviderContainer(
        overrides: [
          movieRepositoryProvider.overrideWithValue(_TestSyncMovieRepository(seasons: [testSeason])),
          mediaDetailsProvider('tv/tv-200')
              .overrideWith((ref) => Future.value(testShow)),
          mediaDetailsProvider('tv_tv-200')
              .overrideWith((ref) => Future.value(testShow)),
          tvShowSeasonsProvider(testShow)
              .overrideWith((ref) => Future.value([testSeason])),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: DetailScreen(id: 'tv/tv-200'),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));

      final watchedBtn = find.widgetWithText(InkWell, 'Watched');
      if (watchedBtn.evaluate().isNotEmpty) {
        await tester.tap(watchedBtn);
      } else {
        final textWatched = find.text('Watched');
        await tester.tap(textWatched);
      }
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));

      final mediaState = container.read(mediaProvider);
      expect(mediaState.watchedList.containsKey('tv-200'), isTrue);
    });

    testWidgets('Item 3: Cleanup Pick For Me Card Tagline',
        (WidgetTester tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(mediaProvider.notifier).addToWatchlist(testMovie);

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

      expect(find.text('Inception'), findsOneWidget);
      expect(find.text('Decide from your watchlist.'), findsOneWidget);
      expect(find.text('"Your mind is the scene of the crime."'), findsNothing);
      expect(find.text('Action · Sci-Fi'), findsNothing);
    });

    testWidgets('Item 4: Info Button beside SegmentedMediaTypeToggle in YourSpaceScreen',
        (WidgetTester tester) async {
      final container = ProviderContainer();
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

      final infoBtn = find.byKey(const ValueKey('app_info_button'));
      final toggle = find.byType(SegmentedMediaTypeToggle);

      expect(infoBtn, findsOneWidget);
      expect(toggle, findsOneWidget);

      final infoRow = find.ancestor(of: infoBtn, matching: find.byType(Row)).first;
      expect(infoRow, findsOneWidget);
    });
  });
}
