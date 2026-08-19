import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/profile_space.dart';
import '../services/profile_storage_service.dart';
import 'ambiance_provider.dart';
import 'media_provider.dart';

final profileStorageServiceProvider = Provider<ProfileStorageService>((ref) {
  return ProfileStorageService();
});

class ProfileState {
  final String activeProfileId;
  final List<ProfileSpace> profiles;
  final bool isLoading;

  const ProfileState({
    this.activeProfileId = 'common',
    this.profiles = const [],
    this.isLoading = false,
  });

  ProfileSpace get activeProfile {
    if (profiles.isEmpty) return ProfileSpace.defaultCommon();
    return profiles.firstWhere(
      (p) => p.id == activeProfileId,
      orElse: () => profiles.first,
    );
  }

  DomainArchive activeDomainArchive(MediumDomain domain) {
    return activeProfile.domainArchive(domain);
  }

  ProfileState copyWith({
    String? activeProfileId,
    List<ProfileSpace>? profiles,
    bool? isLoading,
  }) {
    return ProfileState(
      activeProfileId: activeProfileId ?? this.activeProfileId,
      profiles: profiles ?? this.profiles,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class ProfileNotifier extends Notifier<ProfileState> {
  ProfileStorageService get _storageService =>
      ref.read(profileStorageServiceProvider);

  SharedPreferences get _prefs => ref.read(sharedPreferencesProvider);

  @override
  ProfileState build() {
    List<ProfileSpace> initialProfiles = [
      ProfileSpace.defaultCommon(),
      ProfileSpace.defaultCustom1(),
      ProfileSpace.defaultCustom2(),
    ];
    String activeId = 'common';

    try {
      final prefs = ref.watch(sharedPreferencesProvider);
      activeId = _storageService.getActiveProfileId(prefs);
      initialProfiles = _storageService.loadAllProfilesSync(prefs);
    } catch (_) {}

    return ProfileState(
      activeProfileId: activeId,
      profiles: initialProfiles,
      isLoading: false,
    );
  }

  Future<void> switchProfile(String profileId) async {
    if (state.activeProfileId == profileId) return;

    final targetProfile = state.profiles.firstWhere(
      (p) => p.id == profileId,
      orElse: () => state.activeProfile,
    );

    state = state.copyWith(activeProfileId: targetProfile.id);
    try {
      await _storageService.saveActiveProfileId(_prefs, targetProfile.id);
      await ref.read(mediaProvider.notifier).loadForProfile(targetProfile.id);
    } catch (_) {}
  }

  Future<void> renameProfile(String profileId, String newName) async {
    final trimmed = newName.trim();
    if (trimmed.isEmpty) return;

    final updated = state.profiles.map((p) {
      if (p.id == profileId) {
        return p.copyWith(name: trimmed);
      }
      return p;
    }).toList();

    state = state.copyWith(profiles: updated);

    final target = updated.firstWhere((p) => p.id == profileId);
    try {
      await _storageService.saveProfile(_prefs, target);
    } catch (_) {}
  }

  Future<void> updateProfileIcon(String profileId, String iconKey) async {
    final updated = state.profiles.map((p) {
      if (p.id == profileId) {
        return p.copyWith(iconKey: iconKey);
      }
      return p;
    }).toList();

    state = state.copyWith(profiles: updated);

    final target = updated.firstWhere((p) => p.id == profileId);
    try {
      await _storageService.saveProfile(_prefs, target);
    } catch (_) {}
  }

  Future<void> updateActiveProfile(ProfileSpace Function(ProfileSpace current) updater) async {
    final current = state.activeProfile;
    final updatedProfile = updater(current);

    final updatedList = state.profiles.map((p) {
      if (p.id == updatedProfile.id) return updatedProfile;
      return p;
    }).toList();

    state = state.copyWith(profiles: updatedList);

    try {
      await _storageService.saveProfile(_prefs, updatedProfile);
    } catch (_) {}
  }
}

final profileProvider =
    NotifierProvider<ProfileNotifier, ProfileState>(ProfileNotifier.new);
