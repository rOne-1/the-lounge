import 'package:flutter/services.dart';

/// CRAFT-HAPTIC-1: the 3 theme haptic weight families from the triage doc's
/// judgment call. Flutter's `HapticFeedback` only exposes a handful of
/// discrete platform primitives (no true per-app custom vibration curves),
/// so each family is a distinct *combination* of those primitives per
/// gesture outcome, not a literally different physical sensation --
/// deliberately honest about that platform constraint rather than
/// pretending otherwise.
enum HapticWeight {
  /// Screening Room / Tuscany: sharp, clicky, immediate.
  crispMechanical,

  /// Midnight Cinema / Violet Dusk: soft, weighty, luxurious.
  deepVelvet,

  /// Orchid Bloom: light, minimal, barely-there.
  airySubtle,
}

/// Maps a theme id (`AppTheme.id`, e.g. from `ambianceProvider`) to its
/// haptic weight family. Unknown ids fall back to [HapticWeight.crispMechanical]
/// (the default/first-registered theme's own family) rather than throwing.
HapticWeight hapticWeightForThemeId(String themeId) {
  switch (themeId) {
    case 'screening_room':
    case 'tuscany':
      return HapticWeight.crispMechanical;
    case 'midnight_cinema':
    case 'violet_dusk':
      return HapticWeight.deepVelvet;
    case 'orchid_bloom':
      return HapticWeight.airySubtle;
    default:
      return HapticWeight.crispMechanical;
  }
}

/// CRAFT-HAPTIC-1: outcome-based tactile feedback for the Discover swipe
/// deck (and anywhere else a "strong positive" moment wants the same
/// double-pulse language, e.g. rating a title Loved). Every call is
/// wrapped defensively -- `HapticFeedback` platform channels are unlikely
/// to throw on web/desktop in current Flutter, but the AC explicitly names
/// "zero crashes on non-haptic platforms" as a requirement, so this
/// doesn't rely on that being true forever.
class AppHaptics {
  const AppHaptics._();

  static Future<void> _safeCall(Future<void> Function() call) async {
    try {
      await call();
    } catch (_) {
      // Non-haptic platform (web/desktop) or no vibration hardware --
      // silently a no-op, never a crash.
    }
  }

  /// Fired once when a drag crosses the swipe commit threshold -- a light
  /// tick confirming "you're now far enough to commit," distinct from the
  /// heavier [commitImpact] fired only once the swipe actually releases
  /// past that point.
  static Future<void> thresholdTick(HapticWeight weight) => _safeCall(() {
        switch (weight) {
          case HapticWeight.crispMechanical:
            return HapticFeedback.selectionClick();
          case HapticWeight.deepVelvet:
            return HapticFeedback.lightImpact();
          case HapticWeight.airySubtle:
            return HapticFeedback.selectionClick();
        }
      });

  /// Fired once a swipe commits to a shelf action (fly-off triggered).
  static Future<void> commitImpact(HapticWeight weight) => _safeCall(() {
        switch (weight) {
          case HapticWeight.crispMechanical:
            return HapticFeedback.mediumImpact();
          case HapticWeight.deepVelvet:
            return HapticFeedback.heavyImpact();
          case HapticWeight.airySubtle:
            return HapticFeedback.lightImpact();
        }
      });

  /// Two closely-spaced impacts for a strong positive moment (e.g. rating
  /// a title Loved -- the closest existing analog to "favoriting" in this
  /// app's actual data model; see CRAFT-HAPTIC-1's session log entry for
  /// why this isn't literally a Discover swipe direction).
  static Future<void> doublePulse(HapticWeight weight) async {
    final Future<void> Function() impact = switch (weight) {
      HapticWeight.crispMechanical => HapticFeedback.heavyImpact,
      HapticWeight.deepVelvet => HapticFeedback.heavyImpact,
      HapticWeight.airySubtle => HapticFeedback.lightImpact,
    };
    await _safeCall(impact);
    await Future.delayed(const Duration(milliseconds: 90));
    await _safeCall(impact);
  }
}
