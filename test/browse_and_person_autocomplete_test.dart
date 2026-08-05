import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:the_lounge/models/discover_filter_params.dart';
import 'package:the_lounge/models/media_item.dart';
import 'package:the_lounge/providers/repository_provider.dart';
import 'package:the_lounge/repositories/movie_repository.dart';
import 'package:the_lounge/screens/browse_screen.dart';
import 'package:the_lounge/screens/detail_screen.dart';
import 'package:the_lounge/widgets/person_search_autocomplete.dart';

class _TestRepository implements MovieRepository {
  final Map<String, MediaItem> items;

  _TestRepository(this.items);

  @override
  Future<List<MediaItem>> getTrendingMovies({int page = 1}) async => items.values.toList();

  @override
  Future<List<MediaItem>> getPopularMovies({int page = 1}) async => items.values.toList();

  @override
  Future<List<MediaItem>> getTrendingTvShows({int page = 1}) async => items.values.toList();

  @override
  Future<List<MediaItem>> getTopRatedMovies({int page = 1}) async => items.values.toList();

  @override
  Future<List<MediaItem>> getTopRatedTvShows({int page = 1}) async => items.values.toList();

  @override
  Future<List<MediaItem>> getNowPlayingMovies({int page = 1}) async => items.values.toList();

  @override
  Future<List<MediaItem>> getAiringTodayTvShows({int page = 1}) async => items.values.toList();

  @override
  Future<List<MediaItem>> getUpcomingMovies({int page = 1}) async => items.values.toList();

  @override
  Future<List<MediaItem>> getOnTheAirTvShows({int page = 1}) async => items.values.toList();

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

  group('BrowseScreen & Discover Integration Tests', () {
    testWidgets('BrowseScreen displays active filter chip bar when filters exist',
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
            home: BrowseScreen(),
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
            home: BrowseScreen(),
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

      await tester.pumpAndSettle();

      final keywordChip = find.text('#historical fiction');
      await tester.scrollUntilVisible(keywordChip, 200);
      expect(keywordChip, findsOneWidget);

      await tester.tap(keywordChip);
      await tester.pumpAndSettle();

      // Now on BrowseScreen
      expect(find.byType(BrowseScreen), findsOneWidget);
      expect(find.text('Keyword: #historical fiction'), findsWidgets);

      final filterState = container.read(discoverFilterProvider);
      expect(filterState.keywordName, equals('historical fiction'));
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
            home: BrowseScreen(),
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
  });
}
