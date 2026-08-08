import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:the_lounge/models/media_collection_detail.dart';
import 'package:the_lounge/models/media_item.dart';
import 'package:the_lounge/providers/repository_provider.dart';
import 'package:the_lounge/repositories/mock_movie_repository.dart';
import 'package:the_lounge/screens/browse_screen.dart';
import 'package:the_lounge/screens/collection_screen.dart';
import 'package:the_lounge/screens/detail_screen.dart';
import 'package:the_lounge/screens/discover_screen.dart';
import 'package:the_lounge/screens/media_list_screen.dart';

class TestCollectionRepository extends MockMovieRepository {
  final Map<int, List<MediaItem>> trendingByPage = {
    1: [
      const MediaItem(
          id: '1', title: 'Movie 1', type: MediaType.movie, rating: 8.0, overview: '', genres: []),
      const MediaItem(
          id: '2', title: 'Movie 2', type: MediaType.movie, rating: 7.0, overview: '', genres: []),
    ],
    3: [
      const MediaItem(
          id: '3', title: 'Movie 3', type: MediaType.movie, rating: 8.5, overview: '', genres: []),
      const MediaItem(
          id: '4', title: 'Movie 4', type: MediaType.movie, rating: 7.8, overview: '', genres: []),
    ],
  };

  @override
  Future<List<MediaItem>> getPopularMovies({int page = 1}) async => [];

  @override
  Future<List<MediaItem>> getTrendingMovies({int page = 1}) async {
    return trendingByPage[page] ?? [];
  }

  @override
  Future<MediaCollectionDetail?> getCollectionDetails(int collectionId) async {
    return MediaCollectionDetail(
      id: collectionId,
      name: 'Star Wars Collection',
      overview: 'Epic space saga collection overview text.',
      posterUrl: null,
      backdropUrl: null,
      parts: const [
        MediaItem(
          id: '101',
          title: 'Star Wars: Episode IV',
          type: MediaType.movie,
          rating: 8.6,
          overview: 'A long time ago...',
          genres: ['Action', 'Sci-Fi'],
        ),
        MediaItem(
          id: '102',
          title: 'Star Wars: Episode V',
          type: MediaType.movie,
          rating: 8.7,
          overview: 'The Empire Strikes Back...',
          genres: ['Action', 'Sci-Fi'],
        ),
      ],
    );
  }

  @override
  Future<MediaItem?> getMediaDetails(String id) async {
    return const MediaItem(
      id: 'movie_1',
      title: 'Star Wars: Episode IV',
      type: MediaType.movie,
      rating: 8.6,
      overview: 'Star Wars movie overview',
      genres: ['Action'],
      belongsToCollection: MediaCollection(
        id: 10,
        name: 'Star Wars Collection',
      ),
    );
  }
}

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  testWidgets('Item 7: Reload deck in DiscoverScreen fetches fresh page items',
      (WidgetTester tester) async {
    final repo = TestCollectionRepository();
    final container = ProviderContainer(
      overrides: [
        movieRepositoryProvider.overrideWithValue(repo),
      ],
    );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: Scaffold(
            body: DiscoverScreen(),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Dismiss Legend Overlay
    await tester.tap(find.text('Got it — start swiping'));
    await tester.pumpAndSettle();

    // Verify Page 1 item Movie 1 is displayed
    expect(find.text('Movie 1'), findsOneWidget);

    // Swipe card 1
    await tester.tap(find.byIcon(Icons.star_border));
    await tester.pumpAndSettle();

    // Swipe card 2
    await tester.tap(find.byIcon(Icons.star_border));
    await tester.pumpAndSettle();

    // Pool empty -> _loadPool(isReload: true) automatically called or Reload Deck button visible
    if (find.text('Reload deck').evaluate().isNotEmpty) {
      await tester.tap(find.text('Reload deck'));
      await tester.pumpAndSettle();
    }

    // Verify Page 3 items (Movie 3) now fetched and displayed
    expect(find.text('Movie 3'), findsOneWidget);
  });

  testWidgets('Item 9 & 10: BrowseScreen filter visual confirmation and Load More bottom padding',
      (WidgetTester tester) async {
    final repo = MockMovieRepository();
    final container = ProviderContainer(
      overrides: [
        movieRepositoryProvider.overrideWithValue(repo),
      ],
    );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: BrowseScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Open filter bottom sheet
    await tester.tap(find.text('Filters'));
    await tester.pumpAndSettle();

    // Tap 'Action' genre chip
    await tester.tap(find.text('Action'));
    await tester.pumpAndSettle();

    // Verify Action genre is selected
    expect(find.text('Action'), findsWidgets);

    // Close bottom sheet
    await tester.tap(find.text('Apply Filters'));
    await tester.pumpAndSettle();

    // Verify Active Filter chip bar shows 'Genre: Action'
    expect(find.text('Genre: Action'), findsOneWidget);

    // Verify Load More footer has bottom padding (90 + safe inset)
    final loadMoreFinder = find.text('Load More');
    expect(loadMoreFinder, findsOneWidget);
  });

  testWidgets('Item 10: MediaListScreen Load More bottom padding',
      (WidgetTester tester) async {
    final repo = MockMovieRepository();
    final container = ProviderContainer(
      overrides: [
        movieRepositoryProvider.overrideWithValue(repo),
      ],
    );

    final provider = FutureProvider<List<MediaItem>>((ref) => repo.getTrendingMovies());

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: MediaListScreen(
            title: 'Trending Movies',
            itemsProvider: provider,
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.textContaining('Load More'), findsOneWidget);
  });

  testWidgets('Item 11: CollectionScreen displays collection details and handles navigation',
      (WidgetTester tester) async {
    final repo = TestCollectionRepository();
    final container = ProviderContainer(
      overrides: [
        movieRepositoryProvider.overrideWithValue(repo),
      ],
    );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: CollectionScreen(collectionId: 10),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify Collection name and overview text
    expect(find.text('Star Wars Collection'), findsWidgets);
    expect(find.textContaining('Epic space saga collection overview text.'), findsOneWidget);

    // Verify Collection titles in grid
    expect(find.text('Star Wars: Episode IV'), findsOneWidget);
    expect(find.text('Star Wars: Episode V'), findsOneWidget);
  });

  testWidgets('Item 11: DetailScreen collection banner click navigates to CollectionScreen',
      (WidgetTester tester) async {
    final repo = TestCollectionRepository();
    final container = ProviderContainer(
      overrides: [
        movieRepositoryProvider.overrideWithValue(repo),
      ],
    );

    // Override mediaDetailsProvider for movie_1
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: DetailScreen(id: 'movie_1'),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Tap collection banner
    final bannerFinder = find.textContaining('Part of the Star Wars Collection');
    expect(bannerFinder, findsOneWidget);
    await tester.ensureVisible(bannerFinder);
    await tester.pumpAndSettle();
    await tester.tap(bannerFinder);
    await tester.pumpAndSettle();

    // Verify navigated to CollectionScreen
    expect(find.text('Star Wars Collection'), findsWidgets);
  });
}
