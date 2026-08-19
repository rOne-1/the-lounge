import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:the_lounge/screens/tools_screen.dart';
import 'package:the_lounge/screens/rate_titles_screen.dart';
import 'package:the_lounge/screens/folders_screen.dart';
import 'package:the_lounge/screens/cleanup_swipe_screen.dart';
import 'package:the_lounge/screens/rewatch_vault_screen.dart';
import 'package:the_lounge/providers/media_provider.dart';
import 'package:the_lounge/providers/ambiance_provider.dart';
import 'package:the_lounge/repositories/mock_movie_repository.dart';

void main() {
  setUp(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  Future<ProviderContainer> pumpToolsScreen(WidgetTester tester) async {
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
        child: const MaterialApp(home: Scaffold(body: ToolsScreen())),
      ),
    );
    await tester.pumpAndSettle();
    return container;
  }

  group('YSR-HUB-2: ToolsScreen structure & routing', () {
    testWidgets('renders top bar and all 4 tool cards', (tester) async {
      final container = await pumpToolsScreen(tester);
      addTearDown(container.dispose);

      expect(find.text('Tools'), findsOneWidget);
      expect(find.text('Keep your lounge in order'), findsOneWidget);

      expect(find.text('Rate Titles'), findsOneWidget);
      expect(find.text('Custom Folders'), findsOneWidget);
      expect(find.text('Cleanup Session'), findsOneWidget);
      expect(find.text('Rewatch Vault'), findsOneWidget);
    });

    testWidgets('tapping Rate Titles pushes RateTitlesScreen', (tester) async {
      final container = await pumpToolsScreen(tester);
      addTearDown(container.dispose);

      final finder = find.text('Rate Titles');
      await tester.ensureVisible(finder);
      await tester.tap(finder);
      await tester.pumpAndSettle();

      expect(find.byType(RateTitlesScreen), findsOneWidget);
    });

    testWidgets('tapping Custom Folders pushes FoldersScreen', (tester) async {
      final container = await pumpToolsScreen(tester);
      addTearDown(container.dispose);

      final finder = find.text('Custom Folders');
      await tester.ensureVisible(finder);
      await tester.tap(finder);
      await tester.pumpAndSettle();

      expect(find.byType(FoldersScreen), findsOneWidget);
    });

    testWidgets('tapping Cleanup Session pushes CleanupSwipeScreen', (tester) async {
      final container = await pumpToolsScreen(tester);
      addTearDown(container.dispose);

      final finder = find.text('Cleanup Session');
      await tester.ensureVisible(finder);
      await tester.tap(finder);
      await tester.pumpAndSettle();

      expect(find.byType(CleanupSwipeScreen), findsOneWidget);
    });

    testWidgets('tapping Rewatch Vault pushes RewatchVaultScreen', (tester) async {
      final container = await pumpToolsScreen(tester);
      addTearDown(container.dispose);

      final finder = find.text('Rewatch Vault');
      await tester.ensureVisible(finder);
      await tester.tap(finder);
      await tester.pumpAndSettle();

      expect(find.byType(RewatchVaultScreen), findsOneWidget);
    });
  });
}
