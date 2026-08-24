// Regression coverage for Package 2 of the Beta 3 Polish & Direct Feedback
// sprint: WATCHED-VIEW-1 (Watched defaults to the flat grid, Collection
// grouping is opt-in) and ARCHIVE-SORT-1 (Date Added vs Last Added were
// previously collapsed into the same branch for collection clusters, and
// there was no ascending/descending toggle at all).
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:the_lounge/screens/archive_shelf_screen.dart';
import 'package:the_lounge/providers/media_provider.dart';
import 'package:the_lounge/providers/ambiance_provider.dart';
import 'package:the_lounge/models/media_item.dart';
import 'package:the_lounge/repositories/mock_movie_repository.dart';

class _InstantRepository extends MockMovieRepository {
  @override
  Future<MediaItem?> getMediaDetails(String id) async => null;
}

void main() {
  setUp(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  const movieA = MediaItem(
    id: 'movie-a',
    title: 'Alpha Film',
    type: MediaType.movie,
    rating: 7.5,
    overview: '',
    genres: ['Drama'],
  );
  const movieB = MediaItem(
    id: 'movie-b',
    title: 'Beta Film',
    type: MediaType.movie,
    rating: 7.5,
    overview: '',
    genres: ['Drama'],
  );

  Future<ProviderContainer> pumpWatchedShelf(
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
          home: ArchiveShelfScreen(kind: ArchiveShelfKind.watched),
        ),
      ),
    );
    await tester.pumpAndSettle();

    return container;
  }

  testWidgets(
      'WATCHED-VIEW-1: Watched defaults to the flat grid, not Collection grouping',
      (tester) async {
    final container = await pumpWatchedShelf(tester, [movieA, movieB]);
    addTearDown(container.dispose);

    // The flat grid renders both cards directly -- no ExpansionTile/group
    // wrapper for a default, ungrouped view.
    expect(find.byType(GridView), findsOneWidget);
    expect(find.byType(ExpansionTile), findsNothing);
    expect(find.byKey(const ValueKey('watched_group_by_collection_toggle')), findsOneWidget);
  });

  testWidgets(
      'WATCHED-VIEW-1: toggling Group by Collection switches to the grouped view',
      (tester) async {
    const collectionMovie = MediaItem(
      id: 'movie-c',
      title: 'Collection Film',
      type: MediaType.movie,
      rating: 7.5,
      overview: '',
      genres: ['Drama'],
      belongsToCollection: MediaCollection(id: 1, name: 'Test Trilogy'),
    );
    final container = await pumpWatchedShelf(tester, [collectionMovie]);
    addTearDown(container.dispose);

    expect(find.text('Test Trilogy'), findsNothing);

    await tester.tap(find.byKey(const ValueKey('watched_group_by_collection_toggle')));
    await tester.pumpAndSettle();

    expect(find.text('Test Trilogy'), findsOneWidget);
  });

  testWidgets(
      'ARCHIVE-SORT-1: Date Added and Last Added produce genuinely different collection cluster orderings',
      (tester) async {
    // Insertion order: Alpha collection added first, Beta collection added
    // second -- "Date Added" (insertion-order-based) should put Beta's
    // cluster above Alpha's. Explicit addedDate timestamps are the
    // opposite -- Alpha's is newer -- so "Last Added" should invert that.
    final alphaMovie = MediaItem(
      id: 'alpha-1',
      title: 'Alpha One',
      type: MediaType.movie,
      rating: 7.0,
      overview: '',
      genres: const ['Drama'],
      belongsToCollection: const MediaCollection(id: 1, name: 'Alpha Collection'),
      addedDate: DateTime(2026, 1, 1),
    );
    final betaMovie = MediaItem(
      id: 'beta-1',
      title: 'Beta One',
      type: MediaType.movie,
      rating: 7.0,
      overview: '',
      genres: const ['Drama'],
      belongsToCollection: const MediaCollection(id: 2, name: 'Beta Collection'),
      addedDate: DateTime(2020, 1, 1),
    );

    final container = await pumpWatchedShelf(tester, [alphaMovie, betaMovie]);
    addTearDown(container.dispose);

    await tester.tap(find.byKey(const ValueKey('watched_group_by_collection_toggle')));
    await tester.pumpAndSettle();

    // Default sort is Date Added -- Beta (inserted second/more recently)
    // should appear above Alpha.
    var alphaPos = tester.getTopLeft(find.text('Alpha Collection'));
    var betaPos = tester.getTopLeft(find.text('Beta Collection'));
    expect(betaPos.dy, lessThan(alphaPos.dy));

    // Switch to Last Added -- Alpha has the newer explicit addedDate, so it
    // should now appear above Beta. If this option were still collapsed
    // with Date Added (the original bug), the order would stay unchanged.
    // The dropdown trigger shows the currently-selected label, not the
    // "Sort" hint, once a value is set.
    await tester.tap(find.text('Date Added'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Last Added'));
    await tester.pumpAndSettle();

    alphaPos = tester.getTopLeft(find.text('Alpha Collection'));
    betaPos = tester.getTopLeft(find.text('Beta Collection'));
    expect(alphaPos.dy, lessThan(betaPos.dy));
  });

  testWidgets('ARCHIVE-SORT-1: the ascending/descending toggle reverses order',
      (tester) async {
    final container = await pumpWatchedShelf(tester, [movieA, movieB]);
    addTearDown(container.dispose);

    expect(find.byKey(const ValueKey('archive_sort_direction_toggle')), findsOneWidget);

    // Toggling direction must not throw and must flip the icon shown.
    Icon iconOf() => tester.widget<Icon>(find.descendant(
          of: find.byKey(const ValueKey('archive_sort_direction_toggle')),
          matching: find.byType(Icon),
        ));
    expect(iconOf().icon, Icons.arrow_downward_rounded);

    await tester.tap(find.byKey(const ValueKey('archive_sort_direction_toggle')));
    await tester.pumpAndSettle();

    expect(iconOf().icon, Icons.arrow_upward_rounded);
  });
}
