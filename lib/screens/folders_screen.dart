import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
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
          'Folders',
          style: GoogleFonts.bodoniModa(
            fontSize: 22,
            fontWeight: FontWeight.w500,
            fontStyle: FontStyle.italic,
            color: colors.ink,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 14.0),
            child: Center(
              child: PressableScale(
                key: const ValueKey('create_folder_button'),
                onTap: () => _createFolder(context, ref),
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
                  child: Icon(Icons.add_rounded, color: colors.ink, size: 22),
                ),
              ),
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
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final folder = sortedFolders[index];
                  final count = folder.mediaIds.length;
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
                        borderRadius: BorderRadius.circular(18),
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
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: colors.acc.withValues(alpha: 0.16),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: colors.acc.withValues(alpha: 0.35),
                                width: 1.0,
                              ),
                            ),
                            child: Icon(
                              Icons.folder_rounded,
                              color: colors.acc,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  folder.name,
                                  style: AppThemes.safeGeist(
                                    fontSize: 15.5,
                                    fontWeight: FontWeight.w600,
                                    color: colors.ink,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '$count title${count == 1 ? '' : 's'}',
                                  style: AppThemes.safeGeist(
                                    fontSize: 12.5,
                                    color: colors.sub,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.chevron_right_rounded,
                            color: colors.sub.withValues(alpha: 0.6),
                            size: 22,
                          ),
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
