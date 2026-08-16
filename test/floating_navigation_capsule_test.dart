// Regression coverage for IA-1/NAV-3: the floating navigation capsule that
// replaces ShellScreen's fixed top bar and bottom nav bar.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:the_lounge/screens/shell_screen.dart';
import 'package:the_lounge/screens/settings_screen.dart';
import 'package:the_lounge/screens/discover_screen.dart';
import 'package:the_lounge/providers/media_provider.dart';
import 'package:the_lounge/providers/navigation_provider.dart';
import 'package:the_lounge/providers/ambiance_provider.dart';
import 'package:the_lounge/repositories/mock_movie_repository.dart';

void main() {
  setUp(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  final capsuleFinder = find.byKey(const ValueKey('floating_nav_capsule'));

  Future<ProviderContainer> pumpShell(WidgetTester tester) async {
    tester.view.physicalSize = const Size(412, 915);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

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
        child: const MaterialApp(
          home: ShellScreen(enableAnimation: false),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return container;
  }

  testWidgets('capsule renders collapsed on a fresh load, no fixed top/bottom bars',
      (tester) async {
    final container = await pumpShell(tester);
    addTearDown(container.dispose);

    expect(capsuleFinder, findsOneWidget);
    expect(find.byKey(const ValueKey('floating_nav_tab_home')), findsNothing);
    // Old fixed chrome is gone.
    expect(find.byKey(const ValueKey('settings_button')), findsNothing);
  });

  testWidgets('tap expands the capsule to show 5 tab destinations and the media toggle',
      (tester) async {
    final container = await pumpShell(tester);
    addTearDown(container.dispose);

    await tester.tap(capsuleFinder);
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('floating_nav_tab_home')), findsOneWidget);
    expect(find.byKey(const ValueKey('floating_nav_tab_discover')), findsOneWidget);
    expect(find.byKey(const ValueKey('floating_nav_tab_search')), findsOneWidget);
    expect(find.byKey(const ValueKey('floating_nav_tab_yourSpace')), findsOneWidget);
    expect(find.byKey(const ValueKey('floating_nav_tab_calendar')), findsOneWidget);
    expect(find.text('Movies'), findsOneWidget);
    expect(find.text('TV'), findsOneWidget);
  });

  testWidgets('selecting a tab destination switches the active view and collapses the capsule',
      (tester) async {
    final container = await pumpShell(tester);
    addTearDown(container.dispose);

    await tester.tap(capsuleFinder);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('floating_nav_tab_discover')));
    await tester.pumpAndSettle();

    expect(container.read(navigationProvider).currentTab, AppTab.discover);
    expect(find.byType(DiscoverScreen), findsOneWidget);
    // Collapsed again after selection.
    expect(find.byKey(const ValueKey('floating_nav_tab_home')), findsNothing);
  });

  testWidgets('tapping outside the expanded capsule collapses it', (tester) async {
    final container = await pumpShell(tester);
    addTearDown(container.dispose);

    await tester.tap(capsuleFinder);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('floating_nav_tab_home')), findsOneWidget);

    // Tap far from the capsule, in empty space.
    await tester.tapAt(const Offset(20, 20));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('floating_nav_tab_home')), findsNothing);
  });

  testWidgets('settings shortcut in the expanded capsule opens SettingsScreen',
      (tester) async {
    final container = await pumpShell(tester);
    addTearDown(container.dispose);

    await tester.tap(capsuleFinder);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('floating_nav_settings_button')));
    await tester.pumpAndSettle();

    expect(find.byType(SettingsScreen), findsOneWidget);
  });

  testWidgets('dragging the capsule and releasing snaps it to the nearest screen edge',
      (tester) async {
    final container = await pumpShell(tester);
    addTearDown(container.dispose);

    final startTopLeft = tester.getTopLeft(capsuleFinder);

    // Fling far to the left with a strong leftward velocity.
    await tester.fling(capsuleFinder, const Offset(-300, 0), 1500);
    await tester.pumpAndSettle();

    final endTopLeft = tester.getTopLeft(capsuleFinder);

    // Settled on the left portion of the screen, well away from where it
    // started -- the exact rest pixel depends on the house-spring
    // simulation's own settle tolerance, not asserted precisely here.
    expect(endTopLeft.dx, lessThan(startTopLeft.dx - 150));
    expect(endTopLeft.dx, lessThan(100));
  });
}
