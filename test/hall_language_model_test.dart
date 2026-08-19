import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:the_lounge/models/hall_space.dart';
import 'package:the_lounge/services/hall_storage_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SharedPreferences prefs;
  late HallStorageService service;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    service = HallStorageService();
  });

  group('LANG-1: Hall language lock model and persistence', () {
    test('default halls have no language lock (All Languages / Unrestricted)', () {
      expect(HallSpace.defaultGrandHall().lockedLanguageCode, isNull);
      expect(HallSpace.defaultMezzanineHall().lockedLanguageCode, isNull);
      expect(HallSpace.defaultPrivateScreeningHall().lockedLanguageCode, isNull);
    });

    test('copyWith sets a language lock', () {
      final hall = HallSpace.defaultMezzanineHall().copyWith(
        lockedLanguageCode: 'ja',
        lockedLanguageName: 'Japanese',
      );
      expect(hall.lockedLanguageCode, 'ja');
      expect(hall.lockedLanguageName, 'Japanese');
    });

    test('copyWith(lockedLanguageCode: null) explicitly clears an existing lock '
        '-- regression coverage for the sentinel-pattern fix: plain `?? this.x` '
        'can never express "clear this field" since null always falls through '
        'to the previous value', () {
      final locked = HallSpace.defaultMezzanineHall().copyWith(
        lockedLanguageCode: 'hi',
        lockedLanguageName: 'Hindi',
      );
      expect(locked.lockedLanguageCode, 'hi');

      final unlocked = locked.copyWith(
        lockedLanguageCode: null,
        lockedLanguageName: null,
      );
      expect(unlocked.lockedLanguageCode, isNull);
      expect(unlocked.lockedLanguageName, isNull);
    });

    test('copyWith with no language arguments at all leaves the existing lock untouched', () {
      final locked = HallSpace.defaultGrandHall().copyWith(lockedLanguageCode: 'ko', lockedLanguageName: 'Korean');
      final renamed = locked.copyWith(name: 'Seoul Nights');
      expect(renamed.lockedLanguageCode, 'ko');
      expect(renamed.lockedLanguageName, 'Korean');
    });

    test('toJson/fromJson round-trip preserves a language lock', () {
      final hall = HallSpace.defaultGrandHall()
          .copyWith(lockedLanguageCode: 'hi', lockedLanguageName: 'Hindi');
      final restored = HallSpace.fromJson(hall.toJson());
      expect(restored.lockedLanguageCode, 'hi');
      expect(restored.lockedLanguageName, 'Hindi');
    });

    test('toJson/fromJson round-trip preserves an unlocked (null) hall', () {
      final hall = HallSpace.defaultGrandHall();
      final restored = HallSpace.fromJson(hall.toJson());
      expect(restored.lockedLanguageCode, isNull);
      expect(restored.lockedLanguageName, isNull);
    });

    test('saving and loading a hall preserves a language lock', () async {
      final hall = HallSpace.defaultMezzanineHall()
          .copyWith(lockedLanguageCode: 'ta', lockedLanguageName: 'Tamil');
      await service.saveHall(prefs, hall);

      final loaded = await service.loadHall(prefs, 'custom_1');
      expect(loaded.lockedLanguageCode, 'ta');
      expect(loaded.lockedLanguageName, 'Tamil');
    });

    test('saving a hall after clearing its lock persists the clear, not the old value', () async {
      final locked = HallSpace.defaultGrandHall()
          .copyWith(lockedLanguageCode: 'fr', lockedLanguageName: 'French');
      await service.saveHall(prefs, locked);
      expect((await service.loadHall(prefs, 'common')).lockedLanguageCode, 'fr');

      final unlocked = locked.copyWith(lockedLanguageCode: null, lockedLanguageName: null);
      await service.saveHall(prefs, unlocked);

      final reloaded = await service.loadHall(prefs, 'common');
      expect(reloaded.lockedLanguageCode, isNull);
      expect(reloaded.lockedLanguageName, isNull);
    });

    test('v4 backup export and import preserves per-hall language locks, including unlocked halls', () {
      final halls = [
        HallSpace.defaultGrandHall(), // unrestricted
        HallSpace.defaultMezzanineHall()
            .copyWith(lockedLanguageCode: 'ja', lockedLanguageName: 'Japanese'),
        HallSpace.defaultPrivateScreeningHall()
            .copyWith(lockedLanguageCode: 'hi', lockedLanguageName: 'Hindi'),
      ];

      final jsonString = service.exportFullBackupJson(
        halls: halls,
        activeHallId: 'common',
        themeId: 'screening_room',
      );

      final restored = service.importBackupJson(jsonString);
      expect(restored.length, 3);
      expect(restored[0].lockedLanguageCode, isNull);
      expect(restored[1].lockedLanguageCode, 'ja');
      expect(restored[1].lockedLanguageName, 'Japanese');
      expect(restored[2].lockedLanguageCode, 'hi');
      expect(restored[2].lockedLanguageName, 'Hindi');
    });
  });
}
