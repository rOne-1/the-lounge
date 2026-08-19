import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:the_lounge/providers/ambiance_provider.dart';
import 'package:the_lounge/providers/repository_provider.dart';
import 'package:the_lounge/repositories/mock_movie_repository.dart';
import 'package:the_lounge/screens/settings_screen.dart';
import 'package:the_lounge/screens/lounge_screen.dart';

// IA-1 / NAME-1: The Lounge gets a direct Settings entry point alongside (not
// instead of) the shell's own auto-hiding top-bar gear icon.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SharedPreferences prefs;

  setUp(() async {
    GoogleFonts.config.allowRuntimeFetching = false;
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  testWidgets('tapping the Lounge settings icon opens SettingsScreen', (tester) async {
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
        child: const MaterialApp(home: LoungeScreen()),
      ),
    );
    await tester.pumpAndSettle();

    final settingsButton = find.byKey(const ValueKey('lounge_settings_button'));
    expect(settingsButton, findsOneWidget);
    expect(find.byType(SettingsScreen), findsNothing);

    await tester.tap(settingsButton);
    await tester.pumpAndSettle();

    expect(find.byType(SettingsScreen), findsOneWidget);
  });
}
