import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants.dart';
import '../models/media_item.dart';
import '../providers/media_provider.dart';
import '../providers/navigation_provider.dart';
import '../widgets/atmospheric_empty_state.dart';
import '../widgets/media_image.dart';
import '../widgets/pressable_scale.dart';
import 'detail_screen.dart';

MediaItem? _findKnownItem(MediaState state, String id) {
  return state.watchlist[id] ??
      state.maybeList[id] ??
      state.watchingList[id] ??
      state.watchedList[id] ??
      state.droppedList[id] ??
      state.onHoldList[id];
}

/// One title's rewatch summary: how many times it's been rewatched, and
/// when the most recent rewatch was logged.
class _RewatchSummary {
  final String mediaId;
  final DateTime mostRecent;
  final int count;

  const _RewatchSummary({required this.mediaId, required this.mostRecent, required this.count});
}

/// PERS-SPACE-1 Tools group: a browsable vault of every title with at least
/// one logged rewatch (a `WatchRecord` with `isFirstWatch: false`), most
/// recently rewatched first. Named in the locked 3-group mockup alongside
/// Rate Titles/Custom Folders/Cleanup Session but not otherwise specced in
/// detail -- built here as a straightforward "browse your rewatch history"
/// list, deliberately not reaching into PERS-DIFF-1's later, more elaborate
/// memory-surfacing features (Forgotten Favorites, On This Day).
class RewatchVaultScreen extends ConsumerWidget {
  const RewatchVaultScreen({super.key});

  // PERS-SORT-1: scoped to the active Movies/TV toggle, mirroring every
  // Piles screen -- previously this listed rewatches of both types
  // regardless of the toggle. A title not found in any of the 6 status
  // piles (needs an async mediaDetailsProvider fetch to resolve) can't be
  // type-checked synchronously here -- kept rather than dropped, since
  // wrongly hiding a real rewatch is worse than occasionally showing one
  // of the "wrong" type for a beat.
  List<_RewatchSummary> _computeSummaries(MediaState state, MediaType activeType) {
    final summaries = <_RewatchSummary>[];
    state.watchHistory.forEach((mediaId, records) {
      final rewatches = records.where((r) => !r.isFirstWatch).toList();
      if (rewatches.isEmpty) return;
      final knownType = _findKnownItem(state, mediaId)?.type;
      if (knownType != null && knownType != activeType) return;
      final mostRecent = rewatches
          .map((r) => r.date ?? r.recordedAt)
          .reduce((a, b) => a.isAfter(b) ? a : b);
      summaries.add(_RewatchSummary(mediaId: mediaId, mostRecent: mostRecent, count: rewatches.length));
    });
    summaries.sort((a, b) => b.mostRecent.compareTo(a.mostRecent));
    return summaries;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.ambianceColors;
    final state = ref.watch(mediaProvider);
    final activeType = ref.watch(navigationProvider).activeMediaType == MediaTypeToggle.movies
        ? MediaType.movie
        : MediaType.tv;
    final summaries = _computeSummaries(state, activeType);

    return Scaffold(
      backgroundColor: colors.base,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: colors.ink),
        title: Text(
          'Rewatch Vault',
          style: AppThemes.safeGeist(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: colors.ink,
          ),
        ),
      ),
      body: SafeArea(
        child: summaries.isEmpty
            ? const AtmosphericEmptyState(
                icon: Icons.replay_circle_filled_outlined,
                title: 'No rewatches yet',
                message: 'Titles you log a rewatch for will show up here.',
              )
            : ListView.separated(
                padding: const EdgeInsets.all(18),
                itemCount: summaries.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) => _RewatchRow(summary: summaries[index]),
              ),
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
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: colors.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colors.lineRgba),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: SizedBox(
                width: 44,
                height: 64,
                child: MediaImage(item: item, fit: BoxFit.cover, showFallbackTitle: false),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
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
                    'Rewatched ${summary.count} time${summary.count == 1 ? '' : 's'} · last ${_formatDate(summary.mostRecent)}',
                    style: AppThemes.safeGeist(fontSize: 11, color: colors.sub),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: colors.sub),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingRow(BuildContext context) {
    final colors = context.ambianceColors;
    return Container(
      height: 84,
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.lineRgba),
      ),
    );
  }
}
