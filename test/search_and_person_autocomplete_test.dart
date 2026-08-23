import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:the_lounge/models/discover_filter_params.dart';
import 'package:the_lounge/models/media_item.dart';
import 'package:the_lounge/providers/repository_provider.dart';
import 'package:the_lounge/screens/search_screen.dart';
import 'package:the_lounge/screens/detail_screen.dart';
import 'package:the_lounge/widgets/person_search_autocomplete.dart';

import 'package:the_lounge/repositories/mock_movie_repository.dart';

class _TestRepository extends MockMovieRepository {
  final Map<String, MediaItem> items;

  _TestRepository(this.items);

  @override
  Future<List<MediaItem>> getTrendingMovies({int page = 1, String? originalLanguage}) async => items.values.toList();

  @override
  Future<List<MediaItem>> getPopularMovies({int page = 1, String? originalLanguage}) async => items.values.toList();

  @override
  Future<List<MediaItem>> getTrendingTvShows({int page = 1, String? originalLanguage}) async => items.values.toList();

  @override
  Future<List<MediaItem>> getTopRatedMovies({int page = 1, String? originalLanguage}) async => items.values.toList();

  @override
  Future<List<MediaItem>> getTopRatedTvShows({int page = 1, String? originalLanguage}) async => items.values.toList();

  @override
  Future<List<MediaItem>> getNowPlayingMovies({int page = 1, String? region, String? originalLanguage}) async => items.values.toList();

  @override
  Future<List<MediaItem>> getAiringTodayTvShows({int page = 1, String? originalLanguage}) async => items.values.toList();

  @override
  Future<List<MediaItem>> getUpcomingMovies({int page = 1, String? region, String? originalLanguage}) async => items.values.toList();

  @override
  Future<List<MediaItem>> getOnTheAirTvShows({int page = 1, String? originalLanguage}) async => items.values.toList();

  @override
  Future<MediaItem?> getMediaDetails(String id) async => items[id] ?? items.values.firstOrNull;

  @override
  Future<TvSeason?> getTvSeasonDetails(String tvId, int seasonNumber) async => null;

  @override
  Future<List<MediaItem>> searchMedia(String query) async => items.values.toList();

  @override
  Future<List<Map<String, String>>> getWatchProviderRegions() async => const [
        {'code': 'US', 'name': 'United States'},
      ];

  @override
  Future<List<MediaItem>> discoverMedia({
    required bool isMovies,
    required DiscoverFilterParams params,
    int page = 1,
  }) async =>
      items.values.toList();

  @override
  Future<List<Map<String, dynamic>>> searchPersons(String query) async => [
        {
          'id': 1001,
          'name': 'Christopher Nolan',
          'known_for_department': 'Directing',
          'profile_path': null,
        }
      ];
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PersonSearchAutocomplete Widget Tests', () {
    testWidgets('Renders search text field and debounces person search',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: PersonSearchAutocomplete(isDark: true),
            ),
          ),
        ),
      );

      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('Search cast or crew...'), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'Nolan');
      await tester.pump(const Duration(milliseconds: 100));
      // Before debounce timer fires
      expect(find.text('Christopher Nolan'), findsNothing);

      // Advance past 300ms debounce
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pumpAndSettle();

      expect(find.text('Christopher Nolan'), findsWidgets);
      expect(find.text('Directing'), findsWidgets);
    });

    testWidgets(
        'Regression: does not throw when nested inside an ExpansionTile with a '
        'PageStorageKey (production structure -- search_screen.dart wraps this '
        'in a keyed ExpansionTile, and an unkeyed TextField/ListView inside it '
        'inherits that key as its own PageStorage identity, colliding with the '
        "tile's own stored bool expanded-state)",
        (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: PageStorage(
                bucket: PageStorageBucket(),
                child: ListView(
                  children: [
                    ExpansionTile(
                      key: const PageStorageKey<String>('filter_accordion_Cast & Crew'),
                      title: const Text('Cast & Crew'),
                      children: const [
                        PersonSearchAutocomplete(isDark: true),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Match the real repro exactly: starts collapsed, tap to expand --
      // this is the transition that writes the tile's bool state to
      // PageStorage and triggers the TextField's Scrollable to (mis)read it.
      await tester.tap(find.text('Cast & Crew'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(TextField), findsOneWidget);

      // The results dropdown (a separate Scrollable) must also render
      // without throwing.
      await tester.enterText(find.byType(TextField), 'Nolan');
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Christopher Nolan'), findsWidgets);
    });

    testWidgets(
        'Regression: fills the ExpansionTile width instead of shrink-wrapping to a '
        'blank card (TF-10 -- root Column used mainAxisSize.min + '
        'crossAxisAlignment.start, which shrink-wraps under an ExpansionTile with '
        'expandedCrossAxisAlignment.start since the tile gives unconstrained width)',
        (WidgetTester tester) async {
      const tileWidth = 350.0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: tileWidth,
              child: ExpansionTile(
                key: const PageStorageKey<String>('filter_accordion_Cast & Crew'),
                title: const Text('Cast & Crew'),
                initiallyExpanded: true,
                expandedCrossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  ProviderScope(child: PersonSearchAutocomplete(isDark: true)),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final textFieldWidth = tester.getSize(find.byType(TextField)).width;
      // A collapsed/blank card renders at (or near) zero width; the real
      // field should span essentially the full tile width, well clear of
      // that failure mode.
      expect(textFieldWidth, greaterThan(tileWidth * 0.8));
    });

    testWidgets(
        'Selecting a person sets personId and personName in discoverFilterProvider',
        (WidgetTester tester) async {
      late WidgetRef savedRef;

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: Consumer(
                builder: (context, ref, _) {
                  savedRef = ref;
                  return const PersonSearchAutocomplete(isDark: true);
                },
              ),
            ),
          ),
        ),
      );

      await tester.enterText(find.byType(TextField), 'Nolan');
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pumpAndSettle();

      final personItem = find.text('Christopher Nolan').first;
      await tester.tap(personItem);
      await tester.pumpAndSettle();

      final filterState = savedRef.read(discoverFilterProvider);
      expect(filterState.personName, equals('Christopher Nolan'));
      expect(filterState.personId, isNotNull);
    });
  });

  group('SearchScreen & Discover Integration Tests', () {
    testWidgets('SearchScreen displays active filter chip bar when filters exist',
        (WidgetTester tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(discoverFilterProvider.notifier).updateParams(
            const DiscoverFilterParams(
              genreName: 'Sci-Fi',
              minRating: 8.0,
            ),
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

      expect(find.text('Genre: Sci-Fi'), findsOneWidget);
      expect(find.text('Rating: ≥ 8.0 ★'), findsOneWidget);
      expect(find.text('Reset All'), findsWidgets);
    });

    testWidgets('Tapping Reset All clears all active filters',
        (WidgetTester tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(discoverFilterProvider.notifier).updateParams(
            const DiscoverFilterParams(
              genreName: 'Action',
              minRating: 7.5,
            ),
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

      final resetButton = find.text('Reset All').first;
      await tester.tap(resetButton);
      await tester.pumpAndSettle();

      final filterState = container.read(discoverFilterProvider);
      expect(filterState.hasActiveFilters, isFalse);
    });

    testWidgets(
        'Incoming Keyword Pre-Filter Synchronization from DetailScreen',
        (WidgetTester tester) async {
      final testItem = MediaItem(
        id: 'movie_1',
        title: 'Inception',
        overview: 'A thief who steals corporate secrets through the use of dream-sharing technology.',
        type: MediaType.movie,
        rating: 8.8,
        genres: const ['Action', 'Sci-Fi'],
        keywords: const [
          MediaKeyword(id: 101, name: 'historical fiction'),
        ],
      );

      final container = ProviderContainer(
        overrides: [
          movieRepositoryProvider.overrideWithValue(
            _TestRepository({
              'movie_1': testItem,
              'movie_movie_1': testItem,
            }),
          ),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: DetailScreen(id: testItem.prefixedId),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 500));

      final keywordChip = find.text('#historical fiction');
      await tester.scrollUntilVisible(keywordChip, 200, scrollable: find.byType(Scrollable).first);
      expect(keywordChip, findsOneWidget);

      await tester.tap(keywordChip);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Now on SearchScreen
      expect(find.byType(SearchScreen), findsOneWidget);
      expect(find.text('Keyword: #historical fiction'), findsWidgets);

      final filterState = container.read(discoverFilterProvider);
      expect(filterState.keywordName, equals('historical fiction'));
    });

    testWidgets(
        'Regression: person filter does not hide items with no cast/director data '
        '(Discover-mode grid, credit-less TMDB discover-list items)',
        (WidgetTester tester) async {
      // Real TMDB discover-list responses never include per-item credits
      // (that requires a separate append_to_response=credits call), so cast
      // and director are empty/null here -- exactly like production data.
      // A cast/crew tap from DetailScreen sets personName/personId and lands
      // on this Discover-mode grid with no search query typed.
      final filmography = {
        for (var i = 1; i <= 3; i++)
          'movie_$i': MediaItem(
            id: 'movie_$i',
            title: 'Filmography Title $i',
            overview: '',
            type: MediaType.movie,
            rating: 7.5,
            genres: const [],
          ),
      };

      final container = ProviderContainer(
        overrides: [
          movieRepositoryProvider.overrideWithValue(
            _TestRepository(filmography),
          ),
        ],
      );
      addTearDown(container.dispose);

      container.read(discoverFilterProvider.notifier).setPerson(
            personId: 42,
            personName: 'Tom Holland',
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

      expect(find.text('No media found matching your filters.'), findsNothing);
      expect(find.text('Filmography Title 1'), findsWidgets);
    });

    testWidgets(
        'Regression: originalLanguage filter actually narrows results '
        '(_applyClientFilters previously had no language check at all, so '
        'the filter chip was cosmetic and did nothing)',
        (WidgetTester tester) async {
      final items = {
        'movie_1': const MediaItem(
          id: '1',
          title: 'Korean Drama',
          overview: '',
          type: MediaType.movie,
          rating: 8.0,
          genres: [],
          originalLanguage: 'ko',
        ),
        'movie_2': const MediaItem(
          id: '2',
          title: 'English Show',
          overview: '',
          type: MediaType.movie,
          rating: 8.0,
          genres: [],
          originalLanguage: 'en',
        ),
      };

      final container = ProviderContainer(
        overrides: [
          movieRepositoryProvider.overrideWithValue(_TestRepository(items)),
        ],
      );
      addTearDown(container.dispose);

      container
          .read(discoverFilterProvider.notifier)
          .updateParams(const DiscoverFilterParams(originalLanguage: 'ko'));

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(body: SearchScreen()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Korean Drama'), findsWidgets);
      expect(find.text('English Show'), findsNothing);
    });

    testWidgets('Dual-mode switching between Discover Mode and Search Mode with mode badge',
        (WidgetTester tester) async {
      final testItem = MediaItem(
        id: 'movie_1',
        title: 'Inception',
        overview: 'A thief steals secrets.',
        type: MediaType.movie,
        rating: 8.8,
        genres: const ['Action', 'Sci-Fi'],
      );

      final container = ProviderContainer(
        overrides: [
          movieRepositoryProvider.overrideWithValue(
            _TestRepository({'movie_1': testItem}),
          ),
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

      // Initially in Discover mode (no search mode badge)
      expect(find.textContaining('⚡ Search Mode'), findsNothing);

      // Enter text into search bar
      final searchField = find.byType(TextField).first;
      await tester.enterText(searchField, 'Inception');
      await tester.pumpAndSettle();

      // Now in Search mode: Mode badge is displayed
      expect(
        find.text('⚡ Search Mode: Filtering is scoped to search results for "Inception"'),
        findsOneWidget,
      );

      // Clear search text
      final clearButton = find.byIcon(Icons.close).first;
      await tester.tap(clearButton);
      await tester.pumpAndSettle();

      // Returns to Discover Mode
      expect(find.textContaining('⚡ Search Mode'), findsNothing);
    });

    testWidgets('Filter accordion expansion sections are wrapped in Material widget for ink splashes',
        (WidgetTester tester) async {
      final container = ProviderContainer(
        overrides: [
          movieRepositoryProvider.overrideWithValue(
            _TestRepository({}),
          ),
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

      final filterButton = find.text('Filters').first;
      await tester.tap(filterButton);
      await tester.pumpAndSettle();

      final expansionTileFinder = find.byType(ExpansionTile);
      expect(expansionTileFinder, findsAtLeastNWidgets(1));

      for (final tileElement in expansionTileFinder.evaluate()) {
        final materialAncestor = tester.widget<Material>(
          find.ancestor(
            of: find.byElementPredicate((e) => e == tileElement),
            matching: find.byType(Material),
          ).first,
        );

        expect(materialAncestor.clipBehavior, equals(Clip.antiAlias));
        expect(materialAncestor.borderRadius, equals(BorderRadius.circular(14)));
        expect(materialAncestor.color, isNotNull);
      }
    });
  });
}
