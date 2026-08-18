// Widget tests for YSR-GATEWAY-1: Your Space's Sanctuary Gateway landing screen
// and its 4-card navigation dock routing.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:the_lounge/screens/your_space_screen.dart';
import 'package:the_lounge/screens/archive_screen.dart';
import 'package:the_lounge/screens/tools_screen.dart';
import 'package:the_lounge/screens/settings_screen.dart';
import 'package:the_lounge/widgets/lounge_doorway_emblem.dart';
import 'package:the_lounge/widgets/ambient_glow.dart';
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

  Future<void> tapDockCard(WidgetTester tester, String label) async {
    final finder = find.text(label);
    await tester.ensureVisible(finder);
    await tester.tap(finder);
    await tester.pump();
  }

  group('YSR-GATEWAY-1: Sanctuary Gateway structure', () {
    testWidgets('renders Day overline, greeting, emblem centerpiece and 4 dock cards',
        (tester) async {
      final container = await pumpYourSpace(tester);
      addTearDown(container.dispose);

      // Overline, greeting, subtitle
      expect(find.textContaining('DAY'), findsOneWidget);
      expect(find.textContaining('Good '), findsOneWidget);
      expect(find.textContaining('titles in your space'), findsOneWidget);

      // Centerpiece emblem + ambient glow
      expect(find.byType(LoungeDoorwayEmblem), findsOneWidget);
      expect(find.byType(AmbientGlowWidget), findsOneWidget);

      // 4 Dock Cards
      expect(find.text('Archive'), findsOneWidget);
      expect(find.text('Browse'), findsOneWidget);
      expect(find.text('Tools'), findsOneWidget);
      expect(find.text('Settings'), findsOneWidget);
    });
  });

  group('YSR-GATEWAY-1: 4-Card Dock Navigation Routing', () {
    testWidgets('Archive card pushes ArchiveScreen', (tester) async {
      final container = await pumpYourSpace(tester);
      addTearDown(container.dispose);

      await tapDockCard(tester, 'Archive');
      await tester.pumpAndSettle();

      expect(find.byType(ArchiveScreen), findsOneWidget);
    });

    testWidgets('Browse card switches navigationProvider tab to AppTab.lobby',
        (tester) async {
      final container = await pumpYourSpace(tester);
      addTearDown(container.dispose);

      await tapDockCard(tester, 'Browse');
      await tester.pump();

      expect(container.read(navigationProvider).currentTab, AppTab.lobby);
    });

    testWidgets('Tools card pushes ToolsScreen', (tester) async {
      final container = await pumpYourSpace(tester);
      addTearDown(container.dispose);

      await tapDockCard(tester, 'Tools');
      await tester.pumpAndSettle();

      expect(find.byType(ToolsScreen), findsOneWidget);
    });

    testWidgets('Settings card pushes SettingsScreen', (tester) async {
      final container = await pumpYourSpace(tester);
      addTearDown(container.dispose);

      await tapDockCard(tester, 'Settings');
      await tester.pumpAndSettle();

      expect(find.byType(SettingsScreen), findsOneWidget);
    });
  });
}
