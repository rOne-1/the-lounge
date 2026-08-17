import 'package:flutter/material.dart';
import '../constants.dart';
import 'drag_to_dismiss_sheet.dart';
import 'lounge_text_field.dart';
import 'pressable_scale.dart';

/// PERS-FOLDERS-1: themed bottom-sheet prompt for a folder name -- shared by
/// "create folder" (FoldersScreen) and "rename folder" (FolderDetailScreen)
/// so both use the same entry UX rather than duplicating it. Returns the
/// trimmed name, or null if cancelled/dismissed without a non-empty value.
Future<String?> showFolderNamePrompt(
  BuildContext context, {
  required String sheetTitle,
  String initialValue = '',
  required String confirmLabel,
}) {
  final colors = context.ambianceColors;
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: colors.scrim,
    builder: (sheetContext) => DragToDismissSheet(
      isDark: colors.isDark,
      onDismiss: () => Navigator.of(sheetContext).pop(),
      child: _FolderNameSheetContent(
        sheetTitle: sheetTitle,
        initialValue: initialValue,
        confirmLabel: confirmLabel,
      ),
    ),
  );
}

class _FolderNameSheetContent extends StatefulWidget {
  final String sheetTitle;
  final String initialValue;
  final String confirmLabel;

  const _FolderNameSheetContent({
    required this.sheetTitle,
    required this.initialValue,
    required this.confirmLabel,
  });

  @override
  State<_FolderNameSheetContent> createState() => _FolderNameSheetContentState();
}

class _FolderNameSheetContentState extends State<_FolderNameSheetContent> {
  late final TextEditingController _controller;
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
    WidgetsBinding.instance.addPostFrameCallback((_) => _focusNode.requestFocus());
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _controller.text.trim();
    if (name.isEmpty) return;
    Navigator.of(context).pop(name);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.ambianceColors;
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
        bottom: MediaQuery.of(context).viewInsets.bottom + MediaQuery.of(context).padding.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            widget.sheetTitle,
            style: AppThemes.safeGeist(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: colors.ink,
            ),
          ),
          const SizedBox(height: 16),
          LoungeTextField(
            controller: _controller,
            hintText: 'Folder name',
            focusNode: _focusNode,
            onSubmitted: (_) => _submit(),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: PressableScale(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    height: 44,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: colors.card2,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: colors.lineRgba),
                    ),
                    child: Text(
                      'Cancel',
                      style: AppThemes.safeGeist(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: colors.sub,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: PressableScale(
                  onTap: _submit,
                  child: Container(
                    height: 44,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: colors.acc,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      widget.confirmLabel,
                      style: AppThemes.safeGeist(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: colors.isDark ? Colors.black : Colors.white,
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
