import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants.dart';
import '../models/media_item.dart';
import '../providers/media_provider.dart';
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
    barrierColor: Colors.black.withValues(alpha: 0.6),
    builder: (context) => QuickStatusSheet(item: item),
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
    Color activeBadgeColor = const Color(0xFFCBA86A);

    if (inWatching) {
      activeStatusLabel = 'Watching';
      activeStatusIcon = Icons.play_circle_fill_rounded;
      activeBadgeColor = AppColors.srStatusWatching;
    } else if (inWatchlist) {
      activeStatusLabel = 'Watchlist';
      activeStatusIcon = Icons.bookmark_rounded;
      activeBadgeColor = AppColors.srStatusWatchlist;
    } else if (inSaved) {
      activeStatusLabel = 'Saved';
      activeStatusIcon = Icons.archive_rounded;
      activeBadgeColor = AppColors.srStatusSave;
    } else if (inWatched) {
      activeStatusLabel = 'Watched';
      activeStatusIcon = Icons.check_circle_rounded;
      activeBadgeColor = AppColors.srStatusWatched;
    } else if (inOnHold) {
      activeStatusLabel = 'On-Hold';
      activeStatusIcon = Icons.pause_circle_filled_rounded;
      activeBadgeColor = const Color(0xFFD6A24D);
    } else if (inDropped) {
      activeStatusLabel = 'Dropped';
      activeStatusIcon = Icons.remove_circle_rounded;
      activeBadgeColor = const Color(0xFFC76464);
    }

    final yearStr = item.releaseOrAirDate?.year != null
        ? ' · ${item.releaseOrAirDate!.year}'
        : '';

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF161312),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(
          color: const Color.fromRGBO(201, 168, 106, 0.2),
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
                color: const Color.fromRGBO(239, 230, 216, 0.3),
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
                        color: AppColors.srInk,
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
                        color: AppColors.srSub,
                      ),
                    ),
                    const SizedBox(height: 6),
                    // Active Status Badge
                    if (activeStatusLabel != null)
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
                          color: AppColors.srPill,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color.fromRGBO(239, 230, 216, 0.15),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          'No Status',
                          style: AppThemes.safeGeist(
                            fontSize: 11,
                            fontWeight: FontWeight.w400,
                            color: AppColors.srSub,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Divider(
            color: Color.fromRGBO(201, 168, 106, 0.16),
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
                onTap: () {
                  mediaNotifier.toggleWatchlist(item);
                  Navigator.of(context).pop();
                },
              ),
              _StatusPill(
                label: 'Saved',
                icon: inSaved ? Icons.archive_rounded : Icons.archive_outlined,
                isActive: inSaved,
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
  final VoidCallback onTap;

  const _StatusPill({
    required this.label,
    required this.icon,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Gold active indicator borders (#CBA86A / AppColors.srAcc)
    final borderColor = isActive
        ? const Color(0xFFCBA86A)
        : const Color.fromRGBO(201, 168, 106, 0.16);
    final bgColor = isActive
        ? const Color.fromRGBO(203, 168, 106, 0.15)
        : AppColors.srPill;
    final contentColor =
        isActive ? const Color(0xFFCBA86A) : AppColors.srInk;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        splashColor: const Color.fromRGBO(201, 168, 106, 0.2),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
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
                const Icon(
                  Icons.check_rounded,
                  size: 14,
                  color: Color(0xFFCBA86A),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
