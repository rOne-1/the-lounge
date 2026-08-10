import 'app_theme.dart';
import 'screening_room_theme.dart';
import 'reading_room_theme.dart';
import 'violet_dusk_theme.dart';
import 'midnight_cinema_theme.dart';

final List<AppTheme> allThemes = [
  screeningRoomTheme,
  readingRoomTheme,
  violetDuskTheme,
  midnightCinemaTheme,
];

AppTheme getThemeById(String id) {
  return allThemes.firstWhere(
    (theme) => theme.id == id,
    orElse: () => allThemes.first,
  );
}
