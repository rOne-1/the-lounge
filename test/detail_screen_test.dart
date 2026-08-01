import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:the_lounge/screens/detail_screen.dart';
import 'package:the_lounge/providers/repository_provider.dart';
import 'package:the_lounge/providers/media_provider.dart';
import 'package:the_lounge/providers/ambiance_provider.dart';
import 'package:the_lounge/models/media_item.dart';
import 'package:the_lounge/repositories/movie_repository.dart';

class MockDetailRepository implements MovieRepository {
  final Map<String, MediaItem> items;

  MockDetailRepository(this.items);

  @override
  Future<List<MediaItem>> getTrendingMovies() async => items.values.toList();

  @override
  Future<List<MediaItem>> getPopularMovies() async => items.values.toList();

  @override
  Future<List<MediaItem>> getTrendingTvShows() async => items.values.toList();

  @override
  Future<MediaItem?> getMediaDetails(String id) async => items[id];

  @override
  Future<List<MediaItem>> searchMedia(String query) async => [];
}

void main() {
  setUp(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  final testMovie = MediaItem(
    id: 'movie-1',
    title: 'Inception',
    type: MediaType.movie,
    rating: 8.8,
    releaseOrAirDate: DateTime(2010, 7, 16),
    overview: 'A thief who steals corporate secrets through dream-sharing...',
    genres: const ['Action', 'Sci-Fi', 'Thriller'],
    runtime: 148,
    watchProviders: const ['Netflix', 'Amazon Prime'],
    cast: const ['Leonardo DiCaprio', 'Joseph Gordon-Levitt'],
  );

  final testTvShow = MediaItem(
    id: 'tv-1',
    title: 'Stranger Things',
    type: MediaType.tv,
    rating: 8.7,
    releaseOrAirDate: DateTime(2016, 7, 15),
    nextEpisodeAirDate: DateTime(2026, 8, 10),
    overview: 'When a young boy vanishes, a small town uncovers a mystery...',
    genres: const ['Sci-Fi & Fantasy', 'Drama', 'Mystery'],
    seasonsCount: 4,
    episodesCount: 34,
    watchProviders: const ['Netflix'],
    cast: const ['Millie Bobby Brown', 'Winona Ryder'],
  );

  final testMovieNoProviders = MediaItem(
    id: 'movie-2',
    title: 'Indie Film',
    type: MediaType.movie,
    rating: 7.2,
    releaseOrAirDate: DateTime(2022, 1, 1),
    overview: 'An indie film with no streaming providers.',
    genres: const ['Drama'],
    runtime: 90,
    watchProviders: const [],
  );

  group('MediaNotifier SharedPreferences Unit Tests', () {
    test('defaults to US when SharedPreferences is empty', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
      );
      addTearDown(container.dispose);

      final state = container.read(mediaProvider);
      expect(state.watchProvidersCountry, equals('US'));
    });

    test('loads pre-saved watch_providers_country from SharedPreferences',
        () async {
      SharedPreferences.setMockInitialValues({
        'watch_providers_country': 'GB',
      });
      final prefs = await SharedPreferences.getInstance();

      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
      );
      addTearDown(container.dispose);

      final state = container.read(mediaProvider);
      expect(state.watchProvidersCountry, equals('GB'));
    });

    test('setWatchProvidersCountry updates state and saves to SharedPreferences',
        () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(mediaProvider.notifier);
      await notifier.setWatchProvidersCountry('CA');

      expect(container.read(mediaProvider).watchProvidersCountry, equals('CA'));
      expect(prefs.getString('watch_providers_country'), equals('CA'));
    });
  });

  group('DetailScreen UI and Metadata Tests', () {
    testWidgets('displays movie rating badge, genres, runtime, and release date',
        (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final mockRepo = MockDetailRepository({'movie-1': testMovie});

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            movieRepositoryProvider.overrideWithValue(mockRepo),
          ],
          child: const MaterialApp(
            home: DetailScreen(id: 'movie-1'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify Title
      expect(find.text('Inception'), findsOneWidget);

      // Verify Rating badge
      expect(find.text('★ 8.8'), findsOneWidget);

      // Verify Genre chips
      expect(find.text('Action'), findsOneWidget);
      expect(find.text('Sci-Fi'), findsOneWidget);
      expect(find.text('Thriller'), findsOneWidget);

      // Verify Movie-specific metadata: runtime and release date
      expect(find.text('148 min'), findsOneWidget);
      expect(find.text('Jul 16, 2010'), findsOneWidget);

      // Verify Watch providers
      expect(find.text('Where to Watch'), findsOneWidget);
      expect(find.text('Netflix'), findsOneWidget);
      expect(find.text('Amazon Prime'), findsOneWidget);
    });

    testWidgets(
        'displays TV show rating badge, genres, seasons, episodes, and next air date',
        (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final mockRepo = MockDetailRepository({'tv-1': testTvShow});

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            movieRepositoryProvider.overrideWithValue(mockRepo),
          ],
          child: const MaterialApp(
            home: DetailScreen(id: 'tv-1'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify Title
      expect(find.text('Stranger Things'), findsOneWidget);

      // Verify Rating badge
      expect(find.text('★ 8.7'), findsOneWidget);

      // Verify Genre chips
      expect(find.text('Sci-Fi & Fantasy'), findsOneWidget);
      expect(find.text('Drama'), findsOneWidget);
      expect(find.text('Mystery'), findsOneWidget);

      // Verify TV-specific metadata: seasons, episodes, next air date
      expect(find.text('4 Seasons'), findsOneWidget);
      expect(find.text('34 Episodes'), findsOneWidget);
      expect(find.text('Next: Aug 10, 2026'), findsOneWidget);
      expect(find.text('Jul 15, 2016'), findsOneWidget);
    });

    testWidgets('country selector dropdown updates provider state and preferences',
        (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final mockRepo = MockDetailRepository({'movie-1': testMovie});

      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          movieRepositoryProvider.overrideWithValue(mockRepo),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: DetailScreen(id: 'movie-1'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Default country should be US
      expect(find.text('US'), findsOneWidget);
      expect(container.read(mediaProvider).watchProvidersCountry, equals('US'));

      // Ensure the dropdown is scrolled into view and tapped
      await tester.ensureVisible(find.text('US'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('US'));
      await tester.pumpAndSettle();

      // Tap GB from dropdown menu
      await tester.tap(find.text('GB').last);
      await tester.pumpAndSettle();

      // Verify state and preference update
      expect(container.read(mediaProvider).watchProvidersCountry, equals('GB'));
      expect(prefs.getString('watch_providers_country'), equals('GB'));
    });

    testWidgets('displays empty streaming message when watchProviders is empty',
        (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final mockRepo = MockDetailRepository({'movie-2': testMovieNoProviders});

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            movieRepositoryProvider.overrideWithValue(mockRepo),
          ],
          child: const MaterialApp(
            home: DetailScreen(id: 'movie-2'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Where to Watch'), findsOneWidget);
      expect(
        find.text('No streaming providers available in US.'),
        findsOneWidget,
      );
    });

    testWidgets('large layout renders without error and displays all metadata',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final mockRepo = MockDetailRepository({'movie-1': testMovie});

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            movieRepositoryProvider.overrideWithValue(mockRepo),
          ],
          child: const MaterialApp(
            home: DetailScreen(id: 'movie-1'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Inception'), findsOneWidget);
      expect(find.text('★ 8.8'), findsOneWidget);
      expect(find.text('Action'), findsOneWidget);
      expect(find.text('148 min'), findsOneWidget);
      expect(find.text('Where to Watch'), findsOneWidget);
    });
  });
}
