import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/media_provider.dart';
import '../providers/navigation_provider.dart';
import '../models/media_item.dart';
import '../constants.dart';
import '../utils/pile_sort_group.dart';
import '../widgets/atmospheric_empty_state.dart';
import '../widgets/lounge_dropdown.dart';
import '../widgets/media_card.dart';
import '../widgets/pressable_scale.dart';
import 'cleanup_swipe_screen.dart';
import 'settings_screen.dart';

enum InProgressSubFilter { watching, onHold, dropped }

class YourSpaceScreen extends ConsumerStatefulWidget {
  const YourSpaceScreen({super.key});

  @override
  ConsumerState<YourSpaceScreen> createState() => _YourSpaceScreenState();
}

class _YourSpaceScreenState extends ConsumerState<YourSpaceScreen> {
  InProgressSubFilter _inProgressFilter = InProgressSubFilter.watching;

  // PERS-SORT-1: Watchlist vs Saved each get their own independent
  // sort/group selection (session-only, not persisted -- the locked spec
  // doesn't call for persistence, and it's a fast, cheap-to-redo choice).
  PileSortOption _watchlistSort = PileSortOption.dateAdded;
  PileGroupOption _watchlistGroup = PileGroupOption.none;
  PileSortOption _savedSort = PileSortOption.dateAdded;
  PileGroupOption _savedGroup = PileGroupOption.none;

  // PERS-SORT-1: Personal Rating Sort is offered on the Watched pile only
  // (a TMDB weighted-rating sort wouldn't be meaningful there the way it is
  // for Watchlist/Saved -- everything's already watched).
  bool _watchedSortByRating = false;

  // PERS-SORT-1: the 50-item cleanup banner is dismissible for the session
  // (not persisted -- "never forced," and a cheap choice to re-show next
  // launch if the pile is still over threshold rather than silencing it
  // permanently after one dismissal).
  bool _cleanupBannerDismissed = false;

  // E7: single control to collapse/expand every collection group in the
  // Watched tab at once. Controllers are created lazily per group key and
  // persist across rebuilds (state, not local to _buildWatchedTabContent)
  // so they stay attached to the same ExpansionTile.
  final Map<String, ExpansibleController> _watchedTileControllers = {};
  bool _watchedAllCollapsed = false;

  ExpansibleController _watchedTileController(String key) {
    return _watchedTileControllers.putIfAbsent(key, () => ExpansibleController());
  }

  @override
  void initState() {
    super.initState();
    // B2/E5: monthly new-season/new-episode refresh for Watched shows.
    // No-ops internally unless 30+ days have passed since the last run.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(mediaProvider.notifier).refreshWatchedShowsIfDue();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final mediaState = ref.watch(mediaProvider);
    final navState = ref.watch(navigationProvider);
    final isMovies = navState.activeMediaType == MediaTypeToggle.movies;
    final activeType = isMovies ? MediaType.movie : MediaType.tv;

    final isDark = context.ambianceColors.isDark;

    final inkColor = context.ambianceColors.ink;
    final subColor = context.ambianceColors.sub;
    final accColor = context.ambianceColors.acc;
    final isLarge = MediaQuery.of(context).size.width >= 600;
    final paddingHorizontal = isLarge ? 24.0 : 18.0;

    List<MediaItem> filterList(Map<String, MediaItem> itemsMap) {
      return itemsMap.values
          .where((item) => item.type == activeType)
          .toList();
    }

    List<MediaItem> getInProgressItems() {
      switch (_inProgressFilter) {
        case InProgressSubFilter.watching:
          return filterList(mediaState.watchingList);
        case InProgressSubFilter.onHold:
          return filterList(mediaState.onHoldList);
        case InProgressSubFilter.dropped:
          return filterList(mediaState.droppedList);
      }
    }

    return DefaultTabController(
      length: 4,
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(paddingHorizontal, 12.0, paddingHorizontal, 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Flexible(
                  child: Text(
                    'Your Space',
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.bodoniModa(
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      fontStyle: FontStyle.italic,
                      color: inkColor,
                    ),
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // IA-1: a direct, always-available Settings entry point
                    // in Your Space -- the movie/TV toggle now lives solely
                    // in the FloatingNavigationCapsule (NAV-3).
                    PressableScale(
                      key: const ValueKey('your_space_settings_button'),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (context) => const SettingsScreen()),
                      ),
                      child: Icon(
                        Icons.settings_outlined,
                        color: context.ambianceColors.sub,
                        size: 22,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          TabBar(
            labelColor: accColor,
            unselectedLabelColor: subColor,
            indicatorColor: accColor,
            labelStyle: AppThemes.safeGeist(fontSize: 13, fontWeight: FontWeight.w600),
            unselectedLabelStyle: AppThemes.safeGeist(fontSize: 13, fontWeight: FontWeight.w500),
            tabs: const [
              Tab(text: 'Watchlist'),
              Tab(text: 'Saved'),
              Tab(text: 'In Progress'),
              Tab(text: 'Watched'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                _buildTabContent(
                  context: context,
                  title: 'Watchlist',
                  subtitle: 'Committed watchlist of titles you plan to watch soon.',
                  items: filterList(mediaState.watchlist),
                  isDark: isDark,
                  subColor: subColor,
                  inkColor: inkColor,
                  sort: _watchlistSort,
                  group: _watchlistGroup,
                  onSortChanged: (v) => setState(() => _watchlistSort = v),
                  onGroupChanged: (v) => setState(() => _watchlistGroup = v),
                ),
                _buildTabContent(
                  context: context,
                  title: 'Saved',
                  subtitle: 'Soft, non-committal bookmarks for titles you might want to check out later.',
                  items: filterList(mediaState.maybeList),
                  isDark: isDark,
                  subColor: subColor,
                  inkColor: inkColor,
                  sort: _savedSort,
                  group: _savedGroup,
                  onSortChanged: (v) => setState(() => _savedSort = v),
                  onGroupChanged: (v) => setState(() => _savedGroup = v),
                  banner: _buildCleanupBanner(mediaState.maybeList.length, subColor, inkColor),
                ),
                _buildInProgressTabContent(
                  context: context,
                  title: 'In Progress',
                  subtitle: 'Track active, paused, or stopped viewing progress.',
                  items: getInProgressItems(),
                  isDark: isDark,
                  subColor: subColor,
                  inkColor: inkColor,
                  accColor: accColor,
                ),
                _buildWatchedTabContent(
                  context: context,
                  title: 'Watched',
                  items: filterList(mediaState.watchedList),
                  isDark: isDark,
                  subColor: subColor,
                  inkColor: inkColor,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }



  Widget _buildTabContent({
    required BuildContext context,
    required String title,
    required String? subtitle,
    required List<MediaItem> items,
    required bool isDark,
    required Color subColor,
    required Color inkColor,
    required PileSortOption sort,
    required PileGroupOption group,
    required ValueChanged<PileSortOption> onSortChanged,
    required ValueChanged<PileGroupOption> onGroupChanged,
    Widget? banner,
  }) {
    final isLarge = MediaQuery.of(context).size.width >= 600;
    final paddingHorizontal = isLarge ? 24.0 : 18.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(paddingHorizontal, 16.0, paddingHorizontal, 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppThemes.safeGeist(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: inkColor,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: AppThemes.safeGeist(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: subColor,
                  ),
                ),
              ],
              if (banner != null) ...[
                const SizedBox(height: 10),
                banner,
              ],
              if (items.isNotEmpty) ...[
                const SizedBox(height: 10),
                _buildPileSortGroupBar(
                  sort: sort,
                  group: group,
                  onSortChanged: onSortChanged,
                  onGroupChanged: onGroupChanged,
                ),
              ],
            ],
          ),
        ),
        Expanded(
          child: group == PileGroupOption.none
              ? _buildGrid(
                  context,
                  sortPile(items, sort),
                  isDark,
                  subColor,
                  emptyLabel: 'Your $title is empty',
                )
              : _buildGroupedGrid(
                  context,
                  items,
                  group,
                  sort,
                  isDark,
                  subColor,
                  inkColor,
                  keyPrefix: title.toLowerCase(),
                ),
        ),
      ],
    );
  }

  /// PERS-SORT-1: sort/group selector pills, reusing the bespoke
  /// [LoungeDropdown] (the app's canonical stock-DropdownButton
  /// replacement) rather than introducing a new selector pattern.
  Widget _buildPileSortGroupBar({
    required PileSortOption sort,
    required PileGroupOption group,
    required ValueChanged<PileSortOption> onSortChanged,
    required ValueChanged<PileGroupOption> onGroupChanged,
  }) {
    return Row(
      children: [
        Expanded(
          child: LoungeDropdown<PileSortOption>(
            value: sort,
            hintText: 'Sort',
            isActive: sort != PileSortOption.dateAdded,
            items: PileSortOption.values
                .map((o) => LoungeDropdownItem(value: o, label: o.label))
                .toList(),
            onChanged: (v) {
              if (v != null) onSortChanged(v);
            },
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: LoungeDropdown<PileGroupOption>(
            value: group,
            hintText: 'Group',
            isActive: group != PileGroupOption.none,
            items: PileGroupOption.values
                .map((o) => LoungeDropdownItem(value: o, label: o.label))
                .toList(),
            onChanged: (v) {
              if (v != null) onGroupChanged(v);
            },
          ),
        ),
      ],
    );
  }

  /// PERS-SORT-1: non-intrusive banner offering the 50-item cleanup swipe
  /// tool once the (type-unfiltered) Saved pile crosses
  /// [kPileCleanupThreshold]. Returns null (renders nothing) below the
  /// threshold or once dismissed for the session -- never forced, and the
  /// user can keep hoarding freely.
  Widget? _buildCleanupBanner(int savedCount, Color subColor, Color inkColor) {
    if (savedCount <= kPileCleanupThreshold || _cleanupBannerDismissed) return null;

    final accColor = context.ambianceColors.acc;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: accColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accColor.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Icon(Icons.auto_awesome_outlined, size: 18, color: accColor),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Your Saved list has grown to $savedCount titles -- want to clean it up?',
              style: AppThemes.safeGeist(fontSize: 12, color: inkColor),
            ),
          ),
          PressableScale(
            key: const ValueKey('cleanup_banner_cta'),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => const CleanupSwipeScreen()),
            ),
            child: Padding(
              padding: const EdgeInsets.only(left: 8),
              child: Text(
                'Clean up',
                style: AppThemes.safeGeist(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: accColor,
                ),
              ),
            ),
          ),
          const SizedBox(width: 6),
          PressableScale(
            key: const ValueKey('cleanup_banner_dismiss'),
            onTap: () => setState(() => _cleanupBannerDismissed = true),
            child: Icon(Icons.close_rounded, size: 16, color: subColor),
          ),
        ],
      ),
    );
  }

  /// PERS-SORT-1: grouped rendering (By Genre / By Rating Band), each group
  /// as its own collapsible section -- mirrors the Watched tab's existing
  /// per-collection ExpansionTile pattern for visual consistency.
  Widget _buildGroupedGrid(
    BuildContext context,
    List<MediaItem> items,
    PileGroupOption group,
    PileSortOption sort,
    bool isDark,
    Color subColor,
    Color inkColor, {
    required String keyPrefix,
  }) {
    final grouped =
        group == PileGroupOption.genre ? groupByGenre(items) : groupByRatingBand(items);
    final entries = grouped.entries.toList()
      ..sort((a, b) {
        if (group == PileGroupOption.ratingBand) {
          if (a.key == 'Unrated') return 1;
          if (b.key == 'Unrated') return -1;
          return b.key.compareTo(a.key); // highest band first
        }
        return a.key.compareTo(b.key); // genre alphabetical
      });

    final isLarge = MediaQuery.of(context).size.width >= 600;
    final paddingHorizontal = isLarge ? 24.0 : 18.0;
    final accColor = context.ambianceColors.acc;
    final lineRgba = context.ambianceColors.lineRgba;
    final cardBg = context.ambianceColors.card;

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        paddingHorizontal,
        4.0,
        paddingHorizontal,
        18.0 + MediaQuery.of(context).padding.bottom,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: entries.map((entry) {
          final groupItems = sortPile(entry.value, sort);
          return Container(
            key: ValueKey('${keyPrefix}_group_${entry.key}'),
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: lineRgba, width: 1.0),
            ),
            child: Material(
              color: cardBg,
              borderRadius: BorderRadius.circular(14),
              clipBehavior: Clip.antiAlias,
              child: Theme(
                data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                child: ExpansionTile(
                  initiallyExpanded: true,
                  iconColor: accColor,
                  collapsedIconColor: subColor,
                  title: Row(
                    children: [
                      Expanded(
                        child: Text(
                          entry.key,
                          style: AppThemes.safeGeist(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: inkColor,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: accColor.withAlpha(30),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${groupItems.length}',
                          style: AppThemes.safeGeist(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: accColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  children: [
                    _buildSubGrid(context, groupItems, isDark, '${keyPrefix}_${entry.key}'),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildInProgressTabContent({
    required BuildContext context,
    required String title,
    required String? subtitle,
    required List<MediaItem> items,
    required bool isDark,
    required Color subColor,
    required Color inkColor,
    required Color accColor,
  }) {
    final isLarge = MediaQuery.of(context).size.width >= 600;
    final paddingHorizontal = isLarge ? 24.0 : 18.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(paddingHorizontal, 16.0, paddingHorizontal, 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppThemes.safeGeist(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: inkColor,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: AppThemes.safeGeist(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: subColor,
                  ),
                ),
              ],
              const SizedBox(height: 10),
              _buildSubSegmentedPills(isDark: isDark, accColor: accColor, subColor: subColor),
            ],
          ),
        ),
        Expanded(
          child: _buildGrid(context, items, isDark, subColor, emptyLabel: 'Nothing in progress'),
        ),
      ],
    );
  }

  Widget _buildSubSegmentedPills({
    required bool isDark,
    required Color accColor,
    required Color subColor,
  }) {
    final pillBg = context.ambianceColors.pill;
    final activeTextColor = Theme.of(context).colorScheme.onPrimary;

    Widget buildPill(String label, InProgressSubFilter filter) {
      final isSelected = _inProgressFilter == filter;
      return PressableScale(
        onTap: () {
          setState(() {
            _inProgressFilter = filter;
          });
        },
        child: AnimatedContainer(
          duration: AppPhysics.houseSpringDuration,
          curve: AppPhysics.houseSpringCurve,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: isSelected ? accColor : pillBg,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            label,
            style: AppThemes.safeGeist(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              color: isSelected ? activeTextColor : subColor,
            ),
          ),
        ),
      );
    }

    return Row(
      children: [
        buildPill('Watching', InProgressSubFilter.watching),
        const SizedBox(width: 8),
        buildPill('On-Hold', InProgressSubFilter.onHold),
        const SizedBox(width: 8),
        buildPill('Dropped', InProgressSubFilter.dropped),
      ],
    );
  }

  Widget _buildGrid(BuildContext context, List<MediaItem> items, bool isDark, Color subColor, {String emptyLabel = 'Nothing here yet'}) {
    if (items.isEmpty) {
      return AtmosphericEmptyState(
        icon: Icons.movie_creation_outlined,
        title: emptyLabel,
        message: 'Titles you save here will show up in this list.',
        ctaLabel: 'Discover Titles',
        onCta: () => ref.read(navigationProvider.notifier).setTab(AppTab.discover),
      );
    }

    final isLarge = MediaQuery.of(context).size.width >= 600;

    return GridView.builder(
      padding: EdgeInsets.fromLTRB(
          isLarge ? 24.0 : 18.0, isLarge ? 12.0 : 18.0, isLarge ? 24.0 : 18.0, 18.0 + MediaQuery.of(context).padding.bottom),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 120,
        childAspectRatio: 2 / 3,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return MediaCard(
          key: ValueKey(item.prefixedId),
          item: item,
          isDark: isDark,
          borderRadius: 11,
        ).animate().fade(duration: 250.ms).slideY(
            begin: 0.1,
            end: 0,
            delay: (index.clamp(0, 5) * 40).ms);
      },
    );
  }

  Widget _buildWatchedTabContent({
    required BuildContext context,
    required String title,
    required List<MediaItem> items,
    required bool isDark,
    required Color subColor,
    required Color inkColor,
  }) {
    if (items.isEmpty) {
      return AtmosphericEmptyState(
        icon: Icons.check_circle_outline_rounded,
        title: 'Nothing watched yet',
        message: 'Titles you mark as watched will show up here.',
        ctaLabel: 'Discover Titles',
        onCta: () => ref.read(navigationProvider.notifier).setTab(AppTab.discover),
      );
    }

    final Map<String, List<MediaItem>> groupedByCollection = {};
    final List<MediaItem> standaloneItems = [];

    for (final item in items) {
      final colName = item.collectionName;
      if (colName != null && colName.isNotEmpty) {
        groupedByCollection.putIfAbsent(colName, () => []).add(item);
      } else {
        standaloneItems.add(item);
      }
    }

    if (_watchedSortByRating) {
      final watchHistory = ref.read(mediaProvider).watchHistory;
      for (final key in groupedByCollection.keys.toList()) {
        groupedByCollection[key] = personalRatingSort(groupedByCollection[key]!, watchHistory);
      }
      final sortedStandalone = personalRatingSort(standaloneItems, watchHistory);
      standaloneItems
        ..clear()
        ..addAll(sortedStandalone);
    }

    final isLarge = MediaQuery.of(context).size.width >= 600;
    final paddingHorizontal = isLarge ? 24.0 : 18.0;
    final accColor = context.ambianceColors.acc;
    final lineRgba = context.ambianceColors.lineRgba;
    final cardBg = context.ambianceColors.card;
    final pillColor = context.ambianceColors.pill;

    // E7: keys for whatever groups are actually rendered THIS build -- the
    // collapse-all button closes over this list, so it only ever acts on
    // controllers for groups that genuinely exist right now, never a stale
    // controller left over from a group that's since disappeared (e.g. the
    // last item in a collection got un-watched).
    final watchedGroupKeys = [
      for (final colName in groupedByCollection.keys) 'watched_col_$colName',
      if (standaloneItems.isNotEmpty) 'watched_standalone',
    ];

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        paddingHorizontal,
        16.0,
        paddingHorizontal,
        90.0 + MediaQuery.of(context).padding.bottom,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: AppThemes.safeGeist(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: inkColor,
                ),
              ),
              if (watchedGroupKeys.length > 1)
                PressableScale(
                  onTap: () {
                    final collapseAll = !_watchedAllCollapsed;
                    for (final key in watchedGroupKeys) {
                      final controller = _watchedTileController(key);
                      if (collapseAll) {
                        controller.collapse();
                      } else {
                        controller.expand();
                      }
                    }
                    setState(() => _watchedAllCollapsed = collapseAll);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: pillColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: lineRgba),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AnimatedSwitcher(
                          duration: AppPhysics.houseSpringDuration,
                          switchInCurve: AppPhysics.houseSpringCurve,
                          switchOutCurve: Curves.easeOut,
                          transitionBuilder: (child, animation) =>
                              ScaleTransition(scale: animation, child: child),
                          child: Icon(
                            _watchedAllCollapsed
                                ? Icons.unfold_more
                                : Icons.unfold_less,
                            key: ValueKey(_watchedAllCollapsed),
                            size: 15,
                            color: accColor,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          _watchedAllCollapsed ? 'Expand All' : 'Collapse All',
                          style: AppThemes.safeGeist(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: accColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          // PERS-SORT-1: Personal Rating Sort, offered only here (Watched
          // pile) -- a TMDB weighted-rating sort wouldn't add anything once
          // everything's already watched, but "what did I love?" does.
          PressableScale(
            onTap: () => setState(() => _watchedSortByRating = !_watchedSortByRating),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: _watchedSortByRating ? accColor.withValues(alpha: 0.14) : pillColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _watchedSortByRating ? accColor : lineRgba,
                  width: _watchedSortByRating ? 1.5 : 1.0,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.star_rounded, size: 14, color: _watchedSortByRating ? accColor : subColor),
                  const SizedBox(width: 5),
                  Text(
                    'Sort by My Rating',
                    style: AppThemes.safeGeist(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _watchedSortByRating ? accColor : subColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          ...groupedByCollection.entries.map((entry) {
            final colName = entry.key;
            final colItems = entry.value;
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: lineRgba, width: 1.0),
              ),
              child: Material(
                color: cardBg,
                borderRadius: BorderRadius.circular(14),
                clipBehavior: Clip.antiAlias,
                child: Theme(
                  data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                  child: ExpansionTile(
                    key: PageStorageKey<String>('watched_col_$colName'),
                    controller: _watchedTileController('watched_col_$colName'),
                    initiallyExpanded: true,
                    iconColor: accColor,
                    collapsedIconColor: subColor,
                    title: Row(
                      children: [
                        Icon(Icons.collections_bookmark_outlined, size: 18, color: accColor),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            colName,
                            style: AppThemes.safeGeist(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: inkColor,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: accColor.withAlpha(30),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${colItems.length}',
                            style: AppThemes.safeGeist(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: accColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    children: [
                      _buildSubGrid(context, colItems, isDark, colName),
                    ],
                  ),
                ),
              ),
            );
          }),
          if (standaloneItems.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: lineRgba, width: 1.0),
              ),
              child: Material(
                color: cardBg,
                borderRadius: BorderRadius.circular(14),
                clipBehavior: Clip.antiAlias,
                child: Theme(
                  data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                  child: ExpansionTile(
                    key: const PageStorageKey<String>('watched_standalone'),
                    controller: _watchedTileController('watched_standalone'),
                    initiallyExpanded: true,
                    iconColor: accColor,
                    collapsedIconColor: subColor,
                    title: Row(
                      children: [
                        Icon(Icons.movie_outlined, size: 18, color: accColor),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Standalone Titles',
                            style: AppThemes.safeGeist(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: inkColor,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: accColor.withAlpha(30),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${standaloneItems.length}',
                            style: AppThemes.safeGeist(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: accColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    children: [
                      _buildSubGrid(context, standaloneItems, isDark, 'standalone'),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSubGrid(BuildContext context, List<MediaItem> items, bool isDark, String keySuffix) {
    return GridView.builder(
      key: PageStorageKey<String>('watched_grid_$keySuffix'),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 120,
        childAspectRatio: 2 / 3,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return MediaCard(
          key: ValueKey(item.prefixedId),
          item: item,
          isDark: isDark,
          borderRadius: 11,
        ).animate().fade(duration: 250.ms).slideY(
              begin: 0.1,
              end: 0,
              delay: (index.clamp(0, 5) * 40).ms,
            );
      },
    );
  }
}
