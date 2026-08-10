import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants.dart';

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError(
      'sharedPreferencesProvider must be overridden in main');
});

class AmbianceNotifier extends Notifier<AppTheme> {
  static const _ambianceKey = 'selected_ambiance';

  @override
  AppTheme build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    final storedValue = prefs.getString(_ambianceKey);

    if (storedValue != null) {
      String id = storedValue;
      if (id == 'screeningRoom') id = 'screening_room';
      if (id == 'readingRoom') id = 'reading_room';
      if (id == 'violetDusk') id = 'violet_dusk';
      return getThemeById(id);
    }

    return allThemes.first;
  }

  Future<void> toggleAmbiance() async {
    final currentIndex = allThemes.indexWhere((t) => t.id == state.id);
    final nextIndex = (currentIndex + 1) % allThemes.length;
    final newAmbiance = allThemes[nextIndex];

    state = newAmbiance;
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setString(_ambianceKey, newAmbiance.id);
  }

  Future<void> setAmbiance(AppTheme ambiance) async {
    state = ambiance;
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setString(_ambianceKey, ambiance.id);
  }
}

final ambianceProvider = NotifierProvider<AmbianceNotifier, AppTheme>(() {
  return AmbianceNotifier();
});
