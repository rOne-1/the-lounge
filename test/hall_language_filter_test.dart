import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:the_lounge/models/discover_filter_params.dart';
import 'package:the_lounge/models/media_item.dart';
import 'package:the_lounge/providers/ambiance_provider.dart';
import 'package:the_lounge/providers/hall_provider.dart';
import 'package:the_lounge/providers/media_provider.dart';
import 'package:the_lounge/providers/repository_provider.dart';
import 'package:the_lounge/repositories/mock_movie_repository.dart';
import 'package:the_lounge/widgets/hall_selector_sheet.dart';

/// A movie in English and one in Japanese for every fixed-list endpoint, so
/// tests can assert the Hall language lock actually narrows results rather
/// than just not crashing.
MediaItem _movie(String id, String title, String originalLanguage) => MediaItem(
      id: id,
      title: title,
      type: MediaType.movie,
      rating: 7.5,
      overview: '',
      genres: const [],
      originalLanguage: originalLanguage,
      releaseOrAirDate: DateTime(2026, 1, 1),
    );

/// LANG-2 (2nd pass, 2026-08-19): a real [TmdbMovieRepository] routes
/// through /discover with server-side with_original_language when given a
/// non-null `originalLanguage` (verified separately, at the actual HTTP
/// query-construction level, in tmdb_integration_test.dart). This mock
/// stands in for that behavior -- filtering its own return value by
/// `originalLanguage` when provided -- so tests here can verify the
/// *wiring*: that each of the 9 fixed-list providers actually passes the
/// Hall's locked language through to the repository call, rather than
/// silently dropping it (the actual bug class this whole rewrite targets).
class _MixedLanguageRepository extends MockMovieRepository {
  DiscoverFilterParams? lastDiscoverParams;

  /// Records the `originalLanguage` argument each of the 9 methods was
  /// last called with, keyed by method name -- lets a test assert the
  /// provider passed the Hall's lock through, not just that the returned
  /// data happens to look right.
  final Map<String, String?> capturedOriginalLanguages = {};

  final _en = _movie('en1', 'English Movie', 'en');
  final _ja = _movie('ja1', 'Japanese Movie', 'ja');

  List<MediaItem> _filtered(String methodName, String? originalLanguage) {
    capturedOriginalLanguages[methodName] = originalLanguage;
    if (originalLanguage == null || originalLanguage.isEmpty) return [_en, _ja];
    return [_en, _ja].where((m) => m.originalLanguage == originalLanguage).toList();
  }

  @override
  Future<List<MediaItem>> getTrendingMovies({int page = 1, String? originalLanguage}) async =>
      _filtered('getTrendingMovies', originalLanguage);
  @override
  Future<List<MediaItem>> getPopularMovies({int page = 1, String? originalLanguage}) async =>
      _filtered('getPopularMovies', originalLanguage);
  @override
  Future<List<MediaItem>> getTopRatedMovies({int page = 1, String? originalLanguage}) async =>
      _filtered('getTopRatedMovies', originalLanguage);
  @override
  Future<List<MediaItem>> getUpcomingMovies({int page = 1, String? region, String? originalLanguage}) async =>
      _filtered('getUpcomingMovies', originalLanguage);
  @override
  Future<List<MediaItem>> getNowPlayingMovies({int page = 1, String? region, String? originalLanguage}) async =>
      _filtered('getNowPlayingMovies', originalLanguage);
  @override
  Future<List<MediaItem>> getTrendingTvShows({int page = 1, String? originalLanguage}) async =>
      _filtered('getTrendingTvShows', originalLanguage);
  @override
  Future<List<MediaItem>> getTopRatedTvShows({int page = 1, String? originalLanguage}) async =>
      _filtered('getTopRatedTvShows', originalLanguage);
  @override
  Future<List<MediaItem>> getAiringTodayTvShows({int page = 1, String? originalLanguage}) async =>
      _filtered('getAiringTodayTvShows', originalLanguage);
  @override
  Future<List<MediaItem>> getOnTheAirTvShows({int page = 1, String? originalLanguage}) async =>
      _filtered('getOnTheAirTvShows', originalLanguage);

  @override
  Future<List<MediaItem>> discoverMedia({
    required bool isMovies,
    required DiscoverFilterParams params,
    int page = 1,
  }) async {
    lastDiscoverParams = params;
    if (params.originalLanguage == null) return [_en, _ja];
    return [_en, _ja].where((m) => m.originalLanguage == params.originalLanguage).toList();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SharedPreferences prefs;
  late _MixedLanguageRepository repo;

  setUp(() async {
    GoogleFonts.config.allowRuntimeFetching = false;
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    repo = _MixedLanguageRepository();
  });

  group('LANG-1: HallNotifier.updateHallLanguage', () {
    test('sets a language lock on the target hall and persists it', () async {
      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          movieRepositoryProvider.overrideWithValue(repo),
        ],
      );
      addTearDown(container.dispose);

      await container
          .read(hallProvider.notifier)
          .updateHallLanguage('common', 'hi', 'Hindi');

      expect(container.read(hallProvider).activeHall.lockedLanguageCode, 'hi');
      expect(container.read(hallProvider).activeHall.lockedLanguageName, 'Hindi');
      expect(container.read(activeHallSpaceProvider).lockedLanguageCode, 'hi');
    });

    test('passing null clears an existing lock back to unrestricted', () async {
      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          movieRepositoryProvider.overrideWithValue(repo),
        ],
      );
      addTearDown(container.dispose);

      await container
          .read(hallProvider.notifier)
          .updateHallLanguage('common', 'ko', 'Korean');
      expect(container.read(hallProvider).activeHall.lockedLanguageCode, 'ko');

      await container.read(hallProvider.notifier).updateHallLanguage('common', null, null);
      expect(container.read(hallProvider).activeHall.lockedLanguageCode, isNull);
    });

    test('only updates the targeted hall, leaving others unlocked', () async {
      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          movieRepositoryProvider.overrideWithValue(repo),
        ],
      );
      addTearDown(container.dispose);

      await container
          .read(hallProvider.notifier)
          .updateHallLanguage('custom_1', 'ja', 'Japanese');

      final halls = container.read(hallProvider).halls;
      final mezzanine = halls.firstWhere((h) => h.id == 'custom_1');
      final grand = halls.firstWhere((h) => h.id == 'common');
      expect(mezzanine.lockedLanguageCode, 'ja');
      expect(grand.lockedLanguageCode, isNull);
    });
  });

  group('LANG-2: fixed-list providers (Lobby/Calendar surfaces) respect the Hall language lock', () {
    test('trendingMoviesProvider returns all languages when the hall is unrestricted', () async {
      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          movieRepositoryProvider.overrideWithValue(repo),
        ],
      );
      addTearDown(container.dispose);

      final result = await container.read(trendingMoviesProvider.future);
      expect(result.map((m) => m.id), containsAll(['en1', 'ja1']));
    });

    test('trendingMoviesProvider narrows to the locked language once the hall has one', () async {
      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          movieRepositoryProvider.overrideWithValue(repo),
        ],
      );
      addTearDown(container.dispose);

      await container.read(hallProvider.notifier).updateHallLanguage('common', 'ja', 'Japanese');

      final result = await container.read(trendingMoviesProvider.future);
      expect(result.map((m) => m.id), ['ja1']);
    });

    test('popularMoviesProvider, topRatedMoviesProvider, and upcomingMoviesProvider all '
        'narrow to the locked language (systemic, not one provider patched in isolation)', () async {
      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          movieRepositoryProvider.overrideWithValue(repo),
        ],
      );
      addTearDown(container.dispose);

      await container.read(hallProvider.notifier).updateHallLanguage('common', 'en', 'English');

      expect((await container.read(popularMoviesProvider.future)).map((m) => m.id), ['en1']);
      expect((await container.read(topRatedMoviesProvider.future)).map((m) => m.id), ['en1']);
      expect((await container.read(upcomingMoviesProvider.future)).map((m) => m.id), ['en1']);
    });

    test('every one of the 9 fixed-list providers passes the Hall\'s locked '
        'language through to its repository call (2nd-pass redesign,  '
        '2026-08-19: the 1st-pass fix client-side-filtered/backfilled a '
        'globally-weighted, English-dominated raw list, which still failed '
        'to surface real regional-language content -- fixed by pushing the '
        'filter down to the repository layer, which routes through '
        '/discover with server-side with_original_language instead)', () async {
      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          movieRepositoryProvider.overrideWithValue(repo),
        ],
      );
      addTearDown(container.dispose);

      await container.read(hallProvider.notifier).updateHallLanguage('common', 'hi', 'Hindi');

      await container.read(trendingMoviesProvider.future);
      await container.read(trendingTvShowsProvider.future);
      await container.read(popularMoviesProvider.future);
      await container.read(topRatedMoviesProvider.future);
      await container.read(topRatedTvShowsProvider.future);
      await container.read(nowPlayingMoviesProvider.future);
      await container.read(airingTodayTvShowsProvider.future);
      await container.read(upcomingMoviesProvider.future);
      await container.read(onTheAirTvShowsProvider.future);

      expect(
        repo.capturedOriginalLanguages,
        {
          'getTrendingMovies': 'hi',
          'getTrendingTvShows': 'hi',
          'getPopularMovies': 'hi',
          'getTopRatedMovies': 'hi',
          'getTopRatedTvShows': 'hi',
          'getNowPlayingMovies': 'hi',
          'getAiringTodayTvShows': 'hi',
          'getUpcomingMovies': 'hi',
          'getOnTheAirTvShows': 'hi',
        },
      );
    });

    test('the 9 fixed-list providers pass null through when the hall is '
        'unrestricted, not an empty string or a stale lock', () async {
      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          movieRepositoryProvider.overrideWithValue(repo),
        ],
      );
      addTearDown(container.dispose);

      await container.read(nowPlayingMoviesProvider.future);
      await container.read(onTheAirTvShowsProvider.future);

      expect(repo.capturedOriginalLanguages['getNowPlayingMovies'], isNull);
      expect(repo.capturedOriginalLanguages['getOnTheAirTvShows'], isNull);
    });
  });

  group('LANG-2: discoverMedia (Discover/Search surfaces) receives with_original_language server-side', () {
    test('discoverMediaProvider passes the hall\'s locked language through as originalLanguage', () async {
      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          movieRepositoryProvider.overrideWithValue(repo),
        ],
      );
      addTearDown(container.dispose);

      await container.read(hallProvider.notifier).updateHallLanguage('common', 'ja', 'Japanese');

      final result = await container.read(discoverMediaProvider(true).future);
      expect(repo.lastDiscoverParams?.originalLanguage, 'ja');
      expect(result.map((m) => m.id), ['ja1']);
    });

    test('applyHallLanguageLock overrides the user\'s own filter selection, taking precedence', () {
      const userChoice = DiscoverFilterParams(originalLanguage: 'fr');
      final effective = applyHallLanguageLock(userChoice, 'hi');
      expect(effective.originalLanguage, 'hi');
    });

    test('applyHallLanguageLock is a no-op when the hall is unrestricted', () {
      const userChoice = DiscoverFilterParams(originalLanguage: 'fr');
      final effective = applyHallLanguageLock(userChoice, null);
      expect(effective.originalLanguage, 'fr');
    });
  });

  group('LANG-1: Hall Selector Sheet language picker', () {
    testWidgets('picking a language in the customize dialog locks the active hall', (tester) async {
      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          movieRepositoryProvider.overrideWithValue(repo),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(body: HallSelectorSheet()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final editButtons = find.byIcon(Icons.edit_outlined);
      expect(editButtons, findsWidgets);
      await tester.tap(editButtons.first);
      await tester.pumpAndSettle();

      expect(find.text('LANGUAGE LOCK'), findsOneWidget);
      expect(find.text('All Languages'), findsOneWidget);

      await tester.scrollUntilVisible(
        find.text('Japanese'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Japanese'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(container.read(hallProvider).activeHall.lockedLanguageCode, 'ja');
      expect(container.read(hallProvider).activeHall.lockedLanguageName, 'Japanese');
    });

    testWidgets('picking "All Languages" clears an existing lock', (tester) async {
      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          movieRepositoryProvider.overrideWithValue(repo),
        ],
      );
      addTearDown(container.dispose);
      await container.read(hallProvider.notifier).updateHallLanguage('common', 'ko', 'Korean');

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(body: HallSelectorSheet()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.edit_outlined).first);
      await tester.pumpAndSettle();

      await tester.tap(find.text('All Languages'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(container.read(hallProvider).activeHall.lockedLanguageCode, isNull);
    });
  });
}
