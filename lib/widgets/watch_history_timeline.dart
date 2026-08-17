import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants.dart';
import '../models/media_item.dart';
import '../providers/media_provider.dart';
import 'lounge_rating_sheet.dart';
import 'pressable_scale.dart';

String _formatHistoryDate(DateTime? dt) {
  if (dt == null) return 'No date logged';
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
}

/// PERS-REWATCH-1: collapsible timeline of every logged watch (first watch
/// + rewatches, and per-season records for TV) for [item]. Renders nothing
/// when there's no history yet -- SP-4, never a forced/empty section.
/// Tapping any row reopens [LoungeRatingSheet] scoped to that exact entry.
class WatchHistoryTimeline extends ConsumerStatefulWidget {
  final MediaItem item;

  const WatchHistoryTimeline({super.key, required this.item});

  @override
  ConsumerState<WatchHistoryTimeline> createState() => _WatchHistoryTimelineState();
}

class _WatchHistoryTimelineState extends ConsumerState<WatchHistoryTimeline> {
  bool _expanded = false;

  String _labelFor(WatchRecord record, int rewatchIndex) {
    if (record.seasonNumber != null) {
      return record.isFirstWatch
          ? 'Season ${record.seasonNumber}'
          : 'Season ${record.seasonNumber} · Rewatch $rewatchIndex';
    }
    return record.isFirstWatch ? '1st Watch' : 'Rewatch $rewatchIndex';
  }

  @override
  Widget build(BuildContext context) {
    final records =
        ref.watch(mediaProvider.select((s) => s.watchHistory[widget.item.id]));
    if (records == null || records.isEmpty) return const SizedBox.shrink();

    final sorted = List<WatchRecord>.from(records)
      ..sort((a, b) => (a.date ?? a.recordedAt).compareTo(b.date ?? b.recordedAt));

    // Rewatch numbering follows chronological order, scoped separately for
    // the overall-item timeline vs. each season's own timeline.
    final rewatchCounters = <int?, int>{};
    final labeled = sorted.map((r) {
      int rewatchIndex = 0;
      if (!r.isFirstWatch) {
        rewatchIndex = (rewatchCounters[r.seasonNumber] ?? 0) + 1;
        rewatchCounters[r.seasonNumber] = rewatchIndex;
      }
      return (record: r, label: _labelFor(r, rewatchIndex));
    }).toList();

    final colors = context.ambianceColors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        PressableScale(
          onTap: () => setState(() => _expanded = !_expanded),
          child: Row(
            children: [
              Text(
                'Watch History',
                style: AppThemes.safeGeist(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: colors.ink,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '(${sorted.length})',
                style: AppThemes.safeGeist(fontSize: 13, color: colors.sub),
              ),
              const Spacer(),
              AnimatedRotation(
                turns: _expanded ? 0.5 : 0,
                duration: AppPhysics.houseSpringDuration,
                curve: AppPhysics.houseSpringCurve,
                child: Icon(Icons.expand_more_rounded, color: colors.sub),
              ),
            ],
          ),
        ),
        AnimatedSize(
          duration: AppPhysics.houseSpringDuration,
          curve: AppPhysics.houseSpringCurve,
          alignment: Alignment.topCenter,
          child: _expanded
              ? Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Column(
                    children: labeled
                        .map(
                          (entry) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: _HistoryRow(
                              item: widget.item,
                              record: entry.record,
                              label: entry.label,
                            ),
                          ),
                        )
                        .toList(),
                  ),
                )
              : const SizedBox(width: double.infinity),
        ),
      ],
    );
  }
}

class _HistoryRow extends StatelessWidget {
  final MediaItem item;
  final WatchRecord record;
  final String label;

  const _HistoryRow({
    required this.item,
    required this.record,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.ambianceColors;
    final rating = record.rating;
    final tierColor = rating != null ? AppRatingColors.of(rating) : colors.sub;

    return Consumer(
      builder: (context, ref, _) => PressableScale(
        onTap: () => showLoungeRatingSheet(
          context,
          ref,
          item: item,
          seasonNumber: record.seasonNumber,
          recordToEdit: record,
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: colors.pill,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: colors.lineRgba),
          ),
          child: Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(shape: BoxShape.circle, color: tierColor),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: AppThemes.safeGeist(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: colors.ink,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _formatHistoryDate(record.date),
                      style: AppThemes.safeGeist(fontSize: 11, color: colors.sub),
                    ),
                  ],
                ),
              ),
              if (rating != null)
                Text(
                  rating.label,
                  style: AppThemes.safeGeist(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: tierColor,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
