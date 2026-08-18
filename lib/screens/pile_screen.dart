import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
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

/// PERS-SPACE-1: the six status destinations in Your Space's "Piles" group.
/// Each was previously one of four tabs inside `YourSpaceScreen` (Watching/
/// On-Hold/Dropped were combined into a single "In Progress" tab behind a
/// sub-filter); the 3-group landing redesign promotes all six to standalone
/// destinations, so the sub-filter concept is retired in favor of direct
/// navigation.
enum PileKind {
  watchlist,
  saved,
  watching,
  onHold,
  dropped,
  watched;

  String get label {
    switch (this) {
      case PileKind.watchlist:
        return 'Watchlist';
      case PileKind.saved:
        return 'Saved';
      case PileKind.watching:
        return 'Watching';
      case PileKind.onHold:
        return 'On-Hold';
      case PileKind.dropped:
        return 'Dropped';
      case PileKind.watched:
        return 'Watched';
    }
  }

  String? get subtitle {
    switch (this) {
      case PileKind.watchlist:
        return 'Committed watchlist of titles you plan to watch soon.';
      case PileKind.saved:
        return 'Soft, non-committal bookmarks for titles you might want to check out later.';
      case PileKind.watching:
        return 'Titles you\'re actively watching right now.';
      case PileKind.onHold:
        return 'Paused for now -- pick back up whenever you\'re ready.';
      case PileKind.dropped:
        return 'Titles you stopped watching.';
      case PileKind.watched:
        return null;
    }
  }

  Color get statusColor {
    switch (this) {
      case PileKind.watchlist:
        return AppStatusColors.watchlist;
      case PileKind.saved:
        return AppStatusColors.save;
      case PileKind.watching:
        return AppStatusColors.watching;
      case PileKind.onHold:
        return AppStatusColors.onHold;
      case PileKind.dropped:
        return AppStatusColors.dropped;
      case PileKind.watched:
        return AppStatusColors.watched;
    }
  }

  IconData get icon {
    switch (this) {
      case PileKind.watchlist:
        return Icons.bookmark_rounded;
      case PileKind.saved:
        return Icons.archive_rounded;
      case PileKind.watching:
        return Icons.play_circle_fill_rounded;
      case PileKind.onHold:
        return Icons.pause_circle_filled_rounded;
      case PileKind.dropped:
        return Icons.remove_circle_rounded;
      case PileKind.watched:
        return Icons.check_circle_rounded;
    }
  }

  Map<String, MediaItem> mapFrom(MediaState state) {
    switch (this) {
      case PileKind.watchlist:
        return state.watchlist;
      case PileKind.saved:
        return state.maybeList;
      case PileKind.watching:
        return state.watchingList;
      case PileKind.onHold:
        return state.onHoldList;
      case PileKind.dropped:
        return state.droppedList;
      case PileKind.watched:
        return state.watchedList;
    }
  }
}

/// PERS-SPACE-1/PERS-SORT-1: standalone screen for a single status pile,
/// extracted from `YourSpaceScreen`'s former tab-content builders so every
/// pile (not just the four that used to be tabs) gets the same sort/group
/// suite, respects the global movies/TV toggle, and is independently
/// navigable from the new landing page's Piles group.
class PileScreen extends ConsumerStatefulWidget {
  final PileKind kind;

  const PileScreen({super.key, required this.kind});

  @override
  ConsumerState<PileScreen> createState() => _PileScreenState();
}

class _PileScreenState extends ConsumerState<PileScreen> {
  static const _pileSequence = [
    PileKind.watching,
    PileKind.watchlist,
    PileKind.saved,
    PileKind.onHold,
    PileKind.dropped,
    PileKind.watched,
  ];

  late PileKind _currentKind;

  // PERS-SORT-1: sort/group selection is local to this screen instance
  // (session-only even within a session -- lost on navigating away and
  // back), matching Phase 3's "cheap, fast choice to redo" rationale for
  // not persisting it.
  PileSortOption _sort = PileSortOption.dateAdded;
  PileGroupOption _group = PileGroupOption.none;
  bool _watchedSortByRating = false;
  bool _cleanupBannerDismissed = false;

  // E7: single control to collapse/expand every collection group in the
  // Watched pile at once.
  final Map<String, ExpansibleController> _watchedTileControllers = {};
  bool _watchedAllCollapsed = false;

  @override
  void initState() {
    super.initState();
    _currentKind = widget.kind;
  }

  @override
  void didUpdateWidget(covariant PileScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.kind != widget.kind) {
      _currentKind = widget.kind;
    }
  }

  void _navigateToAdjacentPile(int delta) {
    final currentIndex = _pileSequence.indexOf(_currentKind);
    if (currentIndex == -1) return;
    final nextIndex = currentIndex + delta;
    if (nextIndex >= 0 && nextIndex < _pileSequence.length) {
      setState(() {
        _currentKind = _pileSequence[nextIndex];
      });
    }
  }

  ExpansibleController _watchedTileController(String key) {
    return _watchedTileControllers.putIfAbsent(key, () => ExpansibleController());
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.ambianceColors;
    final mediaState = ref.watch(mediaProvider);
    final navState = ref.watch(navigationProvider);
    final activeType =
        navState.activeMediaType == MediaTypeToggle.movies ? MediaType.movie : MediaType.tv;

    final items = _currentKind
        .mapFrom(mediaState)
        .values
        .where((item) => item.type == activeType)
        .toList();

    return Scaffold(
      backgroundColor: colors.base,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: colors.ink),
        title: Text(
          _currentKind.label,
          style: AppThemes.safeGeist(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: colors.ink,
          ),
        ),
      ),
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onHorizontalDragEnd: (details) {
          final velocity = details.primaryVelocity ?? 0.0;
          if (velocity < -300) {
            // Swipe left -> next pile
            _navigateToAdjacentPile(1);
          } else if (velocity > 300) {
            // Swipe right -> previous pile
            _navigateToAdjacentPile(-1);
          }
        },
        child: SafeArea(
          child: _currentKind == PileKind.watched
              ? _buildWatchedContent(context, items)
              : _buildStandardContent(context, items),
        ),
      ),
    );
  }

  Widget _buildStandardContent(BuildContext context, List<MediaItem> items) {
    final colors = context.ambianceColors;
    final isLarge = MediaQuery.of(context).size.width >= 600;
    final paddingHorizontal = isLarge ? 24.0 : 18.0;
    // Matches CleanupSwipeScreen's own now-type-scoped queue -- the banner's
    // count and threshold should describe exactly what tapping it opens.
    final banner =
        _currentKind == PileKind.saved ? _buildCleanupBanner(context, items.length) : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(paddingHorizontal, 8.0, paddingHorizontal, 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_currentKind.subtitle != null)
                Text(
                  _currentKind.subtitle!,
                  style: AppThemes.safeGeist(fontSize: 12, color: colors.sub),
                ),
              if (banner != null) ...[
                const SizedBox(height: 10),
                banner,
              ],
              if (items.isNotEmpty) ...[
                const SizedBox(height: 10),
                _buildSortGroupBar(),
              ],
            ],
          ),
        ),
        Expanded(
          child: _group == PileGroupOption.none
              ? _buildGrid(
                  context,
                  sortPile(items, _sort),
                  emptyLabel: 'Your ${_currentKind.label} is empty',
                )
              : _buildGroupedGrid(context, items),
        ),
      ],
    );
  }

  Widget _buildSortGroupBar() {
    return Row(
      children: [
        Expanded(
          child: LoungeDropdown<PileSortOption>(
            value: _sort,
            hintText: 'Sort',
            isActive: _sort != PileSortOption.dateAdded,
            items: PileSortOption.values
                .map((o) => LoungeDropdownItem(value: o, label: o.label))
                .toList(),
            onChanged: (v) {
              if (v != null) setState(() => _sort = v);
            },
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: LoungeDropdown<PileGroupOption>(
            value: _group,
            hintText: 'Group',
            isActive: _group != PileGroupOption.none,
            items: PileGroupOption.values
                .map((o) => LoungeDropdownItem(value: o, label: o.label))
                .toList(),
            onChanged: (v) {
              if (v != null) setState(() => _group = v);
            },
          ),
        ),
      ],
    );
  }

  /// PERS-SORT-1: non-intrusive banner offering the 50-item cleanup swipe
  /// tool once the (type-unfiltered) Saved pile crosses
  /// [kPileCleanupThreshold]. Returns null below the threshold or once
  /// dismissed for the session -- never forced, user can keep hoarding.
  Widget? _buildCleanupBanner(BuildContext context, int savedCount) {
    if (savedCount <= kPileCleanupThreshold || _cleanupBannerDismissed) return null;

    final colors = context.ambianceColors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: colors.acc.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.acc.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Icon(Icons.auto_awesome_outlined, size: 18, color: colors.acc),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Your Saved list has grown to $savedCount titles -- want to clean it up?',
              style: AppThemes.safeGeist(fontSize: 12, color: colors.ink),
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
                  color: colors.acc,
                ),
              ),
            ),
          ),
          const SizedBox(width: 6),
          PressableScale(
            key: const ValueKey('cleanup_banner_dismiss'),
            onTap: () => setState(() => _cleanupBannerDismissed = true),
            child: Icon(Icons.close_rounded, size: 16, color: colors.sub),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupedGrid(BuildContext context, List<MediaItem> items) {
    final Map<String, List<MediaItem>> grouped;
    switch (_group) {
      case PileGroupOption.genre:
        grouped = groupByGenre(items);
        break;
      case PileGroupOption.language:
        grouped = groupByLanguage(items);
        break;
      case PileGroupOption.ratingBand:
      case PileGroupOption.none:
        grouped = groupByRatingBand(items);
        break;
    }
    final entries = grouped.entries.toList()
      ..sort((a, b) {
        if (_group == PileGroupOption.ratingBand) {
          if (a.key == 'Unrated') return 1;
          if (b.key == 'Unrated') return -1;
          return b.key.compareTo(a.key); // highest band first
        }
        if (_group == PileGroupOption.language) {
          if (a.key == 'Unknown') return 1;
          if (b.key == 'Unknown') return -1;
          return a.key.compareTo(b.key); // language alphabetical
        }
        return a.key.compareTo(b.key); // genre alphabetical
      });

    final colors = context.ambianceColors;
    final isLarge = MediaQuery.of(context).size.width >= 600;
    final paddingHorizontal = isLarge ? 24.0 : 18.0;
    final keyPrefix = _currentKind.name;

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
          final groupItems = sortPile(entry.value, _sort);
          return Container(
            key: ValueKey('${keyPrefix}_group_${entry.key}'),
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: colors.card,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: colors.lineRgba),
            ),
            child: Theme(
              data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                initiallyExpanded: true,
                tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                title: Row(
                  children: [
                    Text(
                      entry.key,
                      style: AppThemes.safeGeist(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: colors.ink,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: colors.ph,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${groupItems.length}',
                        style: AppThemes.safeGeist(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: colors.sub,
                        ),
                      ),
                    ),
                  ],
                ),
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                    child: GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: 110,
                        childAspectRatio: 2 / 3,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                      ),
                      itemCount: groupItems.length,
                      itemBuilder: (context, index) {
                        final item = groupItems[index];
                        return MediaCard(
                          key: ValueKey(item.prefixedId),
                          item: item,
                          isDark: colors.isDark,
                          borderRadius: 10,
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildGrid(BuildContext context, List<MediaItem> items, {required String emptyLabel}) {
    final isDark = context.ambianceColors.isDark;
    if (items.isEmpty) {
      final allPileItems = _currentKind.mapFrom(ref.watch(mediaProvider)).values.toList();
      final otherTypeCount = allPileItems.length;
      final activeType = ref.watch(navigationProvider).activeMediaType == MediaTypeToggle.movies
          ? MediaType.movie
          : MediaType.tv;

      if (otherTypeCount > 0) {
        final otherTypeName = activeType == MediaType.movie ? 'TV Shows' : 'Movies';
        return AtmosphericEmptyState(
          icon: Icons.swap_horiz_rounded,
          title: 'No ${activeType == MediaType.movie ? 'movies' : 'TV shows'} in ${_currentKind.label}',
          message: 'You have $otherTypeCount title${otherTypeCount == 1 ? '' : 's'} under $otherTypeName in this pile.',
          ctaLabel: 'Switch to $otherTypeName',
          onCta: () => ref.read(navigationProvider.notifier).toggleMediaType(),
        );
      }

      return AtmosphericEmptyState(
        icon: Icons.movie_creation_outlined,
        title: emptyLabel,
        message: 'Titles you save here will show up in this list.',
        ctaLabel: 'Discover Titles',
        onCta: () {
          Navigator.of(context).popUntil((route) => route.isFirst);
          ref.read(navigationProvider.notifier).setTab(AppTab.discover);
        },
      );
    }

    final isLarge = MediaQuery.of(context).size.width >= 600;

    return GridView.builder(
      padding: EdgeInsets.fromLTRB(
          isLarge ? 24.0 : 18.0, isLarge ? 12.0 : 8.0, isLarge ? 24.0 : 18.0, 18.0 + MediaQuery.of(context).padding.bottom),
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

  Widget _buildWatchedContent(BuildContext context, List<MediaItem> items) {
    final colors = context.ambianceColors;

    if (items.isEmpty) {
      final allPileItems = _currentKind.mapFrom(ref.watch(mediaProvider)).values.toList();
      final otherTypeCount = allPileItems.length;
      final activeType = ref.watch(navigationProvider).activeMediaType == MediaTypeToggle.movies
          ? MediaType.movie
          : MediaType.tv;

      if (otherTypeCount > 0) {
        final otherTypeName = activeType == MediaType.movie ? 'TV Shows' : 'Movies';
        return AtmosphericEmptyState(
          icon: Icons.swap_horiz_rounded,
          title: 'No watched ${activeType == MediaType.movie ? 'movies' : 'TV shows'}',
          message: 'You have $otherTypeCount watched title${otherTypeCount == 1 ? '' : 's'} under $otherTypeName.',
          ctaLabel: 'Switch to $otherTypeName',
          onCta: () => ref.read(navigationProvider.notifier).toggleMediaType(),
        );
      }

      return AtmosphericEmptyState(
        icon: Icons.check_circle_outline_rounded,
        title: 'Nothing watched yet',
        message: 'Titles you mark as watched will show up here.',
        ctaLabel: 'Discover Titles',
        onCta: () {
          Navigator.of(context).popUntil((route) => route.isFirst);
          ref.read(navigationProvider.notifier).setTab(AppTab.discover);
        },
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

    final watchedGroupKeys = [
      for (final colName in groupedByCollection.keys) 'watched_col_$colName',
      if (standaloneItems.isNotEmpty) 'watched_standalone',
    ];

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        paddingHorizontal,
        8.0,
        paddingHorizontal,
        24.0 + MediaQuery.of(context).padding.bottom,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (watchedGroupKeys.length > 1)
            Align(
              alignment: Alignment.centerRight,
              child: PressableScale(
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
                    color: colors.pill,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: colors.lineRgba),
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
                          _watchedAllCollapsed ? Icons.unfold_more : Icons.unfold_less,
                          key: ValueKey(_watchedAllCollapsed),
                          size: 15,
                          color: colors.acc,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        _watchedAllCollapsed ? 'Expand All' : 'Collapse All',
                        style: AppThemes.safeGeist(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: colors.acc,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
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
                color: _watchedSortByRating ? colors.acc.withValues(alpha: 0.14) : colors.pill,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _watchedSortByRating ? colors.acc : colors.lineRgba,
                  width: _watchedSortByRating ? 1.5 : 1.0,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.star_rounded, size: 14, color: _watchedSortByRating ? colors.acc : colors.sub),
                  const SizedBox(width: 5),
                  Text(
                    'Sort by My Rating',
                    style: AppThemes.safeGeist(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _watchedSortByRating ? colors.acc : colors.sub,
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
                border: Border.all(color: colors.lineRgba, width: 1.0),
              ),
              child: Material(
                color: colors.card,
                borderRadius: BorderRadius.circular(14),
                clipBehavior: Clip.antiAlias,
                child: Theme(
                  data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                  child: ExpansionTile(
                    key: PageStorageKey<String>('watched_col_$colName'),
                    controller: _watchedTileController('watched_col_$colName'),
                    initiallyExpanded: true,
                    iconColor: colors.acc,
                    collapsedIconColor: colors.sub,
                    title: Row(
                      children: [
                        Icon(Icons.collections_bookmark_outlined, size: 18, color: colors.acc),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            colName,
                            style: AppThemes.safeGeist(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: colors.ink,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: colors.acc.withAlpha(30),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${colItems.length}',
                            style: AppThemes.safeGeist(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: colors.acc,
                            ),
                          ),
                        ),
                      ],
                    ),
                    childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    children: [
                      _buildSubGrid(context, colItems, colName),
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
                border: Border.all(color: colors.lineRgba, width: 1.0),
              ),
              child: Material(
                color: colors.card,
                borderRadius: BorderRadius.circular(14),
                clipBehavior: Clip.antiAlias,
                child: Theme(
                  data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                  child: ExpansionTile(
                    key: const PageStorageKey<String>('watched_standalone'),
                    controller: _watchedTileController('watched_standalone'),
                    initiallyExpanded: true,
                    iconColor: colors.acc,
                    collapsedIconColor: colors.sub,
                    title: Row(
                      children: [
                        Icon(Icons.movie_outlined, size: 18, color: colors.acc),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Standalone Titles',
                            style: AppThemes.safeGeist(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: colors.ink,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: colors.acc.withAlpha(30),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${standaloneItems.length}',
                            style: AppThemes.safeGeist(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: colors.acc,
                            ),
                          ),
                        ),
                      ],
                    ),
                    childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    children: [
                      _buildSubGrid(context, standaloneItems, 'standalone'),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSubGrid(BuildContext context, List<MediaItem> items, String keySuffix) {
    final isDark = context.ambianceColors.isDark;
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
