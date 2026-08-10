import 'package:flutter/material.dart';
import 'theme_registry.dart';
extension AmbianceContext on BuildContext {
  AmbianceColors get ambianceColors => Theme.of(this).extension<AmbianceColors>() ?? allThemes.first.colors;
}

class AmbianceColors extends ThemeExtension<AmbianceColors> {

  final Color base;

  final Color card;

  final Color card2;

  final Color lineRgba;

  final Color ink;

  final Color sub;

  final Color acc;

  final Color ph;

  final Color pill;

  final Color statusWatchlist;

  final Color statusSave;

  final Color statusWatching;

  final Color statusWatched;

  final Color statusOnHold;

  final Color statusDropped;

  final Color glow1;

  final Color glow2;

  final BoxDecoration background;

  final BoxDecoration primaryButtonDecoration;

  final bool isDark;



  const AmbianceColors({

    required this.base,

    required this.card,

    required this.card2,

    required this.lineRgba,

    required this.ink,

    required this.sub,

    required this.acc,

    required this.ph,

    required this.pill,

    required this.statusWatchlist,

    required this.statusSave,

    required this.statusWatching,

    required this.statusWatched,

    required this.statusOnHold,

    required this.statusDropped,

    required this.glow1,

    required this.glow2,

    required this.background,

    required this.primaryButtonDecoration,

    required this.isDark,

  });



  @override

  ThemeExtension<AmbianceColors> copyWith({

    Color? base,

    Color? card,

    Color? card2,

    Color? lineRgba,

    Color? ink,

    Color? sub,

    Color? acc,

    Color? ph,

    Color? pill,

    Color? statusWatchlist,

    Color? statusSave,

    Color? statusWatching,

    Color? statusWatched,

    Color? statusOnHold,

    Color? statusDropped,

    Color? glow1,

    Color? glow2,

    BoxDecoration? background,

    BoxDecoration? primaryButtonDecoration,

    bool? isDark,

  }) {

    return AmbianceColors(

      base: base ?? this.base,

      card: card ?? this.card,

      card2: card2 ?? this.card2,

      lineRgba: lineRgba ?? this.lineRgba,

      ink: ink ?? this.ink,

      sub: sub ?? this.sub,

      acc: acc ?? this.acc,

      ph: ph ?? this.ph,

      pill: pill ?? this.pill,

      statusWatchlist: statusWatchlist ?? this.statusWatchlist,

      statusSave: statusSave ?? this.statusSave,

      statusWatching: statusWatching ?? this.statusWatching,

      statusWatched: statusWatched ?? this.statusWatched,

      statusOnHold: statusOnHold ?? this.statusOnHold,

      statusDropped: statusDropped ?? this.statusDropped,

      glow1: glow1 ?? this.glow1,

      glow2: glow2 ?? this.glow2,

      background: background ?? this.background,

      primaryButtonDecoration: primaryButtonDecoration ?? this.primaryButtonDecoration,

      isDark: isDark ?? this.isDark,

    );

  }



  @override

  ThemeExtension<AmbianceColors> lerp(ThemeExtension<AmbianceColors>? other, double t) {

    if (other is! AmbianceColors) return this;

    return AmbianceColors(

      base: Color.lerp(base, other.base, t)!,

      card: Color.lerp(card, other.card, t)!,

      card2: Color.lerp(card2, other.card2, t)!,

      lineRgba: Color.lerp(lineRgba, other.lineRgba, t)!,

      ink: Color.lerp(ink, other.ink, t)!,

      sub: Color.lerp(sub, other.sub, t)!,

      acc: Color.lerp(acc, other.acc, t)!,

      ph: Color.lerp(ph, other.ph, t)!,

      pill: Color.lerp(pill, other.pill, t)!,

      statusWatchlist: Color.lerp(statusWatchlist, other.statusWatchlist, t)!,

      statusSave: Color.lerp(statusSave, other.statusSave, t)!,

      statusWatching: Color.lerp(statusWatching, other.statusWatching, t)!,

      statusWatched: Color.lerp(statusWatched, other.statusWatched, t)!,

      statusOnHold: Color.lerp(statusOnHold, other.statusOnHold, t)!,

      statusDropped: Color.lerp(statusDropped, other.statusDropped, t)!,

      glow1: Color.lerp(glow1, other.glow1, t)!,

      glow2: Color.lerp(glow2, other.glow2, t)!,

      background: BoxDecoration.lerp(background, other.background, t)!,

      primaryButtonDecoration: BoxDecoration.lerp(primaryButtonDecoration, other.primaryButtonDecoration, t)!,

      isDark: t < 0.5 ? isDark : other.isDark,

    );

  }

}
