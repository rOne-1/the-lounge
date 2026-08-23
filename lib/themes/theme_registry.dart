import 'app_theme.dart';
import 'screening_room_theme.dart';
import 'reading_room_theme.dart';
import 'violet_dusk_theme.dart';
import 'midnight_cinema_theme.dart';
import 'alpine_chalet_theme.dart';
import 'orchid_bloom_theme.dart';
import 'tuscany_theme.dart';
import 'gilded_plum_theme.dart';
import 'riviera_theme.dart';

final List<AppTheme> allThemes = [
  screeningRoomTheme,
  readingRoomTheme,
  violetDuskTheme,
  midnightCinemaTheme,
  alpineChaletTheme,
  orchidBloomTheme,
  tuscanyTheme,
  gildedPlumTheme,
  rivieraTheme,
];

AppTheme getThemeById(String id) {
  return allThemes.firstWhere(
    (theme) => theme.id == id,
    orElse: () => allThemes.first,
  );
}
