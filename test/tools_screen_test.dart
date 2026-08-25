import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:the_lounge/screens/tools_screen.dart';
import 'package:the_lounge/screens/rate_titles_screen.dart';
import 'package:the_lounge/screens/folders_screen.dart';
import 'package:the_lounge/screens/cleanup_swipe_screen.dart';
import 'package:the_lounge/screens/rewatch_vault_screen.dart';
import 'package:the_lounge/models/media_item.dart';
import 'package:the_lounge/providers/media_provider.dart';
import 'package:the_lounge/providers/ambiance_provider.dart';
import 'package:the_lounge/repositories/mock_movie_repository.dart';

void main() {
  setUp(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  Future<ProviderContainer> pumpToolsScreen(WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [
        movieRepositoryProvider.overrideWithValue(MockMovieRepository()),
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
    );
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: Scaffold(body: ToolsScreen())),
      ),
    );
    await tester.pumpAndSettle();
    return container;
  }

  group('YSR-HUB-2: ToolsScreen structure & routing', () {
    testWidgets('renders top bar and all 4 tool cards', (tester) async {
      final container = await pumpToolsScreen(tester);
      addTearDown(container.dispose);

      expect(find.text('Tools'), findsOneWidget);
      expect(find.text('Keep your lounge in order'), findsOneWidget);

      expect(find.text('Rate Titles'), findsOneWidget);
      expect(find.text('Custom Folders'), findsOneWidget);
      expect(find.text('Cleanup Session'), findsOneWidget);
      expect(find.text('Rewatch Vault'), findsOneWidget);
    });

    testWidgets('tapping Rate Titles pushes RateTitlesScreen', (tester) async {
      final container = await pumpToolsScreen(tester);
      addTearDown(container.dispose);

      final finder = find.text('Rate Titles');
      await tester.ensureVisible(finder);
      await tester.tap(finder);
      await tester.pumpAndSettle();

      expect(find.byType(RateTitlesScreen), findsOneWidget);
    });

    testWidgets('tapping Custom Folders pushes FoldersScreen', (tester) async {
      final container = await pumpToolsScreen(tester);
      addTearDown(container.dispose);

      final finder = find.text('Custom Folders');
      await tester.ensureVisible(finder);
      await tester.tap(finder);
      await tester.pumpAndSettle();

      expect(find.byType(FoldersScreen), findsOneWidget);
    });

    testWidgets('tapping Cleanup Session pushes CleanupSwipeScreen', (tester) async {
      final container = await pumpToolsScreen(tester);
      addTearDown(container.dispose);

      final finder = find.text('Cleanup Session');
      await tester.ensureVisible(finder);
      await tester.tap(finder);
      await tester.pumpAndSettle();

      expect(find.byType(CleanupSwipeScreen), findsOneWidget);
    });

    testWidgets('tapping Rewatch Vault pushes RewatchVaultScreen', (tester) async {
      final container = await pumpToolsScreen(tester);
      addTearDown(container.dispose);

      final finder = find.text('Rewatch Vault');
      await tester.ensureVisible(finder);
      await tester.tap(finder);
      await tester.pumpAndSettle();

      expect(find.byType(RewatchVaultScreen), findsOneWidget);
    });
  });

  group('FEAT-TOOLS-1/2: live queue counts and active/quiet visual hierarchy', () {
    const watchedMovie = MediaItem(
      id: 'movie_1',
      title: 'Watched Movie',
      type: MediaType.movie,
      rating: 7.0,
      overview: '',
      genres: [],
    );
    const savedMovie = MediaItem(
      id: 'movie_2',
      title: 'Saved Movie',
      type: MediaType.movie,
      rating: 7.0,
      overview: '',
      genres: [],
    );
    const rewatchedMovie = MediaItem(
      id: 'movie_3',
      title: 'Rewatched Movie',
      type: MediaType.movie,
      rating: 7.0,
      overview: '',
      genres: [],
    );

    testWidgets(
        'a quiescent library shows "All caught up" / zero counts, not the old static copy',
        (tester) async {
      final container = await pumpToolsScreen(tester);
      addTearDown(container.dispose);

      // Rate Titles + Cleanup Session both read "All caught up" when empty.
      expect(find.text('All caught up'), findsNWidgets(2));
      expect(find.text('No rewatches yet'), findsOneWidget);
      expect(find.text('0 playlists'), findsOneWidget);
      // The old hardcoded copy is gone.
      expect(find.text('Batch rating tool'), findsNothing);
      expect(find.text('Curated playlists'), findsNothing);
      expect(find.text('Tidy up Saved'), findsNothing);
      expect(find.text("Titles you've rewatched"), findsNothing);
    });

    testWidgets(
        'an unrated watched title and a Saved item produce live counts and reactively clear',
        (tester) async {
      final container = await pumpToolsScreen(tester);
      addTearDown(container.dispose);
      final notifier = container.read(mediaProvider.notifier);

      notifier.addToWatchedList(watchedMovie);
      notifier.addToMaybeList(savedMovie);
      // addToWatchedList fires a background metadata-enrichment fetch
      // (MockMovieRepository.getMediaDetails has a 500ms delay) -- let it
      // resolve before the test ends, or its pending Timer trips
      // flutter_test's post-dispose invariant.
      await tester.pump(const Duration(milliseconds: 600));

      expect(find.text('1 unrated'), findsOneWidget);
      expect(find.text('1 pending'), findsOneWidget);
      // Both active-count badges render (Rate Titles, Cleanup Session).
      expect(find.text('1'), findsNWidgets(2));

      // Rating the title and clearing Saved brings both back to quiet.
      notifier.addWatchRecord(
        watchedMovie.id,
        WatchRecord(rating: PersonalRating.loved, isFirstWatch: true),
      );
      notifier.removeFromMaybeList(savedMovie.id);
      await tester.pump();

      expect(find.text('All caught up'), findsNWidgets(2));
      expect(find.text('1 unrated'), findsNothing);
      expect(find.text('1 pending'), findsNothing);
    });

    testWidgets('a logged rewatch and a created folder produce live counts',
        (tester) async {
      final container = await pumpToolsScreen(tester);
      addTearDown(container.dispose);
      final notifier = container.read(mediaProvider.notifier);

      notifier.addWatchRecord(
        rewatchedMovie.id,
        WatchRecord(rating: PersonalRating.loved, isFirstWatch: true),
      );
      notifier.addWatchRecord(rewatchedMovie.id, WatchRecord());
      notifier.createFolder('Weekend Watchlist');
      await tester.pump();

      expect(find.text('1 rewatch logged'), findsOneWidget);
      expect(find.text('1 playlist'), findsOneWidget);
    });
  });
}
