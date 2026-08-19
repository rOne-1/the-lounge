import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/media_provider.dart';
import '../providers/navigation_provider.dart';
import '../models/media_item.dart';
import '../constants.dart';
import '../utils/archive_sort_group.dart';
import '../widgets/atmospheric_empty_state.dart';
import '../widgets/lounge_dropdown.dart';
import '../widgets/media_card.dart';
import '../widgets/pressable_scale.dart';
import 'cleanup_swipe_screen.dart';

/// PERS-SPACE-1 / NAME-1: the six status destinations in The Lounge's Archive.
/// Standalone archive bucket destinations (Watching, Watched, Watchlist, Saved, On-Hold, Dropped).
enum ArchiveBucketKind {
  watchlist,
  saved,
  watching,
  onHold,
  dropped,
  watched;

  String get label {
    switch (this) {
      case ArchiveBucketKind.watchlist:
        return 'Watchlist';
      case ArchiveBucketKind.saved:
        return 'Saved';
      case ArchiveBucketKind.watching:
        return 'Watching';
      case ArchiveBucketKind.onHold:
        return 'On-Hold';
      case ArchiveBucketKind.dropped:
        return 'Dropped';
      case ArchiveBucketKind.watched:
        return 'Watched';
    }
  }

  String? get subtitle {
    switch (this) {
      case ArchiveBucketKind.watchlist:
        return 'Committed watchlist of titles you plan to watch soon.';
      case ArchiveBucketKind.saved:
        return 'Soft, non-committal bookmarks for titles you might want to check out later.';
      case ArchiveBucketKind.watching:
        return 'Titles you\'re actively watching right now.';
      case ArchiveBucketKind.onHold:
        return 'Paused for now -- pick back up whenever you\'re ready.';
      case ArchiveBucketKind.dropped:
        return 'Titles you stopped watching.';
      case ArchiveBucketKind.watched:
        return null;
    }
  }

  Color get statusColor {
    switch (this) {
      case ArchiveBucketKind.watchlist:
        return AppStatusColors.watchlist;
      case ArchiveBucketKind.saved:
        return AppStatusColors.save;
      case ArchiveBucketKind.watching:
        return AppStatusColors.watching;
      case ArchiveBucketKind.onHold:
        return AppStatusColors.onHold;
      case ArchiveBucketKind.dropped:
        return AppStatusColors.dropped;
      case ArchiveBucketKind.watched:
        return AppStatusColors.watched;
    }
  }

  IconData get icon {
    switch (this) {
      case ArchiveBucketKind.watchlist:
        return Icons.bookmark_rounded;
      case ArchiveBucketKind.saved:
        return Icons.archive_rounded;
      case ArchiveBucketKind.watching:
        return Icons.play_circle_fill_rounded;
      case ArchiveBucketKind.onHold:
        return Icons.pause_circle_filled_rounded;
      case ArchiveBucketKind.dropped:
        return Icons.remove_circle_rounded;
      case ArchiveBucketKind.watched:
        return Icons.check_circle_rounded;
    }
  }

  Map<String, MediaItem> mapFrom(MediaState state) {
    switch (this) {
      case ArchiveBucketKind.watchlist:
        return state.watchlist;
      case ArchiveBucketKind.saved:
        return state.maybeList;
      case ArchiveBucketKind.watching:
        return state.watchingList;
      case ArchiveBucketKind.onHold:
        return state.onHoldList;
      case ArchiveBucketKind.dropped:
        return state.droppedList;
      case ArchiveBucketKind.watched:
        return state.watchedList;
    }
  }
}

/// Backward compatibility alias for [ArchiveBucketKind].
typedef PileKind = ArchiveBucketKind;

/// PERS-SPACE-1/PERS-SORT-1 / NAME-1: standalone screen for a single status archive bucket,
/// every bucket gets the same sort/group suite, respects the global movies/TV toggle,
/// and is independently navigable from the Archive hub.
class ArchiveBucketScreen extends ConsumerStatefulWidget {
  final ArchiveBucketKind kind;

  const ArchiveBucketScreen({super.key, required this.kind});

  @override
  ConsumerState<ArchiveBucketScreen> createState() => _ArchiveBucketScreenState();
}

/// Backward compatibility alias for [ArchiveBucketScreen].
typedef PileScreen = ArchiveBucketScreen;

class _ArchiveBucketScreenState extends ConsumerState<ArchiveBucketScreen>
    with SingleTickerProviderStateMixin {
  static const _bucketSequence = [
    ArchiveBucketKind.watching,
    ArchiveBucketKind.watchlist,
    ArchiveBucketKind.saved,
    ArchiveBucketKind.onHold,
    ArchiveBucketKind.dropped,
    ArchiveBucketKind.watched,
  ];

  static const Duration _duration = Duration(milliseconds: 360);

  late ArchiveBucketKind _currentKind;
  late final AnimationController _transitionController;
  late Animation<double> _fade;
  late Animation<Offset> _slide;
  late Animation<double> _scale;

  // PERS-SORT-1: sort/group selection is local to this screen instance
  ArchiveSortOption _sort = ArchiveSortOption.dateAdded;
  ArchiveGroupOption _group = ArchiveGroupOption.none;
  bool _watchedSortByRating = false;
  bool _cleanupBannerDismissed = false;

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
    _fade = CurvedAnimation(parent: _transitionController, curve: Curves.easeOutCubic);
    _scale = Tween<double>(begin: 0.985, end: 1.0).animate(
      CurvedAnimation(parent: _transitionController, curve: AppPhysics.houseSpringCurve),
    );
    _slide = Tween<Offset>(
      begin: Offset(reverseDirection ? -0.05 : 0.05, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _transitionController, curve: AppPhysics.houseSpringCurve));
  }

  @override
  void didUpdateWidget(covariant ArchiveBucketScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.kind != widget.kind) {
      final oldIndex = _bucketSequence.indexOf(oldWidget.kind);
      final newIndex = _bucketSequence.indexOf(widget.kind);
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

  void _navigateToAdjacentBucket(int delta) {
    final currentIndex = _bucketSequence.indexOf(_currentKind);
    if (currentIndex == -1) return;
    final nextIndex = currentIndex + delta;
    if (nextIndex >= 0 && nextIndex < _bucketSequence.length) {
      setState(() {
        _currentKind = _bucketSequence[nextIndex];
      });
      _buildAnimations(reverseDirection: delta < 0);
      _transitionController
        ..value = 0.0
        ..forward();
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
            // Swipe left -> next bucket
            _navigateToAdjacentBucket(1);
          } else if (velocity > 300) {
            // Swipe right -> previous bucket
            _navigateToAdjacentBucket(-1);
          }
        },
        child: SafeArea(
          child: FadeTransition(
            opacity: _fade,
            child: ScaleTransition(
              scale: _scale,
              child: SlideTransition(
                position: _slide,
                child: _currentKind == ArchiveBucketKind.watched
                    ? _buildWatchedContent(context, items)
                    : _buildStandardContent(context, items),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStandardContent(BuildContext context, List<MediaItem> items) {
    final colors = context.ambianceColors;
    final isLarge = MediaQuery.of(context).size.width >= 600;
    final paddingHorizontal = isLarge ? 24.0 : 18.0;
    final banner =
        _currentKind == ArchiveBucketKind.saved ? _buildCleanupBanner(context, items.length) : null;

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
          child: _group == ArchiveGroupOption.none
              ? _buildGrid(
                  context,
                  sortArchiveBucket(items, _sort),
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
          child: LoungeDropdown<ArchiveSortOption>(
            value: _sort,
            hintText: 'Sort',
            isActive: _sort != ArchiveSortOption.dateAdded,
            items: ArchiveSortOption.values
                .map((o) => LoungeDropdownItem(value: o, label: o.label))
                .toList(),
            onChanged: (v) {
              if (v != null) setState(() => _sort = v);
            },
          ),
        ),
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
              if (v != null) setState(() => _group = v);
            },
          ),
        ),
      ],
    );
  }

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
          final groupItems = sortArchiveBucket(entry.value, _sort);
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
      final allItems = _currentKind.mapFrom(ref.watch(mediaProvider)).values.toList();
      final otherTypeCount = allItems.length;
      final activeType = ref.watch(navigationProvider).activeMediaType == MediaTypeToggle.movies
          ? MediaType.movie
          : MediaType.tv;

      if (otherTypeCount > 0) {
        final otherTypeName = activeType == MediaType.movie ? 'TV Shows' : 'Movies';
        return AtmosphericEmptyState(
          icon: Icons.swap_horiz_rounded,
          title: 'No ${activeType == MediaType.movie ? 'movies' : 'TV shows'} in ${_currentKind.label}',
          message: 'You have $otherTypeCount title${otherTypeCount == 1 ? '' : 's'} under $otherTypeName in this archive.',
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
      final allItems = _currentKind.mapFrom(ref.watch(mediaProvider)).values.toList();
      final otherTypeCount = allItems.length;
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

    final collectionEntries = groupedByCollection.entries.toList();

    if (_watchedSortByRating) {
      final watchHistory = ref.read(mediaProvider).watchHistory;
      for (final entry in collectionEntries) {
        final sorted = personalRatingSort(entry.value, watchHistory);
        entry.value
          ..clear()
          ..addAll(sorted);
      }
      final sortedStandalone = personalRatingSort(standaloneItems, watchHistory);
      standaloneItems
        ..clear()
        ..addAll(sortedStandalone);
    } else if (_sort == ArchiveSortOption.lastAdded || _sort == ArchiveSortOption.dateAdded) {
      // SORT-2: Sort collection clusters by the most recent timestamp in each cluster
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
        final sorted = sortArchiveBucket(entry.value, _sort);
        entry.value
          ..clear()
          ..addAll(sorted);
      }
      final sortedStandalone = sortArchiveBucket(standaloneItems, _sort);
      standaloneItems
        ..clear()
        ..addAll(sortedStandalone);
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
                  isActive: _sort != ArchiveSortOption.dateAdded && _sort != ArchiveSortOption.lastAdded,
                  items: ArchiveSortOption.values
                      .map((o) => LoungeDropdownItem(value: o, label: o.label))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) {
                      setState(() {
                        _sort = v;
                        _watchedSortByRating = false;
                      });
                    }
                  },
                ),
              ),
              const SizedBox(width: 8),
              PressableScale(
                onTap: () => setState(() => _watchedSortByRating = !_watchedSortByRating),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
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
                      const SizedBox(width: 4),
                      Text(
                        'My Rating',
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
              if (watchedGroupKeys.length > 1) ...[
                const SizedBox(width: 8),
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
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: colors.pill,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: colors.lineRgba),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _watchedAllCollapsed ? Icons.unfold_more : Icons.unfold_less,
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
