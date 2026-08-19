import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:the_lounge/models/media_item.dart';
import 'package:the_lounge/providers/ambiance_provider.dart';
import 'package:the_lounge/providers/navigation_provider.dart';
import 'package:the_lounge/providers/repository_provider.dart';
import 'package:the_lounge/repositories/mock_movie_repository.dart';
import 'package:the_lounge/screens/calendar_screen.dart';
import 'package:the_lounge/screens/archive_shelf_screen.dart';
import 'package:the_lounge/widgets/atmospheric_empty_state.dart';

/// Returns zero titles from every list endpoint -- MockMovieRepository's
/// base implementation ships non-empty fixture data, which is exactly
/// wrong for testing an empty state.
class _EmptyRepository extends MockMovieRepository {
  @override
  Future<List<MediaItem>> getTrendingMovies({int page = 1, String? originalLanguage}) async => [];

  @override
  Future<List<MediaItem>> getTrendingTvShows({int page = 1, String? originalLanguage}) async => [];
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SharedPreferences prefs;

  setUp(() async {
    GoogleFonts.config.allowRuntimeFetching = false;
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  group('ArchiveShelfScreen empty states (FS-3)', () {
    testWidgets('Watchlist pile shows AtmosphericEmptyState, CTA navigates to Discover', (tester) async {
      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          movieRepositoryProvider.overrideWithValue(MockMovieRepository()),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: ArchiveShelfScreen(kind: ArchiveShelfKind.watchlist)),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(AtmosphericEmptyState), findsWidgets);
      expect(find.text('Your Watchlist is empty'), findsOneWidget);
      expect(find.text('Discover Titles'), findsOneWidget);

      expect(container.read(navigationProvider).currentTab, isNot(AppTab.discover));
      await tester.tap(find.text('Discover Titles').first);
      await tester.pump();

      expect(container.read(navigationProvider).currentTab, equals(AppTab.discover));
    });

    testWidgets('Watched pile shows its own AtmosphericEmptyState copy', (tester) async {
      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          movieRepositoryProvider.overrideWithValue(MockMovieRepository()),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: ArchiveShelfScreen(kind: ArchiveShelfKind.watched)),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Nothing watched yet'), findsOneWidget);
      expect(find.text('Discover Titles'), findsOneWidget);
    });
  });

  group('CalendarScreen empty state (FS-3)', () {
    testWidgets('shows AtmosphericEmptyState with a Discover Titles CTA', (tester) async {
      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          movieRepositoryProvider.overrideWithValue(_EmptyRepository()),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: CalendarScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(AtmosphericEmptyState), findsOneWidget);
      expect(find.text('Discover Titles'), findsOneWidget);

      await tester.tap(find.text('Discover Titles'));
      await tester.pump();

      expect(container.read(navigationProvider).currentTab, equals(AppTab.discover));
    });
  });
}
