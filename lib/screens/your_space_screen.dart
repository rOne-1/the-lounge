import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/media_provider.dart';
import '../providers/navigation_provider.dart';
import '../constants.dart';
import '../widgets/ambient_glow.dart';
import '../widgets/lounge_doorway_emblem.dart';
import '../widgets/memory_moments_section.dart';
import '../widgets/pressable_scale.dart';
import 'archive_screen.dart';
import 'tools_screen.dart';
import 'settings_screen.dart';

/// YSR-GATEWAY-1: The Sanctuary Gateway (`The Lounge-selection.png`) - the
/// elevated landing screen for Your Space. Features the dynamic Day overline,
/// Bodoni Moda time-of-day greeting, total titles counter, glowing Lounge Doorway
/// centerpiece emblem, and 4-card quick navigation dock (Archive, Browse -> Lobby,
/// Tools, Settings).
class YourSpaceScreen extends ConsumerStatefulWidget {
  final bool? enableAnimation;

  const YourSpaceScreen({super.key, this.enableAnimation});

  @override
  ConsumerState<YourSpaceScreen> createState() => _YourSpaceScreenState();
}

class _YourSpaceScreenState extends ConsumerState<YourSpaceScreen> {
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
    final colors = context.ambianceColors;
    final isLarge = MediaQuery.of(context).size.width >= 600;
    final paddingHorizontal = isLarge ? 24.0 : 18.0;

    int countFor(Map<String, dynamic> itemsMap) => itemsMap.length;

    final libraryCount = countFor(mediaState.watchlist) +
        countFor(mediaState.maybeList) +
        countFor(mediaState.watchingList) +
        countFor(mediaState.onHoldList) +
        countFor(mediaState.droppedList) +
        countFor(mediaState.watchedList);

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        paddingHorizontal,
        16.0,
        paddingHorizontal,
        100.0 + MediaQuery.of(context).padding.bottom,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 16),
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
            '$libraryCount title${libraryCount == 1 ? '' : 's'} in your space',
            style: AppThemes.safeGeist(
              fontSize: 14,
              color: colors.sub,
              letterSpacing: 0.1,
            ),
          ),
          const SizedBox(height: 48),

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
          const SizedBox(height: 52),

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
                  key: const ValueKey('your_space_settings_button'),
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
                    colors.card2.withValues(alpha: 0.8),
                    colors.card,
                  ],
          ),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: accent.withValues(alpha: isDark ? 0.24 : 0.16),
                    blurRadius: 18,
                    spreadRadius: 1,
                    offset: const Offset(0, 2),
                  ),
                  if (isDark)
                    BoxShadow(
                      color: colors.surfaceHighlight,
                      blurRadius: 0,
                      offset: const Offset(0, 1),
                      blurStyle: BlurStyle.inner,
                    ),
                ]
              : [
                  BoxShadow(
                    color: isDark
                        ? const Color(0x1A000000)
                        : const Color(0x06000000),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                  if (isDark)
                    BoxShadow(
                      color: colors.surfaceHighlight,
                      blurRadius: 0,
                      offset: const Offset(0, 1),
                      blurStyle: BlurStyle.inner,
                    ),
                ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isActive ? accent : colors.sub,
              size: 24,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: AppThemes.safeGeist(
                fontSize: 12.5,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                color: isActive ? colors.ink : colors.sub,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
