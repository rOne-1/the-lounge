import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/media_item.dart';
import '../models/profile_space.dart';
import '../providers/media_provider.dart';
import '../providers/navigation_provider.dart';
import '../providers/profile_provider.dart';
import '../constants.dart';
import '../widgets/ambient_glow.dart';
import '../widgets/lounge_doorway_emblem.dart';
import '../widgets/memory_moments_section.dart';
import '../widgets/pressable_scale.dart';
import '../widgets/profile_selector_sheet.dart';
import 'archive_screen.dart';
import 'tools_screen.dart';
import 'settings_screen.dart';

/// YSR-GATEWAY-1 / NAME-1: The Sanctuary Gateway (`The Lounge-selection.png`) - the
/// elevated landing screen for The Lounge. Features the dynamic Day overline,
/// Bodoni Moda time-of-day greeting, total titles counter, glowing Lounge Doorway
/// centerpiece emblem, and 4-card quick navigation dock (Archive, Browse -> Lobby,
/// Tools, Settings). Responsive and constrained across small phones, foldables,
/// tablets, and desktop displays.
class LoungeScreen extends ConsumerStatefulWidget {
  final bool? enableAnimation;

  const LoungeScreen({super.key, this.enableAnimation});

  @override
  ConsumerState<LoungeScreen> createState() => _LoungeScreenState();
}

class _LoungeScreenState extends ConsumerState<LoungeScreen> {
  @override
  void initState() {
    super.initState();
    // B2/E5: monthly new-season/new-episode refresh for Watched shows.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(mediaProvider.notifier).refreshWatchedShowsIfDue();
      }
    });
  }

  IconData _iconFor(String iconKey) {
    switch (iconKey) {
      case 'star':
        return Icons.star_rounded;
      case 'sparkles':
        return Icons.auto_awesome_rounded;
      case 'popcorn':
        return Icons.movie_filter_rounded;
      case 'heart':
        return Icons.favorite_rounded;
      case 'tv':
        return Icons.tv_rounded;
      case 'movie':
        return Icons.local_movies_rounded;
      default:
        return Icons.person_rounded;
    }
  }

  String get _weekday {
    const days = [
      'MONDAY',
      'TUESDAY',
      'WEDNESDAY',
      'THURSDAY',
      'FRIDAY',
      'SATURDAY',
      'SUNDAY',
    ];
    return days[DateTime.now().weekday - 1];
  }

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 5) return 'Good evening';
    if (hour < 12) return 'Good morning';
    if (hour < 18) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    final mediaState = ref.watch(mediaProvider);
    final profileState = ref.watch(profileProvider);
    final activeProfile = profileState.activeProfile;
    final colors = context.ambianceColors;
    final mediaQuery = MediaQuery.of(context);
    final isLarge = mediaQuery.size.width >= 600;
    final paddingHorizontal = isLarge ? 24.0 : 18.0;
    final screenHeight = mediaQuery.size.height;

    // Adaptive vertical rhythm based on viewport height
    final emblemSpacingTop = screenHeight < 700 ? 32.0 : 48.0;
    final emblemSpacingBottom = screenHeight < 700 ? 36.0 : 52.0;

    final activeMediaType = ref.watch(navigationProvider).activeMediaType;
    final activeDomain = MediumDomain.fromMediaTypeToggle(activeMediaType);
    final targetType = activeMediaType == MediaTypeToggle.movies ? MediaType.movie : MediaType.tv;

    int countForType(Map<String, dynamic> itemsMap) =>
        itemsMap.values.where((m) => m is MediaItem && m.type == targetType).length;

    final libraryCount = countForType(mediaState.watchlist) +
        countForType(mediaState.maybeList) +
        countForType(mediaState.watchingList) +
        countForType(mediaState.onHoldList) +
        countForType(mediaState.droppedList) +
        countForType(mediaState.watchedList);

    String domainSubtitle = '$libraryCount titles in the lounge';
    switch (activeDomain) {
      case MediumDomain.movies:
        domainSubtitle = '$libraryCount ${libraryCount == 1 ? "movie" : "movies"} in the lounge';
        break;
      case MediumDomain.tv:
        domainSubtitle = '$libraryCount ${libraryCount == 1 ? "TV show" : "TV shows"} in the lounge';
        break;
      case MediumDomain.anime:
        domainSubtitle = '$libraryCount ${libraryCount == 1 ? "anime" : "anime series"} in the lounge';
        break;
    }

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        paddingHorizontal,
        16.0,
        paddingHorizontal,
        100.0 + mediaQuery.padding.bottom,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 8),
              // Persona Switcher Pill
              PressableScale(
                key: const ValueKey('lounge_persona_pill'),
                onTap: () => ProfileSelectorSheet.show(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: colors.card,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: colors.lineRgba),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _iconFor(activeProfile.iconKey),
                        size: 14,
                        color: colors.acc,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        activeProfile.name,
                        style: AppThemes.safeGeist(
                          fontSize: 12.0,
                          fontWeight: FontWeight.w600,
                          color: colors.ink,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.keyboard_arrow_down_rounded,
                        size: 15,
                        color: colors.sub,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // 1. Header: Day overline, Bodoni greeting, Library count subtitle
              Text(
                _weekday,
                style: AppThemes.safeGeist(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 2.2,
                  color: colors.sub,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _greeting,
                textAlign: TextAlign.center,
                style: GoogleFonts.bodoniModa(
                  fontSize: 40,
                  fontWeight: FontWeight.w400,
                  fontStyle: FontStyle.italic,
                  color: colors.ink,
                  letterSpacing: -0.5,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                domainSubtitle,
                style: AppThemes.safeGeist(
                  fontSize: 14,
                  color: colors.sub,
                  letterSpacing: 0.1,
                ),
              ),
              SizedBox(height: emblemSpacingTop),

              // 2. Centerpiece: AmbientGlowWidget radiating behind LoungeDoorwayEmblem
              Center(
                child: AmbientGlowWidget(
                  enableAnimation: widget.enableAnimation,
                  duration: const Duration(seconds: 15),
                  borderRadius: BorderRadius.circular(100),
                  padding: const EdgeInsets.all(36.0),
                  color1: colors.glow1,
                  color2: colors.glow2,
                  child: const LoungeDoorwayEmblem(size: 132.0),
                ),
              ),
              SizedBox(height: emblemSpacingBottom),

              // 3. Navigation Dock (4 Quick Access Cards)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: _DockCard(
                      icon: Icons.collections_bookmark_rounded,
                      label: 'Archive',
                      isActive: true,
                      onTap: () => _push(context, const ArchiveScreen()),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _DockCard(
                      icon: Icons.explore_outlined,
                      label: 'Browse',
                      onTap: () => _switchTab(AppTab.lobby),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _DockCard(
                      icon: Icons.tune_rounded,
                      label: 'Tools',
                      onTap: () => _push(context, const ToolsScreen()),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _DockCard(
                      key: const ValueKey('lounge_settings_button'),
                      icon: Icons.light_mode_outlined,
                      label: 'Settings',
                      onTap: () => _push(context, const SettingsScreen()),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 36),

              // 4. Memory Moments Section ("Forgotten Favorites" & "On This Day")
              const MemoryMomentsSection(),
            ],
          ),
        ),
      ),
    );
  }

  void _push(BuildContext context, Widget screen) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => screen),
    );
  }

  void _switchTab(AppTab tab) {
    ref.read(navigationProvider.notifier).setTab(tab);
  }
}

class _DockCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _DockCard({
    super.key,
    required this.icon,
    required this.label,
    this.isActive = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.ambianceColors;
    final accent = colors.acc;
    final isDark = colors.isDark;

    return PressableScale(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppPhysics.houseSpringDuration,
        curve: AppPhysics.houseSpringCurve,
        height: 94,
        padding: const EdgeInsets.symmetric(vertical: 14.0, horizontal: 4.0),
        decoration: BoxDecoration(
          color: colors.card,
          borderRadius: BorderRadius.circular(22.0),
          border: Border.all(
            color: isActive
                ? accent.withValues(alpha: isDark ? 0.75 : 0.85)
                : colors.lineRgba,
            width: isActive ? 1.5 : 1.0,
          ),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isActive
                ? [
                    accent.withValues(alpha: isDark ? 0.16 : 0.10),
                    colors.card,
                  ]
                : [
                    colors.card,
                    colors.card,
                  ],
          ),
          boxShadow: [
            BoxShadow(
              color: colors.scrim.withValues(alpha: isDark ? 0.28 : 0.08),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 24,
              color: isActive ? accent : colors.sub,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: AppThemes.safeGeist(
                fontSize: 12.0,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                color: isActive ? colors.ink : colors.sub,
                letterSpacing: 0.2,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
