// Regression coverage for PERS-NAV-1 / NAME-1: The Lounge is the app's default
// startup destination and navigation anchor.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:the_lounge/main.dart';
import 'package:the_lounge/screens/shell_screen.dart';
import 'package:the_lounge/providers/media_provider.dart';
import 'package:the_lounge/providers/navigation_provider.dart';
import 'package:the_lounge/providers/ambiance_provider.dart';
import 'package:the_lounge/repositories/mock_movie_repository.dart';
import 'package:the_lounge/widgets/noise_texture_overlay.dart';

void main() {
  setUp(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  test('NavigationState defaults to AppTab.lounge', () {
    const state = NavigationState();
    expect(state.currentTab, AppTab.lounge);
  });

  testWidgets('initial tab on a fresh ShellScreen mount is The Lounge',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [
        movieRepositoryProvider.overrideWithValue(MockMovieRepository()),
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: ShellScreen(enableAnimation: false)),
      ),
    );
    await tester.pumpAndSettle();

    expect(container.read(navigationProvider).currentTab, AppTab.lounge);
    // The landing page's own dock card confirms The Lounge, not Lobby,
    // is what's actually showing.
    expect(find.text('Archive'), findsOneWidget);
  });

  testWidgets(
      'a back gesture from every other tab returns to The Lounge, which itself is allowed to pop the root route',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [
        movieRepositoryProvider.overrideWithValue(MockMovieRepository()),
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: ShellScreen(enableAnimation: false)),
      ),
    );
    await tester.pumpAndSettle();

    for (final tab in [AppTab.lobby, AppTab.discover, AppTab.search, AppTab.calendar]) {
      container.read(navigationProvider.notifier).setTab(tab);
      await tester.pumpAndSettle();

      final didPop = await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

      expect(didPop, isTrue, reason: 'back from $tab should be intercepted, not exit the app');
      expect(container.read(navigationProvider).currentTab, AppTab.lounge);
    }

    // Already on The Lounge: back is no longer intercepted (canPop: true),
    // matching the app's designated exit point.
    final finalPop = await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(finalPop, isFalse);
  });

  group('FEAT-GRAIN-1: grain overlay on pushed routes', () {
    testWidgets(
        'the noise grain overlay persists across a pushed route, not just the shell tabs',
        (tester) async {
      tester.view.physicalSize = const Size(412, 915);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            movieRepositoryProvider.overrideWithValue(MockMovieRepository()),
            sharedPreferencesProvider.overrideWithValue(prefs),
          ],
          child: const MyApp(enableAnimation: false),
        ),
      );
      await tester.pumpAndSettle();

      // Landing page (The Lounge, nothing pushed): grain is already present
      // -- it now lives once at the MaterialApp.builder level (main.dart),
      // not per-screen, so it covers the initial shell tabs too.
      expect(find.byType(AppNoiseTexture), findsOneWidget);

      // A real Navigator push while staying on the lounge tab -- before
      // FEAT-GRAIN-1, AppNoiseTexture was drawn inside ShellScreen's own
      // Stack, which sits *underneath* whatever route the Navigator pushes
      // on top, so a pushed screen (Archive here) showed no grain at all.
      await tester.tap(find.text('Archive'));
      await tester.pumpAndSettle();

      // Still exactly one instance -- the same single overlay, not a second
      // copy instantiated by the pushed screen.
      expect(find.byType(AppNoiseTexture), findsOneWidget);
    });
  });
}
