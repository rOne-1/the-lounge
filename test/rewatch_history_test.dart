import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:the_lounge/screens/detail_screen.dart';
import 'package:the_lounge/providers/media_provider.dart';
import 'package:the_lounge/providers/ambiance_provider.dart';
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

  final testMovie = MediaItem(
    id: 'movie-rewatch-1',
    title: 'The Rewatch Test',
    type: MediaType.movie,
    rating: 8.0,
    overview: 'A movie worth watching again.',
    genres: const ['Comedy'],
  );

  Future<ProviderContainer> pumpDetail(WidgetTester tester, MediaItem item) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        movieRepositoryProvider.overrideWithValue(_TestRepository({item.id: item})),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(home: DetailScreen(id: item.id, initialItem: item)),
      ),
    );
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 500));
    return container;
  }

  // Mirrors personal_rating_widget_test.dart's convergent-scroll helper:
  // SingleChildScrollView builds every child unconditionally, so the only
  // real problem is the target's on-screen position relative to the pinned
  // AppBar and viewport edges, not whether it exists in the tree yet.
  Future<void> ensureSafelyVisible(WidgetTester tester, Finder finder) async {
    var center = tester.getCenter(finder);
    var guard = 0;
    while ((center.dy < 100 || center.dy > 550) && guard < 10) {
      final delta = center.dy > 550 ? -150.0 : 150.0;
      await tester.drag(find.byType(Scrollable).first, Offset(0, delta));
      await tester.pumpAndSettle();
      center = tester.getCenter(finder);
      guard++;
    }
  }

  Future<void> tapSafely(WidgetTester tester, Finder finder) async {
    await ensureSafelyVisible(tester, finder);
    await tester.tap(finder);
  }

  group('PERS-REWATCH-1: Add Rewatch pill', () {
    testWidgets('does not appear with no watch history', (tester) async {
      await pumpDetail(tester, testMovie);
      expect(find.text('Add Rewatch'), findsNothing);
    });

    testWidgets('appears once the item has a WatchRecord', (tester) async {
      final container = await pumpDetail(tester, testMovie);
      container.read(mediaProvider.notifier).addWatchRecord(
            testMovie.id,
            WatchRecord(rating: PersonalRating.loved, isFirstWatch: true),
          );
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Add Rewatch'), findsOneWidget);
    });

    testWidgets('logging a rewatch appends a non-first-watch WatchRecord', (tester) async {
      final container = await pumpDetail(tester, testMovie);
      container.read(mediaProvider.notifier).addWatchRecord(
            testMovie.id,
            WatchRecord(
              date: DateTime(2025, 1, 1),
              rating: PersonalRating.loved,
              isFirstWatch: true,
            ),
          );
      await tester.pump(const Duration(milliseconds: 500));

      await tapSafely(tester, find.text('Add Rewatch'));
      await tester.pumpAndSettle();

      expect(find.text('Log a rewatch'), findsOneWidget);

      // Optionally pick a rating tier for the rewatch, then submit.
      await tester.tap(find.text('Liked it'));
      await tester.pump();
      await tester.tap(find.text('Log Rewatch'));
      await tester.pumpAndSettle();

      final history = container.read(mediaProvider).watchHistory[testMovie.id]!;
      expect(history, hasLength(2));
      expect(history[0].isFirstWatch, isTrue);
      expect(history[1].isFirstWatch, isFalse);
      expect(history[1].rating, PersonalRating.liked);
    });

    testWidgets('Cancel on the rewatch sheet does not add a record', (tester) async {
      final container = await pumpDetail(tester, testMovie);
      container.read(mediaProvider.notifier).addWatchRecord(
            testMovie.id,
            WatchRecord(rating: PersonalRating.loved, isFirstWatch: true),
          );
      await tester.pump(const Duration(milliseconds: 500));

      await tapSafely(tester, find.text('Add Rewatch'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(container.read(mediaProvider).watchHistory[testMovie.id], hasLength(1));
    });
  });

  group('PERS-REWATCH-1: Watch History timeline', () {
    testWidgets('renders nothing with no watch history', (tester) async {
      await pumpDetail(tester, testMovie);
      expect(find.text('Watch History'), findsNothing);
    });

    testWidgets('shows a collapsed header with count, expands to reveal labeled entries',
        (tester) async {
      final container = await pumpDetail(tester, testMovie);
      final notifier = container.read(mediaProvider.notifier);
      notifier.addWatchRecord(
        testMovie.id,
        WatchRecord(
          date: DateTime(2025, 1, 1),
          rating: PersonalRating.loved,
          isFirstWatch: true,
        ),
      );
      notifier.addWatchRecord(
        testMovie.id,
        WatchRecord(
          date: DateTime(2025, 6, 1),
          rating: PersonalRating.liked,
          isFirstWatch: false,
        ),
      );
      await tester.pump(const Duration(milliseconds: 500));

      final headerFinder = find.text('Watch History');
      expect(headerFinder, findsOneWidget);
      expect(find.text('(2)'), findsOneWidget);

      // Collapsed: entry rows not yet built.
      expect(find.text('1st Watch'), findsNothing);

      await tapSafely(tester, headerFinder);
      await tester.pumpAndSettle();

      expect(find.text('1st Watch'), findsOneWidget);
      expect(find.text('Rewatch 1'), findsOneWidget);
    });

    testWidgets('tapping a history row opens an edit sheet; Delete entry removes exactly that record',
        (tester) async {
      final container = await pumpDetail(tester, testMovie);
      final notifier = container.read(mediaProvider.notifier);
      final firstWatchAt = DateTime(2025, 1, 1);
      final rewatchAt = DateTime(2025, 6, 1);
      notifier.addWatchRecord(
        testMovie.id,
        WatchRecord(
          date: DateTime(2025, 1, 1),
          rating: PersonalRating.loved,
          isFirstWatch: true,
          recordedAt: firstWatchAt,
        ),
      );
      notifier.addWatchRecord(
        testMovie.id,
        WatchRecord(
          date: DateTime(2025, 6, 1),
          rating: PersonalRating.okay,
          isFirstWatch: false,
          recordedAt: rewatchAt,
        ),
      );
      await tester.pump(const Duration(milliseconds: 500));

      await tapSafely(tester, find.text('Watch History'));
      await tester.pumpAndSettle();

      await tapSafely(tester, find.text('Rewatch 1'));
      await tester.pumpAndSettle();

      expect(find.text('Delete entry'), findsOneWidget);

      await tester.tap(find.text('Delete entry'));
      await tester.pumpAndSettle();

      final history = container.read(mediaProvider).watchHistory[testMovie.id]!;
      expect(history, hasLength(1));
      expect(history.first.recordedAt, firstWatchAt);
    });
  });
}
