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

  testWidgets('renders all 3 halls in HallSelectorSheet and allows switching',
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

    expect(find.text('The Screening Halls'), findsOneWidget);
    expect(find.text('The Grand Hall'), findsOneWidget);
    expect(find.text('The Mezzanine Hall'), findsOneWidget);
    expect(find.text('The Private Screening Hall'), findsOneWidget);
    expect(find.text('MAIN'), findsOneWidget);

    // Tap The Mezzanine Hall to switch
    await tester.tap(find.text('The Mezzanine Hall'));
    await tester.pumpAndSettle();

    expect(container.read(hallProvider).activeHallId, 'custom_1');
  });

  testWidgets('editing hall name opens rename dialog', (WidgetTester tester) async {
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

    final editButtons = find.byIcon(Icons.edit_outlined);
    expect(editButtons, findsWidgets);

    await tester.tap(editButtons.first);
    await tester.pumpAndSettle();

    expect(find.text('Rename Screening Hall'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'Cinema Vault');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(find.text('Rename Screening Hall'), findsNothing);
    final p1 = container.read(hallProvider).halls.firstWhere((p) => p.id == 'custom_1');
    expect(p1.name, 'Cinema Vault');
  });
}
