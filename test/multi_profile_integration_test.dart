import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:the_lounge/models/media_item.dart';
import 'package:the_lounge/models/profile_space.dart';
import 'package:the_lounge/providers/ambiance_provider.dart';
import 'package:the_lounge/providers/media_provider.dart';
import 'package:the_lounge/providers/profile_provider.dart';
import 'package:the_lounge/services/profile_storage_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SharedPreferences prefs;

  setUp(() async {
    GoogleFonts.config.allowRuntimeFetching = false;
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  group('PROF INTEGRATION: Deep ProfileStorageService <-> MediaProvider wiring', () {
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

    testWidgets('Hermetic profile switching, mutation isolation, and domain partitioning', (tester) async {
      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
      );
      addTearDown(container.dispose);

      final profileNotifier = container.read(profileProvider.notifier);
      final mediaNotifier = container.read(mediaProvider.notifier);

      // Step 1: Initial state is Profile 1 (Common)
      expect(container.read(profileProvider).activeProfileId, 'common');
      expect(container.read(mediaProvider).watchlist.isEmpty, isTrue);

      // Add Movie A to Profile 1 (Common) Watchlist
      mediaNotifier.addToWatchlist(movieA);
      expect(container.read(mediaProvider).watchlist.containsKey('movie-A'), isTrue);
      expect(container.read(mediaProvider).watchlist['movie-A']?.title, 'Inception');

      // Step 2: Switch to Profile 2 (Custom 1)
      await profileNotifier.switchProfile('custom_1');
      expect(container.read(profileProvider).activeProfileId, 'custom_1');

      // Assert Profile 2 is clean (Movie A is NOT present)
      expect(container.read(mediaProvider).watchlist.containsKey('movie-A'), isFalse);
      expect(container.read(mediaProvider).watchlist.isEmpty, isTrue);

      // Step 3: Add TV Show B to Profile 2 (Custom 1) Watching list
      mediaNotifier.addToWatchingList(showB);
      expect(container.read(mediaProvider).watchingList.containsKey('tv-B'), isTrue);
      expect(container.read(mediaProvider).watchingList['tv-B']?.title, 'Severance');

      // Step 4: Switch back to Profile 1 (Common)
      await profileNotifier.switchProfile('common');
      expect(container.read(profileProvider).activeProfileId, 'common');

      // Assert Movie A is present in Profile 1, and TV Show B is NOT present
      expect(container.read(mediaProvider).watchlist.containsKey('movie-A'), isTrue);
      expect(container.read(mediaProvider).watchingList.containsKey('tv-B'), isFalse);

      // Switch back to Profile 2: TV Show B is present, Movie A is NOT present
      await profileNotifier.switchProfile('custom_1');
      expect(container.read(mediaProvider).watchingList.containsKey('tv-B'), isTrue);
      expect(container.read(mediaProvider).watchlist.containsKey('movie-A'), isFalse);
    });

    test('v4 JSON Backup export and import roundtrip across all profiles and domains', () async {
      final storageService = ProfileStorageService();

      final profileCommon = ProfileSpace.defaultCommon().copyWith(
        domains: {
          MediumDomain.movies: DomainArchive(
            watchlist: {'movie-A': movieA},
          ),
          MediumDomain.tv: const DomainArchive(),
          MediumDomain.anime: const DomainArchive(),
        },
      );

      final profileCustom1 = ProfileSpace.defaultCustom1().copyWith(
        name: 'Sci-Fi Fan',
        domains: {
          MediumDomain.movies: const DomainArchive(),
          MediumDomain.tv: DomainArchive(
            watching: {'tv-B': showB},
          ),
          MediumDomain.anime: const DomainArchive(),
        },
      );

      final profileCustom2 = ProfileSpace.defaultCustom2().copyWith(name: 'Anime Fan');

      // Export v4 backup JSON
      final exportedJson = storageService.exportFullBackupJson(
        profiles: [profileCommon, profileCustom1, profileCustom2],
        activeProfileId: 'custom_1',
        themeId: 'lounge_classic',
      );

      expect(exportedJson.contains('"schema_version": 4'), isTrue);
      expect(exportedJson.contains('Inception'), isTrue);
      expect(exportedJson.contains('Severance'), isTrue);

      // Import backup into clean prefs
      final freshProfiles = storageService.importBackupJson(exportedJson);
      expect(freshProfiles.length, 3);

      final restoredCommon = freshProfiles.firstWhere((p) => p.id == 'common');
      expect(restoredCommon.domainArchive(MediumDomain.movies).watchlist.containsKey('movie-A'), isTrue);

      final restoredCustom1 = freshProfiles.firstWhere((p) => p.id == 'custom_1');
      expect(restoredCustom1.name, 'Sci-Fi Fan');
      expect(restoredCustom1.domainArchive(MediumDomain.tv).watching.containsKey('tv-B'), isTrue);
    });
  });
}
