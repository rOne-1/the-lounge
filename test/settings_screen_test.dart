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
import 'package:the_lounge/repositories/mock_movie_repository.dart';
import 'package:the_lounge/models/discover_filter_params.dart';

class MockFilePickerPlatform extends FilePickerPlatform {
  String? savePath;
  FilePickerResult? pickResult;
  bool saveFileCalled = false;
  Uint8List? savedBytes;
  bool pickFilesCalled = false;

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

    expect(find.byType(AlertDialog), findsNothing);
    expect(container.read(mediaProvider).watchlist.containsKey('movie_imported'), isTrue);
    expect(container.read(mediaProvider).watchProvidersCountry, equals('CA'));
    expect(container.read(ambianceProvider), equals(readingRoomTheme));
    expect(find.text('Backup imported successfully.'), findsOneWidget);
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

    expect(find.byType(AlertDialog), findsOneWidget);
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
