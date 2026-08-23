// Regression coverage for DATA-2: DetailScreen's network pills were
// previously inert Containers with no onTap handler. Tapping one now
// filters Search by that network, using the same discoverFilterProvider
// wiring already relied on by the Networks accordion in search_screen.dart.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:the_lounge/screens/detail_screen.dart';
import 'package:the_lounge/screens/search_screen.dart';
import 'package:the_lounge/providers/media_provider.dart';
import 'package:the_lounge/providers/ambiance_provider.dart';
import 'package:the_lounge/models/media_item.dart';
import 'package:the_lounge/models/discover_filter_params.dart';
import 'package:the_lounge/repositories/mock_movie_repository.dart';

class _NetworkTestRepository extends MockMovieRepository {
  final MediaItem item;

  _NetworkTestRepository(this.item);

  @override
  Future<MediaItem?> getMediaDetails(String id) async => item;

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

  const testShow = MediaItem(
    id: 'data2-show',
    title: 'Network Test Show',
    type: MediaType.tv,
    rating: 8.0,
    overview: 'Overview',
    genres: ['Drama'],
    networks: [MediaNetwork(id: 49, name: 'HBO')],
  );

  testWidgets('tapping a network pill filters Search by that network',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [
        movieRepositoryProvider.overrideWithValue(_NetworkTestRepository(testShow)),
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
    );
    addTearDown(container.dispose);

    expect(container.read(discoverFilterProvider).tvNetworkId, isNull);

    // DetailScreen has a continuously-animating backdrop glow, so
    // pumpAndSettle() never terminates here -- bounded pumps instead,
    // matching detail_screen_test.dart's own convention.
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: DetailScreen(id: 'data2-show'),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 500));

    // BETA3-PERF-1: the network pill is below the fold, lazily built by
    // the sliver list -- scrollUntilVisible (not ensureVisible, which
    // requires the element to already exist) brings it into range first.
    final hboFinder = find.text('HBO');
    await tester.scrollUntilVisible(hboFinder, 200,
        scrollable: find.byType(Scrollable).first);
    await tester.pump(const Duration(milliseconds: 500));
    await tester.tap(hboFinder);
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byType(SearchScreen), findsOneWidget);
    final filterState = container.read(discoverFilterProvider);
    expect(filterState.tvNetworkId, equals(49));
    expect(filterState.tvNetworkName, equals('HBO'));
  });
}
