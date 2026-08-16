import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants.dart';
import '../models/media_item.dart';
import '../providers/media_provider.dart';
import 'drag_to_dismiss_sheet.dart';
import 'media_image.dart';

/// Helper function to open the [QuickStatusSheet] bottom sheet modal.
Future<void> showQuickStatusSheet(
  BuildContext context,
  WidgetRef ref,
  MediaItem item,
) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: context.ambianceColors.scrim,
    builder: (context) => DragToDismissSheet(
      isDark: context.ambianceColors.isDark,
      onDismiss: () => Navigator.of(context).pop(),
      child: QuickStatusSheet(item: item),
    ),
  );
}

/// A modal selector widget displaying the 6 status options for a [MediaItem]
/// styled with Screening Room aesthetics (dark background #161312, gold active indicator borders, icon + label pills).
class QuickStatusSheet extends ConsumerWidget {
  final MediaItem item;

  const QuickStatusSheet({
    super.key,
    required this.item,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mediaState = ref.watch(mediaProvider);
    final mediaNotifier = ref.read(mediaProvider.notifier);

    final inWatchlist = mediaState.watchlist.containsKey(item.id);
    final inSaved = mediaState.maybeList.containsKey(item.id);
    final inWatching = mediaState.watchingList.containsKey(item.id);
    final inOnHold = mediaState.onHoldList.containsKey(item.id);
    final inDropped = mediaState.droppedList.containsKey(item.id);
    final inWatched = mediaState.watchedList.containsKey(item.id);

    // Active status details
    String? activeStatusLabel;
    IconData? activeStatusIcon;
    Color? activeBadgeColor;

    if (inWatching) {
      activeStatusLabel = 'Watching';
      activeStatusIcon = Icons.play_circle_fill_rounded;
      activeBadgeColor = context.ambianceColors.statusWatching;
    } else if (inWatchlist) {
      activeStatusLabel = 'Watchlist';
      activeStatusIcon = Icons.bookmark_rounded;
      activeBadgeColor = context.ambianceColors.statusWatchlist;
    } else if (inSaved) {
      activeStatusLabel = 'Saved';
      activeStatusIcon = Icons.archive_rounded;
      activeBadgeColor = context.ambianceColors.statusSave;
    } else if (inWatched) {
      activeStatusLabel = 'Watched';
      activeStatusIcon = Icons.check_circle_rounded;
      activeBadgeColor = context.ambianceColors.statusWatched;
    } else if (inOnHold) {
      activeStatusLabel = 'On-Hold';
      activeStatusIcon = Icons.pause_circle_filled_rounded;
      activeBadgeColor = context.ambianceColors.statusOnHold;
    } else if (inDropped) {
      activeStatusLabel = 'Dropped';
      activeStatusIcon = Icons.remove_circle_rounded;
      activeBadgeColor = context.ambianceColors.statusDropped;
    }

    final yearStr = item.releaseOrAirDate?.year != null
        ? ' · ${item.releaseOrAirDate!.year}'
        : '';

    return Container(
      decoration: BoxDecoration(
        color: context.ambianceColors.base,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(
          color: context.ambianceColors.lineRgba,
          width: 1,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.6),
            blurRadius: 20,
            spreadRadius: 2,
            offset: Offset(0, -4),
          )
        ],
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 12,
        bottom: MediaQuery.of(context).padding.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: context.ambianceColors.sub.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Media Header & Current Active Status Badge
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  width: 44,
                  height: 64,
                  child: MediaImage(
                    item: item,
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
                      style: AppThemes.safeGeist(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: context.ambianceColors.ink,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${item.type == MediaType.movie ? 'Movie' : 'TV Show'}$yearStr',
                      style: AppThemes.safeGeist(
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: context.ambianceColors.sub,
                      ),
                    ),
                    const SizedBox(height: 6),
                    // Active Status Badge
                    if (activeStatusLabel != null && activeBadgeColor != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: activeBadgeColor.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: activeBadgeColor.withValues(alpha: 0.6),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              activeStatusIcon,
                              size: 12,
                              color: activeBadgeColor,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              activeStatusLabel,
                              style: AppThemes.safeGeist(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: activeBadgeColor,
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: context.ambianceColors.pill,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: context.ambianceColors.lineRgba,
                            width: 1,
                          ),
                        ),
                        child: Text(
                          'No Status',
                          style: AppThemes.safeGeist(
                            fontSize: 11,
                            fontWeight: FontWeight.w400,
                            color: context.ambianceColors.sub,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Divider(
            color: context.ambianceColors.lineRgba,
            height: 1,
          ),
          const SizedBox(height: 16),
          // 6 Status Option Pills (Grid of 2 columns)
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 2.7,
            children: [
              _StatusPill(
                label: 'Watchlist',
                icon: inWatchlist
                    ? Icons.bookmark_rounded
                    : Icons.bookmark_outline_rounded,
                isActive: inWatchlist,
                activeColor: context.ambianceColors.statusWatchlist,
                onTap: () {
                  mediaNotifier.toggleWatchlist(item);
                  Navigator.of(context).pop();
                },
              ),
              _StatusPill(
                label: 'Saved',
                icon: inSaved ? Icons.archive_rounded : Icons.archive_outlined,
                isActive: inSaved,
                activeColor: context.ambianceColors.statusSave,
                onTap: () {
                  mediaNotifier.toggleMaybe(item);
                  Navigator.of(context).pop();
                },
              ),
              _StatusPill(
                label: 'Watching',
                icon: inWatching
                    ? Icons.play_circle_fill_rounded
                    : Icons.play_circle_outline_rounded,
                isActive: inWatching,
                activeColor: context.ambianceColors.statusWatching,
                onTap: () {
                  mediaNotifier.toggleWatching(item);
                  Navigator.of(context).pop();
                },
              ),
              _StatusPill(
                label: 'On-Hold',
                icon: inOnHold
                    ? Icons.pause_circle_filled_rounded
                    : Icons.pause_circle_outline_rounded,
                isActive: inOnHold,
                activeColor: context.ambianceColors.statusOnHold,
                onTap: () {
                  mediaNotifier.toggleOnHold(item);
                  Navigator.of(context).pop();
                },
              ),
              _StatusPill(
                label: 'Dropped',
                icon: inDropped
                    ? Icons.remove_circle_rounded
                    : Icons.remove_circle_outline_rounded,
                isActive: inDropped,
                activeColor: context.ambianceColors.statusDropped,
                onTap: () {
                  mediaNotifier.toggleDropped(item);
                  Navigator.of(context).pop();
                },
              ),
              _StatusPill(
                label: 'Watched',
                icon: inWatched
                    ? Icons.check_circle_rounded
                    : Icons.check_circle_outline_rounded,
                isActive: inWatched,
                activeColor: context.ambianceColors.statusWatched,
                onTap: () {
                  if (inWatched) {
                    mediaNotifier.removeFromWatchedList(item.id);
                  } else {
                    mediaNotifier.addToWatchedList(item);
                  }
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isActive;
  final Color activeColor;
  final VoidCallback onTap;

  const _StatusPill({
    required this.label,
    required this.icon,
    required this.isActive,
    required this.activeColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor = isActive
        ? activeColor
        : context.ambianceColors.lineRgba;
    final bgColor = isActive
        ? activeColor.withValues(alpha: 0.15)
        : context.ambianceColors.pill;
    final contentColor =
        isActive ? activeColor : context.ambianceColors.ink;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        splashColor: context.ambianceColors.acc.withValues(alpha: 0.2),
        child: AnimatedContainer(
          duration: AppPhysics.houseSpringDuration,
          curve: AppPhysics.houseSpringCurve,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: borderColor,
              width: isActive ? 1.5 : 1.0,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: contentColor,
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  label,
                  style: AppThemes.safeGeist(
                    fontSize: 13,
                    fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                    color: contentColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (isActive) ...[
                const SizedBox(width: 4),
                Icon(
                  Icons.check_rounded,
                  size: 14,
                  color: activeColor,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
