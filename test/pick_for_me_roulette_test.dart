import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:the_lounge/widgets/pick_for_me_roulette_sheet.dart';
import 'package:the_lounge/screens/detail_screen.dart';
import 'package:the_lounge/providers/media_provider.dart';
import 'package:the_lounge/providers/ambiance_provider.dart';
import 'package:the_lounge/models/media_item.dart';
import 'package:the_lounge/repositories/mock_movie_repository.dart';

void main() {
  setUp(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  // Long-runtime, Hulu, Drama -- kept on the Watchlist itself.
  const watchMovie = MediaItem(
    id: 'movie_watch_1',
    title: 'The Long Drama',
    type: MediaType.movie,
    rating: 7.5,
    overview: '',
    genres: ['Drama'],
    runtime: 150,
    watchProviders: ['Hulu'],
  );

  // Short-runtime, Netflix, Comedy -- Saved (Maybe) only, not on Watchlist.
  const maybeMovie = MediaItem(
    id: 'movie_maybe_1',
    title: 'The Short Comedy',
    type: MediaType.movie,
    rating: 6.5,
    overview: '',
    genres: ['Comedy'],
    runtime: 85,
    watchProviders: ['Netflix'],
  );

  const watchShow = MediaItem(
    id: 'tv_watch_1',
    title: 'A Watchlisted Show',
    type: MediaType.tv,
    rating: 8.0,
    overview: '',
    genres: ['Drama'],
  );

  Future<ProviderContainer> pumpRoulette(WidgetTester tester) async {
    // The sheet's full filter-chip stack (Type/Runtime/Service/Mood) plus
    // the curtain and result actions overflows the default 800x600 test
    // viewport -- taller, not scrolled-to, in a real showModalBottomSheet
    // this is unconstrained the same way; widen the viewport instead of
    // asserting through a scroll that doesn't reflect real usage.
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        movieRepositoryProvider.overrideWithValue(MockMovieRepository()),
      ],
    );
    addTearDown(container.dispose);

    final notifier = container.read(mediaProvider.notifier);
    notifier.addToWatchlist(watchMovie);
    notifier.addToMaybeList(maybeMovie);
    notifier.addToWatchlist(watchShow);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: Scaffold(body: PickForMeRouletteSheet()),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return container;
  }

  group('CRAFT-ROULETTE-1: filter chips', () {
    testWidgets('renders Type/Runtime chips, plus Service/Mood chips derived from the pool',
        (tester) async {
      await pumpRoulette(tester);

      expect(find.text('Movies'), findsOneWidget);
      expect(find.text('TV Shows'), findsOneWidget);
      expect(find.text('Under 90m'), findsOneWidget);
      expect(find.text('Under 120m'), findsOneWidget);
      expect(find.text('Netflix'), findsOneWidget);
      expect(find.text('Hulu'), findsOneWidget);
      expect(find.text('Comedy'), findsOneWidget);
      expect(find.text('Drama'), findsOneWidget);
    });

    testWidgets('Movies is the default type, so the TV-only show is not in the pool',
        (tester) async {
      await pumpRoulette(tester);

      await tester.tap(find.text('Spin the Reel'));
      await tester.pumpAndSettle();
      expect(find.text(watchShow.title), findsNothing);

      for (var i = 0; i < 5; i++) {
        await tester.tap(find.text('Roll Again'));
        await tester.pumpAndSettle();
        expect(find.text(watchShow.title), findsNothing);
      }
    });
  });

  group('CRAFT-ROULETTE-1: spin and reveal', () {
    testWidgets('tapping Spin the Reel reveals a result with Watch Now / Roll Again actions',
        (tester) async {
      await pumpRoulette(tester);

      expect(find.text('Spin the Reel'), findsOneWidget);
      expect(find.text('Watch Now'), findsNothing);

      await tester.tap(find.text('Spin the Reel'));
      await tester.pumpAndSettle();

      expect(find.text('Watch Now'), findsOneWidget);
      expect(find.text('Roll Again'), findsOneWidget);
      expect(find.text('Spin the Reel'), findsNothing);
    });

    testWidgets('tapping Watch Now navigates to DetailScreen', (tester) async {
      await pumpRoulette(tester);

      await tester.tap(find.text('Spin the Reel'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Watch Now'));
      await tester.pumpAndSettle();

      expect(find.byType(DetailScreen), findsOneWidget);
    });
  });

  group('CRAFT-ROULETTE-1: filters pool accurately', () {
    testWidgets('Runtime "Under 90m" narrows the pool to only the short title', (tester) async {
      await pumpRoulette(tester);

      await tester.tap(find.text('Under 90m'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Spin the Reel'));
      await tester.pumpAndSettle();

      expect(find.text(maybeMovie.title), findsOneWidget);
      expect(find.text(watchMovie.title), findsNothing);
    });

    testWidgets('Service "Netflix" narrows the pool to only the Netflix title', (tester) async {
      await pumpRoulette(tester);

      await tester.tap(find.text('Netflix'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Spin the Reel'));
      await tester.pumpAndSettle();

      expect(find.text(maybeMovie.title), findsOneWidget);
      expect(find.text(watchMovie.title), findsNothing);
    });

    testWidgets('Mood "Comedy" narrows the pool to only the Comedy title', (tester) async {
      await pumpRoulette(tester);

      await tester.tap(find.text('Comedy'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Spin the Reel'));
      await tester.pumpAndSettle();

      expect(find.text(maybeMovie.title), findsOneWidget);
      expect(find.text(watchMovie.title), findsNothing);
    });

    testWidgets('a filter combination matching nothing shows the empty-pool message, not a crash',
        (tester) async {
      await pumpRoulette(tester);

      // Service/Mood chip options are derived from the *currently filtered*
      // pool, so they can never themselves narrow a selection down to zero
      // (an incompatible option simply isn't offered). Type and Runtime
      // are always offered regardless of the pool, though -- TV Shows has
      // only watchShow, which carries no runtime, so combining it with any
      // runtime cap genuinely empties the pool.
      await tester.tap(find.text('TV Shows'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Under 90m'));
      await tester.pumpAndSettle();

      expect(
        find.text('No titles on your Watchlist or Saved match these filters yet.'),
        findsOneWidget,
      );
      expect(find.text('Spin the Reel'), findsNothing);
    });
  });

  group('CRAFT-ROULETTE-1: result state', () {
    testWidgets('changing a filter after a result resets the curtain back to Spin the Reel',
        (tester) async {
      await pumpRoulette(tester);

      await tester.tap(find.text('Spin the Reel'));
      await tester.pumpAndSettle();
      expect(find.text('Watch Now'), findsOneWidget);

      await tester.tap(find.text('Under 120m'));
      await tester.pumpAndSettle();

      expect(find.text('Spin the Reel'), findsOneWidget);
      expect(find.text('Watch Now'), findsNothing);
    });

    testWidgets('Add to Watchlist appears for a Saved-only winner and adds it to the Watchlist',
        (tester) async {
      final container = await pumpRoulette(tester);

      await tester.tap(find.text('Under 90m'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Spin the Reel'));
      await tester.pumpAndSettle();

      expect(find.text('Add to Watchlist'), findsOneWidget);
      expect(
        container.read(mediaProvider).watchlist.containsKey(maybeMovie.id),
        isFalse,
      );

      await tester.tap(find.text('Add to Watchlist'));
      await tester.pumpAndSettle();

      expect(
        container.read(mediaProvider).watchlist.containsKey(maybeMovie.id),
        isTrue,
      );
    });

    testWidgets('Add to Watchlist does not appear for a title already on the Watchlist',
        (tester) async {
      await pumpRoulette(tester);

      // Force the deterministic Watchlist-only candidate.
      await tester.tap(find.text('Hulu'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Spin the Reel'));
      await tester.pumpAndSettle();

      expect(find.text(watchMovie.title), findsOneWidget);
      expect(find.text('Add to Watchlist'), findsNothing);
    });
  });
}
