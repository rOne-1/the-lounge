// Regression coverage for NAV-2: navigating to a director/cast member's
// filmography from DetailScreen must not silently mutate the root shell
// tab. Previously this pushed SearchScreen as a sub-route AND switched
// navigationProvider to AppTab.search, so popping back out later stranded
// the user on the Search tab regardless of where they actually started.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:the_lounge/screens/detail_screen.dart';
import 'package:the_lounge/screens/search_screen.dart';
import 'package:the_lounge/providers/media_provider.dart';
import 'package:the_lounge/providers/navigation_provider.dart';
import 'package:the_lounge/providers/ambiance_provider.dart';
import 'package:the_lounge/providers/repository_provider.dart';
import 'package:the_lounge/models/media_item.dart';
import 'package:the_lounge/models/discover_filter_params.dart';
import 'package:the_lounge/repositories/mock_movie_repository.dart';

class _DirectorTestRepository extends MockMovieRepository {
  final MediaItem item;

  _DirectorTestRepository(this.item);

  @override
  Future<MediaItem?> getMediaDetails(String id, {String? region}) async => item;

  @override
  Future<TvSeason?> getTvSeasonDetails(String tvId, int seasonNumber) async => null;

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
      [];

  @override
  Future<List<Map<String, dynamic>>> searchPersons(String query) async => [];
}

void main() {
  setUp(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  const testMovie = MediaItem(
    id: 'nav2-movie',
    title: 'Nav Test Movie',
    type: MediaType.movie,
    rating: 8.0,
    overview: 'Overview',
    genres: ['Drama'],
    director: 'Christopher Nolan',
  );

  testWidgets(
      'tapping the director credit pushes SearchScreen without mutating navigationProvider',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [
        movieRepositoryProvider.overrideWithValue(_DirectorTestRepository(testMovie)),
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
    );
    addTearDown(container.dispose);

    // Mounted while the root shell is conceptually on The Lounge (the
    // default startup tab per PERS-NAV-1).
    expect(container.read(navigationProvider).currentTab, AppTab.lounge);

    // DetailScreen has a continuously-animating backdrop glow, so
    // pumpAndSettle() never terminates here -- matches the bounded-pump
    // pattern used elsewhere for this screen (e.g. detail_screen_test.dart).
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: DetailScreen(id: 'nav2-movie'),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 500));

    // BETA3-PERF-1: director credit is below the fold, lazily built by the
    // sliver list -- scrollUntilVisible (not ensureVisible, which requires
    // the element to already exist) brings it into range first.
    final directorFinder = find.text('Christopher Nolan');
    await tester.scrollUntilVisible(directorFinder, 200,
        scrollable: find.byType(Scrollable).first);
    await tester.pump(const Duration(milliseconds: 500));
    await tester.tap(directorFinder);
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byType(SearchScreen), findsOneWidget);
    expect(container.read(navigationProvider).currentTab, AppTab.lounge);

    Navigator.of(tester.element(find.byType(SearchScreen))).pop();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byType(SearchScreen), findsNothing);
    expect(find.byType(DetailScreen), findsOneWidget);
    expect(container.read(navigationProvider).currentTab, AppTab.lounge);
  });

  testWidgets(
      'SEARCH-CAST-1: tapping a director credit clears a stale filter left over from an earlier Search session',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [
        movieRepositoryProvider.overrideWithValue(_DirectorTestRepository(testMovie)),
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
    );
    addTearDown(container.dispose);

    // Simulates a prior, unrelated Search session that left a genre filter
    // active -- discoverFilterProvider is a long-lived singleton, so this
    // would otherwise still be set when the user later taps a completely
    // different director/cast credit from DetailScreen.
    container.read(discoverFilterProvider.notifier).setGenre(
          genreId: 28,
          genreName: 'Action',
        );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: DetailScreen(id: 'nav2-movie'),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 500));

    final directorFinder = find.text('Christopher Nolan');
    await tester.scrollUntilVisible(directorFinder, 200,
        scrollable: find.byType(Scrollable).first);
    await tester.pump(const Duration(milliseconds: 500));
    await tester.tap(directorFinder);
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 500));

    final filterState = container.read(discoverFilterProvider);
    expect(filterState.personName, 'Christopher Nolan');
    expect(filterState.genreId, isNull,
        reason: 'the stale genre filter must be cleared, not combined with the new person filter');
    expect(filterState.genreName, isNull);
  });
}
