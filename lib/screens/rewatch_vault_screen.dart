import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants.dart';
import '../models/media_item.dart';
import '../providers/media_provider.dart';
import '../providers/navigation_provider.dart';
import '../widgets/atmospheric_empty_state.dart';
import '../widgets/lounge_dropdown.dart';
import '../widgets/media_image.dart';
import '../widgets/pressable_scale.dart';
import 'detail_screen.dart';

/// FEAT-REWATCH-1: secondary sort applied to the (type-filtered) rewatch
/// list below the hero card. Follows the same `enum(label)` convention as
/// [ArchiveSortOption] in `archive_sort_group.dart`.
enum RewatchSortOption {
  mostRecent('Most Recent'),
  mostRewatched('Most Rewatched'),
  titleAZ('Title A-Z');

  final String label;
  const RewatchSortOption(this.label);
}

/// FEAT-TOOLS-1: total number of rewatch `WatchRecord` entries logged
/// across every title, both movies and TV (unlike [RewatchVaultScreen]'s
/// own list, which is scoped to the active Movies/TV toggle) -- the Tools
/// Hub card shows one aggregate number regardless of which toggle is
/// active. Also feeds the hero stat on this screen itself (FEAT-REWATCH-1).
int totalRewatchCount(MediaState state) {
  var total = 0;
  for (final records in state.watchHistory.values) {
    total += records.where((r) => !r.isFirstWatch).length;
  }
  return total;
}

/// Item 61: resolves [id] against each shelf's own keys (raw or
/// movie_/tv_-prefixed, whichever the shelf actually stores it under)
/// rather than a bare direct lookup, since `id` here comes from a
/// `watchHistory` key which isn't guaranteed to already be in the shelves'
/// normalized form -- see `resolveStoredId` in media_item.dart.
MediaItem? _findKnownItem(MediaState state, String id) {
  for (final shelf in [
    state.watchlist,
    state.maybeList,
    state.watchingList,
    state.watchedList,
    state.droppedList,
    state.onHoldList,
  ]) {
    final resolved = resolveStoredId(shelf, id);
    if (resolved != null) return shelf[resolved];
  }
  return null;
}

/// FEAT-REWATCH-1: the single most-rewatched title across every type (an
/// aggregate stat like [totalRewatchCount], not scoped to the active
/// Movies/TV toggle -- the hero card is meant to answer "what have I
/// rewatched the most, period," independent of which list is being browsed
/// below it).
({String mediaId, int count})? _mostRewatchedEntry(MediaState state) {
  String? topId;
  var topCount = 0;
  state.watchHistory.forEach((mediaId, records) {
    final count = records.where((r) => !r.isFirstWatch).length;
    if (count > topCount) {
      topCount = count;
      topId = mediaId;
    }
  });
  if (topId == null) return null;
  return (mediaId: topId!, count: topCount);
}

/// One title's rewatch summary: how many times it's been rewatched, and
/// when the most recent rewatch was logged.
class _RewatchSummary {
  final String mediaId;
  final DateTime mostRecent;
  final int count;
  final String title;

  const _RewatchSummary({
    required this.mediaId,
    required this.mostRecent,
    required this.count,
    required this.title,
  });
}

/// PERS-SPACE-1 Tools group: a browsable vault of every title with at least
/// one logged rewatch (a `WatchRecord` with `isFirstWatch: false`), most
/// recently rewatched first by default (FEAT-REWATCH-1 adds Most Rewatched
/// / Title A-Z as alternate sorts).
class RewatchVaultScreen extends ConsumerStatefulWidget {
  const RewatchVaultScreen({super.key});

  @override
  ConsumerState<RewatchVaultScreen> createState() => _RewatchVaultScreenState();
}

class _RewatchVaultScreenState extends ConsumerState<RewatchVaultScreen> {
  RewatchSortOption _sort = RewatchSortOption.mostRecent;

  List<_RewatchSummary> _computeSummaries(MediaState state, MediaType activeType) {
    final summaries = <_RewatchSummary>[];
    state.watchHistory.forEach((mediaId, records) {
      final rewatches = records.where((r) => !r.isFirstWatch).toList();
      if (rewatches.isEmpty) return;
      final known = _findKnownItem(state, mediaId);
      if (known != null && known.type != activeType) return;
      final mostRecent = rewatches
          .map((r) => r.date ?? r.recordedAt)
          .reduce((a, b) => a.isAfter(b) ? a : b);
      summaries.add(_RewatchSummary(
        mediaId: mediaId,
        mostRecent: mostRecent,
        count: rewatches.length,
        title: known?.title ?? '',
      ));
    });
    switch (_sort) {
      case RewatchSortOption.mostRecent:
        summaries.sort((a, b) => b.mostRecent.compareTo(a.mostRecent));
      case RewatchSortOption.mostRewatched:
        summaries.sort((a, b) => b.count.compareTo(a.count));
      case RewatchSortOption.titleAZ:
        summaries.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
    }
    return summaries;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.ambianceColors;
    final state = ref.watch(mediaProvider);
    final activeType = ref.watch(navigationProvider).activeMediaType == MediaTypeToggle.movies
        ? MediaType.movie
        : MediaType.tv;
    final summaries = _computeSummaries(state, activeType);
    final topEntry = _mostRewatchedEntry(state);

    return Scaffold(
      backgroundColor: colors.base,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.only(left: 12.0),
          child: Center(
            child: PressableScale(
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: colors.card,
                  shape: BoxShape.circle,
                  border: Border.all(color: colors.lineRgba),
                  boxShadow: [
                    BoxShadow(
                      color: colors.scrim.withValues(alpha: colors.isDark ? 0.2 : 0.06),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(Icons.chevron_left_rounded, color: colors.ink, size: 22),
              ),
            ),
          ),
        ),
        title: Text(
          'Rewatch Vault',
          style: AppThemes.display(
            context,
            fontSize: 22,
            fontWeight: FontWeight.w500,
            color: colors.ink,
          ),
        ),
      ),
      body: SafeArea(
        child: summaries.isEmpty
            ? AtmosphericEmptyState(
                icon: Icons.replay_circle_filled_outlined,
                title: 'No rewatches yet',
                message: 'Titles you log a rewatch for will show up here.',
                ctaLabel: 'Discover Titles',
                onCta: () => ref.read(navigationProvider.notifier).setTab(AppTab.discover),
              )
            : Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 14, 18, 0),
                    child: _RewatchHeroCard(
                      totalRewatches: totalRewatchCount(state),
                      topMediaId: topEntry?.mediaId,
                      topCount: topEntry?.count ?? 0,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 14, 18, 0),
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: SizedBox(
                        width: 170,
                        child: LoungeDropdown<RewatchSortOption>(
                          value: _sort,
                          hintText: 'Sort',
                          isActive: _sort != RewatchSortOption.mostRecent,
                          items: RewatchSortOption.values
                              .map((o) => LoungeDropdownItem(value: o, label: o.label))
                              .toList(),
                          onChanged: (v) {
                            if (v != null) setState(() => _sort = v);
                          },
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: ListView.separated(
                      padding: const EdgeInsets.all(18),
                      itemCount: summaries.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) => _RewatchRow(summary: summaries[index]),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

/// FEAT-REWATCH-1: hero summary card showing the aggregate rewatch count
/// and the single most-rewatched title, resolved the same known-item/
/// mediaDetailsProvider-fallback way [_RewatchRow] resolves its own title.
class _RewatchHeroCard extends ConsumerWidget {
  final int totalRewatches;
  final String? topMediaId;
  final int topCount;

  const _RewatchHeroCard({
    required this.totalRewatches,
    this.topMediaId,
    this.topCount = 0,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.ambianceColors;

    String? topTitle;
    final id = topMediaId;
    if (id != null) {
      final known = _findKnownItem(ref.watch(mediaProvider), id);
      if (known != null) {
        topTitle = known.title;
      } else {
        topTitle = ref.watch(mediaDetailsProvider(id)).maybeWhen(
              data: (item) => item?.title,
              orElse: () => null,
            );
      }
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colors.acc.withValues(alpha: colors.isDark ? 0.16 : 0.10),
            colors.card,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.acc.withValues(alpha: 0.3)),
        boxShadow: [
          if (colors.isDark)
            BoxShadow(
              color: colors.surfaceHighlight,
              blurRadius: 0,
              offset: const Offset(0, 1),
              blurStyle: BlurStyle.inner,
            ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: colors.acc.withValues(alpha: colors.isDark ? 0.18 : 0.14),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: colors.acc.withValues(alpha: 0.35)),
            ),
            child: Icon(Icons.replay_rounded, color: colors.acc, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$totalRewatches rewatch${totalRewatches == 1 ? '' : 'es'} logged',
                  style: AppThemes.safeGeist(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: colors.ink,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  topTitle != null
                      ? 'Most rewatched: $topTitle ($topCount×)'
                      : 'Keep logging rewatches to surface a favorite',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppThemes.safeGeist(fontSize: 12.5, color: colors.sub),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RewatchRow extends ConsumerWidget {
  final _RewatchSummary summary;

  const _RewatchRow({required this.summary});

  String _formatDate(DateTime dt) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final known = _findKnownItem(ref.watch(mediaProvider), summary.mediaId);
    if (known != null) return _buildRow(context, known);

    final asyncItem = ref.watch(mediaDetailsProvider(summary.mediaId));
    return asyncItem.when(
      data: (item) => item != null ? _buildRow(context, item) : const SizedBox.shrink(),
      loading: () => _buildLoadingRow(context),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildRow(BuildContext context, MediaItem item) {
    final colors = context.ambianceColors;
    return PressableScale(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (context) => DetailScreen(id: item.prefixedId, initialItem: item)),
      ),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: colors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colors.lineRgba),
          boxShadow: [
            if (colors.isDark)
              BoxShadow(
                color: colors.surfaceHighlight,
                blurRadius: 0,
                offset: const Offset(0, 1),
                blurStyle: BlurStyle.inner,
              ),
          ],
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                width: 44,
                height: 64,
                child: MediaImage(
                  imageUrl: item.posterUrl,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppThemes.safeGeist(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: colors.ink,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Rewatched ${summary.count} time${summary.count == 1 ? '' : 's'} · ${_formatDate(summary.mostRecent)}',
                    style: AppThemes.safeGeist(
                      fontSize: 12.5,
                      color: colors.sub,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: colors.acc.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: colors.acc.withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.replay_rounded, size: 13, color: colors.acc),
                  const SizedBox(width: 4),
                  Text(
                    '${summary.count}x',
                    style: AppThemes.safeGeist(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: colors.acc,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingRow(BuildContext context) {
    final colors = context.ambianceColors;
    return Container(
      height: 76,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.lineRgba),
      ),
    );
  }
}
