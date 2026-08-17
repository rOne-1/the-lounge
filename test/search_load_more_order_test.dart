// Regression coverage: dev-reported bug -- Search's "Load More" appended
// new pages to _accumulatedItems correctly, but _applyClientFilters's
// default-sort branch re-sorted the WHOLE accumulated list by voteCount on
// every rebuild (since it re-ran on every build, not just once per fetch),
// so newly-loaded titles got interleaved throughout the existing grid
// instead of appearing at the end. 'popularity.desc' is the default (no
// sort explicitly chosen) and must preserve arrival order -- TMDB's own
// discover response is already popularity-ordered server-side.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:the_lounge/models/discover_filter_params.dart';
import 'package:the_lounge/models/media_item.dart';
import 'package:the_lounge/providers/repository_provider.dart';
import 'package:the_lounge/repositories/mock_movie_repository.dart';
import 'package:the_lounge/screens/search_screen.dart';
import 'package:the_lounge/widgets/media_image.dart';

class _PagedRepository extends MockMovieRepository {
  @override
  Future<List<MediaItem>> discoverMedia({
    required bool isMovies,
    required DiscoverFilterParams params,
    int page = 1,
  }) async {
    if (page == 1) {
      // Deliberately LOW vote counts on page 1 -- if the old voteCount-based
      // default sort were still active, these would sink below page 2's
      // high-vote-count item once it's appended.
      return [
        MediaItem(
            id: 'p1-a',
            title: 'Page1 A',
            type: MediaType.movie,
            rating: 7.0,
            voteCount: 10,
            overview: '',
            genres: const []),
        MediaItem(
            id: 'p1-b',
            title: 'Page1 B',
            type: MediaType.movie,
            rating: 7.0,
            voteCount: 5,
            overview: '',
            genres: const []),
      ];
    }
    // Page 2's item has a much HIGHER vote count than either page-1 item --
    // under the old bug this would jump to the front of the grid on Load
    // More instead of appending after Page1 B.
    return [
      MediaItem(
          id: 'p2-a',
          title: 'Page2 A',
          type: MediaType.movie,
          rating: 8.0,
          voteCount: 9999,
          overview: '',
          genres: const []),
    ];
  }
}

void main() {
  testWidgets(
      'Load More appends new titles after existing ones instead of '
      're-sorting the whole grid by vote count', (tester) async {
    final container = ProviderContainer(
      overrides: [
        movieRepositoryProvider.overrideWithValue(_PagedRepository()),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: SearchScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    List<String> currentOrder() => tester
        .widgetList<MediaImage>(find.byType(MediaImage))
        .map((w) => w.item!.id)
        .toList();

    expect(currentOrder(), ['p1-a', 'p1-b']);

    await tester.tap(find.text('Load More'));
    await tester.pumpAndSettle();

    expect(currentOrder(), ['p1-a', 'p1-b', 'p2-a']);
  });
}
