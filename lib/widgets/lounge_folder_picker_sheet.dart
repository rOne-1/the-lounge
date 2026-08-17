import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants.dart';
import '../providers/media_provider.dart';
import 'drag_to_dismiss_sheet.dart';
import 'lounge_text_field.dart';
import 'pressable_scale.dart';

/// PERS-FOLDERS-1: opens the "Add to Folder" picker as a themed,
/// drag-to-dismiss bottom sheet.
Future<void> showFolderPickerSheet(
  BuildContext context,
  WidgetRef ref, {
  required String mediaId,
  required String mediaTitle,
}) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: context.ambianceColors.scrim,
    builder: (sheetContext) => DragToDismissSheet(
      isDark: context.ambianceColors.isDark,
      onDismiss: () => Navigator.of(sheetContext).pop(),
      child: FolderPickerSheet(mediaId: mediaId, mediaTitle: mediaTitle),
    ),
  );
}

/// A title can belong to any number of folders (multi-select), independent
/// of its status pile. Lists every existing folder with a toggleable check,
/// plus an inline "New Folder" create action.
class FolderPickerSheet extends ConsumerStatefulWidget {
  final String mediaId;
  final String mediaTitle;

  const FolderPickerSheet({
    super.key,
    required this.mediaId,
    required this.mediaTitle,
  });

  @override
  ConsumerState<FolderPickerSheet> createState() => _FolderPickerSheetState();
}

class _FolderPickerSheetState extends ConsumerState<FolderPickerSheet> {
  bool _isCreating = false;
  final _nameController = TextEditingController();
  final _focusNode = FocusNode();

  @override
  void dispose() {
    _nameController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _submitNewFolder() {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;
    final notifier = ref.read(mediaProvider.notifier);
    final id = notifier.createFolder(name);
    notifier.addToFolder(id, widget.mediaId);
    setState(() {
      _isCreating = false;
      _nameController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.ambianceColors;
    final folders = ref.watch(mediaProvider.select((s) => s.customFolders));
    final sortedFolders = folders.values.toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    final notifier = ref.read(mediaProvider.notifier);

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
          Text(
            'Add to Folder',
            style: AppThemes.safeGeist(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: colors.ink,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            widget.mediaTitle,
            style: AppThemes.safeGeist(fontSize: 12, color: colors.sub),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 16),
          if (sortedFolders.isEmpty && !_isCreating)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                'No folders yet. Create one to start curating.',
                style: AppThemes.safeGeist(fontSize: 13, color: colors.sub),
              ),
            )
          else
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 280),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: sortedFolders.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final folder = sortedFolders[index];
                  final isIn = folder.mediaIds.contains(widget.mediaId);
                  return PressableScale(
                    onTap: () {
                      if (isIn) {
                        notifier.removeFromFolder(folder.id, widget.mediaId);
                      } else {
                        notifier.addToFolder(folder.id, widget.mediaId);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: isIn ? colors.acc.withValues(alpha: 0.12) : colors.pill,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isIn ? colors.acc : colors.lineRgba,
                          width: isIn ? 1.5 : 1.0,
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              folder.name,
                              style: AppThemes.safeGeist(
                                fontSize: 14,
                                fontWeight: isIn ? FontWeight.w700 : FontWeight.w500,
                                color: colors.ink,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Icon(
                            isIn ? Icons.check_circle_rounded : Icons.add_circle_outline_rounded,
                            size: 20,
                            color: isIn ? colors.acc : colors.sub,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          const SizedBox(height: 12),
          if (_isCreating)
            Row(
              children: [
                Expanded(
                  child: LoungeTextField(
                    controller: _nameController,
                    hintText: 'Folder name',
                    focusNode: _focusNode,
                    onSubmitted: (_) => _submitNewFolder(),
                  ),
                ),
                const SizedBox(width: 8),
                PressableScale(
                  onTap: _submitNewFolder,
                  child: Container(
                    height: 44,
                    width: 44,
                    decoration: BoxDecoration(
                      color: colors.acc,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.check_rounded,
                      color: colors.isDark ? Colors.black : Colors.white,
                    ),
                  ),
                ),
              ],
            )
          else
            PressableScale(
              onTap: () {
                setState(() => _isCreating = true);
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _focusNode.requestFocus();
                });
              },
              child: Container(
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: colors.card2,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: colors.lineRgba),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add_rounded, size: 18, color: colors.ink),
                    const SizedBox(width: 6),
                    Text(
                      'New Folder',
                      style: AppThemes.safeGeist(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: colors.ink,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
