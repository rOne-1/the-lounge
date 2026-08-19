import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:the_lounge/providers/ambiance_provider.dart';
import 'package:the_lounge/providers/profile_provider.dart';
import 'package:the_lounge/widgets/profile_selector_sheet.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SharedPreferences prefs;

  setUp(() async {
    GoogleFonts.config.allowRuntimeFetching = false;
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  testWidgets('renders all 3 profiles in ProfileSelectorSheet and allows switching',
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
            body: ProfileSelectorSheet(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('The Lounge Personas'), findsOneWidget);
    expect(find.text('Common Space'), findsOneWidget);
    expect(find.text('Persona 1'), findsOneWidget);
    expect(find.text('Persona 2'), findsOneWidget);
    expect(find.text('COMMON'), findsOneWidget);

    // Tap Persona 1 to switch
    await tester.tap(find.text('Persona 1'));
    await tester.pumpAndSettle();

    expect(container.read(profileProvider).activeProfileId, 'custom_1');
  });

  testWidgets('editing persona name opens rename dialog', (WidgetTester tester) async {
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
            body: ProfileSelectorSheet(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final editButtons = find.byIcon(Icons.edit_outlined);
    expect(editButtons, findsWidgets);

    await tester.tap(editButtons.first);
    await tester.pumpAndSettle();

    expect(find.text('Rename Persona'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'Cinema Vault');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(find.text('Rename Persona'), findsNothing);
    final p1 = container.read(profileProvider).profiles.firstWhere((p) => p.id == 'custom_1');
    expect(p1.name, 'Cinema Vault');
  });
}
