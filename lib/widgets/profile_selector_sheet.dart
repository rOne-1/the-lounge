import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants.dart';
import '../models/profile_space.dart';
import '../providers/profile_provider.dart';
import 'drag_to_dismiss_sheet.dart';
import 'pressable_scale.dart';

/// PROF-3: Bottom sheet for selecting, renaming, and customizing Lounge Personas (Profiles).
class ProfileSelectorSheet extends ConsumerWidget {
  const ProfileSelectorSheet({super.key});

  static Future<void> show(BuildContext context) {
    final colors = context.ambianceColors;
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: colors.scrim.withValues(alpha: colors.isDark ? 0.65 : 0.40),
      builder: (context) => const ProfileSelectorSheet(),
    );
  }

  IconData _iconFor(String iconKey) {
    switch (iconKey) {
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
        return Icons.person_rounded;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.ambianceColors;
    final isDark = colors.isDark;
    final profileState = ref.watch(profileProvider);
    final profiles = profileState.profiles;
    final activeId = profileState.activeProfileId;

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
                        'The Lounge Personas',
                        style: GoogleFonts.bodoniModa(
                          fontSize: 22,
                          fontWeight: FontWeight.w500,
                          fontStyle: FontStyle.italic,
                          color: colors.ink,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Partition your archive and watch habits',
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

            // Profile Cards
            ...profiles.map((profile) {
              final isActive = profile.id == activeId;
              final icon = _iconFor(profile.iconKey);

              final movieCount = profile.domainArchive(MediumDomain.movies).totalCount;
              final tvCount = profile.domainArchive(MediumDomain.tv).totalCount;
              final totalCount = movieCount + tvCount;

              final subtitleText = profile.isCommon
                  ? 'Shared Lounge · $totalCount saved'
                  : '$movieCount movies · $tvCount shows';

              return Padding(
                padding: const EdgeInsets.only(bottom: 10.0),
                child: PressableScale(
                  onTap: () {
                    ref.read(profileProvider.notifier).switchProfile(profile.id);
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
                                      profile.name,
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
                                  if (profile.isCommon) ...[
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
                                        'COMMON',
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
                          Icon(
                            Icons.check_circle_rounded,
                            color: colors.acc,
                            size: 22,
                          )
                        else
                          IconButton(
                            icon: Icon(
                              Icons.edit_outlined,
                              size: 18,
                              color: colors.sub,
                            ),
                            onPressed: () => _promptRename(context, ref, profile),
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

  void _promptRename(BuildContext context, WidgetRef ref, ProfileSpace profile) {
    final textController = TextEditingController(text: profile.name);
    final colors = context.ambianceColors;

    showDialog<void>(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          backgroundColor: colors.card,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: colors.lineRgba),
          ),
          title: Text(
            'Rename Persona',
            style: GoogleFonts.bodoniModa(
              fontSize: 20,
              fontStyle: FontStyle.italic,
              color: colors.ink,
            ),
          ),
          content: TextField(
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
                  ref.read(profileProvider.notifier).renameProfile(profile.id, newName);
                }
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
  }
}
