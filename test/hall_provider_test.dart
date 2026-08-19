import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:the_lounge/providers/ambiance_provider.dart';
import 'package:the_lounge/providers/hall_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  group('NOMEN-1: HallProvider state management', () {
    test('initial state loads active common hall and 3 default halls', () async {
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

    test('switchHall updates activeHallId and activeHall getter', () async {
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

    test('renameHall updates hall name in state and persists', () async {
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

    test('updateHallIcon updates iconKey', () async {
      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
      );
      addTearDown(container.dispose);

      await container.read(hallProvider.notifier).updateHallIcon('custom_1', 'heart');

      final state = container.read(hallProvider);
      final p1 = state.halls.firstWhere((p) => p.id == 'custom_1');
      expect(p1.iconKey, 'heart');
    });
  });
}
