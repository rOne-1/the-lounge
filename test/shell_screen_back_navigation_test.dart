// Regression coverage for NAV-1/PERS-NAV-1: the last back press/gesture
// before exiting the app must return to Your Space first (the app's
// navigation anchor), not terminate immediately, when the user is on any
// other tab (Lobby, Discover, Browse, Calendar).
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:the_lounge/screens/shell_screen.dart';
import 'package:the_lounge/providers/media_provider.dart';
import 'package:the_lounge/providers/navigation_provider.dart';
import 'package:the_lounge/providers/ambiance_provider.dart';
import 'package:the_lounge/repositories/mock_movie_repository.dart';

void main() {
  setUp(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  Future<ProviderContainer> pumpShell(WidgetTester tester, AppTab startTab) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [
        movieRepositoryProvider.overrideWithValue(MockMovieRepository()),
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
    );
    container.read(navigationProvider.notifier).setTab(startTab);

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

  testWidgets(
      'system back on a non-Your-Space tab switches to Your Space instead of popping the root route',
      (tester) async {
    final container = await pumpShell(tester, AppTab.discover);
    addTearDown(container.dispose);

    expect(container.read(navigationProvider).currentTab, AppTab.discover);

    // handlePopRoute() resolves true when the request was intercepted/handled
    // without the route actually popping (PopScope's canPop: false case).
    final didPop = await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(didPop, isTrue);
    expect(container.read(navigationProvider).currentTab, AppTab.yourSpace);
    expect(find.byType(ShellScreen), findsOneWidget);
  });

  testWidgets('system back on Your Space is allowed to pop the root route', (tester) async {
    final container = await pumpShell(tester, AppTab.yourSpace);
    addTearDown(container.dispose);

    expect(container.read(navigationProvider).currentTab, AppTab.yourSpace);

    // false here means PopScope did not intercept it -- the root route's
    // own single-route Navigator has nothing left to pop to, so the app is
    // left to fall through to the OS (exit), which is the desired
    // navigation-anchor behavior per PERS-NAV-1.
    final didPop = await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(didPop, isFalse);
  });

  testWidgets('back from Lobby, Discover, Search, and Calendar all redirect to Your Space',
      (tester) async {
    for (final tab in [AppTab.lobby, AppTab.discover, AppTab.search, AppTab.calendar]) {
      final container = await pumpShell(tester, tab);

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

      expect(container.read(navigationProvider).currentTab, AppTab.yourSpace);

      container.dispose();
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    }
  });
}
