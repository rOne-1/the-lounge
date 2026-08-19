import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:the_lounge/models/media_item.dart';
import 'package:the_lounge/models/profile_space.dart';
import 'package:the_lounge/services/profile_storage_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SharedPreferences prefs;
  late ProfileStorageService service;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    service = ProfileStorageService();
  });

  group('PROF-2: ProfileStorageService multi-profile isolation & storage', () {
    test('loadAllProfiles defaults to 3 profiles when empty', () async {
      final profiles = await service.loadAllProfiles(prefs);
      expect(profiles.length, 3);
      expect(profiles[0].id, 'common');
      expect(profiles[0].isCommon, isTrue);
      expect(profiles[1].id, 'custom_1');
      expect(profiles[2].id, 'custom_2');
    });

    test('saveProfile & loadProfile hermetically isolates domain data', () async {
      final movie = const MediaItem(
        id: 'm-100',
        title: 'Interstellar',
        type: MediaType.movie,
        rating: 8.7,
      );
      final tv = const MediaItem(
        id: 't-200',
        title: 'Severance',
        type: MediaType.tv,
        rating: 8.9,
      );

      final custom1 = ProfileSpace.defaultCustom1().copyWith(
        name: 'Sci-Fi Nerd',
        domains: {
          MediumDomain.movies: DomainArchive(watchlist: {'m-100': movie}),
          MediumDomain.tv: DomainArchive(watching: {'t-200': tv}),
          MediumDomain.anime: const DomainArchive(),
        },
      );

      await service.saveProfile(prefs, custom1);

      final loadedCustom1 = await service.loadProfile(prefs, 'custom_1');
      expect(loadedCustom1.name, 'Sci-Fi Nerd');
      expect(loadedCustom1.domainArchive(MediumDomain.movies).watchlist['m-100']?.title, 'Interstellar');
      expect(loadedCustom1.domainArchive(MediumDomain.tv).watching['t-200']?.title, 'Severance');

      // Common profile remains untouched and empty
      final loadedCommon = await service.loadProfile(prefs, 'common');
      expect(loadedCommon.domainArchive(MediumDomain.movies).watchlist.isEmpty, isTrue);
      expect(loadedCommon.domainArchive(MediumDomain.tv).watching.isEmpty, isTrue);
    });

    test('migrateLegacyToCommonIfNeeded splits legacy media into Movies & TV archives', () async {
      final legacyMovie = const MediaItem(
        id: 'movie-1',
        title: 'The Dark Knight',
        type: MediaType.movie,
      );
      final legacyTv = const MediaItem(
        id: 'tv-1',
        title: 'Breaking Bad',
        type: MediaType.tv,
      );

      await prefs.setString(
        'watchlist',
        jsonEncode({
          'movie-1': legacyMovie.toJson(),
          'tv-1': legacyTv.toJson(),
        }),
      );

      await prefs.setString(
        'watched_episodes',
        jsonEncode({
          'tv-1': ['S1E1', 'S1E2']
        }),
      );

      final profiles = await service.loadAllProfiles(prefs);
      final common = profiles.firstWhere((p) => p.id == 'common');

      expect(common.domainArchive(MediumDomain.movies).watchlist.containsKey('movie-1'), isTrue);
      expect(common.domainArchive(MediumDomain.movies).watchlist.containsKey('tv-1'), isFalse);

      expect(common.domainArchive(MediumDomain.tv).watchlist.containsKey('tv-1'), isTrue);
      expect(common.domainArchive(MediumDomain.tv).watchlist.containsKey('movie-1'), isFalse);
      expect(common.domainArchive(MediumDomain.tv).watchedEpisodes['tv-1']?.contains('S1E1'), isTrue);
    });

    test('exportFullBackupJson & importBackupJson v4 schema', () {
      final profiles = [
        ProfileSpace.defaultCommon().copyWith(
          domains: {
            MediumDomain.movies: const DomainArchive(
              watchlist: {
                'm-1': MediaItem(id: 'm-1', title: 'Arrival', type: MediaType.movie),
              },
            ),
          },
        ),
        ProfileSpace.defaultCustom1().copyWith(name: 'Profile B'),
        ProfileSpace.defaultCustom2().copyWith(name: 'Profile C'),
      ];

      final jsonString = service.exportFullBackupJson(
        profiles: profiles,
        activeProfileId: 'common',
        themeId: 'noir',
      );

      final imported = service.importBackupJson(jsonString);
      expect(imported.length, 3);
      expect(imported[0].domainArchive(MediumDomain.movies).watchlist['m-1']?.title, 'Arrival');
      expect(imported[1].name, 'Profile B');
      expect(imported[2].name, 'Profile C');
    });
  });
}
