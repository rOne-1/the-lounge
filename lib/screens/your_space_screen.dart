import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/media_provider.dart';
import '../providers/navigation_provider.dart';
import '../providers/ambiance_provider.dart';
import '../models/media_item.dart';
import '../constants.dart';
import '../widgets/pressable_scale.dart';
import 'cleanup_swipe_screen.dart';
import 'folders_screen.dart';
import 'pile_screen.dart';
import 'rate_titles_screen.dart';
import 'rewatch_vault_screen.dart';
import 'settings_screen.dart';

/// PERS-SPACE-1: Your Space is the app's primary landing screen -- an
/// ambient header plus 3 distinct card groups (Piles, Tools, Browse &
/// Discovery), replacing the former 4-tab layout. Each pile now gets its
/// own standalone [PileScreen] destination (see that file for why the old
/// "In Progress" sub-filter was retired), and the Tools/Browse groups
/// surface destinations that used to live only in Settings or the bottom
/// nav.
class YourSpaceScreen extends ConsumerStatefulWidget {
  const YourSpaceScreen({super.key});

  @override
  ConsumerState<YourSpaceScreen> createState() => _YourSpaceScreenState();
}

class _YourSpaceScreenState extends ConsumerState<YourSpaceScreen> {
  @override
  void initState() {
    super.initState();
    // B2/E5: monthly new-season/new-episode refresh for Watched shows.
    // No-ops internally unless 30+ days have passed since the last run.
    // Lives here (rather than PileScreen) because Your Space -- the app's
    // default startup destination per PERS-NAV-1 -- is guaranteed to mount
    // on every app open, whether or not the user ever opens the Watched
    // pile specifically.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(mediaProvider.notifier).refreshWatchedShowsIfDue();
      }
    });
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
    final navState = ref.watch(navigationProvider);
    final ambiance = ref.watch(ambianceProvider);
    final isMovies = navState.activeMediaType == MediaTypeToggle.movies;
    final activeType = isMovies ? MediaType.movie : MediaType.tv;
    final colors = context.ambianceColors;
    final isLarge = MediaQuery.of(context).size.width >= 600;
    final paddingHorizontal = isLarge ? 24.0 : 18.0;

    int countFor(Map<String, dynamic> itemsMap) => itemsMap.length;
    int typeFilteredCount(Map<String, MediaItem> itemsMap) =>
        itemsMap.values.where((item) => item.type == activeType).length;

    final libraryCount = countFor(mediaState.watchlist) +
        countFor(mediaState.maybeList) +
        countFor(mediaState.watchingList) +
        countFor(mediaState.onHoldList) +
        countFor(mediaState.droppedList) +
        countFor(mediaState.watchedList);

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        paddingHorizontal,
        12.0,
        paddingHorizontal,
        100.0 + MediaQuery.of(context).padding.bottom,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context, ambiance.displayName, libraryCount),
          const SizedBox(height: 26),
          _buildGroupHeader('Piles'),
          const SizedBox(height: 10),
          _buildCardGrid([
            _LandingCardData(
              icon: PileKind.watchlist.icon,
              label: PileKind.watchlist.label,
              subtitle: _countLabel(typeFilteredCount(mediaState.watchlist)),
              accentColor: PileKind.watchlist.statusColor,
              onTap: () => _openPile(context, PileKind.watchlist),
            ),
            _LandingCardData(
              icon: PileKind.saved.icon,
              label: PileKind.saved.label,
              subtitle: _countLabel(typeFilteredCount(mediaState.maybeList)),
              accentColor: PileKind.saved.statusColor,
              onTap: () => _openPile(context, PileKind.saved),
            ),
            _LandingCardData(
              icon: PileKind.watching.icon,
              label: PileKind.watching.label,
              subtitle: _countLabel(typeFilteredCount(mediaState.watchingList)),
              accentColor: PileKind.watching.statusColor,
              onTap: () => _openPile(context, PileKind.watching),
            ),
            _LandingCardData(
              icon: PileKind.onHold.icon,
              label: PileKind.onHold.label,
              subtitle: _countLabel(typeFilteredCount(mediaState.onHoldList)),
              accentColor: PileKind.onHold.statusColor,
              onTap: () => _openPile(context, PileKind.onHold),
            ),
            _LandingCardData(
              icon: PileKind.dropped.icon,
              label: PileKind.dropped.label,
              subtitle: _countLabel(typeFilteredCount(mediaState.droppedList)),
              accentColor: PileKind.dropped.statusColor,
              onTap: () => _openPile(context, PileKind.dropped),
            ),
            _LandingCardData(
              icon: PileKind.watched.icon,
              label: PileKind.watched.label,
              subtitle: _countLabel(typeFilteredCount(mediaState.watchedList)),
              accentColor: PileKind.watched.statusColor,
              onTap: () => _openPile(context, PileKind.watched),
            ),
          ]),
          const SizedBox(height: 26),
          _buildGroupHeader('Tools'),
          const SizedBox(height: 10),
          _buildCardGrid([
            _LandingCardData(
              icon: Icons.star_rounded,
              label: 'Rate Titles',
              subtitle: 'Batch rating tool',
              accentColor: colors.acc,
              onTap: () => _push(context, const RateTitlesScreen()),
            ),
            _LandingCardData(
              icon: Icons.folder_outlined,
              label: 'Custom Folders',
              subtitle: 'Curated playlists',
              accentColor: colors.acc,
              onTap: () => _push(context, const FoldersScreen()),
            ),
            _LandingCardData(
              icon: Icons.auto_awesome_outlined,
              label: 'Cleanup Session',
              subtitle: 'Tidy up Saved',
              accentColor: colors.acc,
              onTap: () => _push(context, const CleanupSwipeScreen()),
            ),
            _LandingCardData(
              icon: Icons.replay_circle_filled_outlined,
              label: 'Rewatch Vault',
              subtitle: 'Titles you\'ve rewatched',
              accentColor: colors.acc,
              onTap: () => _push(context, const RewatchVaultScreen()),
            ),
          ]),
          const SizedBox(height: 26),
          _buildGroupHeader('Browse & Discovery'),
          const SizedBox(height: 10),
          _buildCardGrid([
            _LandingCardData(
              icon: Icons.theaters_outlined,
              label: 'Lobby',
              subtitle: 'Featured carousels',
              accentColor: colors.acc,
              onTap: () => _switchTab(context, AppTab.lobby),
            ),
            _LandingCardData(
              icon: Icons.style_outlined,
              label: 'Discover',
              subtitle: 'Swipe through picks',
              accentColor: colors.acc,
              onTap: () => _switchTab(context, AppTab.discover),
            ),
            _LandingCardData(
              icon: Icons.search,
              label: 'Search',
              subtitle: 'Find any title',
              accentColor: colors.acc,
              onTap: () => _switchTab(context, AppTab.search),
            ),
            _LandingCardData(
              icon: Icons.calendar_today_outlined,
              label: 'Calendar',
              subtitle: 'Upcoming releases',
              accentColor: colors.acc,
              onTap: () => _switchTab(context, AppTab.calendar),
            ),
          ]),
        ],
      ),
    );
  }

  String _countLabel(int count) => '$count title${count == 1 ? '' : 's'}';

  void _openPile(BuildContext context, PileKind kind) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => PileScreen(kind: kind)),
    );
  }

  void _push(BuildContext context, Widget screen) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => screen),
    );
  }

  void _switchTab(BuildContext context, AppTab tab) {
    ref.read(navigationProvider.notifier).setTab(tab);
  }

  Widget _buildHeader(BuildContext context, String ambianceName, int libraryCount) {
    final colors = context.ambianceColors;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _greeting,
                style: GoogleFonts.bodoniModa(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  fontStyle: FontStyle.italic,
                  color: colors.ink,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '$ambianceName · $libraryCount title${libraryCount == 1 ? '' : 's'} in your space',
                style: AppThemes.safeGeist(fontSize: 12.5, color: colors.sub),
              ),
            ],
          ),
        ),
        PressableScale(
          key: const ValueKey('your_space_settings_button'),
          onTap: () => _push(context, const SettingsScreen()),
          child: Icon(
            Icons.settings_outlined,
            color: colors.sub,
            size: 22,
          ),
        ),
      ],
    );
  }

  Widget _buildGroupHeader(String title) {
    final colors = context.ambianceColors;
    return Text(
      title.toUpperCase(),
      style: AppThemes.safeGeist(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: colors.sub,
        letterSpacing: 0.8,
      ),
    );
  }

  Widget _buildCardGrid(List<_LandingCardData> cards) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      // 1.9 overflowed by ~2px at narrow phone widths (412px) once icon +
      // two text lines + padding are accounted for -- 1.6 gives enough
      // vertical headroom across device sizes.
      childAspectRatio: 1.6,
      children: cards.map((c) => _LandingCard(data: c)).toList(),
    );
  }
}

class _LandingCardData {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color accentColor;
  final VoidCallback onTap;

  const _LandingCardData({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.accentColor,
    required this.onTap,
  });
}

class _LandingCard extends StatelessWidget {
  final _LandingCardData data;

  const _LandingCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final colors = context.ambianceColors;
    return PressableScale(
      onTap: data.onTap,
      child: AnimatedContainer(
        duration: AppPhysics.houseSpringDuration,
        curve: AppPhysics.houseSpringCurve,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: colors.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: data.accentColor.withValues(alpha: 0.35)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(data.icon, color: data.accentColor, size: 22),
            const SizedBox(height: 8),
            Text(
              data.label,
              style: AppThemes.safeGeist(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: colors.ink,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              data.subtitle,
              style: AppThemes.safeGeist(fontSize: 11, color: colors.sub),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
