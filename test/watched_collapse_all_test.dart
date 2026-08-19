// Regression coverage for E7: a single control to collapse/expand every
// collection group in the Watched pile at once, instead of tapping each
// ExpansionTile individually.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:the_lounge/screens/pile_screen.dart';
import 'package:the_lounge/providers/media_provider.dart';
import 'package:the_lounge/providers/ambiance_provider.dart';
import 'package:the_lounge/models/media_item.dart';
import 'package:the_lounge/repositories/mock_movie_repository.dart';

/// standaloneMovie has no belongsToCollection, so addToWatchedList fires
/// _enrichWatchedItemCollection's fire-and-forget getMediaDetails call --
/// the default MockMovieRepository simulates 500ms of latency there, which
/// can leave a pending timer past test teardown. Mirrors the
/// _InstantEmptyRepository pattern used elsewhere (e.g.
/// settings_screen_test.dart, rate_titles_screen_test.dart).
class _InstantRepository extends MockMovieRepository {
  @override
  Future<MediaItem?> getMediaDetails(String id) async => null;
}

void main() {
  setUp(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  const collectionMovieA = MediaItem(
    id: 'movie-1',
    title: 'Trilogy Part One',
    type: MediaType.movie,
    rating: 8.0,
    overview: '',
    genres: ['Action'],
    belongsToCollection: MediaCollection(id: 1, name: 'Test Trilogy'),
  );

  const collectionMovieB = MediaItem(
    id: 'movie-2',
    title: 'Trilogy Part Two',
    type: MediaType.movie,
    rating: 8.0,
    overview: '',
    genres: ['Action'],
    belongsToCollection: MediaCollection(id: 1, name: 'Test Trilogy'),
  );

  const standaloneMovie = MediaItem(
    id: 'movie-3',
    title: 'Standalone Film',
    type: MediaType.movie,
    rating: 7.5,
    overview: '',
    genres: ['Drama'],
  );

  Future<ProviderContainer> pumpWatchedPile(
    WidgetTester tester,
    List<MediaItem> items,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [
        movieRepositoryProvider.overrideWithValue(_InstantRepository()),
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
    );
    for (final item in items) {
      container.read(mediaProvider.notifier).addToWatchedList(item);
    }

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: PileScreen(kind: PileKind.watched),
        ),
      ),
    );
    await tester.pumpAndSettle();

    return container;
  }

  testWidgets('Collapse All / Expand All toggles every Watched group at once',
      (tester) async {
    final container = await pumpWatchedPile(
      tester,
      [collectionMovieA, collectionMovieB, standaloneMovie],
    );
    addTearDown(container.dispose);

    // Both groups start expanded -- their sub-grids are mounted.
    expect(find.byKey(const PageStorageKey<String>('watched_grid_Test Trilogy')),
        findsOneWidget);
    expect(find.byKey(const PageStorageKey<String>('watched_grid_standalone')),
        findsOneWidget);
    expect(find.text('Collapse All'), findsOneWidget);

    await tester.tap(find.text('Collapse All'));
    await tester.pumpAndSettle();

    expect(find.byKey(const PageStorageKey<String>('watched_grid_Test Trilogy')),
        findsNothing);
    expect(find.byKey(const PageStorageKey<String>('watched_grid_standalone')),
        findsNothing);
    expect(find.text('Expand All'), findsOneWidget);

    await tester.tap(find.text('Expand All'));
    await tester.pumpAndSettle();

    expect(find.byKey(const PageStorageKey<String>('watched_grid_Test Trilogy')),
        findsOneWidget);
    expect(find.byKey(const PageStorageKey<String>('watched_grid_standalone')),
        findsOneWidget);
    expect(find.text('Collapse All'), findsOneWidget);
  });

  testWidgets('Collapse All button is hidden when there is only one group',
      (tester) async {
    final container = await pumpWatchedPile(tester, [standaloneMovie]);
    addTearDown(container.dispose);

    expect(find.text('Collapse All'), findsNothing);
    expect(find.text('Expand All'), findsNothing);
  });

  testWidgets('SORT-2: collections are sorted by their most recent item addedDate',
      (tester) async {
    final olderCollectionMovie = MediaItem(
      id: 'm-old',
      title: 'Old Matrix',
      type: MediaType.movie,
      rating: 8.5,
      overview: '',
      belongsToCollection: const MediaCollection(id: 2, name: 'Matrix Series'),
      addedDate: DateTime(2024, 1, 1),
    );

    final newerCollectionMovie = MediaItem(
      id: 'm-new',
      title: 'New Avatar',
      type: MediaType.movie,
      rating: 8.0,
      overview: '',
      belongsToCollection: const MediaCollection(id: 3, name: 'Avatar Saga'),
      addedDate: DateTime(2026, 7, 1),
    );

    final container = await pumpWatchedPile(
      tester,
      [olderCollectionMovie, newerCollectionMovie],
    );
    addTearDown(container.dispose);

    // Both collections render
    expect(find.text('Avatar Saga'), findsOneWidget);
    expect(find.text('Matrix Series'), findsOneWidget);

    final avatarPos = tester.getTopLeft(find.text('Avatar Saga'));
    final matrixPos = tester.getTopLeft(find.text('Matrix Series'));

    // Avatar Saga (added in 2026) appears above Matrix Series (added in 2024)
    expect(avatarPos.dy, lessThan(matrixPos.dy));
  });
}
