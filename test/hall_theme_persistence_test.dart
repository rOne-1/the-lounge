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

  group('THEME-1: Hall theme persistence and configuration', () {
    test('default halls have assigned luxury theater themes', () {
      final grandHall = HallSpace.defaultGrandHall();
      expect(grandHall.themeId, 'screening_room');

      final mezzanine = HallSpace.defaultMezzanineHall();
      expect(mezzanine.themeId, 'midnight_cinema');

      final privateScreening = HallSpace.defaultPrivateScreeningHall();
      expect(privateScreening.themeId, 'reading_room');
    });

    test('saving and loading hall preserves custom themeId', () async {
      final grandHall = HallSpace.defaultGrandHall().copyWith(themeId: 'violet_dusk');
      await service.saveHall(prefs, grandHall);

      final loaded = await service.loadHall(prefs, 'common');
      expect(loaded.themeId, 'violet_dusk');
    });

    test('v4 backup export and import preserves per-hall theme IDs', () {
      final halls = [
        HallSpace.defaultGrandHall().copyWith(themeId: 'cafe_calm'),
        HallSpace.defaultMezzanineHall().copyWith(themeId: 'alpine_chalet'),
        HallSpace.defaultPrivateScreeningHall().copyWith(themeId: 'violet_dusk'),
      ];

      final jsonString = service.exportFullBackupJson(
        halls: halls,
        activeHallId: 'common',
        themeId: 'cafe_calm',
      );

      final restored = service.importBackupJson(jsonString);
      expect(restored.length, 3);
      expect(restored[0].themeId, 'cafe_calm');
      expect(restored[1].themeId, 'alpine_chalet');
      expect(restored[2].themeId, 'violet_dusk');
    });
  });
}
