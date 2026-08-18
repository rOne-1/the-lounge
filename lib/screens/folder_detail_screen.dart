import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants.dart';
import '../models/media_item.dart';
import '../providers/media_provider.dart';
import '../providers/navigation_provider.dart';
import '../widgets/atmospheric_empty_state.dart';
import '../widgets/lounge_dialog.dart';
import '../widgets/lounge_folder_name_sheet.dart';
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

/// PERS-FOLDERS-1: view/reorder/rename/delete a single custom folder.
/// Folders only store media IDs (locked spec), not item snapshots, so each
/// row resolves its display data from whichever status pile already has it
/// (instant, no fetch) or falls back to [mediaDetailsProvider] for titles
/// that were added to a folder without ever being in a status pile.
class FolderDetailScreen extends ConsumerWidget {
  final String folderId;

  const FolderDetailScreen({super.key, required this.folderId});

  Future<void> _rename(BuildContext context, WidgetRef ref, String currentName) async {
    final name = await showFolderNamePrompt(
      context,
      sheetTitle: 'Rename Folder',
      initialValue: currentName,
      confirmLabel: 'Save',
    );
    if (name == null) return;
    ref.read(mediaProvider.notifier).renameFolder(folderId, name);
  }

  Future<void> _delete(BuildContext context, WidgetRef ref, String folderName) async {
    final confirmed = await LoungeDialog.show<bool>(
      context,
      title: 'Delete "$folderName"?',
      message: 'This removes the folder itself. Titles inside it are not affected -- '
          'they stay in whatever status piles they already belong to.',
      actions: [
        LoungeDialogAction(
          label: 'Cancel',
          onPressed: () => Navigator.of(context).pop(false),
        ),
        LoungeDialogAction(
          label: 'Delete',
          style: LoungeDialogActionStyle.destructive,
          onPressed: () => Navigator.of(context).pop(true),
        ),
      ],
    );
    if (confirmed == true && context.mounted) {
      ref.read(mediaProvider.notifier).deleteFolder(folderId);
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.ambianceColors;
    final folder = ref.watch(mediaProvider.select((s) => s.customFolders[folderId]));

    if (folder == null) {
      // Deleted from elsewhere (or a stale route) -- pop back rather than
      // render a broken screen for a folder that no longer exists.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (Navigator.of(context).canPop()) Navigator.of(context).pop();
      });
      return const SizedBox.shrink();
    }

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
                      color: colors.isDark
                          ? const Color(0x18000000)
                          : const Color(0x06000000),
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
          folder.name,
          style: GoogleFonts.bodoniModa(
            fontSize: 22,
            fontWeight: FontWeight.w500,
            fontStyle: FontStyle.italic,
            color: colors.ink,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 6.0),
            child: Center(
              child: PressableScale(
                key: const ValueKey('rename_folder_button'),
                onTap: () => _rename(context, ref, folder.name),
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: colors.card,
                    shape: BoxShape.circle,
                    border: Border.all(color: colors.lineRgba),
                  ),
                  child: Icon(Icons.edit_outlined, color: colors.ink, size: 18),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 14.0),
            child: Center(
              child: PressableScale(
                key: const ValueKey('delete_folder_button'),
                onTap: () => _delete(context, ref, folder.name),
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: colors.card,
                    shape: BoxShape.circle,
                    border: Border.all(color: colors.lineRgba),
                  ),
                  child: Icon(Icons.delete_outline_rounded, color: colors.danger, size: 18),
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: folder.mediaIds.isEmpty
            ? AtmosphericEmptyState(
                icon: Icons.folder_open_outlined,
                title: 'This folder is empty',
                message: 'Use "Add to Folder" from any title to start curating this playlist.',
                ctaLabel: 'Discover Titles',
                onCta: () {
                  Navigator.of(context).popUntil((route) => route.isFirst);
                  ref.read(navigationProvider.notifier).setTab(AppTab.discover);
                },
              )
            : ReorderableListView.builder(
                buildDefaultDragHandles: false,
                padding: const EdgeInsets.fromLTRB(14, 8, 14, 24),
                itemCount: folder.mediaIds.length,
                // onReorderItem's newIndex already accounts for the
                // removed item at oldIndex (unlike the deprecated
                // onReorder, which required manual index adjustment).
                onReorderItem: (oldIndex, newIndex) {
                  final newOrder = List<String>.from(folder.mediaIds);
                  final id = newOrder.removeAt(oldIndex);
                  newOrder.insert(newIndex, id);
                  ref.read(mediaProvider.notifier).reorderFolderItems(folderId, newOrder);
                },
                itemBuilder: (context, index) {
                  final mediaId = folder.mediaIds[index];
                  return _FolderItemTile(
                    key: ValueKey('folder_item_$mediaId'),
                    mediaId: mediaId,
                    index: index,
                    onRemove: () =>
                        ref.read(mediaProvider.notifier).removeFromFolder(folderId, mediaId),
                  );
                },
              ),
      ),
    );
  }
}

class _FolderItemTile extends ConsumerWidget {
  final String mediaId;
  final int index;
  final VoidCallback onRemove;

  const _FolderItemTile({
    super.key,
    required this.mediaId,
    required this.index,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final known = _findKnownItem(ref.watch(mediaProvider), mediaId);
    if (known != null) {
      return _buildRow(context, ref, known);
    }

    final asyncItem = ref.watch(mediaDetailsProvider(mediaId));
    return asyncItem.when(
      data: (item) => item != null
          ? _buildRow(context, ref, item)
          : _buildMissingRow(context),
      loading: () => _buildLoadingRow(context),
      error: (_, __) => _buildMissingRow(context),
    );
  }

  Widget _buildRow(BuildContext context, WidgetRef ref, MediaItem item) {
    final colors = context.ambianceColors;
    return Container(
      key: ValueKey('folder_row_$mediaId'),
      margin: const EdgeInsets.only(bottom: 10),
      child: PressableScale(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => DetailScreen(id: item.prefixedId, initialItem: item),
          ),
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
                      item.type == MediaType.movie ? 'Movie' : 'TV Show',
                      style: AppThemes.safeGeist(fontSize: 11, color: colors.sub),
                    ),
                  ],
                ),
              ),
              PressableScale(
                onTap: onRemove,
                child: Icon(Icons.close_rounded, size: 18, color: colors.sub),
              ),
              const SizedBox(width: 12),
              ReorderableDragStartListener(
                index: index,
                child: Icon(Icons.drag_handle_rounded, size: 20, color: colors.sub),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingRow(BuildContext context) {
    final colors = context.ambianceColors;
    return Container(
      key: ValueKey('folder_row_loading_$mediaId'),
      margin: const EdgeInsets.only(bottom: 10),
      height: 84,
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.lineRgba),
      ),
    );
  }

  Widget _buildMissingRow(BuildContext context) {
    final colors = context.ambianceColors;
    return Container(
      key: ValueKey('folder_row_missing_$mediaId'),
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.lineRgba),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Title unavailable',
              style: AppThemes.safeGeist(fontSize: 13, color: colors.sub),
            ),
          ),
          PressableScale(
            onTap: onRemove,
            child: Icon(Icons.close_rounded, size: 18, color: colors.sub),
          ),
          const SizedBox(width: 12),
          ReorderableDragStartListener(
            index: index,
            child: Icon(Icons.drag_handle_rounded, size: 20, color: colors.sub),
          ),
        ],
      ),
    );
  }
}
