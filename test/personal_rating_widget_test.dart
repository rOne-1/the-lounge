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
  Future<MediaItem?> getMediaDetails(String id) async => items[id];

  @override
  Future<TvSeason?> getTvSeasonDetails(String tvId, int seasonNumber) async => null;
}

void main() {
  setUp(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  final testMovie = MediaItem(
    id: 'movie-rate-1',
    title: 'The Rating Test',
    type: MediaType.movie,
    rating: 7.5,
    overview: 'A movie about ratings.',
    genres: const ['Drama'],
  );

  Future<ProviderContainer> pumpDetail(
    WidgetTester tester,
    MediaItem item,
  ) async {
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

  // The Watched toggle sits below the hero image, past the default 800x600
  // test viewport. SingleChildScrollView (used here, not a lazy list) lays
  // out every child unconditionally, so the finder always exists in the
  // tree regardless of scroll offset -- the only real problem is its
  // on-screen *position*: too low (below y=600) misses the hit test
  // entirely, too high (tucked under DetailScreen's pinned AppBar, or
  // scrolled past y=0 into negative territory) does too. Converges to a
  // safe on-screen band by checking actual position and correcting,
  // rather than a single fixed-offset drag -- which would under-scroll the
  // first time this is called in a test and over-scroll on repeat calls
  // (e.g. re-toggling Watched off then on).
  Future<void> ensureSafelyVisible(WidgetTester tester, Finder finder) async {
    var center = tester.getCenter(finder);
    var guard = 0;
    while ((center.dy < 100 || center.dy > 550) && guard < 10) {
      final delta = center.dy > 550 ? -150.0 : 150.0;
      await tester.drag(find.byType(SingleChildScrollView).first, Offset(0, delta));
      await tester.pumpAndSettle();
      center = tester.getCenter(finder);
      guard++;
    }
  }

  Future<void> tapWatched(WidgetTester tester) async {
    final finder = find.text('Watched');
    await ensureSafelyVisible(tester, finder);
    await tester.tap(finder);
  }

  Future<void> tapVisible(WidgetTester tester, String text) async {
    final finder = find.text(text);
    await ensureSafelyVisible(tester, finder);
    await tester.tap(finder);
  }

  group('PERS-RATE-1: personal rating pill', () {
    testWidgets('does not appear for an un-watched title', (tester) async {
      await pumpDetail(tester, testMovie);

      expect(find.text('Rate it'), findsNothing);
      for (final rating in PersonalRating.values) {
        expect(find.text(rating.label), findsNothing);
      }
    });

    testWidgets('shows "Rate it" once the title is marked Watched', (tester) async {
      final container = await pumpDetail(tester, testMovie);

      container.read(mediaProvider.notifier).addToWatchedList(testMovie);
      await tester.pump(const Duration(milliseconds: 500));

      // The auto-prompt sheet also opens on this transition (covered in the
      // group below) -- dismiss it via Skip so the pill assertion below
      // reads the closed-sheet DetailScreen state.
      final skipFinder = find.text('Skip');
      if (skipFinder.evaluate().isNotEmpty) {
        await tester.tap(skipFinder);
        await tester.pumpAndSettle();
      }

      expect(find.text('Rate it'), findsOneWidget);
    });
  });

  group('PERS-RATE-1: auto-prompt on Watched transition', () {
    testWidgets('tapping Watched opens the rating sheet with "How was it?"', (tester) async {
      await pumpDetail(tester, testMovie);

      await tapWatched(tester);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      expect(find.text('How was it?'), findsOneWidget);
      for (final rating in PersonalRating.values) {
        expect(find.text(rating.label), findsOneWidget);
      }
      expect(find.text('Skip'), findsOneWidget);
    });

    testWidgets('tapping a tier writes a first-watch WatchRecord and closes the sheet',
        (tester) async {
      final container = await pumpDetail(tester, testMovie);

      await tapWatched(tester);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      await tester.tap(find.text('Loved it'));
      await tester.pumpAndSettle();

      expect(find.text('How was it?'), findsNothing);
      final history = container.read(mediaProvider).watchHistory[testMovie.id];
      expect(history, hasLength(1));
      expect(history!.first.rating, PersonalRating.loved);
      expect(history.first.isFirstWatch, isTrue);

      // Banner now reflects the rating instead of the "Rate it" invitation.
      expect(find.text('Your rating: Loved it'), findsOneWidget);
      expect(find.text('Rate it'), findsNothing);
    });

    testWidgets('tapping Skip dismisses without writing a record', (tester) async {
      final container = await pumpDetail(tester, testMovie);

      await tapWatched(tester);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      await tester.tap(find.text('Skip'));
      await tester.pumpAndSettle();

      expect(container.read(mediaProvider).watchHistory[testMovie.id], isNull);
      expect(find.text('Rate it'), findsOneWidget);
    });

    testWidgets('re-toggling Watched off then on does not re-prompt once already rated',
        (tester) async {
      final container = await pumpDetail(tester, testMovie);

      await tapWatched(tester);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));
      await tester.tap(find.text('Liked it'));
      await tester.pumpAndSettle();

      // Un-mark then re-mark Watched.
      await tapWatched(tester);
      await tester.pump(const Duration(milliseconds: 500));
      await tapWatched(tester);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      // No auto-prompt this time -- "How was it?" shouldn't reappear.
      expect(find.text('How was it?'), findsNothing);
      final history = container.read(mediaProvider).watchHistory[testMovie.id];
      expect(history, hasLength(1));
      expect(history!.first.rating, PersonalRating.liked);
    });
  });

  group('PERS-RATE-1: editing an existing rating via the pill', () {
    testWidgets('tapping the rating pill opens the sheet pre-selected, and Remove rating clears it',
        (tester) async {
      final container = await pumpDetail(tester, testMovie);

      container.read(mediaProvider.notifier).addToWatchedList(testMovie);
      container.read(mediaProvider.notifier).addWatchRecord(
            testMovie.id,
            WatchRecord(rating: PersonalRating.okay, isFirstWatch: true),
          );
      await tester.pump(const Duration(milliseconds: 500));

      await tapVisible(tester, 'Your rating: It was okay');
      await tester.pumpAndSettle();

      expect(find.text('Rate Movie'), findsOneWidget);
      expect(find.text('Remove rating'), findsOneWidget);

      await tester.tap(find.text('Remove rating'));
      await tester.pumpAndSettle();

      expect(container.read(mediaProvider).watchHistory[testMovie.id], isNull);
      expect(find.text('Rate it'), findsOneWidget);
    });
  });
}
