import 'app_theme.dart';
import 'screening_room_theme.dart';
import 'violet_dusk_theme.dart';
import 'midnight_cinema_theme.dart';
import 'orchid_bloom_theme.dart';
import 'tuscany_theme.dart';
import 'opal_frost_theme.dart';
import 'cobalt_tide_theme.dart';
import 'amethyst_veil_theme.dart';

final List<AppTheme> allThemes = [
  screeningRoomTheme,
  violetDuskTheme,
  midnightCinemaTheme,
  orchidBloomTheme,
  tuscanyTheme,
  opalFrostTheme,
  cobaltTideTheme,
  amethystVeilTheme,
];

AppTheme getThemeById(String id) {
  return allThemes.firstWhere(
    (theme) => theme.id == id,
    orElse: () => allThemes.first,
  );
}
