import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
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
/// recently rewatched first.
class RewatchVaultScreen extends ConsumerWidget {
  const RewatchVaultScreen({super.key});

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
          style: GoogleFonts.bodoniModa(
            fontSize: 22,
            fontWeight: FontWeight.w500,
            fontStyle: FontStyle.italic,
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
