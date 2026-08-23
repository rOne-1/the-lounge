import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:the_lounge/models/media_item.dart';
import 'package:the_lounge/providers/ambiance_provider.dart';
import 'package:the_lounge/providers/hall_provider.dart';
import 'package:the_lounge/providers/media_provider.dart';
import 'package:the_lounge/providers/repository_provider.dart';
import 'package:the_lounge/repositories/mock_movie_repository.dart';
import 'package:the_lounge/screens/media_list_screen.dart';

MediaItem _movie(String id, String title, [String? originalLanguage]) => MediaItem(
      id: id,
      title: title,
      type: MediaType.movie,
      rating: 7.5,
      overview: '',
      genres: const [],
      originalLanguage: originalLanguage,
    );

class _TestLanguageRepository extends MockMovieRepository {
  @override
  Future<List<MediaItem>> getTrendingMovies({
    int page = 1,
    String? originalLanguage,
  }) async {
    if (originalLanguage == 'ja') {
      if (page == 1) {
        return [_movie('ja-1', 'Japanese Movie 1', 'ja')];
      } else if (page == 2) {
        return [_movie('ja-2', 'Japanese Movie 2', 'ja')];
      }
      return [];
    } else if (originalLanguage == 'hi') {
      if (page == 1) {
        return [_movie('hi-1', 'Hindi Movie 1', 'hi')];
      }
      return [];
    } else {
      if (page == 1) {
        return [_movie('en-1', 'English Movie 1', 'en')];
      } else if (page == 2) {
        return [_movie('en-2', 'English Movie 2', 'en')];
      }
      return [];
    }
  }
}

void main() {
  setUp(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  group('MediaListScreen reactive refresh', () {
    testWidgets(
        'changing lockedLanguageCode / active Hall resets pagination and refreshes displayed items',
        (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final repo = _TestLanguageRepository();

      final container = ProviderContainer(
        overrides: [
          movieRepositoryProvider.overrideWithValue(repo),
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Scaffold(
              body: MediaListScreen(
                title: 'Trending',
                itemsProvider: trendingMoviesProvider,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Initially unrestricted (English item loaded)
      expect(find.text('English Movie 1'), findsOneWidget);
      expect(find.text('English Movie 2'), findsNothing);
      expect(find.text('Japanese Movie 1'), findsNothing);

      // Tap Load More to advance to page 2 and accumulate items
      expect(find.text('Load More (Page 2)'), findsOneWidget);
      await tester.tap(find.text('Load More (Page 2)'));
      await tester.pumpAndSettle();

      // Page 2 item is now visible alongside page 1
      expect(find.text('English Movie 1'), findsOneWidget);
      expect(find.text('English Movie 2'), findsOneWidget);

      // Now switch the active Hall language lock to Japanese ('ja')
      await container
          .read(hallProvider.notifier)
          .updateHallLanguage('common', 'ja', 'Japanese');
      await tester.pumpAndSettle();

      // The accumulated items and page count should be reset, showing Japanese items only
      expect(find.text('English Movie 1'), findsNothing);
      expect(find.text('English Movie 2'), findsNothing);
      expect(find.text('Japanese Movie 1'), findsOneWidget);
      expect(find.text('Load More (Page 2)'), findsOneWidget);

      // Switching to another hall with Hindi ('hi') lock
      await container
          .read(hallProvider.notifier)
          .updateHallLanguage('common', 'hi', 'Hindi');
      await tester.pumpAndSettle();

      expect(find.text('Japanese Movie 1'), findsNothing);
      expect(find.text('Hindi Movie 1'), findsOneWidget);
    });
  });
}
