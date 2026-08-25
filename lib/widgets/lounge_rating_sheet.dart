import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants.dart';
import '../models/media_item.dart';
import '../providers/media_provider.dart';
import 'drag_to_dismiss_sheet.dart';
import 'media_image.dart';
import 'pressable_scale.dart';

/// Resolves the "primary" [WatchRecord] for [mediaId]/[seasonNumber] -- the
/// first-watch record in that scope, which is what the rating badge/pill and
/// the auto-prompt-on-Watched flow reason about. Rewatch records are
/// addressed individually via their own `recordedAt` (see
/// [LoungeRatingSheet.recordToEdit]), not through this lookup.
WatchRecord? findPrimaryWatchRecord(
  Map<String, List<WatchRecord>> watchHistory,
  String mediaId,
  int? seasonNumber,
) {
  // Item 61: addWatchRecord resolves against existing shelf keys before
  // writing (see media_provider.dart's _resolveWatchHistoryId), so a
  // not-yet-normalized mediaId here would otherwise miss the prefixed key
  // the record actually landed under.
  final records = watchHistory[resolveStoredId(watchHistory, mediaId) ?? mediaId];
  if (records == null) return null;
  for (final r in records) {
    if (r.seasonNumber == seasonNumber && r.isFirstWatch) return r;
  }
  return null;
}

/// Opens the [LoungeRatingSheet] as a themed, drag-to-dismiss bottom sheet.
///
/// - [isAutoPrompt]: the "just marked Watched" flow -- shows a "Skip" action
///   instead of "Cancel" when nothing is rated yet (SP-4: never blocking).
/// - [recordToEdit]: when set, edits this exact history entry (used by the
///   Watch History timeline) rather than resolving the scope's primary
///   first-watch record.
Future<void> showLoungeRatingSheet(
  BuildContext context,
  WidgetRef ref, {
  required MediaItem item,
  int? seasonNumber,
  bool isAutoPrompt = false,
  WatchRecord? recordToEdit,
}) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: context.ambianceColors.scrim,
    builder: (sheetContext) => DragToDismissSheet(
      isDark: context.ambianceColors.isDark,
      onDismiss: () => Navigator.of(sheetContext).pop(),
      child: LoungeRatingSheet(
        item: item,
        seasonNumber: seasonNumber,
        isAutoPrompt: isAutoPrompt,
        recordToEdit: recordToEdit,
      ),
    ),
  );
}

/// PERS-RATE-1: the 4-tier personal rating selector sheet. Serves three
/// roles through the same widget (tier styling/motion stays uniform per
/// SP-2): the auto-prompt shown on a Watched transition, the manual editor
/// opened from a rating pill, and per-entry editing from the Watch History
/// timeline (via [recordToEdit]).
class LoungeRatingSheet extends ConsumerWidget {
  final MediaItem item;
  final int? seasonNumber;
  final bool isAutoPrompt;
  final WatchRecord? recordToEdit;

  const LoungeRatingSheet({
    super.key,
    required this.item,
    this.seasonNumber,
    this.isAutoPrompt = false,
    this.recordToEdit,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final watchHistory =
        ref.watch(mediaProvider.select((s) => s.watchHistory));
    final resolved =
        recordToEdit ?? findPrimaryWatchRecord(watchHistory, item.id, seasonNumber);
    final notifier = ref.read(mediaProvider.notifier);
    final colors = context.ambianceColors;

    final subtitle = seasonNumber != null
        ? 'Season $seasonNumber'
        : (item.type == MediaType.movie ? 'Movie' : 'TV Show');

    void selectRating(PersonalRating rating) {
      if (resolved != null) {
        notifier.updateWatchRecord(
          item.id,
          resolved.recordedAt,
          resolved.copyWith(rating: rating),
        );
      } else {
        notifier.addWatchRecord(
          item.id,
          WatchRecord(
            rating: rating,
            date: DateTime.now(),
            seasonNumber: seasonNumber,
            isFirstWatch: true,
          ),
        );
      }
      Navigator.of(context).pop();
    }

    void removeRating() {
      if (resolved != null) {
        notifier.deleteWatchRecord(item.id, resolved.recordedAt);
      }
      Navigator.of(context).pop();
    }

    return Container(
      decoration: BoxDecoration(
        color: colors.base,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(color: colors.lineRgba, width: 1),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.6),
            blurRadius: 20,
            spreadRadius: 2,
            offset: Offset(0, -4),
          ),
        ],
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 4,
        bottom: MediaQuery.of(context).padding.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  width: 44,
                  height: 64,
                  child: MediaImage(item: item, fit: BoxFit.cover, showFallbackTitle: false),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: AppThemes.safeGeist(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: colors.ink,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isAutoPrompt ? 'How was it?' : 'Rate $subtitle',
                      style: AppThemes.safeGeist(fontSize: 12, color: colors.sub),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ...PersonalRating.values.map(
            (rating) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _RatingTierRow(
                rating: rating,
                isSelected: resolved?.rating == rating,
                onTap: () => selectRating(rating),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: PressableScale(
                  onTap: resolved != null ? removeRating : () => Navigator.of(context).pop(),
                  child: Container(
                    height: 44,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: colors.card2,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: colors.lineRgba),
                    ),
                    child: Text(
                      resolved != null
                          ? (recordToEdit != null ? 'Delete entry' : 'Remove rating')
                          : (isAutoPrompt ? 'Skip' : 'Cancel'),
                      style: AppThemes.safeGeist(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: resolved != null ? colors.danger : colors.sub,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RatingTierRow extends StatelessWidget {
  final PersonalRating rating;
  final bool isSelected;
  final VoidCallback onTap;

  const _RatingTierRow({
    required this.rating,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.ambianceColors;
    final tierColor = AppRatingColors.of(rating);
    final borderColor = isSelected ? tierColor : colors.lineRgba;
    final bgColor =
        isSelected ? tierColor.withValues(alpha: 0.15) : colors.pill;

    return PressableScale(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppPhysics.houseSpringDuration,
        curve: AppPhysics.houseSpringCurve,
        height: 52,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderColor, width: isSelected ? 1.5 : 1.0),
        ),
        child: Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(shape: BoxShape.circle, color: tierColor),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                rating.label,
                style: AppThemes.safeGeist(
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: colors.ink,
                ),
              ),
            ),
            if (isSelected) Icon(Icons.check_rounded, size: 18, color: tierColor),
          ],
        ),
      ),
    );
  }
}

/// PERS-RATE-1: shows the resolved personal rating for [item]/[seasonNumber],
/// or a "Rate it" invitation once that scope is eligible (Watched for the
/// overall item; season-complete for a season) but still unrated. Renders
/// nothing otherwise -- never forces a decision (SP-4). Tapping opens
/// [LoungeRatingSheet] in manual-edit mode.
///
/// [expanded] switches between two presentations sharing the same
/// eligibility/rating logic:
/// - `false` (default): a small pill, sized for sitting inline among other
///   badges -- used for the per-season pill next to the season selector.
/// - `true`: a full-width, high-contrast banner. Used for the overall-item
///   rating on `DetailScreen`, which used to live inline in the meta-info
///   `Wrap` -- that row's content (and thus the pill's position) varies
///   between movies and TV shows, so the button visibly moved around and
///   blended in with neutral info badges. A fixed-position, unmistakable
///   banner (own row, right after the Watched toggle, styled distinctly
///   from every other action button) fixes both complaints at once.
class PersonalRatingPill extends ConsumerWidget {
  final MediaItem item;
  final int? seasonNumber;
  final bool expanded;

  const PersonalRatingPill({
    super.key,
    required this.item,
    this.seasonNumber,
    this.expanded = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(mediaProvider);
    final record = findPrimaryWatchRecord(state.watchHistory, item.id, seasonNumber);

    final bool isEligible;
    if (seasonNumber == null) {
      isEligible = state.watchedList.containsKey(item.id);
    } else {
      isEligible = state.seasonEndDates[item.id]?[seasonNumber] != null;
    }

    if (record?.rating == null && !isEligible) {
      return const SizedBox.shrink();
    }

    final colors = context.ambianceColors;
    final rating = record?.rating;
    final tierColor = rating != null ? AppRatingColors.of(rating) : colors.acc;
    final label = rating != null ? rating.label : 'Rate it';
    void onTap() =>
        showLoungeRatingSheet(context, ref, item: item, seasonNumber: seasonNumber);

    if (!expanded) {
      return PressableScale(
        onTap: onTap,
        child: AnimatedContainer(
          duration: AppPhysics.houseSpringDuration,
          curve: AppPhysics.houseSpringCurve,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: rating != null ? tierColor.withValues(alpha: 0.16) : colors.pill,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: rating != null ? tierColor.withValues(alpha: 0.6) : colors.lineRgba,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (rating == null) ...[
                Icon(Icons.star_outline_rounded, size: 13, color: tierColor),
                const SizedBox(width: 4),
              ],
              Text(
                label,
                style: AppThemes.safeGeist(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: tierColor,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: PressableScale(
        key: const ValueKey('rate_it_banner'),
        onTap: onTap,
        child: AnimatedContainer(
          duration: AppPhysics.houseSpringDuration,
          curve: AppPhysics.houseSpringCurve,
          width: double.infinity,
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: tierColor.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: tierColor, width: 1.5),
          ),
          alignment: Alignment.center,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                rating == null ? Icons.star_outline_rounded : Icons.star_rounded,
                size: 18,
                color: tierColor,
              ),
              const SizedBox(width: 8),
              Text(
                rating == null ? 'Rate it' : 'Your rating: $label',
                style: AppThemes.safeGeist(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
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
