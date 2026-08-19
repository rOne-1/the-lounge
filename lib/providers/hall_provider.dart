import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/hall_space.dart';
import '../services/hall_storage_service.dart';
import 'ambiance_provider.dart';
import 'media_provider.dart';

final hallStorageServiceProvider = Provider<HallStorageService>((ref) {
  return HallStorageService();
});

final profileStorageServiceProvider = hallStorageServiceProvider;

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

  /// Backward compatibility alias for [activeHallId].
  String get activeProfileId => activeHallId;

  /// Backward compatibility alias for [halls].
  List<HallSpace> get profiles => halls;

  /// Backward compatibility alias for [activeHall].
  HallSpace get activeProfile => activeHall;

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

/// Backward compatibility alias for [HallState].
typedef ProfileState = HallState;

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
      await ref.read(mediaProvider.notifier).loadForProfile(targetHall.id);
      if (targetHall.themeId != null) {
        await ref.read(ambianceProvider.notifier).setTheme(targetHall.themeId!);
      }
    } catch (_) {}
  }

  /// Backward compatibility alias for [switchHall].
  Future<void> switchProfile(String profileId) => switchHall(profileId);

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

  /// Backward compatibility alias for [renameHall].
  Future<void> renameProfile(String profileId, String newName) =>
      renameHall(profileId, newName);

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

  /// Backward compatibility alias for [updateHallIcon].
  Future<void> updateProfileIcon(String profileId, String iconKey) =>
      updateHallIcon(profileId, iconKey);

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

  /// Backward compatibility alias for [updateActiveHall].
  Future<void> updateActiveProfile(HallSpace Function(HallSpace current) updater) =>
      updateActiveHall(updater);
}

/// Backward compatibility alias for [HallNotifier].
typedef ProfileNotifier = HallNotifier;

final hallProvider =
    NotifierProvider<HallNotifier, HallState>(HallNotifier.new);

final activeHallSpaceProvider = Provider<HallSpace>((ref) {
  return ref.watch(hallProvider).activeHall;
});

/// Backward compatibility alias for [hallProvider].
final profileProvider = hallProvider;
