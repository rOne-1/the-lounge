// Regression coverage for IA-1/NAV-3: the floating navigation capsule that
// replaces ShellScreen's fixed top bar and bottom nav bar.
import 'dart:ui' show Tristate;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:the_lounge/main.dart';
import 'package:the_lounge/screens/shell_screen.dart';
import 'package:the_lounge/screens/settings_screen.dart';
import 'package:the_lounge/screens/discover_screen.dart';
import 'package:the_lounge/widgets/hall_selector_sheet.dart';
import 'package:the_lounge/providers/media_provider.dart';
import 'package:the_lounge/providers/navigation_provider.dart';
import 'package:the_lounge/providers/hall_provider.dart';
import 'package:the_lounge/providers/ambiance_provider.dart';
import 'package:the_lounge/repositories/mock_movie_repository.dart';
import 'package:the_lounge/themes/orchid_bloom_theme.dart';

void main() {
  setUp(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  final capsuleFinder = find.byKey(const ValueKey('floating_nav_capsule'));

  Future<ProviderContainer> pumpShell(
    WidgetTester tester, {
    AppTab initialTab = AppTab.lobby,
  }) async {
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
    container.read(navigationProvider.notifier).setTab(initialTab);

    // Mirrors MyApp's real tree shape (main.dart): the capsule is hosted via
    // GlobalCapsuleLayer as a Stack sibling of `child` (the routed
    // Navigator) inside MaterialApp.builder, not a descendant of it. Pumping
    // bare ShellScreen as `home` (the old shape of this test) exercised a
    // capsule instance that no longer exists in production and masked a
    // real bug where the actual global capsule had no reachable Navigator.
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          navigatorKey: rootNavigatorKey,
          navigatorObservers: [container.read(loungeRouteObserverProvider)],
          home: const ShellScreen(enableAnimation: false),
          builder: (context, child) {
            return Stack(
              children: [
                child ?? const SizedBox(),
                const GlobalCapsuleLayer(enableAnimation: false),
              ],
            );
          },
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
    expect(find.byKey(const ValueKey('floating_nav_tab_lobby')), findsNothing);
    // Old fixed chrome is gone.
    expect(find.byKey(const ValueKey('settings_button')), findsNothing);
  });

  testWidgets('tap expands the capsule to show 5 tab destinations and the media toggle',
      (tester) async {
    final container = await pumpShell(tester);
    addTearDown(container.dispose);

    await tester.tap(capsuleFinder);
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('floating_nav_tab_lobby')), findsOneWidget);
    expect(find.byKey(const ValueKey('floating_nav_tab_discover')), findsOneWidget);
    expect(find.byKey(const ValueKey('floating_nav_tab_search')), findsOneWidget);
    expect(find.byKey(const ValueKey('floating_nav_tab_lounge')), findsOneWidget);
    expect(find.byKey(const ValueKey('floating_nav_tab_calendar')), findsOneWidget);
    expect(find.text('Movies'), findsOneWidget);
    expect(find.text('TV'), findsOneWidget);
  });

  testWidgets(
      'BETA3-A11Y-1: expanded tab destinations expose a selected semantic, '
      'and the Hall shortcut announces the active Hall by name', (tester) async {
    final handle = tester.ensureSemantics();
    final container = await pumpShell(tester);
    addTearDown(container.dispose);

    await tester.tap(capsuleFinder);
    await tester.pumpAndSettle();

    final lobbyTab =
        find.byKey(const ValueKey('floating_nav_tab_lobby'));
    final discoverTab =
        find.byKey(const ValueKey('floating_nav_tab_discover'));

    // Lobby is the initial tab -- selected. Discover is not.
    expect(tester.getSemantics(lobbyTab).flagsCollection.isSelected,
        Tristate.isTrue);
    expect(
        tester.getSemantics(discoverTab).flagsCollection.isSelected,
        isNot(Tristate.isTrue));

    final hallButton =
        find.byKey(const ValueKey('floating_nav_profile_button'));
    final hallSemantics = tester.getSemantics(hallButton);
    expect(hallSemantics.flagsCollection.isButton, isTrue);
    expect(hallSemantics.label, contains('Switch Hall'));
    expect(hallSemantics.label,
        contains(container.read(activeHallSpaceProvider).name));

    handle.dispose();
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
    expect(find.byKey(const ValueKey('floating_nav_tab_lobby')), findsNothing);
  });

  testWidgets('tapping outside the expanded capsule collapses it', (tester) async {
    final container = await pumpShell(tester);
    addTearDown(container.dispose);

    await tester.tap(capsuleFinder);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('floating_nav_tab_lobby')), findsOneWidget);

    // Tap far from the capsule, in empty space.
    await tester.tapAt(const Offset(20, 20));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('floating_nav_tab_lobby')), findsNothing);
  });

  testWidgets('NAV-DIM-1: expanding the capsule fades in a backdrop scrim, collapsing fades it out',
      (tester) async {
    final container = await pumpShell(tester);
    addTearDown(container.dispose);

    AnimatedOpacity scrimOpacityWidget() =>
        tester.widget<AnimatedOpacity>(find.byType(AnimatedOpacity).first);

    // Collapsed by default: scrim present in the tree (so it can animate
    // in later) but faded out.
    expect(scrimOpacityWidget().opacity, 0.0);

    await tester.tap(capsuleFinder);
    await tester.pumpAndSettle();

    expect(scrimOpacityWidget().opacity, 1.0);

    // Tapping the scrim itself (not just "far away") collapses the capsule.
    await tester.tapAt(const Offset(20, 20));
    await tester.pumpAndSettle();

    expect(scrimOpacityWidget().opacity, 0.0);
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

  testWidgets('hall shortcut in the expanded capsule opens HallSelectorSheet and displays active hall name',
      (tester) async {
    final container = await pumpShell(tester);
    addTearDown(container.dispose);

    await tester.tap(capsuleFinder);
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('floating_nav_profile_button')), findsOneWidget);
    expect(find.text('The Grand Hall'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('floating_nav_profile_button')));
    await tester.pumpAndSettle();

    expect(find.byType(HallSelectorSheet), findsOneWidget);
  });

  testWidgets('FIX-1: capsule dynamically updates active hall name upon hall switch',
      (tester) async {
    final container = await pumpShell(tester);
    addTearDown(container.dispose);

    await tester.tap(capsuleFinder);
    await tester.pumpAndSettle();
    expect(find.text('The Grand Hall'), findsOneWidget);

    // Switch to Mezzanine Hall
    await container.read(hallProvider.notifier).switchHall('custom_1');
    await tester.pumpAndSettle();

    expect(find.text('The Mezzanine Hall'), findsOneWidget);
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

  testWidgets('expanded capsule has theme surface fill for high contrast in light mode Orchid Bloom',
      (tester) async {
    final container = await pumpShell(tester);
    addTearDown(container.dispose);

    await container.read(ambianceProvider.notifier).setTheme(orchidBloomTheme.id);
    await tester.pumpAndSettle();

    // Tap to expand
    await tester.tap(capsuleFinder);
    await tester.pumpAndSettle();

    // Find the Container for the capsule body
    final containers = tester.widgetList<Container>(find.byType(Container));
    final capsuleBodyContainer = containers.firstWhere(
      (c) => (c.decoration as BoxDecoration?)?.borderRadius == BorderRadius.circular(28),
    );

    final decoration = capsuleBodyContainer.decoration as BoxDecoration;
    expect(decoration.color, isNotNull, reason: 'Expanded capsule must have a solid/frosted background color');
    expect(decoration.color!.a, greaterThan(0.8), reason: 'Surface fill must have high opacity for contrast over scrim');
  });

  testWidgets('switching themes with capsule expanded or collapsed does not trigger shadow blur radius assertion crash',
      (tester) async {
    final container = await pumpShell(tester);
    addTearDown(container.dispose);

    // Expand the capsule
    await tester.tap(capsuleFinder);
    await tester.pumpAndSettle();

    // Cycle through all themes during expanded state
    final themeIds = ['screening_room', 'midnight_cinema', 'orchid_bloom', 'violet_dusk', 'tuscany'];
    for (final id in themeIds) {
      await container.read(ambianceProvider.notifier).setTheme(id);
      // Pump multiple frames to exercise the spring curve across all frame intervals
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 150));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    }

    // Collapse the capsule
    await tester.tap(capsuleFinder);
    await tester.pumpAndSettle();

    // Cycle through all themes during collapsed state
    for (final id in themeIds) {
      await container.read(ambianceProvider.notifier).setTheme(id);
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 150));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    }
  });
}
