// Regression coverage for E7: a single control to collapse/expand every
// collection group in the Watched tab at once, instead of tapping each
// ExpansionTile individually.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:the_lounge/screens/your_space_screen.dart';
import 'package:the_lounge/providers/media_provider.dart';
import 'package:the_lounge/models/media_item.dart';
import 'package:the_lounge/repositories/mock_movie_repository.dart';

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

  Future<ProviderContainer> pumpWatchedTab(WidgetTester tester) async {
    final container = ProviderContainer(
      overrides: [
        movieRepositoryProvider.overrideWithValue(MockMovieRepository()),
      ],
    );
    container.read(mediaProvider.notifier).addToWatchedList(collectionMovieA);
    container.read(mediaProvider.notifier).addToWatchedList(collectionMovieB);
    container.read(mediaProvider.notifier).addToWatchedList(standaloneMovie);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: Scaffold(body: YourSpaceScreen()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Watched'));
    await tester.pumpAndSettle();

    return container;
  }

  testWidgets('Collapse All / Expand All toggles every Watched group at once',
      (tester) async {
    final container = await pumpWatchedTab(tester);
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
    final container = ProviderContainer(
      overrides: [
        movieRepositoryProvider.overrideWithValue(MockMovieRepository()),
      ],
    );
    addTearDown(container.dispose);
    container.read(mediaProvider.notifier).addToWatchedList(standaloneMovie);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: Scaffold(body: YourSpaceScreen()),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Watched'));
    await tester.pumpAndSettle();

    expect(find.text('Collapse All'), findsNothing);
    expect(find.text('Expand All'), findsNothing);
  });
}
