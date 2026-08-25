import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:the_lounge/screens/rewatch_vault_screen.dart';
import 'package:the_lounge/screens/detail_screen.dart';
import 'package:the_lounge/providers/media_provider.dart';
import 'package:the_lounge/providers/ambiance_provider.dart';
import 'package:the_lounge/models/media_item.dart';
import 'package:the_lounge/repositories/mock_movie_repository.dart';

class _TestRepository extends MockMovieRepository {
  final Map<String, MediaItem> items;
  _TestRepository(this.items);

  @override
  Future<MediaItem?> getMediaDetails(String id, {String? region}) async => items[id];

  @override
  Future<TvSeason?> getTvSeasonDetails(String tvId, int seasonNumber) async => null;
}

void main() {
  setUp(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  final rewatchedMovie = MediaItem(
    id: 'movie-rewatch-1',
    title: 'Rewatched Movie',
    type: MediaType.movie,
    rating: 8.0,
    overview: 'A movie worth watching again.',
    genres: const ['Drama'],
  );

  final neverRewatchedMovie = MediaItem(
    id: 'movie-once-1',
    title: 'Watched Once',
    type: MediaType.movie,
    rating: 7.0,
    overview: 'Only watched once.',
    genres: const ['Comedy'],
  );

  Future<ProviderContainer> pumpVault(WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        movieRepositoryProvider.overrideWithValue(
          _TestRepository({rewatchedMovie.id: rewatchedMovie, neverRewatchedMovie.id: neverRewatchedMovie}),
        ),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: RewatchVaultScreen()),
      ),
    );
    await tester.pumpAndSettle();
    return container;
  }

  group('PERS-SPACE-1: RewatchVaultScreen', () {
    testWidgets('shows the empty state with no rewatches logged', (tester) async {
      await pumpVault(tester);
      expect(find.text('No rewatches yet'), findsOneWidget);
    });

    testWidgets('a title with only a first-watch record does not appear', (tester) async {
      final container = await pumpVault(tester);
      container.read(mediaProvider.notifier).addWatchRecord(
            neverRewatchedMovie.id,
            WatchRecord(rating: PersonalRating.liked, isFirstWatch: true),
          );
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: RewatchVaultScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('No rewatches yet'), findsOneWidget);
      expect(find.text(neverRewatchedMovie.title), findsNothing);
    });

    testWidgets('a title with a rewatch record appears with its rewatch count', (tester) async {
      final container = await pumpVault(tester);
      container.read(mediaProvider.notifier).addWatchRecord(
            rewatchedMovie.id,
            WatchRecord(
              date: DateTime(2025, 1, 1),
              rating: PersonalRating.loved,
              isFirstWatch: true,
            ),
          );
      container.read(mediaProvider.notifier).addWatchRecord(
            rewatchedMovie.id,
            WatchRecord(
              date: DateTime(2025, 6, 1),
              rating: PersonalRating.loved,
              isFirstWatch: false,
            ),
          );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: RewatchVaultScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(rewatchedMovie.title), findsOneWidget);
      expect(find.textContaining('Rewatched 1 time'), findsOneWidget);
    });

    testWidgets('only shows rewatches for titles matching the active Movies/TV toggle',
        (tester) async {
      final rewatchedShow = MediaItem(
        id: 'tv-rewatch-1',
        title: 'Rewatched Show',
        type: MediaType.tv,
        rating: 8.5,
        overview: 'A show worth watching again.',
        genres: const ['Sci-Fi'],
      );
      final container = await pumpVault(tester);
      // Known synchronously (in a status pile) so the type filter can apply
      // without waiting on the async mediaDetailsProvider fallback.
      container.read(mediaProvider.notifier).addToWatchedList(rewatchedMovie);
      container.read(mediaProvider.notifier).addToWatchedList(rewatchedShow);
      container.read(mediaProvider.notifier).addWatchRecord(
            rewatchedMovie.id,
            WatchRecord(isFirstWatch: true),
          );
      container.read(mediaProvider.notifier).addWatchRecord(
            rewatchedMovie.id,
            WatchRecord(isFirstWatch: false),
          );
      container.read(mediaProvider.notifier).addWatchRecord(
            rewatchedShow.id,
            WatchRecord(isFirstWatch: true),
          );
      container.read(mediaProvider.notifier).addWatchRecord(
            rewatchedShow.id,
            WatchRecord(isFirstWatch: false),
          );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: RewatchVaultScreen()),
        ),
      );
      await tester.pumpAndSettle();

      // Default activeMediaType is movies -- no explicit override needed.
      expect(find.text(rewatchedMovie.title), findsOneWidget);
      expect(find.text(rewatchedShow.title), findsNothing);
    });

    testWidgets('tapping a row navigates to DetailScreen', (tester) async {
      final container = await pumpVault(tester);
      container.read(mediaProvider.notifier).addWatchRecord(
            rewatchedMovie.id,
            WatchRecord(isFirstWatch: true),
          );
      container.read(mediaProvider.notifier).addWatchRecord(
            rewatchedMovie.id,
            WatchRecord(isFirstWatch: false),
          );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: RewatchVaultScreen()),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text(rewatchedMovie.title));
      await tester.pumpAndSettle();

      expect(find.byType(DetailScreen), findsOneWidget);
    });
  });
}
