// Regression coverage for E1/TF-9: SearchScreen's compact-layout header
// (title/Filters row + search bar + filter-chip bar) should be visible on a
// fresh load, collapse out of view once the results grid scrolls down past
// the ScrollChromeTracker threshold, and come back on scrolling up.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:the_lounge/models/discover_filter_params.dart';
import 'package:the_lounge/models/media_item.dart';
import 'package:the_lounge/providers/repository_provider.dart';
import 'package:the_lounge/repositories/mock_movie_repository.dart';
import 'package:the_lounge/screens/search_screen.dart';

class _TestRepository extends MockMovieRepository {
  final Map<String, MediaItem> items;

  _TestRepository(this.items);

  @override
  Future<List<MediaItem>> discoverMedia({
    required bool isMovies,
    required DiscoverFilterParams params,
    int page = 1,
  }) async =>
      items.values.toList();
}

void main() {
  final searchBarFinder = find.text('Search across the catalog');

  Future<ProviderContainer> pumpSearch(WidgetTester tester) async {
    // SearchScreen's compact layout applies below its own 800px breakpoint
    // (isLarge = width > 800); the default test surface (800x600) already
    // sits right at that line, so pin it explicitly to a real phone width
    // rather than relying on the boundary value.
    tester.view.physicalSize = const Size(412, 915);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final items = <String, MediaItem>{
      for (var i = 0; i < 40; i++)
        'movie-$i': MediaItem(
          id: 'movie-$i',
          title: 'Discover Title $i',
          type: MediaType.movie,
          rating: 7.0,
          overview: '',
          genres: const ['Drama'],
        ),
    };

    final container = ProviderContainer(
      overrides: [
        movieRepositoryProvider.overrideWithValue(_TestRepository(items)),
      ],
    );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: SearchScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return container;
  }

  testWidgets('search header is visible on a fresh load', (tester) async {
    final container = await pumpSearch(tester);
    addTearDown(container.dispose);

    expect(searchBarFinder, findsOneWidget);
  });

  testWidgets('search header collapses on scroll-down and returns on scroll-up',
      (tester) async {
    final container = await pumpSearch(tester);
    addTearDown(container.dispose);

    expect(searchBarFinder, findsOneWidget);

    final gridFinder = find.byType(GridView).first;
    await tester.drag(gridFinder, const Offset(0, -400));
    await tester.pumpAndSettle();

    expect(searchBarFinder, findsNothing);

    await tester.drag(gridFinder, const Offset(0, 400));
    await tester.pumpAndSettle();

    expect(searchBarFinder, findsOneWidget);
  });
}
