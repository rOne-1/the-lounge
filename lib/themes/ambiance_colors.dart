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

  /// IMDb/TMDB-style star rating accent, harmonized per theme palette.
  final Color starRating;

  /// Inner card bevel highlight sheen (top edge light catch).
  final Color surfaceHighlight;

  /// Translucent floating bottom navigation bar base color.
  final Color navBarBg;

  /// Backdrop hero gradient fade and modal barrier scrim.
  final Color scrim;

  /// Destructive actions, reset, clear data, error highlights.
  final Color danger;

  /// Confirmation, backup export success, saved indicators.
  final Color success;

  final Color glow1;
  final Color glow2;

  final BoxDecoration background;
  final BoxDecoration primaryButtonDecoration;

  /// THEME-DEPTH-2: base visibility of the procedural grain texture
  /// (`AppNoiseTexture`) -- richer on velvet/luxury dark themes, barely
  /// there on airy light ones. Independent of [grainTint]'s own alpha.
  final double grainOpacity;

  /// THEME-DEPTH-2: color wash applied over the grain structure via
  /// `BlendMode.color`, carrying its own alpha as the wash strength. Keeps
  /// the grain feeling like *this* theme's material rather than one
  /// neutral gray texture reused everywhere.
  final Color grainTint;

  /// THEME-DEPTH-3: elevation for card-like surfaces (see [ThemeShadows]).
  final List<BoxShadow> cardShadow;

  /// THEME-DEPTH-3: elevation for floating overlay chrome.
  final List<BoxShadow> ambientGlowShadow;

  /// THEME-DEPTH-3: elevation for dialogs/sheets/panels.
  final List<BoxShadow> dialogShadow;

  /// THEME-DEPTH-4: Bespoke signature decorative motif builder for this theme.
  final WidgetBuilder? signatureMotif;

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
    required this.starRating,
    required this.surfaceHighlight,
    required this.navBarBg,
    required this.scrim,
    required this.danger,
    required this.success,
    required this.glow1,
    required this.glow2,
    required this.background,
    required this.primaryButtonDecoration,
    required this.grainOpacity,
    required this.grainTint,
    required this.cardShadow,
    required this.ambientGlowShadow,
    required this.dialogShadow,
    this.signatureMotif,
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
    Color? starRating,
    Color? surfaceHighlight,
    Color? navBarBg,
    Color? scrim,
    Color? danger,
    Color? success,
    Color? glow1,
    Color? glow2,
    BoxDecoration? background,
    BoxDecoration? primaryButtonDecoration,
    double? grainOpacity,
    Color? grainTint,
    List<BoxShadow>? cardShadow,
    List<BoxShadow>? ambientGlowShadow,
    List<BoxShadow>? dialogShadow,
    WidgetBuilder? signatureMotif,
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
      starRating: starRating ?? this.starRating,
      surfaceHighlight: surfaceHighlight ?? this.surfaceHighlight,
      navBarBg: navBarBg ?? this.navBarBg,
      scrim: scrim ?? this.scrim,
      danger: danger ?? this.danger,
      success: success ?? this.success,
      glow1: glow1 ?? this.glow1,
      glow2: glow2 ?? this.glow2,
      background: background ?? this.background,
      primaryButtonDecoration: primaryButtonDecoration ?? this.primaryButtonDecoration,
      grainOpacity: grainOpacity ?? this.grainOpacity,
      grainTint: grainTint ?? this.grainTint,
      cardShadow: cardShadow ?? this.cardShadow,
      ambientGlowShadow: ambientGlowShadow ?? this.ambientGlowShadow,
      dialogShadow: dialogShadow ?? this.dialogShadow,
      signatureMotif: signatureMotif ?? this.signatureMotif,
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
      starRating: Color.lerp(starRating, other.starRating, t)!,
      surfaceHighlight: Color.lerp(surfaceHighlight, other.surfaceHighlight, t)!,
      navBarBg: Color.lerp(navBarBg, other.navBarBg, t)!,
      scrim: Color.lerp(scrim, other.scrim, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
      success: Color.lerp(success, other.success, t)!,
      glow1: Color.lerp(glow1, other.glow1, t)!,
      glow2: Color.lerp(glow2, other.glow2, t)!,
      background: BoxDecoration.lerp(background, other.background, t)!,
      primaryButtonDecoration: BoxDecoration.lerp(primaryButtonDecoration, other.primaryButtonDecoration, t)!,
      grainOpacity: (grainOpacity + (other.grainOpacity - grainOpacity) * t.clamp(0.0, 1.0)).clamp(0.0, 1.0),
      grainTint: Color.lerp(grainTint, other.grainTint, t)!,
      cardShadow: BoxShadow.lerpList(cardShadow, other.cardShadow, t.clamp(0.0, 1.0)) ?? cardShadow,
      ambientGlowShadow:
          BoxShadow.lerpList(ambientGlowShadow, other.ambientGlowShadow, t.clamp(0.0, 1.0)) ?? ambientGlowShadow,
      dialogShadow: BoxShadow.lerpList(dialogShadow, other.dialogShadow, t.clamp(0.0, 1.0)) ?? dialogShadow,
      signatureMotif: t < 0.5 ? signatureMotif : other.signatureMotif,
      isDark: t < 0.5 ? isDark : other.isDark,
    );
  }
}
