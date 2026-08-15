// Regression coverage for E1/TF-4: ShellScreen's compact-layout top bar
// (Settings gear + Undo button) should be visible on a fresh load, collapse
// out of view once the active tab's content scrolls down past the
// ScrollChromeTracker threshold, and come back on scrolling up.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:the_lounge/screens/shell_screen.dart';
import 'package:the_lounge/screens/your_space_screen.dart';
import 'package:the_lounge/providers/media_provider.dart';
import 'package:the_lounge/providers/navigation_provider.dart';
import 'package:the_lounge/providers/ambiance_provider.dart';
import 'package:the_lounge/models/media_item.dart';
import 'package:the_lounge/repositories/mock_movie_repository.dart';

void main() {
  setUp(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  final settingsButtonFinder = find.byKey(const ValueKey('settings_button'));

  Future<ProviderContainer> pumpShell(WidgetTester tester) async {
    // ResponsiveLayout switches to the compact (phone) layout below 600
    // logical px; the default test surface is wide enough to trigger the
    // desktop/tablet layout instead, which doesn't have this collapsible
    // top bar at all.
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

    // Enough watchlist items to make YourSpace's grid genuinely scrollable.
    for (var i = 0; i < 40; i++) {
      container.read(mediaProvider.notifier).addToWatchlist(
            MediaItem(
              id: 'movie-$i',
              title: 'Watchlist Title $i',
              type: MediaType.movie,
              rating: 7.0,
              overview: '',
              genres: const ['Drama'],
            ),
          );
    }
    container.read(navigationProvider.notifier).setTab(AppTab.yourSpace);

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

  testWidgets('top bar is visible on a fresh load', (tester) async {
    final container = await pumpShell(tester);
    addTearDown(container.dispose);

    expect(settingsButtonFinder, findsOneWidget);
  });

  testWidgets('top bar collapses on scroll-down and returns on scroll-up',
      (tester) async {
    final container = await pumpShell(tester);
    addTearDown(container.dispose);

    expect(settingsButtonFinder, findsOneWidget);

    final gridFinder = find
        .descendant(of: find.byType(YourSpaceScreen), matching: find.byType(GridView))
        .first;
    await tester.drag(gridFinder, const Offset(0, -400));
    await tester.pumpAndSettle();

    expect(settingsButtonFinder, findsNothing);

    await tester.drag(gridFinder, const Offset(0, 400));
    await tester.pumpAndSettle();

    expect(settingsButtonFinder, findsOneWidget);
  });
}
