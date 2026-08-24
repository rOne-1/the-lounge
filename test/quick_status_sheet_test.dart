import 'dart:ui' show Tristate;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:the_lounge/models/hall_space.dart';
import 'package:the_lounge/models/media_item.dart';
import 'package:the_lounge/providers/media_provider.dart';
import 'package:the_lounge/providers/ambiance_provider.dart';
import 'package:the_lounge/services/hall_storage_service.dart';
import 'package:the_lounge/widgets/quick_status_sheet.dart';
import 'package:the_lounge/widgets/drag_to_dismiss_sheet.dart';
import 'package:the_lounge/widgets/media_card.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  final testItem = MediaItem(
    id: 'movie_101',
    title: 'Inception',
    type: MediaType.movie,
    rating: 8.8,
    overview: 'A thief who steals corporate secrets through the use of dream-sharing technology...',
    genres: const ['Action', 'Sci-Fi'],
    releaseOrAirDate: DateTime(2010),
  );

  group('QuickStatusSheet Widget Tests', () {
    testWidgets('displays all 6 status options and current active status badge', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => Consumer(
                  builder: (context, ref, child) {
                    return ElevatedButton(
                      onPressed: () => showQuickStatusSheet(context, ref, testItem),
                      child: const Text('Open Sheet'),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      );

      // Tap button to open QuickStatusSheet
      await tester.tap(find.text('Open Sheet'));
      await tester.pumpAndSettle();

      // Check QuickStatusSheet container is present
      expect(find.byType(QuickStatusSheet), findsOneWidget);
      expect(find.text('No Status'), findsOneWidget);

      // Check all 6 status options are present
      expect(find.text('Watchlist'), findsOneWidget);
      expect(find.text('Saved'), findsOneWidget);
      expect(find.text('Watching'), findsOneWidget);
      expect(find.text('On-Hold'), findsOneWidget);
      expect(find.text('Dropped'), findsOneWidget);
      expect(find.text('Watched'), findsOneWidget);
    });

    testWidgets('HALL-SAVE-1: shows a chip per Hall, defaulting to the active one selected',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => Consumer(
                  builder: (context, ref, child) {
                    return ElevatedButton(
                      onPressed: () => showQuickStatusSheet(context, ref, testItem),
                      child: const Text('Open Sheet'),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Sheet'));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('quick_status_hall_picker')), findsOneWidget);
      expect(find.text('The Grand Hall'), findsOneWidget);
      expect(find.text('The Mezzanine Hall'), findsOneWidget);
      expect(find.text('The Private Screening Hall'), findsOneWidget);
    });

    testWidgets(
        'HALL-SAVE-1: picking a different Hall and tapping a status places the title there, and it syncs into the aggregating Grand Hall',
        (WidgetTester tester) async {
      final container = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => Consumer(
                  builder: (context, ref, child) {
                    return ElevatedButton(
                      onPressed: () => showQuickStatusSheet(context, ref, testItem),
                      child: const Text('Open Sheet'),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Sheet'));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('quick_status_hall_custom_1')));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Watchlist'));
      await tester.pump();
      // The confirmation toast has its own 3s auto-dismiss timer -- let it
      // fully resolve before the test ends, or flutter_test's pending-timer
      // invariant trips.
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();

      // It landed in the Mezzanine Hall's (custom_1) own storage, not the
      // Grand Hall's.
      final raw = prefs.getString(
        HallStorageService.domainStorageKey('custom_1', MediumDomain.movies),
      );
      expect(raw, isNotNull);
      expect(raw!.contains('movie_101'), isTrue);
      final grandHallRaw = prefs.getString(
        HallStorageService.domainStorageKey('common', MediumDomain.movies),
      );
      expect(grandHallRaw == null || !grandHallRaw.contains('movie_101'), isTrue);

      // HALL-SYNC-1: since the active Hall is the Grand Hall (which
      // aggregates every other Hall), the save is immediately visible --
      // as a read-only aggregated title, not a native one.
      final state = container.read(mediaProvider);
      expect(state.watchlist.containsKey('movie_101'), isTrue);
      expect(state.readOnlyMediaIds.contains('movie_101'), isTrue);
    });

    testWidgets('BETA3-A11Y-1: status pills expose a button role, correct label, and selected state', (WidgetTester tester) async {
      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
      );
      addTearDown(container.dispose);
      final handle = tester.ensureSemantics();

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => Consumer(
                  builder: (context, ref, child) {
                    return ElevatedButton(
                      onPressed: () => showQuickStatusSheet(context, ref, testItem),
                      child: const Text('Open Sheet'),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Sheet'));
      await tester.pumpAndSettle();

      final watchlistLabel = find.bySemanticsLabel('Watchlist');
      expect(watchlistLabel, findsOneWidget);
      var watchlistSemantics = tester.getSemantics(watchlistLabel);
      expect(watchlistSemantics.flagsCollection.isButton, isTrue);
      expect(watchlistSemantics.flagsCollection.isSelected, isNot(Tristate.isTrue));

      await tester.tap(find.text('Watchlist'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open Sheet'));
      await tester.pumpAndSettle();

      watchlistSemantics = tester.getSemantics(find.bySemanticsLabel('Watchlist'));
      expect(watchlistSemantics.flagsCollection.isSelected, Tristate.isTrue);

      handle.dispose();
    });

    testWidgets('is wrapped in DragToDismissSheet and a fling-down dismisses it (DS-3)', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => Consumer(
                  builder: (context, ref, child) {
                    return ElevatedButton(
                      onPressed: () => showQuickStatusSheet(context, ref, testItem),
                      child: const Text('Open Sheet'),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Sheet'));
      await tester.pumpAndSettle();

      expect(find.byType(DragToDismissSheet), findsOneWidget);
      expect(find.byType(QuickStatusSheet), findsOneWidget);

      await tester.fling(find.byType(QuickStatusSheet), const Offset(0, 300), 1000);
      await tester.pumpAndSettle();

      expect(find.byType(QuickStatusSheet), findsNothing);
    });

    testWidgets('tapping status option updates provider state and active badge', (WidgetTester tester) async {
      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => Consumer(
                  builder: (context, ref, child) {
                    return ElevatedButton(
                      onPressed: () => showQuickStatusSheet(context, ref, testItem),
                      child: const Text('Open Sheet'),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      );

      // Open sheet
      await tester.tap(find.text('Open Sheet'));
      await tester.pumpAndSettle();

      // Tap 'Watching' pill
      await tester.tap(find.text('Watching'));
      await tester.pumpAndSettle();

      // Verify item is now in watchingList
      final mediaState = container.read(mediaProvider);
      expect(mediaState.watchingList.containsKey(testItem.id), isTrue);

      // Re-open sheet and check active status badge shows 'Watching'
      await tester.tap(find.text('Open Sheet'));
      await tester.pumpAndSettle();

      expect(find.text('Watching'), findsNWidgets(2)); // Badge + Pill
    });

    testWidgets('tapping Watched status toggles watchedList state', (WidgetTester tester) async {
      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => Consumer(
                  builder: (context, ref, child) {
                    return ElevatedButton(
                      onPressed: () => showQuickStatusSheet(context, ref, testItem),
                      child: const Text('Open Sheet'),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      );

      // Open sheet & tap Watched
      await tester.tap(find.text('Open Sheet'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Watched'));
      await tester.pumpAndSettle();

      // Verify in watchedList
      expect(container.read(mediaProvider).watchedList.containsKey(testItem.id), isTrue);

      // Open sheet & tap Watched again to remove
      await tester.tap(find.text('Open Sheet'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Watched').last);
      await tester.pumpAndSettle();

      // Verify removed from watchedList
      expect(container.read(mediaProvider).watchedList.containsKey(testItem.id), isFalse);
    });
  });

  group('MediaCard Widget Tests', () {
    testWidgets('long press opens QuickStatusSheet without navigating', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: Center(
                child: MediaCard(
                  item: testItem,
                  isDark: true,
                  width: 120,
                  height: 180,
                  showTitle: true,
                ),
              ),
            ),
          ),
        ),
      );

      // Long press on MediaCard
      await tester.longPress(find.byType(MediaCard));
      await tester.pumpAndSettle();

      // Verify QuickStatusSheet is shown with all 6 options
      expect(find.byType(QuickStatusSheet), findsOneWidget);
      expect(find.text('Watchlist'), findsOneWidget);
      expect(find.text('Saved'), findsOneWidget);
      expect(find.text('Watching'), findsOneWidget);
      expect(find.text('On-Hold'), findsOneWidget);
      expect(find.text('Dropped'), findsOneWidget);
      expect(find.text('Watched'), findsOneWidget);
    });
  });
}
