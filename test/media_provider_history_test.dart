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
  GoogleFonts.config.allowRuntimeFetching = false;

  const movie1 = MediaItem(
    id: 'movie_1',
    title: 'Movie 1',
    type: MediaType.movie,
    rating: 8.0,
    overview: 'Overview 1',
    genres: ['Action'],
  );

  group('PERS-DATA-1: watchHistory mutations', () {
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

    test('addWatchRecord appends to a new media ID history list', () {
      final notifier = container.read(mediaProvider.notifier);
      final record = WatchRecord(rating: PersonalRating.loved, isFirstWatch: true);

      notifier.addWatchRecord(movie1.id, record);

      final state = container.read(mediaProvider);
      expect(state.watchHistory[movie1.id], hasLength(1));
      expect(state.watchHistory[movie1.id]!.first.rating, PersonalRating.loved);
    });

    test('addWatchRecord appends a rewatch without disturbing the first watch', () {
      final notifier = container.read(mediaProvider.notifier);
      final first = WatchRecord(
        date: DateTime(2025, 1, 1),
        rating: PersonalRating.loved,
        isFirstWatch: true,
      );
      final rewatch = WatchRecord(
        date: DateTime(2026, 1, 1),
        rating: PersonalRating.liked,
        isFirstWatch: false,
      );

      notifier.addWatchRecord(movie1.id, first);
      notifier.addWatchRecord(movie1.id, rewatch);

      final history = container.read(mediaProvider).watchHistory[movie1.id]!;
      expect(history, hasLength(2));
      expect(history[0].isFirstWatch, isTrue);
      expect(history[0].rating, PersonalRating.loved);
      expect(history[1].isFirstWatch, isFalse);
      expect(history[1].rating, PersonalRating.liked);
    });

    test('updateWatchRecord replaces the record identified by recordedAt', () {
      final notifier = container.read(mediaProvider.notifier);
      final recordedAt = DateTime(2026, 1, 1, 12);
      notifier.addWatchRecord(
        movie1.id,
        WatchRecord(rating: PersonalRating.okay, recordedAt: recordedAt),
      );

      notifier.updateWatchRecord(
        movie1.id,
        recordedAt,
        WatchRecord(rating: PersonalRating.loved, recordedAt: recordedAt),
      );

      final history = container.read(mediaProvider).watchHistory[movie1.id]!;
      expect(history, hasLength(1));
      expect(history.first.rating, PersonalRating.loved);
    });

    test('updateWatchRecord is a no-op when recordedAt is not found', () {
      final notifier = container.read(mediaProvider.notifier);
      notifier.addWatchRecord(movie1.id, WatchRecord());

      notifier.updateWatchRecord(
        movie1.id,
        DateTime(1999),
        WatchRecord(rating: PersonalRating.loved),
      );

      expect(container.read(mediaProvider).watchHistory[movie1.id], hasLength(1));
      expect(
        container.read(mediaProvider).watchHistory[movie1.id]!.first.rating,
        isNull,
      );
    });

    test('deleteWatchRecord removes only the targeted record', () {
      final notifier = container.read(mediaProvider.notifier);
      final keepAt = DateTime(2026, 1, 1);
      final removeAt = DateTime(2026, 2, 1);
      notifier.addWatchRecord(movie1.id, WatchRecord(recordedAt: keepAt));
      notifier.addWatchRecord(movie1.id, WatchRecord(recordedAt: removeAt));

      notifier.deleteWatchRecord(movie1.id, removeAt);

      final history = container.read(mediaProvider).watchHistory[movie1.id]!;
      expect(history, hasLength(1));
      expect(history.first.recordedAt, keepAt);
    });

    test('deleteWatchRecord removes the media ID entirely once its list empties', () {
      final notifier = container.read(mediaProvider.notifier);
      final at = DateTime(2026, 1, 1);
      notifier.addWatchRecord(movie1.id, WatchRecord(recordedAt: at));

      notifier.deleteWatchRecord(movie1.id, at);

      expect(container.read(mediaProvider).watchHistory.containsKey(movie1.id), isFalse);
    });

    test('watchHistory persists to SharedPreferences and survives a reload', () async {
      final notifier = container.read(mediaProvider.notifier);
      notifier.addWatchRecord(
        movie1.id,
        WatchRecord(
          date: DateTime(2026, 1, 1),
          rating: PersonalRating.loved,
          isFirstWatch: true,
        ),
      );
      await notifier.saveToPrefs();

      // Simulate app restart: fresh container reading the same prefs.
      final restartedContainer = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      );
      addTearDown(restartedContainer.dispose);

      final restoredHistory =
          restartedContainer.read(mediaProvider).watchHistory[movie1.id];
      expect(restoredHistory, hasLength(1));
      expect(restoredHistory!.first.rating, PersonalRating.loved);
      expect(restoredHistory.first.isFirstWatch, isTrue);
    });

    test('removeFromWatchedList does not delete watchHistory (personal memories persist)', () {
      final notifier = container.read(mediaProvider.notifier);
      notifier.addToWatchedList(movie1);
      notifier.addWatchRecord(
        movie1.id,
        WatchRecord(rating: PersonalRating.loved, isFirstWatch: true),
      );

      notifier.removeFromWatchedList(movie1.id);

      expect(container.read(mediaProvider).watchHistory[movie1.id], hasLength(1));
    });
  });

  group('PERS-DATA-1: backup export/import schema migration', () {
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

    test('export writes schema version 2 with watchHistory and date maps', () {
      final notifier = container.read(mediaProvider.notifier);
      notifier.addToWatchedList(movie1);
      notifier.addWatchRecord(
        movie1.id,
        WatchRecord(rating: PersonalRating.loved, isFirstWatch: true),
      );

      final json = notifier.exportBackupJson('screening_room');

      expect(json, contains('"version":2'));
      expect(json, contains('watchHistory'));
      expect(json, contains('startDates'));
      expect(json, contains('endDates'));
    });

    test('round-trip: export then import into a fresh container restores watchHistory and dates', () async {
      final notifier = container.read(mediaProvider.notifier);
      notifier.addToWatchedList(movie1);
      notifier.addWatchRecord(
        movie1.id,
        WatchRecord(rating: PersonalRating.loved, isFirstWatch: true),
      );
      final json = notifier.exportBackupJson('screening_room');
      // Strip selectedAmbiance before importing: applying it round-trips
      // through getThemeById()/allThemes, which eagerly builds every theme's
      // TextTheme via GoogleFonts -- a real network/asset dependency this
      // test has no need to exercise, since it's only verifying watchHistory
      // and date-map persistence through the backup schema.
      final withoutAmbiance = jsonDecode(json) as Map<String, dynamic>
        ..remove('selectedAmbiance');

      final freshPrefs = prefs;
      final freshContainer = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(freshPrefs)],
      );
      addTearDown(freshContainer.dispose);
      final freshNotifier = freshContainer.read(mediaProvider.notifier);

      final ok =
          await freshNotifier.importBackupJson(jsonEncode(withoutAmbiance));

      expect(ok, isTrue);
      final state = freshContainer.read(mediaProvider);
      expect(state.watchHistory[movie1.id], hasLength(1));
      expect(state.startDates[movie1.id], isNotNull);
      expect(state.endDates[movie1.id], isNotNull);
    });

    test('legacy version-1 backups (pre-Personalization Epic) still import successfully', () async {
      final legacyBackup = '''
      {
        "version": 1,
        "watchlist": {},
        "maybeList": {},
        "watchingList": {},
        "watchedList": {"movie_1": {"id": "movie_1", "title": "Movie 1", "type": "movie", "rating": 8.0}},
        "droppedList": {},
        "onHoldList": {},
        "watchedEpisodes": {},
        "watchProvidersCountry": "US"
      }
      ''';
      final notifier = container.read(mediaProvider.notifier);

      final ok = await notifier.importBackupJson(legacyBackup);

      expect(ok, isTrue);
      final state = container.read(mediaProvider);
      expect(state.watchedList.containsKey('movie_1'), isTrue);
      expect(state.watchHistory, isEmpty);
      expect(state.startDates, isEmpty);
      expect(state.endDates, isEmpty);
    });

    test('clearAllData wipes watchHistory and derived dates', () async {
      final notifier = container.read(mediaProvider.notifier);
      notifier.addToWatchedList(movie1);
      notifier.addWatchRecord(movie1.id, WatchRecord(rating: PersonalRating.loved));

      await notifier.clearAllData();

      final state = container.read(mediaProvider);
      expect(state.watchHistory, isEmpty);
      expect(state.startDates, isEmpty);
      expect(state.endDates, isEmpty);
      expect(prefs.getString('the_lounge_watch_history'), isNull);
    });
  });
}
