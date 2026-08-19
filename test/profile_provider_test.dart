import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:the_lounge/providers/ambiance_provider.dart';
import 'package:the_lounge/providers/profile_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SharedPreferences prefs;

  setUp(() async {
    GoogleFonts.config.allowRuntimeFetching = false;
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  group('PROF-2: ProfileProvider backward compatibility layer', () {
    testWidgets('initial state loads active common profile and 3 default profiles', (tester) async {
      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
      );
      addTearDown(container.dispose);

      final state = container.read(profileProvider);
      expect(state.activeProfileId, 'common');
      expect(state.profiles.length, 3);
      expect(state.activeProfile.name, 'The Grand Hall');
    });

    testWidgets('switchProfile updates activeProfileId and activeProfile getter', (tester) async {
      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
      );
      addTearDown(container.dispose);

      await container.read(profileProvider.notifier).switchProfile('custom_1');

      final state = container.read(profileProvider);
      expect(state.activeProfileId, 'custom_1');
      expect(state.activeProfile.id, 'custom_1');
      expect(state.activeProfile.isCommon, isFalse);
    });

    testWidgets('renameProfile updates profile name in state and persists', (tester) async {
      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
      );
      addTearDown(container.dispose);

      await container.read(profileProvider.notifier).renameProfile('custom_2', 'Midnight Anime Vault');

      final state = container.read(profileProvider);
      final p2 = state.profiles.firstWhere((p) => p.id == 'custom_2');
      expect(p2.name, 'Midnight Anime Vault');
    });

    testWidgets('updateProfileIcon updates profile icon in state and persists', (tester) async {
      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
      );
      addTearDown(container.dispose);

      await container.read(profileProvider.notifier).updateProfileIcon('custom_1', 'reel');

      final state = container.read(profileProvider);
      final p1 = state.profiles.firstWhere((p) => p.id == 'custom_1');
      expect(p1.iconKey, 'reel');
    });
  });
}
