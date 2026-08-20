import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants.dart';
import '../models/media_item.dart';
import '../providers/media_provider.dart';
import 'lounge_rating_sheet.dart' show findPrimaryWatchRecord;

/// PERS-DIFF-1: horizontal segmented bar on `DetailScreen` showing each
/// season's personal rating as a color-coded tier fill (e.g. S1: Loved,
/// S2: Loved, S3: Liked, S4: Not for me). Unrated seasons render as a
/// neutral placeholder segment rather than being omitted, so the segment
/// count always matches the show's `seasonsCount` -- an at-a-glance "how
/// much of this show have I actually rated" signal, not just a ratings
/// list. Only renders for multi-season TV shows; single-season shows and
/// movies have nothing to segment.
class SeasonalRatingBar extends ConsumerWidget {
  final MediaItem item;

  const SeasonalRatingBar({super.key, required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (item.type != MediaType.tv) return const SizedBox.shrink();
    final seasonsCount = item.seasonsCount ?? 1;
    if (seasonsCount <= 1) return const SizedBox.shrink();

    final watchHistory = ref.watch(
      mediaProvider.select((s) => s.watchHistory[item.id] ?? const []),
    );

    final ratings = <int, PersonalRating?>{
      for (var seasonNum = 1; seasonNum <= seasonsCount; seasonNum++)
        seasonNum:
            findPrimaryWatchRecord({item.id: watchHistory}, item.id, seasonNum)
                ?.rating,
    };

    final inkColor = context.ambianceColors.ink;
    final subColor = context.ambianceColors.sub;
    final unratedColor = context.ambianceColors.lineRgba;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        Text(
          'Your Season Ratings',
          style: AppThemes.safeGeist(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: inkColor,
          ),
        ),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: SizedBox(
            height: 10,
            child: Row(
              children: List.generate(seasonsCount, (index) {
                final seasonNum = index + 1;
                final rating = ratings[seasonNum];
                return Expanded(
                  child: Tooltip(
                    message: rating != null
                        ? 'Season $seasonNum: ${rating.label}'
                        : 'Season $seasonNum: not rated',
                    // Stock Tooltip defaults to long-press on touch
                    // platforms -- a plain tap never revealed this on
                    // Android. See chronological_heatmap.dart for the same
                    // fix and reasoning.
                    triggerMode: TooltipTriggerMode.tap,
                    // SP-2: themed to match the app's dark chrome instead
                    // of Flutter's plain light default popup.
                    decoration: BoxDecoration(
                      color: context.ambianceColors.card2,
                      borderRadius: BorderRadius.circular(8),
                      border:
                          Border.all(color: context.ambianceColors.lineRgba),
                    ),
                    textStyle:
                        AppThemes.safeGeist(fontSize: 12, color: inkColor),
                    child: Container(
                      margin: EdgeInsets.only(
                          right: seasonNum == seasonsCount ? 0 : 2),
                      color: rating != null
                          ? AppRatingColors.of(rating)
                          : unratedColor,
                    ),
                  ),
                );
              }),
            ),
          ),
        )
            .animate()
            .fadeIn(
              duration: AppPhysics.houseSpringDuration,
              curve: AppPhysics.houseSpringCurve,
            )
            .scaleX(begin: 0.92, end: 1, curve: AppPhysics.houseSpringCurve),
        const SizedBox(height: 8),
        Wrap(
          spacing: 12,
          runSpacing: 4,
          children: List.generate(seasonsCount, (index) {
            final seasonNum = index + 1;
            final rating = ratings[seasonNum];
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: rating != null
                        ? AppRatingColors.of(rating)
                        : unratedColor,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  'S$seasonNum',
                  style: AppThemes.safeGeist(fontSize: 11, color: subColor),
                ),
              ],
            );
          }),
        ),
      ],
    );
  }
}
