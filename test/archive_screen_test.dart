import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:the_lounge/screens/archive_screen.dart';
import 'package:the_lounge/screens/archive_bucket_screen.dart';
import 'package:the_lounge/providers/media_provider.dart';
import 'package:the_lounge/providers/navigation_provider.dart';
import 'package:the_lounge/providers/ambiance_provider.dart';
import 'package:the_lounge/repositories/mock_movie_repository.dart';

void main() {
  setUp(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  Future<ProviderContainer> pumpArchiveScreen(WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [
        movieRepositoryProvider.overrideWithValue(MockMovieRepository()),
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
    );
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: Scaffold(body: ArchiveScreen())),
      ),
    );
    await tester.pumpAndSettle();
    return container;
  }

  group('YSR-HUB-1: ArchiveScreen structure & routing', () {
    testWidgets('renders top bar and all 6 bucket cards', (tester) async {
      final container = await pumpArchiveScreen(tester);
      addTearDown(container.dispose);

      expect(find.text('Your Archive'), findsOneWidget);
      expect(find.textContaining('6 buckets'), findsOneWidget);

      expect(find.text('Watching'), findsOneWidget);
      expect(find.text('Watched'), findsOneWidget);
      expect(find.text('Watchlist'), findsOneWidget);
      expect(find.text('Saved'), findsOneWidget);
      expect(find.text('On-Hold'), findsOneWidget);
      expect(find.text('Dropped'), findsOneWidget);
    });

    testWidgets('tapping Watching card pushes ArchiveBucketScreen(kind: watching)', (tester) async {
      final container = await pumpArchiveScreen(tester);
      addTearDown(container.dispose);

      final finder = find.text('Watching');
      await tester.ensureVisible(finder);
      await tester.tap(finder);
      await tester.pumpAndSettle();

      final bucketScreen = tester.widget<ArchiveBucketScreen>(find.byType(ArchiveBucketScreen));
      expect(bucketScreen.kind, ArchiveBucketKind.watching);
    });

    testWidgets('tapping Dropped card pushes ArchiveBucketScreen(kind: dropped)', (tester) async {
      final container = await pumpArchiveScreen(tester);
      addTearDown(container.dispose);

      final finder = find.text('Dropped');
      await tester.ensureVisible(finder);
      await tester.tap(finder);
      await tester.pumpAndSettle();

      final bucketScreen = tester.widget<ArchiveBucketScreen>(find.byType(ArchiveBucketScreen));
      expect(bucketScreen.kind, ArchiveBucketKind.dropped);
    });

    testWidgets('tapping Watched card pushes ArchiveBucketScreen(kind: watched)', (tester) async {
      final container = await pumpArchiveScreen(tester);
      addTearDown(container.dispose);

      final finder = find.text('Watched');
      await tester.ensureVisible(finder);
      await tester.tap(finder);
      await tester.pumpAndSettle();

      final bucketScreen = tester.widget<ArchiveBucketScreen>(find.byType(ArchiveBucketScreen));
      expect(bucketScreen.kind, ArchiveBucketKind.watched);
    });

    testWidgets('COUNT-1 / COUNT-2: counts react dynamically to Movies vs TV media toggle',
        (tester) async {
      final container = await pumpArchiveScreen(tester);
      addTearDown(container.dispose);

      // Initially Movies mode: 0 movies · 6 buckets
      expect(find.text('0 movies · 6 buckets'), findsOneWidget);

      // Switch to TV mode
      container.read(navigationProvider.notifier).setMediaType(MediaTypeToggle.tv);
      await tester.pumpAndSettle();

      expect(find.text('0 TV shows · 6 buckets'), findsOneWidget);
    });
  });
}
