import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:the_lounge/providers/ambiance_provider.dart';
import 'package:the_lounge/providers/hall_provider.dart';
import 'package:the_lounge/widgets/hall_selector_sheet.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SharedPreferences prefs;

  setUp(() async {
    GoogleFonts.config.allowRuntimeFetching = false;
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  group('THEME-2: Reactive theme auto-switching on hall switch & theme picker', () {
    testWidgets('switching halls auto-applies that hall\'s saved theme to ambianceProvider', (tester) async {
      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
      );
      addTearDown(container.dispose);

      // Default active hall is Grand Hall ('screening_room')
      expect(container.read(hallProvider).activeHall.themeId, 'screening_room');

      // Switch to Mezzanine Hall ('midnight_cinema')
      await container.read(hallProvider.notifier).switchHall('custom_1');

      expect(container.read(hallProvider).activeHall.themeId, 'midnight_cinema');
      expect(container.read(ambianceProvider).id, 'midnight_cinema');

      // Switch to Private Screening Hall ('reading_room')
      await container.read(hallProvider.notifier).switchHall('custom_2');

      expect(container.read(hallProvider).activeHall.themeId, 'reading_room');
      expect(container.read(ambianceProvider).id, 'reading_room');
    });

    testWidgets('updateHallTheme updates hall theme and applies immediately if active', (tester) async {
      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
      );
      addTearDown(container.dispose);

      // Update active Grand Hall theme to 'violet_dusk'
      await container.read(hallProvider.notifier).updateHallTheme('common', 'violet_dusk');

      expect(container.read(hallProvider).activeHall.themeId, 'violet_dusk');
      expect(container.read(ambianceProvider).id, 'violet_dusk');
    });

    testWidgets('Hall customize dialog allows picking a theme and updates ambiance',
        (WidgetTester tester) async {
      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(
              body: HallSelectorSheet(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Open customize dialog for first hall
      final editButtons = find.byIcon(Icons.edit_outlined);
      expect(editButtons, findsWidgets);
      await tester.tap(editButtons.first);
      await tester.pumpAndSettle();

      expect(find.text('Customize Screening Hall'), findsOneWidget);
      expect(find.text('HALL AMBIANCE THEME'), findsOneWidget);

      // Select 'Violet Dusk' theme
      await tester.tap(find.text('Violet Dusk'));
      await tester.pumpAndSettle();

      // Save
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(container.read(hallProvider).activeHall.themeId, 'violet_dusk');
      expect(container.read(ambianceProvider).id, 'violet_dusk');
    });
  });
}
