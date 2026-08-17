import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:the_lounge/models/media_item.dart';
import 'package:the_lounge/providers/media_provider.dart';
import 'package:the_lounge/providers/ambiance_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  const movie1 = MediaItem(
    id: 'movie_1',
    title: 'Movie 1',
    type: MediaType.movie,
    rating: 8.0,
    overview: 'Overview 1',
    genres: ['Action'],
  );
  const movie2 = MediaItem(
    id: 'movie_2',
    title: 'Movie 2',
    type: MediaType.movie,
    rating: 7.0,
    overview: 'Overview 2',
    genres: ['Comedy'],
  );

  group('PERS-FOLDERS-1: CRUD', () {
    late SharedPreferences prefs;
    late ProviderContainer container;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      container = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      );
    });

    tearDown(() => container.dispose());

    test('createFolder adds an empty folder and returns its ID', () {
      final notifier = container.read(mediaProvider.notifier);
      final id = notifier.createFolder('Spooky Season');

      final folder = container.read(mediaProvider).customFolders[id];
      expect(folder, isNotNull);
      expect(folder!.name, 'Spooky Season');
      expect(folder.mediaIds, isEmpty);
    });

    test('renameFolder updates the name without touching mediaIds', () {
      final notifier = container.read(mediaProvider.notifier);
      final id = notifier.createFolder('Old Name');
      notifier.addToFolder(id, movie1.id);

      notifier.renameFolder(id, 'New Name');

      final folder = container.read(mediaProvider).customFolders[id]!;
      expect(folder.name, 'New Name');
      expect(folder.mediaIds, [movie1.id]);
    });

    test('deleteFolder removes it entirely', () {
      final notifier = container.read(mediaProvider.notifier);
      final id = notifier.createFolder('Temp');

      notifier.deleteFolder(id);

      expect(container.read(mediaProvider).customFolders.containsKey(id), isFalse);
    });

    test('addToFolder appends without duplicating', () {
      final notifier = container.read(mediaProvider.notifier);
      final id = notifier.createFolder('Nolan Marathons');

      notifier.addToFolder(id, movie1.id);
      notifier.addToFolder(id, movie1.id); // duplicate, should no-op
      notifier.addToFolder(id, movie2.id);

      final folder = container.read(mediaProvider).customFolders[id]!;
      expect(folder.mediaIds, [movie1.id, movie2.id]);
    });

    test('removeFromFolder removes exactly the targeted title', () {
      final notifier = container.read(mediaProvider.notifier);
      final id = notifier.createFolder('Watchlist Backup');
      notifier.addToFolder(id, movie1.id);
      notifier.addToFolder(id, movie2.id);

      notifier.removeFromFolder(id, movie1.id);

      final folder = container.read(mediaProvider).customFolders[id]!;
      expect(folder.mediaIds, [movie2.id]);
    });

    test('reorderFolderItems replaces the ordering wholesale', () {
      final notifier = container.read(mediaProvider.notifier);
      final id = notifier.createFolder('Ranked');
      notifier.addToFolder(id, movie1.id);
      notifier.addToFolder(id, movie2.id);

      notifier.reorderFolderItems(id, [movie2.id, movie1.id]);

      final folder = container.read(mediaProvider).customFolders[id]!;
      expect(folder.mediaIds, [movie2.id, movie1.id]);
    });

    test('mutations on a non-existent folder ID are no-ops', () {
      final notifier = container.read(mediaProvider.notifier);
      notifier.renameFolder('missing', 'x');
      notifier.addToFolder('missing', movie1.id);
      notifier.removeFromFolder('missing', movie1.id);
      notifier.reorderFolderItems('missing', [movie1.id]);

      expect(container.read(mediaProvider).customFolders, isEmpty);
    });
  });

  group('PERS-FOLDERS-1: status independence', () {
    late SharedPreferences prefs;
    late ProviderContainer container;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      container = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      );
    });

    tearDown(() => container.dispose());

    test('removing a title from the Watched pile does not remove it from its folders', () {
      final notifier = container.read(mediaProvider.notifier);
      notifier.addToWatchedList(movie1);
      final id = notifier.createFolder('Favorites');
      notifier.addToFolder(id, movie1.id);

      notifier.removeFromWatchedList(movie1.id);

      final folder = container.read(mediaProvider).customFolders[id]!;
      expect(folder.mediaIds, [movie1.id]);
    });

    test('changing status from Watched to Dropped does not remove it from its folders', () {
      final notifier = container.read(mediaProvider.notifier);
      notifier.addToWatchedList(movie1);
      final id = notifier.createFolder('Favorites');
      notifier.addToFolder(id, movie1.id);

      notifier.addToDroppedList(movie1);

      final folder = container.read(mediaProvider).customFolders[id]!;
      expect(folder.mediaIds, [movie1.id]);
      expect(container.read(mediaProvider).droppedList.containsKey(movie1.id), isTrue);
    });

    test('removeFromAllLists does not remove a title from its folders', () {
      final notifier = container.read(mediaProvider.notifier);
      notifier.addToWatchlist(movie1);
      final id = notifier.createFolder('Favorites');
      notifier.addToFolder(id, movie1.id);

      notifier.removeFromAllLists(movie1.id);

      final folder = container.read(mediaProvider).customFolders[id]!;
      expect(folder.mediaIds, [movie1.id]);
    });

    test('a title can belong to a folder without being in any status pile at all', () {
      final notifier = container.read(mediaProvider.notifier);
      final id = notifier.createFolder('Someday');

      notifier.addToFolder(id, movie1.id);

      final state = container.read(mediaProvider);
      expect(state.customFolders[id]!.mediaIds, [movie1.id]);
      expect(state.watchlist.containsKey(movie1.id), isFalse);
      expect(state.watchedList.containsKey(movie1.id), isFalse);
    });
  });

  group('PERS-FOLDERS-1: persistence and backup', () {
    late SharedPreferences prefs;
    late ProviderContainer container;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      container = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      );
    });

    tearDown(() => container.dispose());

    test('folders persist to SharedPreferences and survive a reload', () async {
      final notifier = container.read(mediaProvider.notifier);
      final id = notifier.createFolder('Persisted Folder');
      notifier.addToFolder(id, movie1.id);
      await notifier.saveToPrefs();

      final restarted = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      );
      addTearDown(restarted.dispose);

      final folder = restarted.read(mediaProvider).customFolders[id];
      expect(folder, isNotNull);
      expect(folder!.name, 'Persisted Folder');
      expect(folder.mediaIds, [movie1.id]);
    });

    test('export writes schema version 3 with customFolders', () {
      final notifier = container.read(mediaProvider.notifier);
      final id = notifier.createFolder('Export Test');
      notifier.addToFolder(id, movie1.id);

      final json = notifier.exportBackupJson('screening_room');

      expect(json, contains('"version":3'));
      expect(json, contains('customFolders'));
      expect(json, contains('Export Test'));
    });

    test('round-trip: export then import into a fresh container restores folders', () async {
      final notifier = container.read(mediaProvider.notifier);
      final id = notifier.createFolder('Round Trip');
      notifier.addToFolder(id, movie1.id);
      final json = notifier.exportBackupJson('screening_room');
      final withoutAmbiance = jsonDecode(json) as Map<String, dynamic>
        ..remove('selectedAmbiance');

      final freshContainer = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      );
      addTearDown(freshContainer.dispose);
      final freshNotifier = freshContainer.read(mediaProvider.notifier);

      final ok = await freshNotifier.importBackupJson(jsonEncode(withoutAmbiance));

      expect(ok, isTrue);
      final folder = freshContainer.read(mediaProvider).customFolders[id];
      expect(folder, isNotNull);
      expect(folder!.name, 'Round Trip');
      expect(folder.mediaIds, [movie1.id]);
    });

    test('legacy version-2 backups (pre-PERS-FOLDERS-1) still import successfully', () async {
      final legacyBackup = '''
      {
        "version": 2,
        "watchlist": {"movie_1": {"id": "movie_1", "title": "Movie 1", "type": "movie", "rating": 8.0}},
        "maybeList": {},
        "watchingList": {},
        "watchedList": {},
        "droppedList": {},
        "onHoldList": {},
        "watchedEpisodes": {},
        "watchProvidersCountry": "US",
        "watchHistory": {},
        "startDates": {},
        "endDates": {},
        "seasonStartDates": {},
        "seasonEndDates": {}
      }
      ''';
      final notifier = container.read(mediaProvider.notifier);

      final ok = await notifier.importBackupJson(legacyBackup);

      expect(ok, isTrue);
      final state = container.read(mediaProvider);
      expect(state.watchlist.containsKey('movie_1'), isTrue);
      expect(state.customFolders, isEmpty);
    });

    test('clearAllData wipes customFolders', () async {
      final notifier = container.read(mediaProvider.notifier);
      notifier.createFolder('To Be Cleared');

      await notifier.clearAllData();

      expect(container.read(mediaProvider).customFolders, isEmpty);
      expect(prefs.getString('the_lounge_custom_folders'), isNull);
    });
  });
}
