import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:the_lounge/screens/rewatch_vault_screen.dart';
import 'package:the_lounge/screens/detail_screen.dart';
import 'package:the_lounge/providers/media_provider.dart';
import 'package:the_lounge/providers/ambiance_provider.dart';
import 'package:the_lounge/providers/navigation_provider.dart';
import 'package:the_lounge/models/media_item.dart';
import 'package:the_lounge/repositories/mock_movie_repository.dart';

class _TestRepository extends MockMovieRepository {
  final Map<String, MediaItem> items;
  _TestRepository(this.items);

  @override
  Future<MediaItem?> getMediaDetails(String id, {String? region}) async => items[id];

  @override
  Future<TvSeason?> getTvSeasonDetails(String tvId, int seasonNumber) async => null;
}

void main() {
  setUp(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  final rewatchedMovie = MediaItem(
    id: 'movie-rewatch-1',
    title: 'Rewatched Movie',
    type: MediaType.movie,
    rating: 8.0,
    overview: 'A movie worth watching again.',
    genres: const ['Drama'],
  );

  final neverRewatchedMovie = MediaItem(
    id: 'movie-once-1',
    title: 'Watched Once',
    type: MediaType.movie,
    rating: 7.0,
    overview: 'Only watched once.',
    genres: const ['Comedy'],
  );

  Future<ProviderContainer> pumpVault(WidgetTester tester, {List<MediaItem> extraItems = const []}) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        movieRepositoryProvider.overrideWithValue(
          _TestRepository({
            rewatchedMovie.id: rewatchedMovie,
            neverRewatchedMovie.id: neverRewatchedMovie,
            for (final item in extraItems) item.id: item,
          }),
        ),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: RewatchVaultScreen()),
      ),
    );
    await tester.pumpAndSettle();
    return container;
  }

  group('PERS-SPACE-1: RewatchVaultScreen', () {
    testWidgets('shows the empty state with no rewatches logged', (tester) async {
      await pumpVault(tester);
      expect(find.text('No rewatches yet'), findsOneWidget);
    });

    testWidgets('a title with only a first-watch record does not appear', (tester) async {
      final container = await pumpVault(tester);
      container.read(mediaProvider.notifier).addWatchRecord(
            neverRewatchedMovie.id,
            WatchRecord(rating: PersonalRating.liked, isFirstWatch: true),
          );
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: RewatchVaultScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('No rewatches yet'), findsOneWidget);
      expect(find.text(neverRewatchedMovie.title), findsNothing);
    });

    testWidgets('a title with a rewatch record appears with its rewatch count', (tester) async {
      final container = await pumpVault(tester);
      container.read(mediaProvider.notifier).addWatchRecord(
            rewatchedMovie.id,
            WatchRecord(
              date: DateTime(2025, 1, 1),
              rating: PersonalRating.loved,
              isFirstWatch: true,
            ),
          );
      container.read(mediaProvider.notifier).addWatchRecord(
            rewatchedMovie.id,
            WatchRecord(
              date: DateTime(2025, 6, 1),
              rating: PersonalRating.loved,
              isFirstWatch: false,
            ),
          );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: RewatchVaultScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(rewatchedMovie.title), findsOneWidget);
      expect(find.textContaining('Rewatched 1 time'), findsOneWidget);
    });

    testWidgets('only shows rewatches for titles matching the active Movies/TV toggle',
        (tester) async {
      final rewatchedShow = MediaItem(
        id: 'tv-rewatch-1',
        title: 'Rewatched Show',
        type: MediaType.tv,
        rating: 8.5,
        overview: 'A show worth watching again.',
        genres: const ['Sci-Fi'],
      );
      final container = await pumpVault(tester);
      // Known synchronously (in a status pile) so the type filter can apply
      // without waiting on the async mediaDetailsProvider fallback.
      container.read(mediaProvider.notifier).addToWatchedList(rewatchedMovie);
      container.read(mediaProvider.notifier).addToWatchedList(rewatchedShow);
      container.read(mediaProvider.notifier).addWatchRecord(
            rewatchedMovie.id,
            WatchRecord(isFirstWatch: true),
          );
      container.read(mediaProvider.notifier).addWatchRecord(
            rewatchedMovie.id,
            WatchRecord(isFirstWatch: false),
          );
      container.read(mediaProvider.notifier).addWatchRecord(
            rewatchedShow.id,
            WatchRecord(isFirstWatch: true),
          );
      container.read(mediaProvider.notifier).addWatchRecord(
            rewatchedShow.id,
            WatchRecord(isFirstWatch: false),
          );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: RewatchVaultScreen()),
        ),
      );
      await tester.pumpAndSettle();

      // Default activeMediaType is movies -- no explicit override needed.
      expect(find.text(rewatchedMovie.title), findsOneWidget);
      expect(find.text(rewatchedShow.title), findsNothing);
    });

    testWidgets('tapping a row navigates to DetailScreen', (tester) async {
      final container = await pumpVault(tester);
      container.read(mediaProvider.notifier).addWatchRecord(
            rewatchedMovie.id,
            WatchRecord(isFirstWatch: true),
          );
      container.read(mediaProvider.notifier).addWatchRecord(
            rewatchedMovie.id,
            WatchRecord(isFirstWatch: false),
          );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: RewatchVaultScreen()),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text(rewatchedMovie.title));
      await tester.pumpAndSettle();

      expect(find.byType(DetailScreen), findsOneWidget);
    });
  });

  group('FEAT-REWATCH-2: empty-state CTA', () {
    testWidgets('the empty state has a Discover Titles CTA that switches the active tab',
        (tester) async {
      final container = await pumpVault(tester);

      expect(find.text('No rewatches yet'), findsOneWidget);
      expect(find.text('Discover Titles'), findsOneWidget);
      expect(container.read(navigationProvider).currentTab, isNot(AppTab.discover));

      await tester.tap(find.text('Discover Titles'));
      await tester.pump();

      expect(container.read(navigationProvider).currentTab, equals(AppTab.discover));
    });
  });

  group('FEAT-REWATCH-1: hero summary card & secondary sort', () {
    testWidgets('hero card shows the aggregate rewatch count and the most-rewatched title',
        (tester) async {
      // rewatchedMovie: rewatched twice. A second, once-rewatched movie is
      // added so "most rewatched" has a real winner to pick between.
      final onceRewatchedMovie = MediaItem(
        id: 'movie_once_rewatch',
        title: 'Once Rewatched',
        type: MediaType.movie,
        rating: 6.5,
        overview: '',
        genres: const [],
      );
      final container = await pumpVault(tester, extraItems: [onceRewatchedMovie]);
      final notifier = container.read(mediaProvider.notifier);

      notifier.addToWatchedList(rewatchedMovie);
      notifier.addToWatchedList(onceRewatchedMovie);
      notifier.addWatchRecord(rewatchedMovie.id, WatchRecord(isFirstWatch: true));
      notifier.addWatchRecord(rewatchedMovie.id, WatchRecord(isFirstWatch: false));
      notifier.addWatchRecord(rewatchedMovie.id, WatchRecord(isFirstWatch: false));
      notifier.addWatchRecord(onceRewatchedMovie.id, WatchRecord(isFirstWatch: true));
      notifier.addWatchRecord(onceRewatchedMovie.id, WatchRecord(isFirstWatch: false));

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: RewatchVaultScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('3 rewatches logged'), findsOneWidget);
      expect(find.textContaining('Most rewatched: ${rewatchedMovie.title}'), findsOneWidget);
    });

    testWidgets('the sort dropdown reorders the rewatch list', (tester) async {
      // Ids are pre-normalized ('movie_' prefixed, per normalizeMediaId in
      // media_item.dart) so addToWatchedList's internal normalization is a
      // no-op and the key it stores under matches the raw id addWatchRecord
      // below uses -- otherwise _findKnownItem can't resolve either title
      // (a real key-mismatch trap in this codebase's id handling, not
      // specific to this test).
      final aTitleMovie = MediaItem(
        id: 'movie_alpha',
        title: 'Alpha Movie',
        type: MediaType.movie,
        rating: 6.0,
        overview: '',
        genres: const [],
      );
      final zTitleMovie = MediaItem(
        id: 'movie_zeta',
        title: 'Zeta Movie',
        type: MediaType.movie,
        rating: 6.0,
        overview: '',
        genres: const [],
      );
      final container = await pumpVault(tester, extraItems: [aTitleMovie, zTitleMovie]);
      final notifier = container.read(mediaProvider.notifier);

      notifier.addToWatchedList(aTitleMovie);
      notifier.addToWatchedList(zTitleMovie);
      // Zeta rewatched more recently and more often than Alpha, so the
      // default (Most Recent) and Most Rewatched sorts should both surface
      // it first, while Title A-Z should surface Alpha first instead.
      notifier.addWatchRecord(aTitleMovie.id, WatchRecord(date: DateTime(2025, 1, 1), isFirstWatch: true));
      notifier.addWatchRecord(aTitleMovie.id, WatchRecord(date: DateTime(2025, 1, 2), isFirstWatch: false));
      notifier.addWatchRecord(zTitleMovie.id, WatchRecord(date: DateTime(2025, 6, 1), isFirstWatch: true));
      notifier.addWatchRecord(zTitleMovie.id, WatchRecord(date: DateTime(2025, 6, 2), isFirstWatch: false));
      notifier.addWatchRecord(zTitleMovie.id, WatchRecord(date: DateTime(2025, 6, 3), isFirstWatch: false));

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: RewatchVaultScreen()),
        ),
      );
      await tester.pumpAndSettle();

      // Assert via on-screen row position (robust to the flutter_animate
      // wrapping around each row): Zeta's title should sit above Alpha's
      // under Most Recent (the default sort).
      final zetaCenter = tester.getCenter(find.text(zTitleMovie.title));
      final alphaCenter = tester.getCenter(find.text(aTitleMovie.title));
      expect(zetaCenter.dy, lessThan(alphaCenter.dy));

      // Switch to Title A-Z -- Alpha should now be above Zeta.
      await tester.tap(find.text('Most Recent'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Title A-Z'));
      await tester.pumpAndSettle();

      final zetaCenterAfter = tester.getCenter(find.text(zTitleMovie.title));
      final alphaCenterAfter = tester.getCenter(find.text(aTitleMovie.title));
      expect(alphaCenterAfter.dy, lessThan(zetaCenterAfter.dy));
    });
  });

  group('outstanding_issues_notepad.md item 61: id-normalization mismatch', () {
    testWidgets(
        'a raw (non-normalized) id resolves synchronously via _findKnownItem, no async fallback needed',
        (tester) async {
      // Regression for the exact bug this item documented: before the fix,
      // addWatchRecord stored watchHistory under the caller's raw,
      // hyphenated id while addToWatchedList stored the shelf entry under
      // the movie_-prefixed normalized id, so _findKnownItem (looking up
      // by the watchHistory key) never found the shelf item and both the
      // hero card and the row silently rendered blank. No extraItems/mock
      // repository fallback is registered here on purpose -- if resolution
      // regresses, this test can only pass via the async path, which it
      // deliberately can't reach (no repository entry for this id).
      const rawId = 'unprefixed-raw-id';
      const rawItem = MediaItem(
        id: rawId,
        title: 'Raw Id Title',
        type: MediaType.movie,
        rating: 7.5,
        overview: '',
        genres: [],
      );
      final container = await pumpVault(tester);
      final notifier = container.read(mediaProvider.notifier);

      notifier.addToWatchedList(rawItem);
      notifier.addWatchRecord(rawId, WatchRecord(isFirstWatch: true));
      notifier.addWatchRecord(rawId, WatchRecord(isFirstWatch: false));

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: RewatchVaultScreen()),
        ),
      );
      await tester.pump(); // no pumpAndSettle: proves it's already resolved, not just eventually

      expect(find.text('Raw Id Title'), findsOneWidget);
      expect(find.textContaining('Most rewatched: Raw Id Title'), findsOneWidget);
    });
  });
}
