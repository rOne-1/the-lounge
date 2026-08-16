import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:file_picker/file_picker.dart';
import 'package:file_picker/src/platform/file_picker_platform_interface.dart';
import 'package:share_plus_platform_interface/share_plus_platform_interface.dart';
import 'package:the_lounge/providers/media_provider.dart';
import 'package:the_lounge/providers/ambiance_provider.dart';
import 'package:the_lounge/screens/settings_screen.dart';
import 'package:the_lounge/constants.dart';
import 'package:the_lounge/themes/app_theme.dart';
import 'package:the_lounge/themes/screening_room_theme.dart';
import 'package:the_lounge/themes/reading_room_theme.dart';
import 'package:the_lounge/models/media_item.dart';
import 'package:the_lounge/widgets/animated_segmented_control.dart';
import 'package:the_lounge/widgets/lounge_dialog.dart';
import 'package:the_lounge/repositories/mock_movie_repository.dart';
import 'package:the_lounge/models/discover_filter_params.dart';
import 'package:the_lounge/services/api_call_tracker.dart';

class MockFilePickerPlatform extends FilePickerPlatform {
  String? savePath;
  FilePickerResult? pickResult;
  bool saveFileCalled = false;
  Uint8List? savedBytes;
  bool pickFilesCalled = false;

  /// Real (fake-clock-tracked) delay so tests can observe the E8 blocking
  /// overlay mid-flight via `tester.pump()` before it resolves, instead of
  /// racing a zero-latency mock that would already be done by the next frame.
  Duration saveDelay = Duration.zero;

  @override
  Future<String?> saveFile({
    String? dialogTitle,
    String? fileName,
    String? initialDirectory,
    FileType type = FileType.any,
    List<String>? allowedExtensions,
    Uint8List? bytes,
    bool lockParentWindow = false,
  }) async {
    if (saveDelay > Duration.zero) {
      await Future<void>.delayed(saveDelay);
    }
    saveFileCalled = true;
    savedBytes = bytes;
    return savePath;
  }

  @override
  Future<FilePickerResult?> pickFiles({
    String? dialogTitle,
    String? initialDirectory,
    FileType type = FileType.any,
    List<String>? allowedExtensions,
    Function(FilePickerStatus)? onFileLoading,
    int compressionQuality = 0,
    bool allowMultiple = false,
    bool withData = false,
    bool withReadStream = false,
    bool lockParentWindow = false,
    bool readSequential = false,
    bool cancelUploadOnWindowBlur = true,
  }) async {
    pickFilesCalled = true;
    return pickResult;
  }
}

class MockSharePlatform extends SharePlatform {
  bool shareCalled = false;
  ShareParams? lastParams;

  @override
  Future<ShareResult> share(ShareParams params) async {
    shareCalled = true;
    lastParams = params;
    return const ShareResult('result', ShareResultStatus.success);
  }
}

void main() {
  late MockFilePickerPlatform mockFilePicker;
  late MockSharePlatform mockSharePlatform;
  late SharedPreferences prefs;

  setUp(() async {
    mockFilePicker = MockFilePickerPlatform();
    mockSharePlatform = MockSharePlatform();
    FilePickerPlatform.instance = mockFilePicker;
    SharePlatform.instance = mockSharePlatform;
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    ApiCallTracker.instance.reset();
  });

  ProviderContainer createContainer() {
    return ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        // Override movieRepositoryProvider with an instantly-resolving stub so
        // that loadPool() calls triggered by importBackupJson don't leave
        // pending async timers that cause pumpAndSettle to time out.
        movieRepositoryProvider.overrideWithValue(_InstantEmptyRepository()),
      ],
    );
  }

  Widget createSettingsScreen(ProviderContainer container) {
    return UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(
        home: SettingsScreen(),
      ),
    );
  }

  testWidgets('SettingsScreen renders correctly in light/dark themes and toggle updates ambianceProvider', (WidgetTester tester) async {
    final container = createContainer();
    addTearDown(container.dispose);

    expect(container.read(ambianceProvider), equals(screeningRoomTheme));

    await tester.pumpWidget(createSettingsScreen(container));
    await tester.pumpAndSettle();

    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('AMBIANCE'), findsOneWidget);
    expect(find.text('DATA MANAGEMENT'), findsOneWidget);
    expect(find.text('ABOUT'), findsOneWidget);

    final switchFinder = find.byType(AnimatedSegmentedControl<AppTheme>);
    expect(switchFinder, findsOneWidget);

    

    await tester.tap(find.text('Reading'));
    await tester.pumpAndSettle();

    expect(container.read(ambianceProvider), equals(readingRoomTheme));

    
  });

  testWidgets('E6: Debug section shows live TMDB call/failure counts', (WidgetTester tester) async {
    final container = createContainer();
    addTearDown(container.dispose);
    addTearDown(ApiCallTracker.instance.reset);

    await tester.pumpWidget(createSettingsScreen(container));
    await tester.pumpAndSettle();

    // The Debug section sits at the bottom of the ListView, below the
    // default viewport + cache extent in the test surface.
    await tester.scrollUntilVisible(find.text('DEBUG'), 300);
    await tester.pumpAndSettle();

    expect(find.text('DEBUG'), findsOneWidget);
    expect(find.text('TMDB calls this session'), findsOneWidget);
    expect(find.text('0'), findsWidgets);

    ApiCallTracker.instance.recordCall();
    ApiCallTracker.instance.recordCall();
    ApiCallTracker.instance.recordFailure();
    await tester.pump();

    expect(find.text('2'), findsOneWidget);
    expect(find.text('1'), findsOneWidget);
  });

  testWidgets('Export Backup triggers file picker serialization and saves file', (WidgetTester tester) async {
    final container = createContainer();
    addTearDown(container.dispose);

    final testMovie = MediaItem(
      id: 'movie_1',
      title: 'Inception',
      type: MediaType.movie,
      rating: 8.8,
      overview: 'Dream within a dream',
      genres: const [],
    );
    container.read(mediaProvider.notifier).addToWatchlist(testMovie);

    final exportPath = 'mock_export_path.json';
    mockFilePicker.savePath = exportPath;

    await tester.pumpWidget(createSettingsScreen(container));
    await tester.pumpAndSettle();

    final exportBtn = find.byKey(const ValueKey('export_backup_button'));
    expect(exportBtn, findsOneWidget);

    await tester.tap(exportBtn);
    await tester.pumpAndSettle();

    expect(mockFilePicker.saveFileCalled, isTrue);
    expect(mockFilePicker.savedBytes, isNotNull);

    final exportedJson = utf8.decode(mockFilePicker.savedBytes!);
    final decoded = jsonDecode(exportedJson);
    expect(decoded['version'], equals(1));
    expect(decoded['watchlist']['movie_1']['title'], equals('Inception'));
    expect(find.text('Backup exported successfully.'), findsOneWidget);

    // Let the LoungeToast's auto-dismiss timer fire before teardown.
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
  });

  testWidgets('Share Backup triggers SharePlatform serialization', (WidgetTester tester) async {
    final container = createContainer();
    addTearDown(container.dispose);

    await tester.pumpWidget(createSettingsScreen(container));
    await tester.pumpAndSettle();

    final shareBtn = find.byKey(const ValueKey('share_backup_button'));
    expect(shareBtn, findsOneWidget);

    await tester.tap(shareBtn);
    await tester.pumpAndSettle();

    expect(mockSharePlatform.shareCalled, isTrue);
    expect(mockSharePlatform.lastParams, isNotNull);
    expect(mockSharePlatform.lastParams!.files, isNotEmpty);
    expect(mockSharePlatform.lastParams!.fileNameOverrides, isNotEmpty);
    expect(mockSharePlatform.lastParams!.fileNameOverrides!.first, equals('the_lounge_backup.json'));
  });

  testWidgets('Import Backup perform file selection and updates Riverpod state', (WidgetTester tester) async {
    final container = createContainer();
    addTearDown(container.dispose);

    expect(container.read(mediaProvider).watchlist, isEmpty);

    final backupData = {
      'version': 1,
      'watchlist': {
        'movie_imported': {
          'id': 'movie_imported',
          'title': 'Imported Movie',
          'type': 'movie',
          'rating': 7.5,
          'overview': 'Imported from JSON',
          'genres': [],
        }
      },
      'maybeList': {},
      'watchingList': {},
      'watchedList': {},
      'droppedList': {},
      'onHoldList': {},
      'watchedEpisodes': {},
      'watchProvidersCountry': 'CA',
      'selectedAmbiance': 'readingRoom',
    };
    final backupJson = jsonEncode(backupData);

    mockFilePicker.pickResult = FilePickerResult([
      PlatformFile(
        name: 'test_backup.json',
        size: backupJson.length,
        bytes: Uint8List.fromList(utf8.encode(backupJson)),
      )
    ]);

    await tester.pumpWidget(createSettingsScreen(container));
    await tester.pumpAndSettle();

    final importBtn = find.byKey(const ValueKey('import_backup_button'));
    expect(importBtn, findsOneWidget);

    await tester.tap(importBtn);
    await tester.pumpAndSettle();

    expect(find.byType(LoungeDialog), findsNothing);
    expect(container.read(mediaProvider).watchlist.containsKey('movie_imported'), isTrue);
    expect(container.read(mediaProvider).watchProvidersCountry, equals('CA'));
    expect(container.read(ambianceProvider), equals(readingRoomTheme));
    expect(find.text('Backup imported successfully.'), findsOneWidget);

    // Let the LoungeToast's auto-dismiss timer fire before teardown.
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
  });

  testWidgets('Import Backup with existing local data prompts for overwrite confirmation', (WidgetTester tester) async {
    final container = createContainer();
    addTearDown(container.dispose);

    final existingMovie = MediaItem(
      id: 'existing_movie',
      title: 'Existing Title',
      type: MediaType.movie,
      rating: 5.0,
      overview: 'Existing Overview',
      genres: const [],
    );
    container.read(mediaProvider.notifier).addToWatchlist(existingMovie);

    final backupData = {
      'version': 1,
      'watchlist': {
        'new_movie': {
          'id': 'new_movie',
          'title': 'New Movie Title',
          'type': 'movie',
          'rating': 9.0,
          'overview': 'New Overview',
          'genres': [],
        }
      },
      'maybeList': {},
      'watchingList': {},
      'watchedList': {},
      'droppedList': {},
      'onHoldList': {},
      'watchedEpisodes': {},
      'watchProvidersCountry': 'US',
      'selectedAmbiance': 'screeningRoom',
    };
    final backupJson = jsonEncode(backupData);

    mockFilePicker.pickResult = FilePickerResult([
      PlatformFile(
        name: 'test_backup.json',
        size: backupJson.length,
        bytes: Uint8List.fromList(utf8.encode(backupJson)),
      )
    ]);

    await tester.pumpWidget(createSettingsScreen(container));
    await tester.pumpAndSettle();

    final importBtn = find.byKey(const ValueKey('import_backup_button'));
    await tester.tap(importBtn);
    await tester.pumpAndSettle();

    expect(find.byType(LoungeDialog), findsOneWidget);
    expect(find.text('Overwrite current data?'), findsOneWidget);
    expect(find.text('This will replace all your current watchlists, watch history, and settings. Are you sure you want to overwrite?'), findsOneWidget);

    final cancelBtn = find.byKey(const ValueKey('cancel_overwrite_button'));
    await tester.tap(cancelBtn);
    await tester.pumpAndSettle();

    expect(container.read(mediaProvider).watchlist.containsKey('existing_movie'), isTrue);
    expect(container.read(mediaProvider).watchlist.containsKey('new_movie'), isFalse);

    await tester.tap(importBtn);
    await tester.pumpAndSettle();

    final confirmBtn = find.byKey(const ValueKey('confirm_overwrite_button'));
    await tester.tap(confirmBtn);
    await tester.pumpAndSettle();

    expect(container.read(mediaProvider).watchlist.containsKey('existing_movie'), isFalse);
    expect(container.read(mediaProvider).watchlist.containsKey('new_movie'), isTrue);
    expect(find.text('Backup imported successfully.'), findsOneWidget);

    // Let the LoungeToast's auto-dismiss timer fire before teardown.
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
  });

  testWidgets('Reset Account prompts for confirmation and clears data (E8)', (WidgetTester tester) async {
    final container = createContainer();
    addTearDown(container.dispose);

    final testMovie = MediaItem(
      id: 'movie_1',
      title: 'Inception',
      type: MediaType.movie,
      rating: 8.8,
      overview: 'Dream within a dream',
      genres: const [],
    );
    container.read(mediaProvider.notifier).addToWatchlist(testMovie);
    expect(container.read(mediaProvider).watchlist, isNotEmpty);

    await tester.pumpWidget(createSettingsScreen(container));
    await tester.pumpAndSettle();

    final resetBtn = find.byKey(const ValueKey('reset_account_button'));
    await tester.tap(resetBtn);
    await tester.pumpAndSettle();

    expect(find.text('Reset everything?'), findsOneWidget);

    // Cancelling must not touch any data.
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(container.read(mediaProvider).watchlist, isNotEmpty);

    await tester.tap(resetBtn);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Reset Everything'));
    await tester.pumpAndSettle();

    expect(container.read(mediaProvider).watchlist, isEmpty);
    expect(find.text('Account reset successfully.'), findsOneWidget);

    // Let the LoungeToast's auto-dismiss timer fire before teardown.
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
  });

  test('clearAllData refreshes the discover pool exclusion snapshot (B5)', () async {
    // Plain (non-widget) test, deliberately: this only needs
    // MediaNotifier.clearAllData() and the discover deck provider, neither
    // of which SettingsScreen's own widget tree watches -- driving it
    // through testWidgets' fake-async pump cycle for an unobserved provider
    // is exactly what made this flaky/hang-prone (see git history). A plain
    // test runs real async/real Timers directly, no pumping involved.
    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        movieRepositoryProvider.overrideWithValue(_SingleMovieResetRepository()),
      ],
    );
    addTearDown(container.dispose);

    // movie_1 is in the watchlist, so it must be excluded from the pool.
    container.read(mediaProvider.notifier).addToWatchlist(
          const MediaItem(
            id: '1',
            title: 'Movie 1',
            type: MediaType.movie,
            rating: 8.0,
            overview: '',
            genres: [],
          ),
        );
    await container.read(discoverMoviesDeckProvider.notifier).loadPool(isReload: false);
    expect(
      container.read(discoverMoviesDeckProvider).pool.any((item) => item.id == '1'),
      isFalse,
      reason: 'Precondition: movie_1 must be excluded (it is in the watchlist)',
    );

    await container.read(mediaProvider.notifier).clearAllData();
    // clearAllData() fires the deck refresh without awaiting it (matching
    // importBackupJson's existing fire-and-forget pattern).
    await Future<void>.delayed(const Duration(milliseconds: 500));

    // The watchlist is now empty, so movie_1 must reappear in the pool --
    // this only happens if clearAllData() actually re-ran loadPool().
    expect(
      container.read(discoverMoviesDeckProvider).pool.any((item) => item.id == '1'),
      isTrue,
      reason: 'movie_1 is no longer excluded after reset and must be back in the pool',
    );
  });

  testWidgets('Export shows the blocking loading overlay while running, then clears it (E8)', (WidgetTester tester) async {
    final container = createContainer();
    addTearDown(container.dispose);

    mockFilePicker.savePath = 'mock_export_path.json';
    // Force a real (fake-clock) gap so the overlay is observably up before
    // the operation resolves, instead of racing a zero-latency mock.
    mockFilePicker.saveDelay = const Duration(milliseconds: 50);

    await tester.pumpWidget(createSettingsScreen(container));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('export_backup_button')));
    await tester.pump();
    expect(find.text('Exporting your backup…'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.pumpAndSettle();
    expect(find.text('Exporting your backup…'), findsNothing);
    expect(find.text('Backup exported successfully.'), findsOneWidget);

    // Let the LoungeToast's auto-dismiss timer fire before teardown.
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
  });

  testWidgets('Import Backup with malformed/unsupported file shows error message', (WidgetTester tester) async {
    final container = createContainer();
    addTearDown(container.dispose);

    final badBackup = '{"version": 2, "watchlist": {}}';

    mockFilePicker.pickResult = FilePickerResult([
      PlatformFile(
        name: 'bad_backup.json',
        size: badBackup.length,
        bytes: Uint8List.fromList(utf8.encode(badBackup)),
      )
    ]);

    await tester.pumpWidget(createSettingsScreen(container));
    await tester.pumpAndSettle();

    final importBtn = find.byKey(const ValueKey('import_backup_button'));
    await tester.tap(importBtn);
    await tester.pumpAndSettle();

    expect(find.text('Import failed: Invalid backup file format.'), findsOneWidget);

    // Let the LoungeToast's auto-dismiss timer fire before teardown.
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
  });
}

/// A repository stub that resolves all calls synchronously (no timers) with
/// empty results. Used in settings tests to prevent loadPool() — triggered by
/// importBackupJson — from leaving pending async timers that cause
/// pumpAndSettle to time out.
class _InstantEmptyRepository extends MockMovieRepository {
  @override
  Future<List<MediaItem>> discoverMedia({
    required bool isMovies,
    required DiscoverFilterParams params,
    int page = 1,
  }) async =>
      [];

  @override
  Future<List<MediaItem>> getPopularMovies({int page = 1}) async => [];

  @override
  Future<List<MediaItem>> getTrendingMovies({int page = 1}) async => [];

  @override
  Future<List<MediaItem>> getTopRatedMovies({int page = 1}) async => [];

  @override
  Future<List<MediaItem>> getNowPlayingMovies({
    int page = 1,
    String? region,
  }) async =>
      [];

  @override
  Future<List<MediaItem>> getUpcomingMovies({int page = 1}) async => [];

  @override
  Future<List<MediaItem>> getTrendingTvShows({int page = 1}) async => [];

  @override
  Future<List<MediaItem>> getTopRatedTvShows({int page = 1}) async => [];

  @override
  Future<TvSeason?> getTvSeasonDetails(String tvId, int seasonNumber) async =>
      null;
}

/// A repository that returns exactly one movie (id='1') from [discoverMedia],
/// used to prove the discover pool's exclusion snapshot actually gets
/// refreshed after a reset (B5).
class _SingleMovieResetRepository extends MockMovieRepository {
  static const _movie1 = MediaItem(
    id: '1',
    title: 'Movie 1',
    type: MediaType.movie,
    rating: 8.0,
    overview: '',
    genres: [],
    // Without a vote count, meanRatingOf/weightedRatingOf treat this as
    // "unvoted" and exclude it from the pool mean entirely, collapsing its
    // own weighted rating to 0 and failing loadPool's quality filter --
    // nothing to do with exclusion. Matches discover_test.dart's proven
    // _SingleMovieRepository fixture.
    voteCount: 5000,
  );

  @override
  Future<List<MediaItem>> discoverMedia({
    required bool isMovies,
    required DiscoverFilterParams params,
    int page = 1,
  }) async =>
      isMovies && page == 1 ? [_movie1] : [];

  // loadPool's fallback calls (getPopularMovies for movies, getTopRatedTvShows
  // for TV) fall through to MockMovieRepository's base implementations,
  // which carry real 100ms Future.delayed() calls each. Since discoverMedia
  // above only ever returns one item (so loadPool's `< 5 items` loop
  // condition never short-circuits and always runs all 5 attempts), those
  // delays compound to ~1.5s+ per loadPool() call if left in place.
  // Overriding these to resolve instantly, matching discover_test.dart's
  // proven _SingleMovieRepository pattern, keeps this test fast and
  // deterministic.
  @override
  Future<List<MediaItem>> getPopularMovies({int page = 1}) async => [];

  @override
  Future<List<MediaItem>> getTrendingMovies({int page = 1}) async => [];

  @override
  Future<List<MediaItem>> getTopRatedMovies({int page = 1}) async => [];

  @override
  Future<List<MediaItem>> getNowPlayingMovies({
    int page = 1,
    String? region,
  }) async =>
      [];

  @override
  Future<List<MediaItem>> getUpcomingMovies({int page = 1}) async => [];

  @override
  Future<List<MediaItem>> getTopRatedTvShows({int page = 1}) async => [];
}
