import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/hall_space.dart';
import '../services/hall_storage_service.dart';
import 'ambiance_provider.dart';
import 'media_provider.dart';

final hallStorageServiceProvider = Provider<HallStorageService>((ref) {
  return HallStorageService();
});

class HallState {
  final String activeHallId;
  final List<HallSpace> halls;
  final bool isLoading;

  const HallState({
    this.activeHallId = 'common',
    this.halls = const [],
    this.isLoading = false,
  });

  HallSpace get activeHall {
    if (halls.isEmpty) return HallSpace.defaultGrandHall();
    return halls.firstWhere(
      (p) => p.id == activeHallId,
      orElse: () => halls.first,
    );
  }

  DomainArchive activeDomainArchive(MediumDomain domain) {
    return activeHall.domainArchive(domain);
  }

  HallState copyWith({
    String? activeHallId,
    List<HallSpace>? halls,
    bool? isLoading,
  }) {
    return HallState(
      activeHallId: activeHallId ?? this.activeHallId,
      halls: halls ?? this.halls,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class HallNotifier extends Notifier<HallState> {
  HallStorageService get _storageService =>
      ref.read(hallStorageServiceProvider);

  SharedPreferences get _prefs => ref.read(sharedPreferencesProvider);

  @override
  HallState build() {
    List<HallSpace> initialHalls = [
      HallSpace.defaultGrandHall(),
      HallSpace.defaultMezzanineHall(),
      HallSpace.defaultPrivateScreeningHall(),
    ];
    String activeId = 'common';

    try {
      final prefs = ref.watch(sharedPreferencesProvider);
      activeId = _storageService.getActiveHallId(prefs);
      initialHalls = _storageService.loadAllHallsSync(prefs);
    } catch (_) {}

    return HallState(
      activeHallId: activeId,
      halls: initialHalls,
      isLoading: false,
    );
  }

  Future<void> switchHall(String hallId) async {
    if (state.activeHallId == hallId) return;

    final targetHall = state.halls.firstWhere(
      (p) => p.id == hallId,
      orElse: () => state.activeHall,
    );

    state = state.copyWith(activeHallId: targetHall.id);
    try {
      await _storageService.saveActiveHallId(_prefs, targetHall.id);
      await ref.read(mediaProvider.notifier).loadForHall(targetHall.id);
    } catch (_) {}

    // Discover's deck providers are plain (non-autoDispose) Notifiers that
    // only ever fetch once, in their own build() -- nothing about mediaProvider
    // finishing its reload for the new hall makes them re-run on their own.
    // Left alone, the pool would keep showing the previous hall's candidates
    // (built from its exclusion set and, since LANG-2, its language lock)
    // indefinitely. Invalidating forces build() to re-run, which kicks off a
    // fresh loadPool() against the now-current mediaProvider/hall state.
    // In its own try/catch, deliberately not sharing one with the theme
    // switch below: they're independent side effects of a hall switch, and
    // the theme switch's GoogleFonts/network path failing must never
    // silently skip the deck refresh (or vice versa) just because they
    // happened to share a swallowed exception.
    try {
      ref.invalidate(discoverMoviesDeckProvider);
      ref.invalidate(discoverTvDeckProvider);
    } catch (_) {}

    if (targetHall.themeId != null) {
      try {
        await ref.read(ambianceProvider.notifier).setTheme(targetHall.themeId!);
      } catch (_) {}
    }
  }

  Future<void> renameHall(String hallId, String newName) async {
    final trimmed = newName.trim();
    if (trimmed.isEmpty) return;

    final updated = state.halls.map((p) {
      if (p.id == hallId) {
        return p.copyWith(name: trimmed);
      }
      return p;
    }).toList();

    state = state.copyWith(halls: updated);

    final target = updated.firstWhere((p) => p.id == hallId);
    try {
      await _storageService.saveHall(_prefs, target);
    } catch (_) {}
  }

  Future<void> updateHallIcon(String hallId, String iconKey) async {
    final updated = state.halls.map((p) {
      if (p.id == hallId) {
        return p.copyWith(iconKey: iconKey);
      }
      return p;
    }).toList();

    state = state.copyWith(halls: updated);

    final target = updated.firstWhere((p) => p.id == hallId);
    try {
      await _storageService.saveHall(_prefs, target);
    } catch (_) {}
  }

  Future<void> updateHallTheme(String hallId, String themeId) async {
    final updated = state.halls.map((p) {
      if (p.id == hallId) {
        return p.copyWith(themeId: themeId);
      }
      return p;
    }).toList();

    state = state.copyWith(halls: updated);

    final target = updated.firstWhere((p) => p.id == hallId);
    try {
      await _storageService.saveHall(_prefs, target);
      if (state.activeHallId == hallId) {
        await ref.read(ambianceProvider.notifier).setTheme(themeId);
      }
    } catch (_) {}
  }

  /// LANG-1: Sets or clears a hall's language restriction. Pass `null` for
  /// both [languageCode] and [languageName] to unlock the hall back to All
  /// Languages -- HallSpace.copyWith's sentinel pattern makes that an
  /// explicit clear, not a no-op.
  Future<void> updateHallLanguage(
    String hallId,
    String? languageCode,
    String? languageName,
  ) async {
    final updated = state.halls.map((p) {
      if (p.id == hallId) {
        return p.copyWith(
          lockedLanguageCode: languageCode,
          lockedLanguageName: languageName,
        );
      }
      return p;
    }).toList();

    state = state.copyWith(halls: updated);

    final target = updated.firstWhere((p) => p.id == hallId);
    try {
      await _storageService.saveHall(_prefs, target);
    } catch (_) {}

    // Same reactivity gap switchHall closes, hit from a different angle:
    // editing the *active* hall's language lock in place (no hall switch
    // involved) leaves an already-loaded Discover pool built from the old
    // lock. Only refresh when the edited hall is actually the active one --
    // editing a different hall's settings shouldn't touch the deck you're
    // not even looking at. Own try/catch, independent of the save above, for
    // the same reason as switchHall's.
    if (state.activeHallId == hallId) {
      try {
        ref.invalidate(discoverMoviesDeckProvider);
        ref.invalidate(discoverTvDeckProvider);
      } catch (_) {}
    }
  }

  /// BACKUP-1: persists every hall from an imported multi-hall backup and
  /// refreshes both this provider's and mediaProvider's state to reflect
  /// it -- a plain [saveHall] loop alone would leave the two providers'
  /// in-memory caches stale (same reactivity gap [switchHall] closes for a
  /// live hall switch).
  Future<void> applyImportedHalls(List<HallSpace> halls) async {
    if (halls.isEmpty) return;
    for (final hall in halls) {
      await _storageService.saveHall(_prefs, hall);
    }

    final stillActiveId =
        halls.any((h) => h.id == state.activeHallId) ? state.activeHallId : halls.first.id;
    await _storageService.saveActiveHallId(_prefs, stillActiveId);

    state = state.copyWith(halls: halls, activeHallId: stillActiveId);
    await ref.read(mediaProvider.notifier).loadForHall(stillActiveId);

    try {
      ref.invalidate(discoverMoviesDeckProvider);
      ref.invalidate(discoverTvDeckProvider);
    } catch (_) {}
  }

  Future<void> updateActiveHall(HallSpace Function(HallSpace current) updater) async {
    final current = state.activeHall;
    final updatedHall = updater(current);

    final updatedList = state.halls.map((p) {
      if (p.id == updatedHall.id) return updatedHall;
      return p;
    }).toList();

    state = state.copyWith(halls: updatedList);

    try {
      await _storageService.saveHall(_prefs, updatedHall);
    } catch (_) {}
  }

}

final hallProvider =
    NotifierProvider<HallNotifier, HallState>(HallNotifier.new);

final activeHallSpaceProvider = Provider<HallSpace>((ref) {
  return ref.watch(hallProvider).activeHall;
});
