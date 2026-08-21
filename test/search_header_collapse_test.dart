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

    final slideWidget = tester.widget<AnimatedSlide>(find.byType(AnimatedSlide).first);
    expect(slideWidget.offset, Offset.zero);

    final opacityWidget = tester.widget<AnimatedOpacity>(find.byType(AnimatedOpacity).first);
    expect(opacityWidget.opacity, 1.0);
  });

  testWidgets(
      'SEARCH-1 & SEARCH-2: search header slides/fades on scroll without viewport height mutations',
      (tester) async {
    final container = await pumpSearch(tester);
    addTearDown(container.dispose);

    final gridFinder = find.byType(GridView).first;
    final initialGridSize = tester.getSize(gridFinder);

    // Initial state: visible
    expect(tester.widget<AnimatedSlide>(find.byType(AnimatedSlide).first).offset, Offset.zero);
    expect(tester.widget<AnimatedOpacity>(find.byType(AnimatedOpacity).first).opacity, 1.0);

    // Drag down to scroll content up (collapse chrome)
    await tester.drag(gridFinder, const Offset(0, -400));
    await tester.pumpAndSettle();

    // Chrome collapsed: slide offset -1.0, opacity 0.0
    expect(tester.widget<AnimatedSlide>(find.byType(AnimatedSlide).first).offset, const Offset(0, -1.0));
    expect(tester.widget<AnimatedOpacity>(find.byType(AnimatedOpacity).first).opacity, 0.0);

    // Viewport height remains unchanged (zero layout shifts / jitter)
    final collapsedGridSize = tester.getSize(gridFinder);
    expect(collapsedGridSize, equals(initialGridSize));

    // Drag up to scroll content down (reveal chrome)
    await tester.drag(gridFinder, const Offset(0, 400));
    await tester.pumpAndSettle();

    expect(tester.widget<AnimatedSlide>(find.byType(AnimatedSlide).first).offset, Offset.zero);
    expect(tester.widget<AnimatedOpacity>(find.byType(AnimatedOpacity).first).opacity, 1.0);

    // Viewport height remains unchanged
    final revealedGridSize = tester.getSize(gridFinder);
    expect(revealedGridSize, equals(initialGridSize));
  });

  testWidgets(
      'SEARCH: compact header layer hierarchy decouples BackdropFilter from animated opacity and ancestor compositing',
      (tester) async {
    final container = await pumpSearch(tester);
    addTearDown(container.dispose);

    // Verify BackdropFilter exists in the compact header
    final backdropFilterFinder = find.byType(BackdropFilter);
    expect(backdropFilterFinder, findsWidgets);

    // Verify BackdropFilter is NOT a descendant of any AnimatedOpacity (prevents blank render engine glitch)
    final backdropUnderOpacityFinder = find.ancestor(
      of: backdropFilterFinder,
      matching: find.byType(AnimatedOpacity),
    );
    expect(backdropUnderOpacityFinder, findsNothing);

    // Verify header AnimatedOpacity (250ms) is a descendant of BackdropFilter
    final headerAnimatedOpacityFinder = find.descendant(
      of: backdropFilterFinder.first,
      matching: find.byWidgetPredicate(
        (w) => w is AnimatedOpacity && w.duration == const Duration(milliseconds: 250),
      ),
    );
    expect(headerAnimatedOpacityFinder, findsOneWidget);

    // Verify RepaintBoundary is an ancestor of BackdropFilter
    final repaintBoundaryAncestorFinder = find.ancestor(
      of: backdropFilterFinder.first,
      matching: find.byType(RepaintBoundary),
    );
    expect(repaintBoundaryAncestorFinder, findsWidgets);
  });
}

