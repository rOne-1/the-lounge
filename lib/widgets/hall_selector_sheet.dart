import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants.dart';
import '../models/hall_space.dart';
import '../models/media_item.dart';
import '../providers/hall_provider.dart';
import '../providers/media_provider.dart';
import 'drag_to_dismiss_sheet.dart';
import 'pressable_scale.dart';

/// PROF-3 / NOMEN-1 / FIX-2: Bottom sheet for selecting, renaming, and managing Screening Halls.
class HallSelectorSheet extends ConsumerWidget {
  const HallSelectorSheet({super.key});

  static Future<void> show(BuildContext context) {
    final colors = context.ambianceColors;
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: colors.scrim.withValues(alpha: colors.isDark ? 0.65 : 0.40),
      builder: (context) => const HallSelectorSheet(),
    );
  }

  IconData _iconFor(String iconKey) {
    switch (iconKey) {
      case 'arch':
        return Icons.meeting_room_rounded;
      case 'reel':
        return Icons.movie_filter_rounded;
      case 'curtain':
        return Icons.auto_awesome_rounded;
      case 'star':
        return Icons.star_rounded;
      case 'sparkles':
        return Icons.auto_awesome_rounded;
      case 'popcorn':
        return Icons.movie_filter_rounded;
      case 'heart':
        return Icons.favorite_rounded;
      case 'tv':
        return Icons.tv_rounded;
      case 'movie':
        return Icons.local_movies_rounded;
      default:
        return Icons.theater_comedy_rounded;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.ambianceColors;
    final isDark = colors.isDark;
    final hallState = ref.watch(hallProvider);
    final mediaState = ref.watch(mediaProvider);
    final halls = hallState.halls;
    final activeId = hallState.activeHallId;

    int countForType(Map<String, dynamic> itemsMap, MediaType targetType) =>
        itemsMap.values.where((m) => m is MediaItem && m.type == targetType).length;

    return DragToDismissSheet(
      isDark: isDark,
      onDismiss: () => Navigator.of(context).pop(),
      child: Container(
        padding: EdgeInsets.fromLTRB(
          20,
          8,
          20,
          24 + MediaQuery.of(context).viewInsets.bottom + MediaQuery.of(context).padding.bottom,
        ),
        decoration: BoxDecoration(
          color: colors.card,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          border: Border(
            top: BorderSide(color: colors.lineRgba, width: 1.0),
          ),
          boxShadow: [
            BoxShadow(
              color: colors.scrim.withValues(alpha: isDark ? 0.35 : 0.12),
              blurRadius: 24,
              offset: const Offset(0, -6),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'The Screening Halls',
                        style: GoogleFonts.bodoniModa(
                          fontSize: 22,
                          fontWeight: FontWeight.w500,
                          fontStyle: FontStyle.italic,
                          color: colors.ink,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Partition your archive and screening spaces',
                        style: AppThemes.safeGeist(
                          fontSize: 12.5,
                          color: colors.sub,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: Icon(Icons.close_rounded, color: colors.sub, size: 20),
                  splashRadius: 20,
                ),
              ],
            ),
            const SizedBox(height: 18),

            // Hall Cards
            ...halls.map((hall) {
              final isActive = hall.id == activeId;
              final icon = _iconFor(hall.iconKey);

              final movieCount = isActive
                  ? (countForType(mediaState.watchlist, MediaType.movie) +
                      countForType(mediaState.maybeList, MediaType.movie) +
                      countForType(mediaState.watchingList, MediaType.movie) +
                      countForType(mediaState.onHoldList, MediaType.movie) +
                      countForType(mediaState.droppedList, MediaType.movie) +
                      countForType(mediaState.watchedList, MediaType.movie))
                  : hall.domainArchive(MediumDomain.movies).totalCount;

              final tvCount = isActive
                  ? (countForType(mediaState.watchlist, MediaType.tv) +
                      countForType(mediaState.maybeList, MediaType.tv) +
                      countForType(mediaState.watchingList, MediaType.tv) +
                      countForType(mediaState.onHoldList, MediaType.tv) +
                      countForType(mediaState.droppedList, MediaType.tv) +
                      countForType(mediaState.watchedList, MediaType.tv))
                  : hall.domainArchive(MediumDomain.tv).totalCount;

              final subtitleText =
                  '$movieCount ${movieCount == 1 ? "movie" : "movies"} · $tvCount ${tvCount == 1 ? "show" : "shows"}';

              return Padding(
                padding: const EdgeInsets.only(bottom: 10.0),
                child: PressableScale(
                  onTap: () {
                    ref.read(hallProvider.notifier).switchHall(hall.id);
                    Navigator.of(context).pop();
                  },
                  child: AnimatedContainer(
                    duration: AppPhysics.houseSpringDuration,
                    curve: AppPhysics.houseSpringCurve,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: isActive
                          ? colors.acc.withValues(alpha: isDark ? 0.14 : 0.08)
                          : colors.base,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isActive
                            ? colors.acc.withValues(alpha: isDark ? 0.70 : 0.85)
                            : colors.lineRgba,
                        width: isActive ? 1.5 : 1.0,
                      ),
                    ),
                    child: Row(
                      children: [
                        // Avatar Icon
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isActive
                                ? colors.acc.withValues(alpha: isDark ? 0.25 : 0.15)
                                : colors.card,
                            border: Border.all(
                              color: isActive ? colors.acc : colors.lineRgba,
                            ),
                          ),
                          child: Icon(
                            icon,
                            size: 22,
                            color: isActive ? colors.acc : colors.sub,
                          ),
                        ),
                        const SizedBox(width: 14),

                        // Name & Details
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      hall.name,
                                      style: AppThemes.safeGeist(
                                        fontSize: 15,
                                        fontWeight: isActive
                                            ? FontWeight.w600
                                            : FontWeight.w500,
                                        color: colors.ink,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (hall.isCommon) ...[
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: colors.acc
                                            .withValues(alpha: isDark ? 0.18 : 0.10),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        'MAIN',
                                        style: AppThemes.safeGeist(
                                          fontSize: 9.5,
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: 0.6,
                                          color: colors.acc,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                subtitleText,
                                style: AppThemes.safeGeist(
                                  fontSize: 12,
                                  color: colors.sub,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Action / Active Checkmark
                        if (isActive)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: Icon(
                                  Icons.edit_outlined,
                                  size: 18,
                                  color: colors.sub,
                                ),
                                onPressed: () => _promptCustomizeHall(context, ref, hall),
                                splashRadius: 18,
                              ),
                              const SizedBox(width: 2),
                              Icon(
                                Icons.check_circle_rounded,
                                color: colors.acc,
                                size: 22,
                              ),
                            ],
                          )
                        else
                          IconButton(
                            icon: Icon(
                              Icons.edit_outlined,
                              size: 18,
                              color: colors.sub,
                            ),
                            onPressed: () => _promptCustomizeHall(context, ref, hall),
                            splashRadius: 18,
                          ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  void _promptCustomizeHall(BuildContext context, WidgetRef ref, HallSpace hall) {
    final textController = TextEditingController(text: hall.name);
    String selectedThemeId = hall.themeId ??
        (hall.id == 'common' ? 'screening_room' : (hall.id == 'custom_1' ? 'midnight_cinema' : 'reading_room'));
    String? selectedLanguageCode = hall.lockedLanguageCode;
    String? selectedLanguageName = hall.lockedLanguageName;
    final colors = context.ambianceColors;

    showDialog<void>(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: colors.card,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(color: colors.lineRgba),
              ),
              title: Text(
                'Customize Screening Hall',
                style: GoogleFonts.bodoniModa(
                  fontSize: 20,
                  fontStyle: FontStyle.italic,
                  color: colors.ink,
                ),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'HALL NAME',
                      style: AppThemes.safeGeist(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                        color: colors.sub,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: textController,
                      autofocus: true,
                      style: AppThemes.safeGeist(color: colors.ink),
                      decoration: InputDecoration(
                        hintText: 'Enter name',
                        hintStyle: AppThemes.safeGeist(color: colors.sub),
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: colors.lineRgba),
                        ),
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: colors.acc),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'HALL AMBIANCE THEME',
                      style: AppThemes.safeGeist(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                        color: colors.sub,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: allThemes.map((theme) {
                        final isThemeSelected = theme.id == selectedThemeId;
                        return PressableScale(
                          onTap: () {
                            setDialogState(() {
                              selectedThemeId = theme.id;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: isThemeSelected
                                  ? colors.acc.withValues(alpha: 0.15)
                                  : colors.base,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isThemeSelected ? colors.acc : colors.lineRgba,
                                width: isThemeSelected ? 1.5 : 1.0,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 14,
                                  height: 14,
                                  decoration: BoxDecoration(
                                    color: theme.colors.acc,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: theme.colors.ink.withValues(alpha: 0.3),
                                      width: 1,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  theme.displayName,
                                  style: AppThemes.safeGeist(
                                    fontSize: 11.5,
                                    fontWeight: isThemeSelected ? FontWeight.w600 : FontWeight.w400,
                                    color: colors.ink,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'LANGUAGE LOCK',
                      style: AppThemes.safeGeist(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                        color: colors.sub,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Restricts Lobby, Discover, Search, and Calendar in this hall to one original language.',
                      style: AppThemes.safeGeist(fontSize: 11, color: colors.sub),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        PressableScale(
                          onTap: () {
                            setDialogState(() {
                              selectedLanguageCode = null;
                              selectedLanguageName = null;
                            });
                          },
                          child: _LanguageChip(
                            label: 'All Languages',
                            isSelected: selectedLanguageCode == null,
                            colors: colors,
                          ),
                        ),
                        ...supportedLanguages.map((lang) {
                          final isSelected = selectedLanguageCode == lang['code'];
                          return PressableScale(
                            onTap: () {
                              setDialogState(() {
                                selectedLanguageCode = lang['code'];
                                selectedLanguageName = lang['name'];
                              });
                            },
                            child: _LanguageChip(
                              label: lang['name']!,
                              isSelected: isSelected,
                              colors: colors,
                            ),
                          );
                        }),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogCtx).pop(),
                  child: Text(
                    'Cancel',
                    style: AppThemes.safeGeist(color: colors.sub),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    final newName = textController.text.trim();
                    if (newName.isNotEmpty) {
                      ref.read(hallProvider.notifier).renameHall(hall.id, newName);
                    }
                    ref.read(hallProvider.notifier).updateHallTheme(hall.id, selectedThemeId);
                    ref.read(hallProvider.notifier).updateHallLanguage(
                          hall.id,
                          selectedLanguageCode,
                          selectedLanguageName,
                        );
                    Navigator.of(dialogCtx).pop();
                  },
                  child: Text(
                    'Save',
                    style: AppThemes.safeGeist(
                      color: colors.acc,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

/// LANG-1: a single language-lock chip in [HallSelectorSheet]'s customize
/// dialog, matching the visual weight of the theme-swatch chips right above
/// it (accent-tinted fill + border when selected) minus the color swatch,
/// since a language has no color of its own to show.
class _LanguageChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final AmbianceColors colors;

  const _LanguageChip({
    required this.label,
    required this.isSelected,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isSelected ? colors.acc.withValues(alpha: 0.15) : colors.base,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected ? colors.acc : colors.lineRgba,
          width: isSelected ? 1.5 : 1.0,
        ),
      ),
      child: Text(
        label,
        style: AppThemes.safeGeist(
          fontSize: 11.5,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
          color: colors.ink,
        ),
      ),
    );
  }
}
