import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:the_lounge/screens/your_space_screen.dart';
import 'package:the_lounge/screens/detail_screen.dart';
import 'package:the_lounge/screens/browse_screen.dart';
import 'package:the_lounge/widgets/pick_for_me_card.dart';
import 'package:the_lounge/widgets/segmented_toggle.dart';
import 'package:the_lounge/providers/media_provider.dart';
import 'package:the_lounge/providers/navigation_provider.dart';
import 'package:the_lounge/models/media_item.dart';
import 'package:the_lounge/repositories/mock_movie_repository.dart';

class _TestSyncMovieRepository extends MockMovieRepository {
  @override
  Future<TvSeason?> getTvSeasonDetails(String tvId, int seasonNumber) async => null;
}

void main() {
  setUp(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  group('Fix Pass Round 4 Pass 1 Tests', () {
    final testMovie = MediaItem(
      id: 'movie-100',
      title: 'Inception',
      type: MediaType.movie,
      rating: 8.8,
      overview: 'Dream within a dream overview.',
      tagline: 'Your mind is the scene of the crime.',
      genres: const ['Sci-Fi', 'Action'],
      director: 'Christopher Nolan',
    );

    final similarMovie = MediaItem(
      id: 'movie-101',
      title: 'Interstellar',
      type: MediaType.movie,
      rating: 8.6,
      overview: 'Space exploration overview.',
      posterUrl: 'https://image.tmdb.org/t/p/w500/interstellar.jpg',
      genres: const ['Sci-Fi'],
      director: 'Christopher Nolan',
    );

    testWidgets('Item 3 & 5: YourSpaceScreen includes Movies|TV toggle in header and relocated TMDB button in footer', (WidgetTester tester) async {
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

      expect(find.text('Your Space'), findsOneWidget);
      expect(find.byType(SegmentedMediaTypeToggle), findsOneWidget);
      expect(find.byKey(const ValueKey('app_info_button')), findsOneWidget);

      // Verify toggle switches media type
      expect(container.read(navigationProvider).activeMediaType, equals(MediaTypeToggle.movies));
      await tester.tap(find.text('TV'));
      await tester.pumpAndSettle();
      expect(container.read(navigationProvider).activeMediaType, equals(MediaTypeToggle.tv));
    });

    testWidgets('Item 4: PickForMeCard displays simplified tagline text "Decide from your watchlist."', (WidgetTester tester) async {
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
      expect(find.text('Dream within a dream overview.'), findsNothing);
    });

    testWidgets('Item 8: Tapping director credit sets person filter and navigates to search/browse', (WidgetTester tester) async {
      final container = ProviderContainer(
        overrides: [
          movieRepositoryProvider.overrideWithValue(_TestSyncMovieRepository()),
          mediaDetailsProvider('movie-100').overrideWith((ref) => Future.value(testMovie)),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: DetailScreen(id: 'movie-100'),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));
      final directorFinder = find.text('Christopher Nolan');
      await tester.scrollUntilVisible(directorFinder, 200, scrollable: find.byType(Scrollable).first);
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Director'), findsOneWidget);
      expect(directorFinder, findsOneWidget);

      await tester.tap(directorFinder, warnIfMissed: false);
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(BrowseScreen), findsOneWidget);
      final filterState = container.read(discoverFilterProvider);
      expect(filterState.personName, equals('Christopher Nolan'));
    });

    testWidgets('Item 9: Similar Titles rail displays recommendations and navigates when tapped', (WidgetTester tester) async {
      final container = ProviderContainer(
        overrides: [
          movieRepositoryProvider.overrideWithValue(_TestSyncMovieRepository()),
          mediaDetailsProvider('movie-100').overrideWith((ref) => Future.value(testMovie)),
          mediaDetailsProvider('movie-101').overrideWith((ref) => Future.value(similarMovie)),
          mediaDetailsProvider(similarMovie.prefixedId).overrideWith((ref) => Future.value(similarMovie)),
          similarMediaProvider(testMovie.prefixedId).overrideWith((ref) => Future.value([similarMovie])),
          similarMediaProvider(similarMovie.prefixedId).overrideWith((ref) => Future.value([])),
          mediaRecommendationsProvider(testMovie.prefixedId).overrideWith((ref) => Future.value([])),
          mediaRecommendationsProvider(similarMovie.prefixedId).overrideWith((ref) => Future.value([])),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: DetailScreen(id: 'movie-100'),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));
      final similarTitleFinder = find.text('Similar titles');
      await tester.scrollUntilVisible(similarTitleFinder, 200, scrollable: find.byType(Scrollable).first);
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));

      expect(similarTitleFinder, findsOneWidget);
      final target = find.text('Interstellar');
      await tester.ensureVisible(target);
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.tap(target);
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(DetailScreen, skipOffstage: false), findsNWidgets(2));
    });
  });
}
