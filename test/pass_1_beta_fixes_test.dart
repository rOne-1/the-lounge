import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:the_lounge/models/media_item.dart';
import 'package:the_lounge/repositories/mock_movie_repository.dart';
import 'package:the_lounge/providers/repository_provider.dart';
import 'package:the_lounge/providers/media_provider.dart';
import 'package:the_lounge/providers/ambiance_provider.dart';
import 'package:the_lounge/screens/detail_screen.dart';
import 'package:the_lounge/screens/your_space_screen.dart';

class MockPass1Repository extends MockMovieRepository {
  final Map<String, MediaItem> items;

  MockPass1Repository(this.items);

  @override
  Future<MediaItem?> getMediaDetails(String id) async => items[id];

  @override
  Future<TvSeason?> getTvSeasonDetails(String tvId, int seasonNumber) async => null;
}

void main() {
  group('Pass 1 Beta Bug Fixes Unit & Widget Tests', () {
    test('MediaItem captures originalLanguage, spokenLanguages, and status correctly', () {
      final item = MediaItem(
        id: 'movie_1',
        title: 'Amélie',
        type: MediaType.movie,
        rating: 8.3,
        overview: 'French comedy film',
        genres: const ['Comedy', 'Romance'],
        originalLanguage: 'fr',
        spokenLanguages: const ['French'],
        status: 'Released',
      );

      expect(item.originalLanguage, 'fr');
      expect(item.spokenLanguages, ['French']);
      expect(item.status, 'Released');
      expect(item.originalLanguageDisplay, 'French');
    });

    test('MediaItem originalLanguageDisplay converts ISO 639-1 code if spokenLanguages is empty', () {
      final item = MediaItem(
        id: 'movie_2',
        title: 'Parasite',
        type: MediaType.movie,
        rating: 8.5,
        overview: 'Korean thriller',
        genres: const ['Thriller'],
        originalLanguage: 'ko',
      );

      expect(item.originalLanguageDisplay, 'Korean');
    });

    testWidgets('YourSpaceScreen displays App Info button and opens TMDB Attribution & Privacy dialog',
        (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(
              body: YourSpaceScreen(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final settingsButton = find.byKey(const ValueKey('settings_button'));
      expect(settingsButton, findsOneWidget);

      await tester.tap(settingsButton);
      await tester.pumpAndSettle();

      expect(find.text('Settings'), findsOneWidget);
      expect(find.text('TMDB Attribution'), findsOneWidget);
      expect(
        find.text('This product uses the TMDB API but is not endorsed or certified by TMDB.'),
        findsOneWidget,
      );
      expect(find.text('Tester Privacy Note'), findsOneWidget);
    });

    testWidgets('DetailScreen displays language pill and TV status badge',
        (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      final testTvShow = MediaItem(
        id: 'tv_100',
        title: 'Test Show',
        type: MediaType.tv,
        rating: 9.0,
        overview: 'A great TV show',
        genres: const ['Drama'],
        originalLanguage: 'ja',
        status: 'Returning Series',
        seasonsCount: 2,
        episodesCount: 24,
      );

      final mockRepo = MockPass1Repository({'tv_100': testTvShow});

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
            home: DetailScreen(id: 'tv_100'),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Japanese'), findsOneWidget);
      expect(find.text('Returning Series'), findsOneWidget);
    });

    testWidgets('DetailScreen guards unreleased movie from being marked watched',
        (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      final unreleasedMovie = MediaItem(
        id: 'movie_999',
        title: 'Future Movie 2030',
        type: MediaType.movie,
        rating: 0.0,
        overview: 'Coming soon',
        genres: const ['Sci-Fi'],
        releaseOrAirDate: DateTime(2030, 1, 1),
      );

      final mockRepo = MockPass1Repository({'movie_999': unreleasedMovie});

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
            home: DetailScreen(id: 'movie_999'),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));

      final watchedButton = find.text('Watched');
      expect(watchedButton, findsOneWidget);

      await tester.ensureVisible(watchedButton);
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.tap(watchedButton);
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('This title has not been released yet.'), findsOneWidget);
    });
  });
}
