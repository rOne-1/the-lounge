import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants.dart';
import '../providers/media_provider.dart';
import '../widgets/atmospheric_empty_state.dart';
import '../widgets/lounge_folder_name_sheet.dart';
import '../widgets/pressable_scale.dart';
import 'folder_detail_screen.dart';

/// PERS-FOLDERS-1: lists every custom folder with a create action. Tapping
/// a folder opens [FolderDetailScreen].
class FoldersScreen extends ConsumerWidget {
  const FoldersScreen({super.key});

  Future<void> _createFolder(BuildContext context, WidgetRef ref) async {
    final name = await showFolderNamePrompt(
      context,
      sheetTitle: 'New Folder',
      confirmLabel: 'Create',
    );
    if (name == null) return;
    ref.read(mediaProvider.notifier).createFolder(name);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.ambianceColors;
    final folders = ref.watch(mediaProvider.select((s) => s.customFolders));
    final sortedFolders = folders.values.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return Scaffold(
      backgroundColor: colors.base,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: colors.ink),
        title: Text(
          'Folders',
          style: AppThemes.safeGeist(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: colors.ink,
          ),
        ),
        actions: [
          PressableScale(
            key: const ValueKey('create_folder_button'),
            onTap: () => _createFolder(context, ref),
            child: Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Icon(Icons.add_rounded, color: colors.ink),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: sortedFolders.isEmpty
            ? AtmosphericEmptyState(
                icon: Icons.folder_outlined,
                title: 'No folders yet',
                message: 'Create a folder to start curating your own playlists of titles.',
                ctaLabel: 'New Folder',
                onCta: () => _createFolder(context, ref),
              )
            : ListView.separated(
                padding: const EdgeInsets.all(18),
                itemCount: sortedFolders.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final folder = sortedFolders[index];
                  return PressableScale(
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => FolderDetailScreen(folderId: folder.id),
                      ),
                    ),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: colors.card,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: colors.lineRgba),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.folder_rounded, color: colors.acc, size: 22),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  folder.name,
                                  style: AppThemes.safeGeist(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: colors.ink,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${folder.mediaIds.length} title${folder.mediaIds.length == 1 ? '' : 's'}',
                                  style: AppThemes.safeGeist(fontSize: 12, color: colors.sub),
                                ),
                              ],
                            ),
                          ),
                          Icon(Icons.chevron_right_rounded, color: colors.sub),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
