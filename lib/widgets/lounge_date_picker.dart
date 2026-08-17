import 'package:flutter/material.dart';
import '../constants.dart';

/// PERS-DATE-1/PERS-REWATCH-1: themed date picker used anywhere a watch date
/// needs manual editing or backdating. Wraps Flutter's built-in calendar
/// (a bespoke calendar widget is a larger, separate undertaking -- flagged
/// in the triage doc) in the active ambiance's palette via a scoped [Theme],
/// so it never reads as an unthemed stock Material dialog (SP-2).
Future<DateTime?> showLoungeDatePicker(
  BuildContext context, {
  required DateTime initialDate,
  DateTime? firstDate,
  DateTime? lastDate,
}) {
  final colors = context.ambianceColors;
  return showDatePicker(
    context: context,
    initialDate: initialDate,
    firstDate: firstDate ?? DateTime(1900),
    lastDate: lastDate ?? DateTime.now(),
    builder: (context, child) {
      return Theme(
        data: Theme.of(context).copyWith(
          colorScheme: (colors.isDark ? const ColorScheme.dark() : const ColorScheme.light())
              .copyWith(
            primary: colors.acc,
            onPrimary: colors.isDark ? Colors.black : Colors.white,
            surface: colors.base,
            onSurface: colors.ink,
          ),
          dialogTheme: DialogThemeData(backgroundColor: colors.base),
          textTheme: Theme.of(context).textTheme.apply(
                bodyColor: colors.ink,
                displayColor: colors.ink,
              ),
        ),
        child: child!,
      );
    },
  );
}
