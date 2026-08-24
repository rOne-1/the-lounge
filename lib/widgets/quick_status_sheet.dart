import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants.dart';
import '../models/hall_space.dart';
import '../models/media_item.dart';
import '../providers/hall_provider.dart';
import '../providers/media_provider.dart';
import 'drag_to_dismiss_sheet.dart';
import 'lounge_folder_picker_sheet.dart';
import 'lounge_toast.dart';
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
class QuickStatusSheet extends ConsumerStatefulWidget {
  final MediaItem item;

  const QuickStatusSheet({
    super.key,
    required this.item,
  });

  @override
  ConsumerState<QuickStatusSheet> createState() => _QuickStatusSheetState();
}

class _QuickStatusSheetState extends ConsumerState<QuickStatusSheet> {
  // HALL-SAVE-1: defaults to whichever Hall is currently active; picking a
  // different one here targets that Hall instead, without switching to it.
  late String _targetHallId;

  @override
  void initState() {
    super.initState();
    _targetHallId = ref.read(hallProvider).activeHallId;
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final hallState = ref.watch(hallProvider);
    final activeHallId = hallState.activeHallId;
    final isCrossHall = _targetHallId != activeHallId;
    final mediaState = ref.watch(mediaProvider);
    final mediaNotifier = ref.read(mediaProvider.notifier);

    // ORG-AGG-1: this title was pulled into the Grand Hall's aggregated
    // view from another Hall, not natively saved here -- status/folder
    // changes are blocked to avoid silently duplicating it into the Grand
    // Hall's own storage (see MediaNotifier._saveToPrefs). Open its actual
    // Hall to edit it there instead.
    final isReadOnly = mediaState.readOnlyMediaIds.contains(item.id);
    final readOnlyHallName = mediaState.readOnlySourceHallName[item.id];

    void guardEdit(BuildContext context, VoidCallback action) {
      if (isReadOnly) {
        LoungeToast.show(
          context,
          readOnlyHallName != null
              ? 'This title lives in $readOnlyHallName -- open it there to change status.'
              : 'This title lives in another Hall -- open it there to change status.',
          type: ToastType.info,
        );
        return;
      }
      action();
    }

    // HALL-SAVE-1: cross-hall taps skip the active-Hall toggle machinery
    // entirely -- this sheet has no reliable read on the target Hall's
    // existing shelf placement, so every tap there is a plain "place it on
    // this shelf", not a toggle, followed by a confirmation toast naming
    // the Hall it went to.
    void handleStatusTap(ArchiveShelfKind shelf, VoidCallback activeHallToggle) {
      if (isCrossHall) {
        final targetHallName =
            hallState.halls.firstWhere((h) => h.id == _targetHallId).name;
        mediaNotifier.saveToHallShelf(
          hallId: _targetHallId,
          item: item,
          shelf: shelf,
        );
        // Show the toast before popping -- Overlay.of walks the element
        // tree, and this sheet's own context is no longer safe to use for
        // that once Navigator.pop has started tearing it down.
        LoungeToast.show(
          context,
          'Added to ${shelf.label} in $targetHallName.',
          type: ToastType.success,
        );
        Navigator.of(context).pop();
        return;
      }
      guardEdit(context, () {
        activeHallToggle();
        Navigator.of(context).pop();
      });
    }

    // HALL-SAVE-1: mediaState only ever reflects the active Hall -- once a
    // different target Hall is picked, this sheet can't know that Hall's
    // real shelf placement without loading it, so no pill shows as active
    // and every tap is a plain "add to this shelf there" rather than a
    // toggle.
    final inWatchlist = !isCrossHall && mediaState.watchlist.containsKey(item.id);
    final inSaved = !isCrossHall && mediaState.maybeList.containsKey(item.id);
    final inWatching = !isCrossHall && mediaState.watchingList.containsKey(item.id);
    final inOnHold = !isCrossHall && mediaState.onHoldList.containsKey(item.id);
    final inDropped = !isCrossHall && mediaState.droppedList.containsKey(item.id);
    final inWatched = !isCrossHall && mediaState.watchedList.containsKey(item.id);
    // Item 1: an optimistic TV Watched/Watching placement not yet
    // confirmed by real per-episode data.
    final isPendingConfirmation =
        mediaState.pendingWatchConfirmation.contains(item.id);

    // Active status details
    String? activeStatusLabel;
    IconData? activeStatusIcon;
    Color? activeBadgeColor;

    if (inWatching) {
      activeStatusLabel =
          isPendingConfirmation ? 'Watching · Confirming' : 'Watching';
      activeStatusIcon = Icons.play_circle_fill_rounded;
      activeBadgeColor = AppStatusColors.watching;
    } else if (inWatchlist) {
      activeStatusLabel = 'Watchlist';
      activeStatusIcon = Icons.bookmark_rounded;
      activeBadgeColor = AppStatusColors.watchlist;
    } else if (inSaved) {
      activeStatusLabel = 'Saved';
      activeStatusIcon = Icons.archive_rounded;
      activeBadgeColor = AppStatusColors.save;
    } else if (inWatched) {
      activeStatusLabel =
          isPendingConfirmation ? 'Watched · Confirming' : 'Watched';
      activeStatusIcon = Icons.check_circle_rounded;
      activeBadgeColor = AppStatusColors.watched;
    } else if (inOnHold) {
      activeStatusLabel = 'On-Hold';
      activeStatusIcon = Icons.pause_circle_filled_rounded;
      activeBadgeColor = AppStatusColors.onHold;
    } else if (inDropped) {
      activeStatusLabel = 'Dropped';
      activeStatusIcon = Icons.remove_circle_rounded;
      activeBadgeColor = AppStatusColors.dropped;
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
        top: 10,
        bottom: MediaQuery.of(context).padding.bottom + 14,
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
          const SizedBox(height: 10),
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
                    showFallbackTitle: false,
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
          if (isReadOnly) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: context.ambianceColors.pill,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: context.ambianceColors.lineRgba),
              ),
              child: Row(
                children: [
                  Icon(Icons.lock_outline_rounded,
                      size: 14, color: context.ambianceColors.sub),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      readOnlyHallName != null
                          ? 'From $readOnlyHallName -- view only here.'
                          : 'From another Hall -- view only here.',
                      style: AppThemes.safeGeist(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                        color: context.ambianceColors.sub,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 8),
          // HALL-SAVE-1: pick which Hall the status pills below act on --
          // defaults to the active Hall, no switching required to target
          // another one.
          SizedBox(
            height: 28,
            child: ListView.separated(
              key: const ValueKey('quick_status_hall_picker'),
              scrollDirection: Axis.horizontal,
              itemCount: hallState.halls.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final hall = hallState.halls[index];
                final isSelected = hall.id == _targetHallId;
                return Material(
                  color: Colors.transparent,
                  child: InkWell(
                    key: ValueKey('quick_status_hall_${hall.id}'),
                    onTap: () => setState(() => _targetHallId = hall.id),
                    borderRadius: BorderRadius.circular(999),
                    child: AnimatedContainer(
                      duration: AppPhysics.houseSpringDuration,
                      curve: AppPhysics.houseSpringCurve,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? context.ambianceColors.acc.withValues(alpha: 0.15)
                            : context.ambianceColors.pill,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: isSelected
                              ? context.ambianceColors.acc
                              : context.ambianceColors.lineRgba,
                          width: isSelected ? 1.5 : 1.0,
                        ),
                      ),
                      child: Text(
                        hall.name,
                        style: AppThemes.safeGeist(
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                          color: isSelected
                              ? context.ambianceColors.acc
                              : context.ambianceColors.sub,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          Divider(
            color: context.ambianceColors.lineRgba,
            height: 1,
          ),
          const SizedBox(height: 8),
          // 6 Status Option Pills (Grid of 2 columns)
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 3.1,
            children: [
              _StatusPill(
                label: 'Watchlist',
                icon: inWatchlist
                    ? Icons.bookmark_rounded
                    : Icons.bookmark_outline_rounded,
                isActive: inWatchlist,
                activeColor: AppStatusColors.watchlist,
                onTap: () => handleStatusTap(
                    ArchiveShelfKind.watchlist, () => mediaNotifier.toggleWatchlist(item)),
              ),
              _StatusPill(
                label: 'Saved',
                icon: inSaved ? Icons.archive_rounded : Icons.archive_outlined,
                isActive: inSaved,
                activeColor: AppStatusColors.save,
                onTap: () => handleStatusTap(
                    ArchiveShelfKind.saved, () => mediaNotifier.toggleMaybe(item)),
              ),
              _StatusPill(
                label: inWatching && isPendingConfirmation
                    ? 'Watching · Confirming'
                    : 'Watching',
                icon: inWatching
                    ? Icons.play_circle_fill_rounded
                    : Icons.play_circle_outline_rounded,
                isActive: inWatching,
                activeColor: AppStatusColors.watching,
                onTap: () => handleStatusTap(
                    ArchiveShelfKind.watching, () => mediaNotifier.toggleWatching(item)),
              ),
              _StatusPill(
                label: 'On-Hold',
                icon: inOnHold
                    ? Icons.pause_circle_filled_rounded
                    : Icons.pause_circle_outline_rounded,
                isActive: inOnHold,
                activeColor: AppStatusColors.onHold,
                onTap: () => handleStatusTap(
                    ArchiveShelfKind.onHold, () => mediaNotifier.toggleOnHold(item)),
              ),
              _StatusPill(
                label: 'Dropped',
                icon: inDropped
                    ? Icons.remove_circle_rounded
                    : Icons.remove_circle_outline_rounded,
                isActive: inDropped,
                activeColor: AppStatusColors.dropped,
                onTap: () => handleStatusTap(
                    ArchiveShelfKind.dropped, () => mediaNotifier.toggleDropped(item)),
              ),
              _StatusPill(
                label: inWatched && isPendingConfirmation
                    ? 'Watched · Confirming'
                    : 'Watched',
                icon: inWatched
                    ? Icons.check_circle_rounded
                    : Icons.check_circle_outline_rounded,
                isActive: inWatched,
                activeColor: AppStatusColors.watched,
                onTap: () => handleStatusTap(ArchiveShelfKind.watched, () {
                  if (inWatched) {
                    mediaNotifier.removeFromWatchedList(item.id);
                  } else {
                    mediaNotifier.addToWatchedList(item);
                  }
                }),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // PERS-FOLDERS-1: status-independent, deliberately separate from
          // the 6 status pills above -- folders are a different axis
          // (curation, not status) from Watchlist/Saved/etc.
          Material(
            color: Colors.transparent,
            child: InkWell(
              key: const ValueKey('quick_status_add_to_folder'),
              onTap: () => guardEdit(context, () {
                Navigator.of(context).pop();
                showFolderPickerSheet(context, ref,
                    mediaId: item.id, mediaTitle: item.title);
              }),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: context.ambianceColors.pill,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: context.ambianceColors.lineRgba),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.folder_outlined,
                        size: 16, color: context.ambianceColors.ink),
                    const SizedBox(width: 8),
                    Text(
                      'Add to Folder',
                      style: AppThemes.safeGeist(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: context.ambianceColors.ink,
                      ),
                    ),
                  ],
                ),
              ),
            ),
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
    final borderColor =
        isActive ? activeColor : context.ambianceColors.lineRgba;
    final bgColor = isActive
        ? activeColor.withValues(alpha: 0.15)
        : context.ambianceColors.pill;
    final contentColor = isActive ? activeColor : context.ambianceColors.ink;

    // BETA3-A11Y-1: one explicit merged announcement per status pill
    // ("Watching, selected" / "Watching") instead of the icon (no label),
    // Text, and conditional checkmark icon being read as separate
    // disconnected fragments.
    return Semantics(
      label: label,
      selected: isActive,
      button: true,
      excludeSemantics: true,
      child: Material(
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
      ),
    );
  }
}
