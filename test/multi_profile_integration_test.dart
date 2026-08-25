import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:the_lounge/models/media_item.dart';
import 'package:the_lounge/models/hall_space.dart';
import 'package:the_lounge/providers/ambiance_provider.dart';
import 'package:the_lounge/providers/media_provider.dart';
import 'package:the_lounge/providers/hall_provider.dart';
import 'package:the_lounge/services/hall_storage_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SharedPreferences prefs;

  setUp(() async {
    GoogleFonts.config.allowRuntimeFetching = false;
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  group('HALL INTEGRATION: Deep HallStorageService <-> MediaProvider wiring',
      () {
    final movieA = const MediaItem(
      id: 'movie_A',
      title: 'Inception',
      type: MediaType.movie,
      rating: 8.8,
      overview: 'Dream within a dream',
      genres: ['Sci-Fi', 'Action'],
    );

    final showB = const MediaItem(
      id: 'tv_B',
      title: 'Severance',
      type: MediaType.tv,
      rating: 8.9,
      overview: 'Work-life balance taken literally',
      genres: ['Sci-Fi', 'Drama'],
    );

    testWidgets(
        'Hermetic hall switching, mutation isolation, and domain partitioning',
        (tester) async {
      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
      );
      addTearDown(container.dispose);

      final hallNotifier = container.read(hallProvider.notifier);
      final mediaNotifier = container.read(mediaProvider.notifier);

      // Step 1: Initial state is The Grand Hall (common)
      expect(container.read(hallProvider).activeHallId, 'common');
      expect(container.read(mediaProvider).watchlist.isEmpty, isTrue);

      // Add Movie A to The Grand Hall's Watchlist
      mediaNotifier.addToWatchlist(movieA);
      expect(container.read(mediaProvider).watchlist.containsKey('movie_A'),
          isTrue);
      expect(container.read(mediaProvider).watchlist['movie_A']?.title,
          'Inception');

      // Step 2: Switch to The Mezzanine Hall
      await hallNotifier.switchHall('custom_1');
      expect(container.read(hallProvider).activeHallId, 'custom_1');

      // Assert The Mezzanine Hall is clean (Movie A is NOT present)
      expect(container.read(mediaProvider).watchlist.containsKey('movie_A'),
          isFalse);
      expect(container.read(mediaProvider).watchlist.isEmpty, isTrue);

      // Step 3: Add TV Show B to The Mezzanine Hall's Watching list
      mediaNotifier.addToWatchingList(showB);
      expect(container.read(mediaProvider).watchingList.containsKey('tv_B'),
          isTrue);
      expect(container.read(mediaProvider).watchingList['tv_B']?.title,
          'Severance');

      // Step 4: Switch back to The Grand Hall
      await hallNotifier.switchHall('common');
      expect(container.read(hallProvider).activeHallId, 'common');

      // Assert Movie A (native) is present. ORG-AGG-1: the Grand Hall is now
      // an aggregate of the other Halls too, so TV Show B (native to the
      // Mezzanine Hall) is also visible here -- but marked read-only, not
      // treated as if it were natively saved in the Grand Hall.
      expect(container.read(mediaProvider).watchlist.containsKey('movie_A'),
          isTrue);
      expect(container.read(mediaProvider).watchingList.containsKey('tv_B'),
          isTrue);
      expect(container.read(mediaProvider).readOnlyMediaIds.contains('tv_B'),
          isTrue);
      expect(container.read(mediaProvider).readOnlyMediaIds.contains('movie_A'),
          isFalse);
      expect(container.read(mediaProvider).readOnlySourceHallName['tv_B'],
          'The Mezzanine Hall');

      // ORG-AGG-1: aggregated titles must never get silently duplicated
      // into the Grand Hall's own native storage. Trigger an unrelated
      // native save (adding Movie A again is a no-op mutation, but it still
      // exercises the real _saveToPrefs path) and confirm the Grand Hall's
      // own on-disk archive still has no trace of TV Show B.
      mediaNotifier.addToWatchlist(movieA);
      final grandMovieRaw = prefs.getString(
        HallStorageService.domainStorageKey('common', MediumDomain.tv),
      );
      expect(grandMovieRaw == null || !grandMovieRaw.contains('tv_B'), isTrue);

      // Switch back to The Mezzanine Hall: TV Show B is present natively,
      // Movie A (native to the Grand Hall only) is NOT present -- the
      // Mezzanine Hall itself is not part of any aggregate and stays fully
      // isolated.
      await hallNotifier.switchHall('custom_1');
      expect(container.read(mediaProvider).watchingList.containsKey('tv_B'),
          isTrue);
      expect(container.read(mediaProvider).watchlist.containsKey('movie_A'),
          isFalse);
      expect(container.read(mediaProvider).readOnlyMediaIds.isEmpty, isTrue);
    });

    test(
        'v4 JSON Backup export and import roundtrip across all halls and domains',
        () async {
      final storageService = HallStorageService();

      final grandHall = HallSpace.defaultGrandHall().copyWith(
        domains: {
          MediumDomain.movies: DomainArchive(
            watchlist: {'movie_A': movieA},
          ),
          MediumDomain.tv: const DomainArchive(),
          MediumDomain.anime: const DomainArchive(),
        },
      );

      final mezzanineHall = HallSpace.defaultMezzanineHall().copyWith(
        name: 'Sci-Fi Fan',
        domains: {
          MediumDomain.movies: const DomainArchive(),
          MediumDomain.tv: DomainArchive(
            watching: {'tv_B': showB},
          ),
          MediumDomain.anime: const DomainArchive(),
        },
      );

      final privateScreeningHall =
          HallSpace.defaultPrivateScreeningHall().copyWith(name: 'Anime Fan');

      // Export v4 backup JSON
      final exportedJson = storageService.exportFullBackupJson(
        halls: [grandHall, mezzanineHall, privateScreeningHall],
        activeHallId: 'custom_1',
        themeId: 'lounge_classic',
      );

      expect(exportedJson.contains('"schema_version": 4'), isTrue);
      expect(exportedJson.contains('Inception'), isTrue);
      expect(exportedJson.contains('Severance'), isTrue);

      // Import backup into clean prefs
      final freshHalls = storageService.importBackupJson(exportedJson);
      expect(freshHalls.length, 3);

      final restoredGrandHall = freshHalls.firstWhere((h) => h.id == 'common');
      expect(
          restoredGrandHall
              .domainArchive(MediumDomain.movies)
              .watchlist
              .containsKey('movie_A'),
          isTrue);

      final restoredMezzanineHall =
          freshHalls.firstWhere((h) => h.id == 'custom_1');
      expect(restoredMezzanineHall.name, 'Sci-Fi Fan');
      expect(
          restoredMezzanineHall
              .domainArchive(MediumDomain.tv)
              .watching
              .containsKey('tv_B'),
          isTrue);
    });

    testWidgets(
        'resetAllHalls actually erases every hall\'s namespaced storage, not just legacy keys (does not resurrect after a simulated restart)',
        (tester) async {
      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
      );
      addTearDown(container.dispose);

      final hallNotifier = container.read(hallProvider.notifier);
      final mediaNotifier = container.read(mediaProvider.notifier);

      // Populate two different halls natively so a reset that only
      // touches the active hall (or only legacy keys) would be caught.
      mediaNotifier.addToWatchlist(movieA);
      await hallNotifier.switchHall('custom_1');
      mediaNotifier.addToWatchingList(showB);
      await hallNotifier.switchHall('common');
      expect(container.read(mediaProvider).watchlist.containsKey('movie_A'),
          isTrue);

      // Mirrors settings_screen.dart's "Reset Everything" handler.
      await mediaNotifier.clearAllData();
      await hallNotifier.resetAllHalls();
      // clearAllData/resetAllHalls kick off Discover pool reloads against
      // MockMovieRepository's simulated 100ms-per-request network delay (a
      // real Timer under testWidgets' fake-async clock) -- loadPool can
      // issue several sequential requests per attempt across up to 5
      // attempts, so advance well past the worst case before the container
      // that owns it gets disposed, or the test framework flags a pending
      // timer as a leak.
      await tester.pump(const Duration(seconds: 3));

      // Simulate an app restart: fresh container/notifiers reading the
      // exact same SharedPreferences instance. Before the fix, both
      // halls' real namespaced storage survived untouched and the data
      // reappeared here even though clearAllData had already run.
      final restartedContainer = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
      );
      addTearDown(restartedContainer.dispose);

      expect(restartedContainer.read(mediaProvider).watchlist.isEmpty, isTrue);

      // Check the Mezzanine Hall's own real storage directly (rather than
      // switching to it, which would exercise switchHall's own Discover
      // deck invalidation/reload side effect unrelated to what this test
      // is verifying) -- the previously-broken clearAllData only ever
      // reset the active hall's in-memory state, never another hall's
      // on-disk archive.
      final mezzanineRaw = prefs.getString(
        HallStorageService.domainStorageKey('custom_1', MediumDomain.tv),
      );
      expect(mezzanineRaw == null || !mezzanineRaw.contains('tv_B'), isTrue);
    });
  });
}
