import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/archive_view_state_provider.dart';
import '../providers/media_provider.dart';
import '../providers/navigation_provider.dart';
import '../models/media_item.dart';
import '../models/hall_space.dart';
import '../constants.dart';
import '../utils/archive_sort_group.dart';
import '../widgets/atmospheric_empty_state.dart';
import '../widgets/lounge_dropdown.dart';
import '../widgets/media_card.dart';
import '../widgets/pressable_scale.dart';
import 'cleanup_swipe_screen.dart';

export '../models/hall_space.dart' show ArchiveShelfKind;

/// PERS-SPACE-1/PERS-SORT-1 / NAME-1: standalone screen for a single status archive shelf,
/// every shelf gets the same sort/group suite, respects the global movies/TV toggle,
/// and is independently navigable from the Archive hub.
class ArchiveShelfScreen extends ConsumerStatefulWidget {
  final ArchiveShelfKind kind;

  const ArchiveShelfScreen({super.key, required this.kind});

  @override
  ConsumerState<ArchiveShelfScreen> createState() => _ArchiveShelfScreenState();
}

class _ArchiveShelfScreenState extends ConsumerState<ArchiveShelfScreen>
    with SingleTickerProviderStateMixin {
  // ITEM-2 (dev feedback, 2026-08-27): reordered to the dev's specified
  // chain (Watching <-> Watched <-> Watchlist <-> Saved <-> Lobby <-> Search
  // <-> Calendar) -- On-Hold and Dropped are no longer part of the swipe
  // sequence (not mentioned in the requested chain); both shelves are still
  // reachable normally from the Archive hub, they just aren't swipe-linked
  // to their neighbors anymore. Saved is now the sequence's outer boundary
  // -- swiping past it exits to the Lobby tab (see _navigateToAdjacentShelf).
  static const _shelfSequence = [
    ArchiveShelfKind.watching,
    ArchiveShelfKind.watched,
    ArchiveShelfKind.watchlist,
    ArchiveShelfKind.saved,
  ];

  static const Duration _duration = Duration(milliseconds: 360);

  late ArchiveShelfKind _currentKind;
  late final AnimationController _transitionController;
  late Animation<double> _fade;
  late Animation<Offset> _slide;
  late Animation<double> _scale;

  // PERS-SORT-2: sort/group selection now lives in archiveViewStateProvider
  // so it survives navigating away from and back to Archive -- these fields
  // are re-synced from that provider at the top of every build() and are
  // otherwise read exactly as before throughout this class. Not
  // final/getters specifically so the rest of this file (30+ read sites)
  // needed zero changes beyond the sync itself.
  ArchiveSortOption _sort = ArchiveSortOption.lastAdded;
  ArchiveGroupOption _group = ArchiveGroupOption.none;
  bool _watchedSortByRating = false;
  bool _cleanupBannerDismissed = false;

  // ARCHIVE-SORT-1: applies to every sort option above, on every shelf.
  bool _sortAscending = false;

  // WATCHED-VIEW-1: Watched now defaults to the same flat, lazily-built grid
  // every other shelf uses -- Collection grouping is an opt-in view, not
  // the default, toggled via this flag rather than always-on.
  bool _watchedGroupByCollection = false;

  // E7: single control to collapse/expand every collection group in the Watched archive at once.
  final Map<String, ExpansibleController> _watchedTileControllers = {};
  bool _watchedAllCollapsed = false;

  @override
  void initState() {
    super.initState();
    _currentKind = widget.kind;
    _transitionController = AnimationController(
      vsync: this,
      duration: _duration,
      value: 1.0,
    );
    _buildAnimations(reverseDirection: false);
  }

  void _buildAnimations({required bool reverseDirection}) {
    _fade = CurvedAnimation(
        parent: _transitionController, curve: Curves.easeOutCubic);
    _scale = Tween<double>(begin: 0.985, end: 1.0).animate(
      CurvedAnimation(
          parent: _transitionController, curve: AppPhysics.houseSpringCurve),
    );
    _slide = Tween<Offset>(
      begin: Offset(reverseDirection ? -0.05 : 0.05, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
        parent: _transitionController, curve: AppPhysics.houseSpringCurve));
  }

  @override
  void didUpdateWidget(covariant ArchiveShelfScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.kind != widget.kind) {
      final oldIndex = _shelfSequence.indexOf(oldWidget.kind);
      final newIndex = _shelfSequence.indexOf(widget.kind);
      _currentKind = widget.kind;
      _buildAnimations(reverseDirection: newIndex < oldIndex);
      _transitionController
        ..value = 0.0
        ..forward();
    }
  }

  @override
  void dispose() {
    _transitionController.dispose();
    super.dispose();
  }

  void _navigateToAdjacentShelf(int delta) {
    final currentIndex = _shelfSequence.indexOf(_currentKind);
    if (currentIndex == -1) return;
    final nextIndex = currentIndex + delta;
    if (nextIndex >= 0 && nextIndex < _shelfSequence.length) {
      setState(() {
        _currentKind = _shelfSequence[nextIndex];
      });
      _buildAnimations(reverseDirection: delta < 0);
      _transitionController
        ..value = 0.0
        ..forward();
      return;
    }
    // ITEM-2: swiping forward past the last shelf in the sequence (Saved)
    // exits the shelf cluster entirely and lands on the Lobby tab -- the
    // chain's outer boundary on this side. Swiping backward past the first
    // shelf (Watching) is a no-op; Watching is the true start of the whole
    // 7-screen chain, nothing precedes it.
    if (nextIndex >= _shelfSequence.length &&
        _currentKind == ArchiveShelfKind.saved) {
      Navigator.of(context).popUntil((route) => route.isFirst);
      ref.read(navigationProvider.notifier).setTab(AppTab.lobby);
    }
  }

  ExpansibleController _watchedTileController(String key) {
    return _watchedTileControllers.putIfAbsent(
        key, () => ExpansibleController());
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.ambianceColors;
    // PERS-SORT-2: re-synced from the provider on every build so this
    // screen's sort/group selection survives being disposed and recreated
    // (e.g. leaving Archive and coming back), instead of resetting to
    // defaults the way local State did.
    final viewState = ref.watch(archiveViewStateProvider);
    _sort = viewState.sort;
    _group = viewState.group;
    _sortAscending = viewState.sortAscending;
    _watchedSortByRating = viewState.watchedSortByRating;
    _watchedGroupByCollection = viewState.watchedGroupByCollection;
    final mediaState = ref.watch(mediaProvider);
    final navState = ref.watch(navigationProvider);
    final activeType = navState.activeMediaType == MediaTypeToggle.movies
        ? MediaType.movie
        : MediaType.tv;

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
            // Swipe left -> next shelf
            _navigateToAdjacentShelf(1);
          } else if (velocity > 300) {
            // Swipe right -> previous shelf
            _navigateToAdjacentShelf(-1);
          }
        },
        child: SafeArea(
          child: FadeTransition(
            opacity: _fade,
            child: ScaleTransition(
              scale: _scale,
              child: SlideTransition(
                position: _slide,
                child: (_currentKind == ArchiveShelfKind.watched &&
                        _watchedGroupByCollection)
                    ? _buildWatchedContent(context, items)
                    : _buildStandardContent(context, items),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// ARCHIVE-SORT-1: the one place every sort decision funnels through --
  /// Watched's "My Rating" toggle takes priority over [_sort] when active
  /// (same precedence [_buildWatchedContent] already used), then
  /// [_sortAscending] reverses whichever result came out, uniformly for
  /// every shelf and every sort option.
  List<MediaItem> _sortedItems(List<MediaItem> items) {
    final sorted =
        (_currentKind == ArchiveShelfKind.watched && _watchedSortByRating)
            ? personalRatingSort(items, ref.read(mediaProvider).watchHistory)
            : sortArchiveShelf(items, _sort);
    return _sortAscending ? sorted.reversed.toList() : sorted;
  }

  Widget _buildStandardContent(BuildContext context, List<MediaItem> items) {
    final colors = context.ambianceColors;
    final isLarge = MediaQuery.of(context).size.width >= 600;
    final paddingHorizontal = isLarge ? 24.0 : 18.0;
    final banner = _currentKind == ArchiveShelfKind.saved
        ? _buildCleanupBanner(context, items.length)
        : null;
    final isWatched = _currentKind == ArchiveShelfKind.watched;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(
              paddingHorizontal, 8.0, paddingHorizontal, 8.0),
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
                if (isWatched) ...[
                  const SizedBox(height: 8),
                  _buildWatchedToolbarExtras(colors),
                ],
              ],
            ],
          ),
        ),
        Expanded(
          child: _group == ArchiveGroupOption.none
              ? _buildGrid(
                  context,
                  _sortedItems(items),
                  emptyLabel: 'Your ${_currentKind.label} is empty',
                )
              : _buildGroupedGrid(context, items),
        ),
      ],
    );
  }

  /// WATCHED-VIEW-1: "My Rating" sort and "Group by Collection" are extra,
  /// Watched-only controls -- kept separate from the shared Sort/Group
  /// dropdowns (which apply to every shelf) rather than folding them into
  /// [ArchiveSortOption]/[ArchiveGroupOption], since neither one is a
  /// meaningful choice on any other shelf.
  /// A small pill-shaped toggle button shared by every Watched-only toolbar
  /// control ("My Rating", "Group by Collection") across both
  /// [_buildWatchedToolbarExtras] and [_buildWatchedContent]'s own toolbar --
  /// pulled out specifically so "Group by Collection" can never again exist
  /// in only one of the two places and strand the user unable to turn it
  /// back off once active (the bug this was fixed for).
  Widget _buildPillToggle({
    required Key? key,
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
    required AmbianceColors colors,
  }) {
    return PressableScale(
      key: key,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? colors.acc.withValues(alpha: 0.14) : colors.pill,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isActive ? colors.acc : colors.lineRgba,
            width: isActive ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: isActive ? colors.acc : colors.sub),
            const SizedBox(width: 4),
            Text(
              label,
              style: AppThemes.safeGeist(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isActive ? colors.acc : colors.sub,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMyRatingToggle(AmbianceColors colors) => _buildPillToggle(
        key: const ValueKey('watched_my_rating_toggle'),
        icon: Icons.star_rounded,
        label: 'My Rating',
        isActive: _watchedSortByRating,
        onTap: () => ref
            .read(archiveViewStateProvider.notifier)
            .toggleWatchedSortByRating(),
        colors: colors,
      );

  Widget _buildGroupByCollectionToggle(AmbianceColors colors) =>
      _buildPillToggle(
        key: const ValueKey('watched_group_by_collection_toggle'),
        icon: Icons.collections_bookmark_outlined,
        label: 'Group by Collection',
        isActive: _watchedGroupByCollection,
        onTap: () => ref
            .read(archiveViewStateProvider.notifier)
            .toggleWatchedGroupByCollection(),
        colors: colors,
      );

  Widget _buildWatchedToolbarExtras(AmbianceColors colors) {
    return Row(
      children: [
        _buildMyRatingToggle(colors),
        const SizedBox(width: 8),
        _buildGroupByCollectionToggle(colors),
      ],
    );
  }

  /// ARCHIVE-SORT-1: ascending/descending toggle, applies to every sort
  /// option and to every shelf (including collection clusters) -- shared so
  /// it's never present in the standard toolbar but missing from Watched's
  /// collection-grouped one, the same "control that always applies but only
  /// exists in one of two toolbars" bug "Group by Collection" had.
  Widget _buildSortDirectionToggle(AmbianceColors colors) {
    return PressableScale(
      key: const ValueKey('archive_sort_direction_toggle'),
      onTap: () =>
          ref.read(archiveViewStateProvider.notifier).toggleSortAscending(),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: colors.pill,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colors.lineRgba),
        ),
        child: Icon(
          _sortAscending
              ? Icons.arrow_upward_rounded
              : Icons.arrow_downward_rounded,
          size: 16,
          color: colors.acc,
        ),
      ),
    );
  }

  Widget _buildSortGroupBar() {
    final colors = context.ambianceColors;
    return Row(
      children: [
        Expanded(
          child: LoungeDropdown<ArchiveSortOption>(
            value: _sort,
            hintText: 'Sort',
            isActive: _sort != ArchiveSortOption.lastAdded,
            items: ArchiveSortOption.values
                .map((o) => LoungeDropdownItem(value: o, label: o.label))
                .toList(),
            onChanged: (v) {
              if (v != null) {
                ref.read(archiveViewStateProvider.notifier).setSort(v);
              }
            },
          ),
        ),
        const SizedBox(width: 8),
        // ARCHIVE-SORT-1: ascending/descending toggle, applies to every sort
        // option above and to every shelf (including collection clusters).
        _buildSortDirectionToggle(colors),
        const SizedBox(width: 8),
        Expanded(
          child: LoungeDropdown<ArchiveGroupOption>(
            value: _group,
            hintText: 'Group',
            isActive: _group != ArchiveGroupOption.none,
            items: ArchiveGroupOption.values
                .map((o) => LoungeDropdownItem(value: o, label: o.label))
                .toList(),
            onChanged: (v) {
              if (v != null) {
                ref.read(archiveViewStateProvider.notifier).setGroup(v);
              }
            },
          ),
        ),
      ],
    );
  }

  Widget? _buildCleanupBanner(BuildContext context, int savedCount) {
    if (savedCount <= kArchiveCleanupThreshold || _cleanupBannerDismissed) {
      return null;
    }

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
              MaterialPageRoute(
                  builder: (context) => const CleanupSwipeScreen()),
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
      case ArchiveGroupOption.genre:
        grouped = groupByGenre(items);
        break;
      case ArchiveGroupOption.language:
        grouped = groupByLanguage(items);
        break;
      case ArchiveGroupOption.ratingBand:
      case ArchiveGroupOption.none:
        grouped = groupByRatingBand(items);
        break;
    }
    final entries = grouped.entries.toList()
      ..sort((a, b) {
        if (_group == ArchiveGroupOption.ratingBand) {
          if (a.key == 'Unrated') return 1;
          if (b.key == 'Unrated') return -1;
          return b.key.compareTo(a.key); // highest band first
        }
        if (_group == ArchiveGroupOption.language) {
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
          final groupItems = _sortedItems(entry.value);
          return Container(
            key: ValueKey('${keyPrefix}_group_${entry.key}'),
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: colors.card,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: colors.lineRgba),
            ),
            child: Theme(
              data:
                  Theme.of(context).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                initiallyExpanded: true,
                tilePadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
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
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
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
                      gridDelegate:
                          const SliverGridDelegateWithMaxCrossAxisExtent(
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

  Widget _buildGrid(BuildContext context, List<MediaItem> items,
      {required String emptyLabel}) {
    final isDark = context.ambianceColors.isDark;
    if (items.isEmpty) {
      final allItems =
          _currentKind.mapFrom(ref.watch(mediaProvider)).values.toList();
      final otherTypeCount = allItems.length;
      final activeType = ref.watch(navigationProvider).activeMediaType ==
              MediaTypeToggle.movies
          ? MediaType.movie
          : MediaType.tv;

      final isWatched = _currentKind == ArchiveShelfKind.watched;

      if (otherTypeCount > 0) {
        final otherTypeName =
            activeType == MediaType.movie ? 'TV Shows' : 'Movies';
        return AtmosphericEmptyState(
          icon: Icons.swap_horiz_rounded,
          title: isWatched
              ? 'No watched ${activeType == MediaType.movie ? 'movies' : 'TV shows'}'
              : 'No ${activeType == MediaType.movie ? 'movies' : 'TV shows'} in ${_currentKind.label}',
          message: isWatched
              ? 'You have $otherTypeCount watched title${otherTypeCount == 1 ? '' : 's'} under $otherTypeName.'
              : 'You have $otherTypeCount title${otherTypeCount == 1 ? '' : 's'} under $otherTypeName in this archive.',
          ctaLabel: 'Switch to $otherTypeName',
          onCta: () => ref.read(navigationProvider.notifier).toggleMediaType(),
        );
      }

      return AtmosphericEmptyState(
        icon: isWatched
            ? Icons.check_circle_outline_rounded
            : Icons.movie_creation_outlined,
        title: isWatched ? 'Nothing watched yet' : emptyLabel,
        message: isWatched
            ? 'Titles you mark as watched will show up here.'
            : 'Titles you save here will show up in this list.',
        ctaLabel: 'Discover Titles',
        onCta: () {
          Navigator.of(context).popUntil((route) => route.isFirst);
          ref.read(navigationProvider.notifier).setTab(AppTab.discover);
        },
      );
    }

    final isLarge = MediaQuery.of(context).size.width >= 600;

    return GridView.builder(
      padding: EdgeInsets.fromLTRB(isLarge ? 24.0 : 18.0, isLarge ? 12.0 : 8.0,
          isLarge ? 24.0 : 18.0, 18.0 + MediaQuery.of(context).padding.bottom),
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
        )
            .animate()
            .fade(duration: 250.ms)
            .slideY(begin: 0.1, end: 0, delay: (index.clamp(0, 5) * 40).ms);
      },
    );
  }

  Widget _buildWatchedContent(BuildContext context, List<MediaItem> items) {
    final colors = context.ambianceColors;

    if (items.isEmpty) {
      final allItems =
          _currentKind.mapFrom(ref.watch(mediaProvider)).values.toList();
      final otherTypeCount = allItems.length;
      final activeType = ref.watch(navigationProvider).activeMediaType ==
              MediaTypeToggle.movies
          ? MediaType.movie
          : MediaType.tv;

      if (otherTypeCount > 0) {
        final otherTypeName =
            activeType == MediaType.movie ? 'TV Shows' : 'Movies';
        return AtmosphericEmptyState(
          icon: Icons.swap_horiz_rounded,
          title:
              'No watched ${activeType == MediaType.movie ? 'movies' : 'TV shows'}',
          message:
              'You have $otherTypeCount watched title${otherTypeCount == 1 ? '' : 's'} under $otherTypeName.',
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

    final collectionEntries = groupedByCollection.entries.toList();

    if (_watchedSortByRating) {
      final watchHistory = ref.read(mediaProvider).watchHistory;
      for (final entry in collectionEntries) {
        final sorted = personalRatingSort(entry.value, watchHistory);
        entry.value
          ..clear()
          ..addAll(sorted);
      }
      final sortedStandalone =
          personalRatingSort(standaloneItems, watchHistory);
      standaloneItems
        ..clear()
        ..addAll(sortedStandalone);
    } else if (_sort == ArchiveSortOption.lastAdded) {
      // ARCHIVE-SORT-1: cluster order (and item order within each cluster)
      // by explicit addedDate/releaseDate timestamps.
      collectionEntries.sort((a, b) {
        final dateA = getCollectionLastAdded(a.value);
        final dateB = getCollectionLastAdded(b.value);
        return dateB.compareTo(dateA);
      });
      for (final entry in collectionEntries) {
        entry.value.sort((a, b) {
          final ad = a.addedDate ?? a.releaseOrAirDate;
          final bd = b.addedDate ?? b.releaseOrAirDate;
          if (ad == null && bd == null) return 0;
          if (ad == null) return 1;
          if (bd == null) return -1;
          return bd.compareTo(ad);
        });
      }
      standaloneItems.sort((a, b) {
        final ad = a.addedDate ?? a.releaseOrAirDate;
        final bd = b.addedDate ?? b.releaseOrAirDate;
        if (ad == null && bd == null) return 0;
        if (ad == null) return 1;
        if (bd == null) return -1;
        return bd.compareTo(ad);
      });
    } else {
      for (final entry in collectionEntries) {
        final sorted = sortArchiveShelf(entry.value, _sort);
        entry.value
          ..clear()
          ..addAll(sorted);
      }
      final sortedStandalone = sortArchiveShelf(standaloneItems, _sort);
      standaloneItems
        ..clear()
        ..addAll(sortedStandalone);
    }

    if (_sortAscending) {
      final reversedEntries = collectionEntries.reversed.toList();
      collectionEntries
        ..clear()
        ..addAll(reversedEntries);
      for (final entry in collectionEntries) {
        final reversed = entry.value.reversed.toList();
        entry.value
          ..clear()
          ..addAll(reversed);
      }
      final reversedStandalone = standaloneItems.reversed.toList();
      standaloneItems
        ..clear()
        ..addAll(reversedStandalone);
    }

    final isLarge = MediaQuery.of(context).size.width >= 600;
    final paddingHorizontal = isLarge ? 24.0 : 18.0;

    final watchedGroupKeys = [
      for (final entry in collectionEntries) 'watched_col_${entry.key}',
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
          Row(
            children: [
              Expanded(
                child: LoungeDropdown<ArchiveSortOption>(
                  value: _sort,
                  hintText: 'Sort',
                  isActive: _sort != ArchiveSortOption.lastAdded,
                  items: ArchiveSortOption.values
                      .map((o) => LoungeDropdownItem(value: o, label: o.label))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) {
                      ref
                          .read(archiveViewStateProvider.notifier)
                          .setSortClearingRatingToggle(v);
                    }
                  },
                ),
              ),
              const SizedBox(width: 8),
              // ARCHIVE-SORT-1: this toggle applies here exactly as much as
              // on the standard toolbar -- previously only the standard one
              // had it, so switching to collection view silently lost the
              // ability to flip sort direction, same class of bug as
              // "Group by Collection" going missing from this same toolbar.
              _buildSortDirectionToggle(colors),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildMyRatingToggle(colors),
              // BUG FIX: previously this toolbar had no way to turn
              // "Group by Collection" back off once active -- the standard
              // toolbar's toggle was the only one, and switching to this
              // grouped view replaces that entire toolbar, stranding the
              // user until the screen was torn down and rebuilt.
              _buildGroupByCollectionToggle(colors),
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
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: colors.pill,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: colors.lineRgba),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _watchedAllCollapsed
                              ? Icons.unfold_more
                              : Icons.unfold_less,
                          size: 14,
                          color: colors.acc,
                        ),
                        const SizedBox(width: 4),
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
            ],
          ),
          const SizedBox(height: 12),
          ...collectionEntries.map((entry) {
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
                  data: Theme.of(context)
                      .copyWith(dividerColor: Colors.transparent),
                  child: ExpansionTile(
                    key: PageStorageKey<String>('watched_col_$colName'),
                    controller: _watchedTileController('watched_col_$colName'),
                    initiallyExpanded: true,
                    iconColor: colors.acc,
                    collapsedIconColor: colors.sub,
                    title: Row(
                      children: [
                        Icon(Icons.collections_bookmark_outlined,
                            size: 18, color: colors.acc),
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
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
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
                  data: Theme.of(context)
                      .copyWith(dividerColor: Colors.transparent),
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
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
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

  Widget _buildSubGrid(
      BuildContext context, List<MediaItem> items, String keySuffix) {
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
