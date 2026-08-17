import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants.dart';
import '../models/media_item.dart';
import '../providers/media_provider.dart';
import 'drag_to_dismiss_sheet.dart';
import 'lounge_date_picker.dart';
import 'media_image.dart';
import 'pressable_scale.dart';

/// PERS-REWATCH-1: opens the rewatch quick-log sheet as a themed,
/// drag-to-dismiss bottom sheet.
Future<void> showLoungeRewatchSheet(
  BuildContext context,
  WidgetRef ref, {
  required MediaItem item,
}) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: context.ambianceColors.scrim,
    builder: (sheetContext) => DragToDismissSheet(
      isDark: context.ambianceColors.isDark,
      onDismiss: () => Navigator.of(sheetContext).pop(),
      child: LoungeRewatchSheet(item: item),
    ),
  );
}

/// PERS-REWATCH-1: quick-log sheet for logging an additional watch of a
/// title without disturbing its original first-watch [WatchRecord]. Date
/// defaults to today (editable/backdateable via [showLoungeDatePicker]);
/// rating is optional (SP-4: never blocking).
class LoungeRewatchSheet extends ConsumerStatefulWidget {
  final MediaItem item;

  const LoungeRewatchSheet({super.key, required this.item});

  @override
  ConsumerState<LoungeRewatchSheet> createState() => _LoungeRewatchSheetState();
}

class _LoungeRewatchSheetState extends ConsumerState<LoungeRewatchSheet> {
  late DateTime _selectedDate;
  PersonalRating? _selectedRating;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
  }

  String _formatDate(DateTime dt) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
  }

  Future<void> _pickDate() async {
    final picked = await showLoungeDatePicker(context, initialDate: _selectedDate);
    if (picked != null && mounted) {
      setState(() => _selectedDate = picked);
    }
  }

  void _logRewatch() {
    ref.read(mediaProvider.notifier).addWatchRecord(
          widget.item.id,
          WatchRecord(
            date: _selectedDate,
            rating: _selectedRating,
            isFirstWatch: false,
          ),
        );
    Navigator.of(context).pop();
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
                  child: MediaImage(item: widget.item, fit: BoxFit.cover, showFallbackTitle: false),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.item.title,
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
                      'Log a rewatch',
                      style: AppThemes.safeGeist(fontSize: 12, color: colors.sub),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            'Watch date',
            style: AppThemes.safeGeist(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: colors.sub,
            ),
          ),
          const SizedBox(height: 8),
          PressableScale(
            onTap: _pickDate,
            child: Container(
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: colors.pill,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: colors.lineRgba),
              ),
              child: Row(
                children: [
                  Icon(Icons.calendar_today_outlined, size: 16, color: colors.sub),
                  const SizedBox(width: 10),
                  Text(
                    _formatDate(_selectedDate),
                    style: AppThemes.safeGeist(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: colors.ink,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Rating (optional)',
            style: AppThemes.safeGeist(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: colors.sub,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: PersonalRating.values.map((rating) {
              final isSelected = _selectedRating == rating;
              final tierColor = AppRatingColors.of(rating);
              return PressableScale(
                onTap: () => setState(() {
                  _selectedRating = isSelected ? null : rating;
                }),
                child: AnimatedContainer(
                  duration: AppPhysics.houseSpringDuration,
                  curve: AppPhysics.houseSpringCurve,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? tierColor.withValues(alpha: 0.18) : colors.pill,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isSelected ? tierColor : colors.lineRgba,
                      width: isSelected ? 1.5 : 1.0,
                    ),
                  ),
                  child: Text(
                    rating.label,
                    style: AppThemes.safeGeist(
                      fontSize: 12.5,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected ? tierColor : colors.ink,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
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
                  onTap: _logRewatch,
                  child: Container(
                    height: 44,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: colors.acc,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Log Rewatch',
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
