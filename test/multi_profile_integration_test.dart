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

  group('HALL INTEGRATION: Deep HallStorageService <-> MediaProvider wiring', () {
    final movieA = const MediaItem(
      id: 'movie-A',
      title: 'Inception',
      type: MediaType.movie,
      rating: 8.8,
      overview: 'Dream within a dream',
      genres: ['Sci-Fi', 'Action'],
    );

    final showB = const MediaItem(
      id: 'tv-B',
      title: 'Severance',
      type: MediaType.tv,
      rating: 8.9,
      overview: 'Work-life balance taken literally',
      genres: ['Sci-Fi', 'Drama'],
    );

    testWidgets('Hermetic hall switching, mutation isolation, and domain partitioning', (tester) async {
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
      expect(container.read(mediaProvider).watchlist.containsKey('movie-A'), isTrue);
      expect(container.read(mediaProvider).watchlist['movie-A']?.title, 'Inception');

      // Step 2: Switch to The Mezzanine Hall
      await hallNotifier.switchHall('custom_1');
      expect(container.read(hallProvider).activeHallId, 'custom_1');

      // Assert The Mezzanine Hall is clean (Movie A is NOT present)
      expect(container.read(mediaProvider).watchlist.containsKey('movie-A'), isFalse);
      expect(container.read(mediaProvider).watchlist.isEmpty, isTrue);

      // Step 3: Add TV Show B to The Mezzanine Hall's Watching list
      mediaNotifier.addToWatchingList(showB);
      expect(container.read(mediaProvider).watchingList.containsKey('tv-B'), isTrue);
      expect(container.read(mediaProvider).watchingList['tv-B']?.title, 'Severance');

      // Step 4: Switch back to The Grand Hall
      await hallNotifier.switchHall('common');
      expect(container.read(hallProvider).activeHallId, 'common');

      // Assert Movie A is present in The Grand Hall, and TV Show B is NOT present
      expect(container.read(mediaProvider).watchlist.containsKey('movie-A'), isTrue);
      expect(container.read(mediaProvider).watchingList.containsKey('tv-B'), isFalse);

      // Switch back to The Mezzanine Hall: TV Show B is present, Movie A is NOT present
      await hallNotifier.switchHall('custom_1');
      expect(container.read(mediaProvider).watchingList.containsKey('tv-B'), isTrue);
      expect(container.read(mediaProvider).watchlist.containsKey('movie-A'), isFalse);
    });

    test('v4 JSON Backup export and import roundtrip across all halls and domains', () async {
      final storageService = HallStorageService();

      final grandHall = HallSpace.defaultGrandHall().copyWith(
        domains: {
          MediumDomain.movies: DomainArchive(
            watchlist: {'movie-A': movieA},
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
            watching: {'tv-B': showB},
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
      expect(restoredGrandHall.domainArchive(MediumDomain.movies).watchlist.containsKey('movie-A'), isTrue);

      final restoredMezzanineHall = freshHalls.firstWhere((h) => h.id == 'custom_1');
      expect(restoredMezzanineHall.name, 'Sci-Fi Fan');
      expect(restoredMezzanineHall.domainArchive(MediumDomain.tv).watching.containsKey('tv-B'), isTrue);
    });
  });
}
