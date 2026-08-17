// Widget tests for PERS-SPACE-1: Your Space's 3-group landing page
// (Piles/Tools/Browse & Discovery) and its card navigation routing.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:the_lounge/screens/your_space_screen.dart';
import 'package:the_lounge/screens/pile_screen.dart';
import 'package:the_lounge/screens/rate_titles_screen.dart';
import 'package:the_lounge/screens/folders_screen.dart';
import 'package:the_lounge/screens/cleanup_swipe_screen.dart';
import 'package:the_lounge/screens/rewatch_vault_screen.dart';
import 'package:the_lounge/screens/settings_screen.dart';
import 'package:the_lounge/providers/media_provider.dart';
import 'package:the_lounge/providers/navigation_provider.dart';
import 'package:the_lounge/providers/ambiance_provider.dart';
import 'package:the_lounge/repositories/mock_movie_repository.dart';

void main() {
  setUp(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  Future<ProviderContainer> pumpYourSpace(WidgetTester tester) async {
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
        child: const MaterialApp(home: Scaffold(body: YourSpaceScreen())),
      ),
    );
    await tester.pumpAndSettle();
    return container;
  }

  // The landing page is a single, tall SingleChildScrollView -- later cards
  // (Tools, Browse & Discovery) sit below the default test viewport.
  Future<void> tapCard(WidgetTester tester, String label) async {
    final finder = find.text(label);
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
  }

  group('PERS-SPACE-1: landing page structure', () {
    testWidgets('renders an ambient header and all 3 group sections', (tester) async {
      final container = await pumpYourSpace(tester);
      addTearDown(container.dispose);

      expect(find.textContaining('Good '), findsOneWidget); // time-of-day greeting
      expect(find.textContaining('title'), findsWidgets); // library count line

      expect(find.text('PILES'), findsOneWidget);
      expect(find.text('TOOLS'), findsOneWidget);
      expect(find.text('BROWSE & DISCOVERY'), findsOneWidget);
    });

    testWidgets('all 6 pile cards are present', (tester) async {
      final container = await pumpYourSpace(tester);
      addTearDown(container.dispose);

      for (final label in ['Watchlist', 'Saved', 'Watching', 'On-Hold', 'Dropped', 'Watched']) {
        expect(find.text(label), findsOneWidget, reason: '$label pile card should render');
      }
    });

    testWidgets('all 4 tools cards and 4 browse cards are present', (tester) async {
      final container = await pumpYourSpace(tester);
      addTearDown(container.dispose);

      for (final label in ['Rate Titles', 'Custom Folders', 'Cleanup Session', 'Rewatch Vault']) {
        expect(find.text(label), findsOneWidget, reason: '$label tools card should render');
      }
      for (final label in ['Lobby', 'Discover', 'Search', 'Calendar']) {
        expect(find.text(label), findsOneWidget, reason: '$label browse card should render');
      }
    });
  });

  group('PERS-SPACE-1: Piles group routing', () {
    testWidgets('tapping a pile card pushes the matching PileScreen', (tester) async {
      final container = await pumpYourSpace(tester);
      addTearDown(container.dispose);

      await tapCard(tester, 'Dropped');
      await tester.pumpAndSettle();

      final pileScreen = tester.widget<PileScreen>(find.byType(PileScreen));
      expect(pileScreen.kind, PileKind.dropped);
    });
  });

  group('PERS-SPACE-1: Tools group routing', () {
    testWidgets('Rate Titles card opens RateTitlesScreen', (tester) async {
      final container = await pumpYourSpace(tester);
      addTearDown(container.dispose);

      await tapCard(tester, 'Rate Titles');
      await tester.pumpAndSettle();

      expect(find.byType(RateTitlesScreen), findsOneWidget);
    });

    testWidgets('Custom Folders card opens FoldersScreen', (tester) async {
      final container = await pumpYourSpace(tester);
      addTearDown(container.dispose);

      await tapCard(tester, 'Custom Folders');
      await tester.pumpAndSettle();

      expect(find.byType(FoldersScreen), findsOneWidget);
    });

    testWidgets('Cleanup Session card opens CleanupSwipeScreen', (tester) async {
      final container = await pumpYourSpace(tester);
      addTearDown(container.dispose);

      await tapCard(tester, 'Cleanup Session');
      await tester.pumpAndSettle();

      expect(find.byType(CleanupSwipeScreen), findsOneWidget);
    });

    testWidgets('Rewatch Vault card opens RewatchVaultScreen', (tester) async {
      final container = await pumpYourSpace(tester);
      addTearDown(container.dispose);

      await tapCard(tester, 'Rewatch Vault');
      await tester.pumpAndSettle();

      expect(find.byType(RewatchVaultScreen), findsOneWidget);
    });
  });

  group('PERS-SPACE-1: Browse & Discovery group routing', () {
    testWidgets('Lobby/Discover/Search/Calendar cards switch navigationProvider\'s tab',
        (tester) async {
      final container = await pumpYourSpace(tester);
      addTearDown(container.dispose);

      final cases = {
        'Lobby': AppTab.lobby,
        'Discover': AppTab.discover,
        'Search': AppTab.search,
        'Calendar': AppTab.calendar,
      };

      for (final entry in cases.entries) {
        await tapCard(tester, entry.key);
        await tester.pump();
        expect(container.read(navigationProvider).currentTab, entry.value);
      }
    });
  });

  group('PERS-SPACE-1: header', () {
    testWidgets('settings icon opens SettingsScreen', (tester) async {
      final container = await pumpYourSpace(tester);
      addTearDown(container.dispose);

      final settingsFinder = find.byKey(const ValueKey('your_space_settings_button'));
      await tester.ensureVisible(settingsFinder);
      await tester.tap(settingsFinder);
      await tester.pumpAndSettle();

      expect(find.byType(SettingsScreen), findsOneWidget);
    });
  });
}
