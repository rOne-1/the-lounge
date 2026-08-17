import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:the_lounge/screens/folders_screen.dart';
import 'package:the_lounge/screens/folder_detail_screen.dart';
import 'package:the_lounge/screens/detail_screen.dart';
import 'package:the_lounge/screens/your_space_screen.dart';
import 'package:the_lounge/providers/media_provider.dart';
import 'package:the_lounge/providers/ambiance_provider.dart';
import 'package:the_lounge/models/media_item.dart';
import 'package:the_lounge/repositories/mock_movie_repository.dart';

class _TestRepository extends MockMovieRepository {
  final Map<String, MediaItem> items;
  _TestRepository(this.items);

  @override
  Future<MediaItem?> getMediaDetails(String id) async => items[id];

  @override
  Future<TvSeason?> getTvSeasonDetails(String tvId, int seasonNumber) async => null;
}

void main() {
  setUp(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  final movie1 = MediaItem(
    id: 'movie-folder-1',
    title: 'Folder Test Movie',
    type: MediaType.movie,
    rating: 7.5,
    overview: 'A movie to put in a folder.',
    genres: const ['Drama'],
  );

  Future<ProviderContainer> pumpFolders(WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        movieRepositoryProvider.overrideWithValue(_TestRepository({movie1.id: movie1})),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: FoldersScreen()),
      ),
    );
    await tester.pumpAndSettle();
    return container;
  }

  group('PERS-FOLDERS-1: FoldersScreen', () {
    testWidgets('shows the empty state with no folders', (tester) async {
      await pumpFolders(tester);
      expect(find.text('No folders yet'), findsOneWidget);
    });

    testWidgets('creating a folder adds it to the list', (tester) async {
      final container = await pumpFolders(tester);

      await tester.tap(find.byKey(const ValueKey('create_folder_button')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Spooky Season');
      await tester.tap(find.text('Create'));
      await tester.pumpAndSettle();

      expect(find.text('Spooky Season'), findsOneWidget);
      expect(container.read(mediaProvider).customFolders, hasLength(1));
    });

    testWidgets('creating a folder works via the real Your Space navigation path',
        (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          movieRepositoryProvider.overrideWithValue(_TestRepository({movie1.id: movie1})),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: Scaffold(body: YourSpaceScreen())),
        ),
      );
      await tester.pumpAndSettle();

      final foldersCardFinder = find.text('Custom Folders');
      await tester.ensureVisible(foldersCardFinder);
      await tester.pumpAndSettle();
      await tester.tap(foldersCardFinder);
      await tester.pumpAndSettle();

      expect(find.byType(FoldersScreen), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('create_folder_button')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Via Your Space');
      await tester.tap(find.text('Create'));
      await tester.pumpAndSettle();

      expect(find.text('Via Your Space'), findsOneWidget);
      expect(container.read(mediaProvider).customFolders, hasLength(1));
    });

    testWidgets('tapping a folder opens FolderDetailScreen', (tester) async {
      final container = await pumpFolders(tester);
      container.read(mediaProvider.notifier).createFolder('My Folder');
      await tester.pumpAndSettle();

      await tester.tap(find.text('My Folder'));
      await tester.pumpAndSettle();

      expect(find.byType(FolderDetailScreen), findsOneWidget);
    });
  });

  group('PERS-FOLDERS-1: FolderDetailScreen', () {
    testWidgets('shows the empty state for a folder with no titles', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final container = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      );
      addTearDown(container.dispose);
      final folderId = container.read(mediaProvider.notifier).createFolder('Empty Folder');

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(home: FolderDetailScreen(folderId: folderId)),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('This folder is empty'), findsOneWidget);
    });

    testWidgets('renders a known title instantly and removing it via the X clears it', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          movieRepositoryProvider.overrideWithValue(_TestRepository({movie1.id: movie1})),
        ],
      );
      addTearDown(container.dispose);
      container.read(mediaProvider.notifier).addToWatchlist(movie1);
      final folderId = container.read(mediaProvider.notifier).createFolder('With Item');
      container.read(mediaProvider.notifier).addToFolder(folderId, movie1.id);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(home: FolderDetailScreen(folderId: folderId)),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(movie1.title), findsOneWidget);

      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pumpAndSettle();

      expect(container.read(mediaProvider).customFolders[folderId]!.mediaIds, isEmpty);
      expect(find.text('This folder is empty'), findsOneWidget);
    });

    testWidgets('rename updates the app bar title and folder name', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final container = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      );
      addTearDown(container.dispose);
      final folderId = container.read(mediaProvider.notifier).createFolder('Before Rename');

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(home: FolderDetailScreen(folderId: folderId)),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('rename_folder_button')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'After Rename');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(find.text('After Rename'), findsOneWidget);
      expect(container.read(mediaProvider).customFolders[folderId]!.name, 'After Rename');
    });

    testWidgets('delete removes the folder and pops back', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final container = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      );
      addTearDown(container.dispose);
      final folderId = container.read(mediaProvider.notifier).createFolder('Delete Me');

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Builder(
              builder: (context) => Scaffold(
                body: Center(
                  child: TextButton(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => FolderDetailScreen(folderId: folderId)),
                    ),
                    child: const Text('open'),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('delete_folder_button')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      expect(container.read(mediaProvider).customFolders.containsKey(folderId), isFalse);
      expect(find.text('open'), findsOneWidget); // popped back to caller
    });
  });

  group('PERS-FOLDERS-1: Add to Folder from DetailScreen', () {
    testWidgets('adding a title via the Add to Folder sheet reflects in provider state',
        (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          movieRepositoryProvider.overrideWithValue(_TestRepository({movie1.id: movie1})),
        ],
      );
      addTearDown(container.dispose);
      container.read(mediaProvider.notifier).createFolder('Pick Me');

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(home: DetailScreen(id: movie1.id, initialItem: movie1)),
        ),
      );
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));

      final addToFolderFinder = find.byKey(const ValueKey('add_to_folder_button'));
      // Same convergent-scroll approach as personal_rating_widget_test.dart:
      // the action buttons sit below the hero, past the default viewport.
      var center = tester.getCenter(addToFolderFinder);
      var guard = 0;
      while ((center.dy < 100 || center.dy > 550) && guard < 10) {
        final delta = center.dy > 550 ? -150.0 : 150.0;
        await tester.drag(find.byType(SingleChildScrollView).first, Offset(0, delta));
        await tester.pumpAndSettle();
        center = tester.getCenter(addToFolderFinder);
        guard++;
      }
      await tester.tap(addToFolderFinder);
      await tester.pumpAndSettle();

      expect(find.text('Add to Folder'), findsWidgets);
      final folderId = container.read(mediaProvider).customFolders.keys.first;
      await tester.tap(find.text('Pick Me'));
      await tester.pumpAndSettle();

      expect(container.read(mediaProvider).customFolders[folderId]!.mediaIds, [movie1.id]);
    });
  });
}
