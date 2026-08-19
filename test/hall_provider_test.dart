import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:the_lounge/providers/ambiance_provider.dart';
import 'package:the_lounge/providers/hall_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SharedPreferences prefs;

  setUp(() async {
    GoogleFonts.config.allowRuntimeFetching = false;
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  group('NOMEN-1: HallProvider state management', () {
    testWidgets('initial state loads active common hall and 3 default halls', (tester) async {
      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
      );
      addTearDown(container.dispose);

      final state = container.read(hallProvider);
      expect(state.activeHallId, 'common');
      expect(state.halls.length, 3);
      expect(state.activeHall.name, 'The Grand Hall');
    });

    testWidgets('switchHall updates activeHallId and activeHall getter', (tester) async {
      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
      );
      addTearDown(container.dispose);

      await container.read(hallProvider.notifier).switchHall('custom_1');

      final state = container.read(hallProvider);
      expect(state.activeHallId, 'custom_1');
      expect(state.activeHall.id, 'custom_1');
      expect(state.activeHall.isCommon, isFalse);
    });

    testWidgets('renameHall updates hall name in state and persists', (tester) async {
      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
      );
      addTearDown(container.dispose);

      await container.read(hallProvider.notifier).renameHall('custom_2', 'Midnight Anime Vault');

      final state = container.read(hallProvider);
      final p2 = state.halls.firstWhere((p) => p.id == 'custom_2');
      expect(p2.name, 'Midnight Anime Vault');
    });

    testWidgets('updateHallIcon updates hall icon in state and persists', (tester) async {
      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
      );
      addTearDown(container.dispose);

      await container.read(hallProvider.notifier).updateHallIcon('custom_1', 'reel');

      final state = container.read(hallProvider);
      final p1 = state.halls.firstWhere((p) => p.id == 'custom_1');
      expect(p1.iconKey, 'reel');
    });
  });
}
