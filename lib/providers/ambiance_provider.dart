import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants.dart';

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError(
      'sharedPreferencesProvider must be overridden in main');
});

class AmbianceNotifier extends Notifier<AmbianceType> {
  static const _ambianceKey = 'selected_ambiance';

  @override
  AmbianceType build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    final storedValue = prefs.getString(_ambianceKey);

    if (storedValue != null) {
      return AmbianceType.values.firstWhere(
        (e) => e.name == storedValue,
        orElse: () => AmbianceType.screeningRoom,
      );
    }

    return AmbianceType.screeningRoom;
  }

  Future<void> toggleAmbiance() async {
    final newAmbiance = state == AmbianceType.screeningRoom
        ? AmbianceType.readingRoom
        : AmbianceType.screeningRoom;

    state = newAmbiance;
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setString(_ambianceKey, newAmbiance.name);
  }

  Future<void> setAmbiance(AmbianceType ambiance) async {
    state = ambiance;
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setString(_ambianceKey, ambiance.name);
  }
}

final ambianceProvider = NotifierProvider<AmbianceNotifier, AmbianceType>(() {
  return AmbianceNotifier();
});
