import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:the_lounge/models/media_item.dart';
import 'package:the_lounge/models/hall_space.dart';
import 'package:the_lounge/services/hall_storage_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SharedPreferences prefs;
  late HallStorageService service;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    service = HallStorageService();
  });

  group('NOMEN-1: HallStorageService multi-hall isolation & storage', () {
    test('loadAllHalls defaults to 3 halls when empty', () async {
      final halls = await service.loadAllHalls(prefs);
      expect(halls.length, 3);
      expect(halls[0].id, 'common');
      expect(halls[0].name, 'The Grand Hall');
      expect(halls[0].isCommon, isTrue);
      expect(halls[1].id, 'custom_1');
      expect(halls[1].name, 'The Mezzanine Hall');
      expect(halls[2].id, 'custom_2');
      expect(halls[2].name, 'The Private Screening Hall');
    });

    test('saveHall & loadHall hermetically isolates domain data', () async {
      final movie = const MediaItem(
        id: 'movie_100',
        title: 'Interstellar',
        type: MediaType.movie,
        rating: 8.7,
        overview: '',
        genres: ['Sci-Fi'],
      );
      final tv = const MediaItem(
        id: 'tv_200',
        title: 'Severance',
        type: MediaType.tv,
        rating: 8.9,
        overview: '',
        genres: ['Sci-Fi'],
      );

      final custom1 = HallSpace.defaultMezzanineHall().copyWith(
        name: 'Sci-Fi Screening Room',
        domains: {
          MediumDomain.movies: DomainArchive(watchlist: {'movie_100': movie}),
          MediumDomain.tv: DomainArchive(watching: {'tv_200': tv}),
          MediumDomain.anime: const DomainArchive(),
        },
      );

      await service.saveHall(prefs, custom1);

      final loadedCustom1 = await service.loadHall(prefs, 'custom_1');
      expect(loadedCustom1.name, 'Sci-Fi Screening Room');
      expect(loadedCustom1.domainArchive(MediumDomain.movies).watchlist['movie_100']?.title, 'Interstellar');
      expect(loadedCustom1.domainArchive(MediumDomain.tv).watching['tv_200']?.title, 'Severance');

      // Grand Hall remains untouched and empty
      final loadedCommon = await service.loadHall(prefs, 'common');
      expect(loadedCommon.domainArchive(MediumDomain.movies).watchlist.isEmpty, isTrue);
      expect(loadedCommon.domainArchive(MediumDomain.tv).watching.isEmpty, isTrue);
    });

    test('migrateLegacyToCommonIfNeeded splits legacy media into Movies & TV archives', () async {
      // TH-58: legacy-persisted raw ids ('movie-1'/'tv-1', not yet
      // domain-prefixed) -- this test specifically exercises that the
      // migration self-heals them, so the fixtures deliberately do NOT
      // use the new prefixed form the way other tests' fixtures do.
      final legacyMovie = const MediaItem(
        id: 'movie-1',
        title: 'The Dark Knight',
        type: MediaType.movie,
        rating: 9.0,
        overview: '',
        genres: ['Action'],
      );
      final legacyTv = const MediaItem(
        id: 'tv-1',
        title: 'Breaking Bad',
        type: MediaType.tv,
        rating: 9.5,
        overview: '',
        genres: ['Drama'],
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

      final halls = await service.loadAllHalls(prefs);
      final common = halls.firstWhere((p) => p.id == 'common');

      // Self-healed to domain-prefixed ids on load -- the legacy raw keys
      // ('movie-1'/'tv-1') no longer appear anywhere.
      expect(common.domainArchive(MediumDomain.movies).watchlist.containsKey('movie_movie-1'), isTrue);
      expect(common.domainArchive(MediumDomain.movies).watchlist.containsKey('movie-1'), isFalse);
      expect(common.domainArchive(MediumDomain.movies).watchlist.containsKey('tv_tv-1'), isFalse);

      expect(common.domainArchive(MediumDomain.tv).watchlist.containsKey('tv_tv-1'), isTrue);
      expect(common.domainArchive(MediumDomain.tv).watchlist.containsKey('tv-1'), isFalse);
      expect(common.domainArchive(MediumDomain.tv).watchlist.containsKey('movie_movie-1'), isFalse);
      expect(common.domainArchive(MediumDomain.tv).watchedEpisodes['tv_tv-1']?.contains('S1E1'), isTrue);
    });

    test('exportFullBackupJson & importBackupJson v4 schema', () {
      final halls = [
        HallSpace.defaultGrandHall().copyWith(
          domains: {
            MediumDomain.movies: const DomainArchive(
              watchlist: {
                'movie_1': MediaItem(
                  id: 'movie_1',
                  title: 'Arrival',
                  type: MediaType.movie,
                  rating: 8.0,
                  overview: '',
                  genres: ['Sci-Fi'],
                ),
              },
            ),
          },
        ),
        HallSpace.defaultMezzanineHall().copyWith(name: 'Hall B'),
        HallSpace.defaultPrivateScreeningHall().copyWith(name: 'Hall C'),
      ];

      final jsonString = service.exportFullBackupJson(
        halls: halls,
        activeHallId: 'common',
        themeId: 'screening_room',
      );

      final imported = service.importBackupJson(jsonString);
      expect(imported.length, 3);
      expect(imported[0].domainArchive(MediumDomain.movies).watchlist['movie_1']?.title, 'Arrival');
      expect(imported[1].name, 'Hall B');
      expect(imported[2].name, 'Hall C');
    });

    test('importBackupJson v4 preserves standard 3 halls when importing partial profiles', () {
      final partialBackupJson = jsonEncode({
        'schema_version': 4,
        'exported_at': DateTime.now().toIso8601String(),
        'active_profile_id': 'custom_1',
        'theme_id': 'midnight_cinema',
        'profiles': [
          HallSpace.defaultPrivateScreeningHall().copyWith(name: 'Imported Screening').toJson(),
          HallSpace.defaultMezzanineHall().copyWith(name: 'Imported Mezzanine').toJson(),
        ],
      });

      final imported = service.importBackupJson(partialBackupJson);
      expect(imported.length, 3);
      final ids = imported.map((h) => h.id).toList();
      expect(ids, containsAll(['common', 'custom_1', 'custom_2']));
      expect(imported.firstWhere((h) => h.id == 'common').name, 'The Grand Hall');
      expect(imported.firstWhere((h) => h.id == 'custom_1').name, 'Imported Mezzanine');
      expect(imported.firstWhere((h) => h.id == 'custom_2').name, 'Imported Screening');
    });
  });
}
