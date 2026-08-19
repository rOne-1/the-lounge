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

class _MixedLanguageRepository extends MockMovieRepository {
  DiscoverFilterParams? lastDiscoverParams;

  final _en = _movie('en1', 'English Movie', 'en');
  final _ja = _movie('ja1', 'Japanese Movie', 'ja');

  @override
  Future<List<MediaItem>> getTrendingMovies({int page = 1}) async => [_en, _ja];
  @override
  Future<List<MediaItem>> getPopularMovies({int page = 1}) async => [_en, _ja];
  @override
  Future<List<MediaItem>> getTopRatedMovies({int page = 1}) async => [_en, _ja];
  @override
  Future<List<MediaItem>> getUpcomingMovies({int page = 1}) async => [_en, _ja];
  @override
  Future<List<MediaItem>> getNowPlayingMovies({int page = 1, String? region}) async =>
      [_en, _ja];
  @override
  Future<List<MediaItem>> getTrendingTvShows({int page = 1}) async => [_en, _ja];
  @override
  Future<List<MediaItem>> getTopRatedTvShows({int page = 1}) async => [_en, _ja];
  @override
  Future<List<MediaItem>> getAiringTodayTvShows({int page = 1}) async => [_en, _ja];
  @override
  Future<List<MediaItem>> getOnTheAirTvShows({int page = 1}) async => [_en, _ja];

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
