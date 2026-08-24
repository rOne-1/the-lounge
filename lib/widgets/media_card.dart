import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants.dart';
import '../models/media_item.dart';
import '../providers/media_provider.dart';
import '../screens/detail_screen.dart';
import 'media_image.dart';
import 'pressable_scale.dart';
import 'quick_status_sheet.dart';
import 'status_pulse_ring.dart';

/// The single canonical media poster card used across Home, Browse, Your
/// Space, Calendar, Media List, and Collection. Consolidates the gesture
/// handling (tap-to-open, long-press quick-status), the house-spring press
/// physics, the theme-token bevel/rating/status treatment, and the optional
/// title/subtitle caption into one implementation so no screen reinvents it.
class MediaCard extends ConsumerWidget {
  final MediaItem item;
  final double? width;
  final double? height;
  final double borderRadius;
  final bool isDark;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool showTitle;
  final bool showSubtitle;
  final String? customSubtitle;

  /// An additional overlay drawn on top of the poster (e.g. a season pill,
  /// an air-date badge) — composed alongside, not instead of, the
  /// standardized rating badge and status indicator below.
  final Widget? badge;
  final BoxFit fit;

  /// Shows the ★ rating badge (ambiance.starRating) when the item has a
  /// rating. Disable for contexts that already surface rating elsewhere.
  final bool showRatingBadge;

  /// Shows the current watch-status indicator (watchlist/saved/watching/
  /// watched), pulse-highlighted via [StatusPulseRing] when it changes.
  final bool showStatusIndicator;

  const MediaCard({
    super.key,
    required this.item,
    this.width,
    this.height,
    this.borderRadius = 11.0,
    required this.isDark,
    this.onTap,
    this.onLongPress,
    this.showTitle = false,
    this.showSubtitle = false,
    this.customSubtitle,
    this.badge,
    this.fit = BoxFit.cover,
    this.showRatingBadge = true,
    this.showStatusIndicator = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subColor = context.ambianceColors.sub;
    final inkColor = context.ambianceColors.ink;
    final phColor = context.ambianceColors.ph;
    final lineRgba = context.ambianceColors.lineRgba;
    final surfaceHighlight = context.ambianceColors.surfaceHighlight;

    final mediaState = ref.watch(mediaProvider);
    final statusInfo = showStatusIndicator ? _resolveStatus(mediaState) : null;

    final posterWidget = OpenContainer(
      transitionDuration: AppPhysics.houseSpringDuration,
      closedElevation: 0,
      openElevation: 0,
      closedColor: Colors.transparent,
      openColor: context.ambianceColors.base,
      middleColor: Colors.transparent,
      closedShape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      closedBuilder: (context, openContainer) {
        // BETA3-A11Y-2: one merged announcement (title, year, medium type,
        // rating) instead of an unlabeled image -- MediaCard is the core
        // tile across every rail/grid/list in the app.
        final yearStr = item.releaseOrAirDate?.year != null
            ? ', ${item.releaseOrAirDate!.year}'
            : '';
        final typeStr = item.type == MediaType.movie ? 'Movie' : 'TV Show';
        final ratingStr = (showRatingBadge && item.rating > 0)
            ? ', rated ${item.rating.toStringAsFixed(1)}'
            : '';
        final statusStr = statusInfo != null
            ? ', ${statusInfo.label}${statusInfo.isPending ? ', confirming' : ''}'
            : '';
        final semanticLabel =
            '${item.title}$yearStr, $typeStr$ratingStr$statusStr';

        return PressableScale(
          onTap: onTap ?? openContainer,
          onLongPress: onLongPress ??
              () {
                // Long-pressing a card near an active text field (e.g.
                // Search's query box) must not leave the keyboard open
                // behind the status sheet -- unfocus unconditionally; a
                // no-op when nothing is focused.
                FocusScope.of(context).unfocus();
                showQuickStatusSheet(context, ref, item);
              },
          child: Semantics(
            label: semanticLabel,
            excludeSemantics: true,
            child: Container(
              width: width,
              height: height,
              decoration: BoxDecoration(
                color: phColor,
                borderRadius: BorderRadius.circular(borderRadius),
                border: Border.all(color: lineRgba),
                boxShadow: [
                  ...context.ambianceColors.cardShadow,
                  BoxShadow(
                    color: surfaceHighlight,
                    blurRadius: 0,
                    spreadRadius: 0,
                    offset: const Offset(0, 1),
                    blurStyle: BlurStyle.inner,
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  MediaImage(
                    item: item,
                    fit: fit,
                    showFallbackTitle: !showTitle,
                  ),
                  if (showRatingBadge && item.rating > 0)
                    Positioned(
                      top: 6,
                      right: 6,
                      child: _RatingBadge(rating: item.rating),
                    ),
                  if (statusInfo != null)
                    Positioned(
                      top: 6,
                      left: 6,
                      child: StatusPulseRing(
                        isSelected: true,
                        accentColor: statusInfo.color,
                        borderRadius: 8,
                        child: _StatusChip(
                          icon: statusInfo.icon,
                          color: statusInfo.color,
                          isPending: statusInfo.isPending,
                        ),
                      ),
                    ),
                  if (badge != null) badge!,
                ],
              ),
            ),
          ),
        );
      },
      openBuilder: (context, _) =>
          DetailScreen(id: item.prefixedId, initialItem: item),
    );

    if (!showTitle && !showSubtitle) {
      return posterWidget;
    }

    final subtitleText = customSubtitle ??
        (item.genres.isNotEmpty
            ? item.genres.first
            : (item.type == MediaType.movie ? 'Movie' : 'TV Show'));

    return SizedBox(
      width: width,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          posterWidget,
          if (showTitle) ...[
            const SizedBox(height: 6),
            Text(
              item.title,
              style: AppThemes.safeGeist(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: inkColor,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          if (showSubtitle) ...[
            const SizedBox(height: 2),
            Text(
              subtitleText,
              style: AppThemes.safeGeist(
                fontSize: 11,
                fontWeight: FontWeight.w400,
                color: subColor,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }

  _StatusInfo? _resolveStatus(MediaState mediaState) {
    // Item 1: an optimistic TV Watched/Watching placement not yet
    // confirmed by real per-episode data.
    final isPending = mediaState.pendingWatchConfirmation.contains(item.id);
    if (mediaState.watchingList.containsKey(item.id)) {
      return _StatusInfo(
          Icons.play_circle_fill_rounded, AppStatusColors.watching, 'Watching',
          isPending: isPending);
    }
    if (mediaState.watchlist.containsKey(item.id)) {
      return _StatusInfo(
          Icons.bookmark_rounded, AppStatusColors.watchlist, 'Watchlist');
    }
    if (mediaState.maybeList.containsKey(item.id)) {
      return _StatusInfo(Icons.archive_rounded, AppStatusColors.save, 'Saved');
    }
    if (mediaState.watchedList.containsKey(item.id)) {
      return _StatusInfo(
          Icons.check_circle_rounded, AppStatusColors.watched, 'Watched',
          isPending: isPending);
    }
    return null;
  }
}

class _StatusInfo {
  final IconData icon;
  final Color color;
  final String label;
  final bool isPending;
  const _StatusInfo(this.icon, this.color, this.label,
      {this.isPending = false});
}

class _StatusChip extends StatelessWidget {
  final IconData icon;
  final Color color;

  /// Item 1: a TV show's Watched/Watching placement can still be the
  /// optimistic fallback guess, not yet confirmed by real per-episode
  /// data -- swaps to a sync glyph at reduced opacity instead of silently
  /// showing a status that might still flip once the real data lands.
  final bool isPending;

  const _StatusChip({
    required this.icon,
    required this.color,
    this.isPending = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: context.ambianceColors.scrim,
        shape: BoxShape.circle,
      ),
      child: Opacity(
        opacity: isPending ? 0.75 : 1.0,
        child: Icon(
          isPending ? Icons.sync_rounded : icon,
          size: 12,
          color: color,
        ),
      ),
    );
  }
}

class _RatingBadge extends StatelessWidget {
  final double rating;

  const _RatingBadge({required this.rating});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: context.ambianceColors.scrim,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.star, size: 10, color: context.ambianceColors.starRating),
          const SizedBox(width: 3),
          Text(
            rating.toStringAsFixed(1),
            style: AppThemes.safeGeist(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
