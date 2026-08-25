// DATA-CONT-4: SearchScreen's local-library alternative-title matching.
// TMDB's live text search has no way for this app to query by an
// alternative/translated title -- that data only exists on a title's own
// detail payload. The one case this app can resolve correctly is a title
// already in the user's library: verifies searching by that title's
// Japanese translation surfaces it even though the mocked live search
// returns nothing for that query.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:the_lounge/models/media_item.dart';
import 'package:the_lounge/providers/ambiance_provider.dart';
import 'package:the_lounge/providers/media_provider.dart';
import 'package:the_lounge/repositories/mock_movie_repository.dart';
import 'package:the_lounge/screens/search_screen.dart';
import 'package:the_lounge/widgets/media_image.dart';

class _EmptySearchRepository extends MockMovieRepository {
  @override
  Future<List<MediaItem>> searchMedia(String query) async => [];
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets(
      'searching by a library title\'s Japanese translation surfaces it even when live search returns nothing',
      (tester) async {
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(overrides: [
      movieRepositoryProvider.overrideWithValue(_EmptySearchRepository()),
      sharedPreferencesProvider.overrideWithValue(prefs),
    ]);
    addTearDown(container.dispose);

    const libraryItem = MediaItem(
      id: 'movie_42',
      title: 'Inception',
      type: MediaType.movie,
      rating: 8.8,
      overview: '',
      genres: [],
      translatedTitlesByLanguage: {'ja': 'インセプション'},
    );
    container.read(mediaProvider.notifier).addToWatchlist(libraryItem);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: SearchScreen()),
      ),
    );
    await tester.pumpAndSettle();

    final searchField = find.byType(TextField).first;
    await tester.enterText(searchField, 'インセプション');
    await tester.pumpAndSettle();

    final ids = tester
        .widgetList<MediaImage>(find.byType(MediaImage))
        .map((w) => w.item!.id)
        .toList();
    expect(ids, contains('movie_42'));
  });

  testWidgets(
      'a query matching nothing in the library and nothing in live search shows the empty state',
      (tester) async {
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(overrides: [
      movieRepositoryProvider.overrideWithValue(_EmptySearchRepository()),
      sharedPreferencesProvider.overrideWithValue(prefs),
    ]);
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: SearchScreen()),
      ),
    );
    await tester.pumpAndSettle();

    final searchField = find.byType(TextField).first;
    await tester.enterText(searchField, 'zzz_no_match_zzz');
    await tester.pumpAndSettle();

    expect(find.byType(MediaImage), findsNothing);
  });
}
