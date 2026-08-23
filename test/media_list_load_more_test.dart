// Regression coverage for B8/TF-23: "Load more" broken in Now Playing, and
// no explicit end-of-list state when a list genuinely exhausts.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:the_lounge/models/media_item.dart';
import 'package:the_lounge/providers/hall_provider.dart';
import 'package:the_lounge/providers/media_provider.dart';
import 'package:the_lounge/providers/ambiance_provider.dart';
import 'package:the_lounge/repositories/mock_movie_repository.dart';
import 'package:the_lounge/screens/lobby_screen.dart';
import 'package:the_lounge/screens/media_list_screen.dart';

MediaItem _movie(String id, String title, [String? originalLanguage]) => MediaItem(
      id: id,
      title: title,
      type: MediaType.movie,
      rating: 7.0,
      overview: '',
      genres: const [],
      originalLanguage: originalLanguage,
    );

/// Captures the `region` argument on every getNowPlayingMovies call and
/// serves 3 pages of distinct, non-overlapping items so the test can tell
/// pages apart and detect a premature/incorrect exhaustion.
class _RegionAwareRepository extends MockMovieRepository {
  final List<String?> capturedRegions = [];

  @override
  Future<List<MediaItem>> getNowPlayingMovies({
    int page = 1,
    String? region,
    String? originalLanguage,
  }) async {
    capturedRegions.add(region);
    switch (page) {
      case 1:
        return [_movie('np1', 'Now Playing One')];
      case 2:
        return [_movie('np2', 'Now Playing Two')];
      default:
        return [];
    }
  }

  @override
  Future<List<MediaItem>> getTrendingMovies({int page = 1, String? originalLanguage}) async =>
      page == 1 ? [_movie('t1', 'Trending One')] : [];

  @override
  Future<List<MediaItem>> getPopularMovies({int page = 1, String? originalLanguage}) async => [];

  @override
  Future<List<MediaItem>> getTopRatedMovies({int page = 1, String? originalLanguage}) async => [];

  @override
  Future<List<MediaItem>> getUpcomingMovies({int page = 1, String? region, String? originalLanguage}) async => [];

  @override
  Future<List<MediaItem>> getTrendingTvShows({int page = 1, String? originalLanguage}) async => [];

  @override
  Future<List<MediaItem>> getTopRatedTvShows({int page = 1, String? originalLanguage}) async => [];

  @override
  Future<List<MediaItem>> getAiringTodayTvShows({int page = 1, String? originalLanguage}) async => [];

  @override
  Future<List<MediaItem>> getOnTheAirTvShows({int page = 1, String? originalLanguage}) async => [];
}

/// Dev-reported 2026-08-19 (related bug found while investigating the
/// Lobby-rail regression): the initial itemsProvider fetch enforces a
/// Hall's language lock, but "Load More" called the raw repository
/// directly and let wrong-language items leak in from page 2 onward.
/// Page 1 is entirely the locked language; page 2 deliberately mixes in a
/// wrong-language item so a test only passes if Load More itself filters.
class _MixedLanguagePagedRepository extends MockMovieRepository {
  @override
  Future<List<MediaItem>> getTrendingMovies({int page = 1, String? originalLanguage}) async {
    switch (page) {
      case 1:
        return [_movie('t-hi-1', 'Hindi One', 'hi')];
      case 2:
        return [_movie('t-hi-2', 'Hindi Two', 'hi'), _movie('t-en-1', 'English One', 'en')];
      default:
        return [];
    }
  }
}

void main() {
  setUp(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  testWidgets(
      'Now Playing "See all" -> Load More keeps using the user\'s watch-providers '
      'region on every page, not just the first (B8/TF-23)',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final repo = _RegionAwareRepository();

    final container = ProviderContainer(
      overrides: [
        movieRepositoryProvider.overrideWithValue(repo),
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
    );
    addTearDown(container.dispose);

    // Non-US region: the bug this regression test targets was `_loadMore`
    // silently falling back to the repository's 'US' default on every page
    // after the first, regardless of this setting.
    await container.read(mediaProvider.notifier).setWatchProvidersCountry('IN');

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: LobbyScreen(enableAnimation: false),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final nowPlayingRail = find.ancestor(
      of: find.text('Now Playing'),
      matching: find.byType(MediaRail),
    );
    expect(nowPlayingRail, findsOneWidget);

    final seeAllButton = find.descendant(
      of: nowPlayingRail,
      matching: find.text('See all'),
    );
    await tester.scrollUntilVisible(
      seeAllButton,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(seeAllButton);
    await tester.pumpAndSettle();

    expect(find.byType(MediaListScreen), findsOneWidget);
    expect(find.text('Now Playing One'), findsOneWidget);
    // Page 1 (the initial itemsProvider load) already used the right region.
    expect(repo.capturedRegions, equals(['IN']));

    await tester.tap(find.text('Load More (Page 2)'));
    await tester.pumpAndSettle();

    expect(find.text('Now Playing Two'), findsOneWidget);
    // Page 2, fetched via the fixed fetchPage wiring, must match.
    expect(repo.capturedRegions, equals(['IN', 'IN']));
    expect(find.text('You\'ve reached the end'), findsNothing);

    // Page 3 is empty -- the list is now genuinely exhausted.
    await tester.tap(find.text('Load More (Page 3)'));
    await tester.pumpAndSettle();

    expect(repo.capturedRegions, equals(['IN', 'IN', 'IN']));
    expect(find.text('You\'ve reached the end'), findsOneWidget);
    expect(find.textContaining('Load More'), findsNothing);
  });

  testWidgets(
      'Shows "You\'ve reached the end" even when the very first Load More tap '
      'exhausts the list (never advances past page 1)',
      (WidgetTester tester) async {
    final repo = _RegionAwareRepository();
    final container = ProviderContainer(
      overrides: [movieRepositoryProvider.overrideWithValue(repo)],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: Scaffold(
            body: MediaListScreen(
              title: 'Trending',
              itemsProvider: FutureProvider((ref) => repo.getTrendingMovies()),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Trending One'), findsOneWidget);
    expect(find.text('Load More (Page 2)'), findsOneWidget);

    await tester.tap(find.text('Load More (Page 2)'));
    await tester.pumpAndSettle();

    expect(find.text('You\'ve reached the end'), findsOneWidget);
    expect(find.textContaining('Load More'), findsNothing);
  });

  testWidgets(
      'Load More respects an active Hall language lock instead of leaking '
      'wrong-language items in from page 2+ (dev-reported bug, 2026-08-19)',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final repo = _MixedLanguagePagedRepository();

    final container = ProviderContainer(
      overrides: [
        movieRepositoryProvider.overrideWithValue(repo),
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
    );
    addTearDown(container.dispose);

    await container.read(hallProvider.notifier).updateHallLanguage('common', 'hi', 'Hindi');

    // Deliberately a plain single-page FutureProvider here, NOT
    // trendingMoviesProvider -- that provider's own initial fetch already
    // backfills across pages (the other bugfix above), which would pull
    // page 2's Hindi item in before any "Load More" tap and defeat the
    // point of this test: isolating whether Load More itself, in
    // isolation, still respects the lock on pages it fetches directly.
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: Scaffold(
            body: MediaListScreen(
              title: 'Trending',
              itemsProvider: FutureProvider((ref) => repo.getTrendingMovies()),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Hindi One'), findsOneWidget);
    expect(find.text('Load More (Page 2)'), findsOneWidget);

    await tester.tap(find.text('Load More (Page 2)'));
    await tester.pumpAndSettle();

    // The English item on page 2 must be filtered out; the Hindi one kept.
    expect(find.text('Hindi Two'), findsOneWidget);
    expect(find.text('English One'), findsNothing);
  });
}
