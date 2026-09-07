import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'ambiance_provider.dart';

/// Three-tier control over decorative/ambient motion app-wide (breathing
/// glows, poster tilt/glare, and any future shader-driven ambient effects).
/// Deliberately does NOT touch core interaction feedback (PressableScale's
/// tap scale, dialog/sheet entrance transitions) -- those are functional
/// feedback, not ambient decoration, and stay on regardless of this setting.
enum MotionIntensity {
  /// Decorative motion disabled outright -- glows render at a fixed frame,
  /// tilt/glare don't respond to pointer movement.
  off,

  /// Decorative motion still runs, scaled down (see [scale]) -- a middle
  /// ground for anyone sensitive to full-strength ambient motion without
  /// wanting it gone entirely.
  reduced,

  /// Full intensity, as designed. Default.
  full;

  /// Whether decorative motion should animate at all at this tier.
  bool get animates => this != MotionIntensity.off;

  /// Magnitude scale (0.0-1.0) applied to continuous decorative motion --
  /// tilt angle, glare intensity, shader flow speed, etc. `off` and
  /// `reduced` both disable the underlying animation controller entirely
  /// (see [animates]); this only matters for effects that are still
  /// animating but should read as gentler at `reduced`.
  double get scale {
    switch (this) {
      case MotionIntensity.off:
        return 0.0;
      case MotionIntensity.reduced:
        return 0.4;
      case MotionIntensity.full:
        return 1.0;
    }
  }

  String get label {
    switch (this) {
      case MotionIntensity.off:
        return 'Off';
      case MotionIntensity.reduced:
        return 'Reduced';
      case MotionIntensity.full:
        return 'Full';
    }
  }

  /// Combines this tier with a widget's own already-requested
  /// `enableAnimation` value (the existing per-widget test-suppression
  /// convention used across the app -- explicit `false` means "a test is
  /// pumping this widget directly and needs animation off to avoid a
  /// pending-timer/pumpAndSettle failure", not a user preference).
  ///
  /// - `requested == false` always stays `false` -- this tier never
  ///   re-enables an animation a caller explicitly suppressed.
  /// - At `off`, always returns `false` regardless of what was requested --
  ///   decorative motion is fully disabled at this tier.
  /// - At `reduced`/`full`, [requested] (`null` or `true`) passes through
  ///   unchanged, preserving whatever auto-detection the widget's own
  ///   `enableAnimation ?? !isTestEnvironment` default does internally.
  bool? gateAnimation(bool? requested) {
    if (requested == false) return false;
    if (!animates) return false;
    return requested;
  }
}

class MotionIntensityNotifier extends Notifier<MotionIntensity> {
  static const _prefsKey = 'motion_intensity';

  @override
  MotionIntensity build() {
    try {
      final prefs = ref.watch(sharedPreferencesProvider);
      final stored = prefs.getString(_prefsKey);
      return MotionIntensity.values.firstWhere(
        (v) => v.name == stored,
        orElse: () => MotionIntensity.full,
      );
    } catch (_) {
      // Defensively catch missing SharedPreferences override in unit tests
      // (same pattern as MediaNotifier.build) -- this provider is now
      // watched from many widgets (AuroraGlow/Tilt3DCard call sites) whose
      // existing tests never had reason to override sharedPreferencesProvider
      // before, since nothing they rendered previously needed it.
      return MotionIntensity.full;
    }
  }

  Future<void> setIntensity(MotionIntensity intensity) async {
    state = intensity;
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setString(_prefsKey, intensity.name);
  }
}

final motionIntensityProvider =
    NotifierProvider<MotionIntensityNotifier, MotionIntensity>(() {
  return MotionIntensityNotifier();
});
