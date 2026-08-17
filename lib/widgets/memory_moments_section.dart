import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants.dart';
import '../models/media_item.dart';
import '../providers/media_provider.dart';
import '../screens/detail_screen.dart';
import '../utils/memory_differentiation.dart';
import 'media_card.dart';
import 'pressable_scale.dart';

MediaItem? _findKnownItem(MediaState state, String id) {
  return state.watchlist[id] ??
      state.maybeList[id] ??
      state.watchingList[id] ??
      state.watchedList[id] ??
      state.droppedList[id] ??
      state.onHoldList[id];
}

/// PERS-DIFF-1: Your Space's emotional-memory surface -- "On This Day"
/// anniversary callouts and a "Forgotten Favorites" rail. Purely
/// data-driven and renders nothing when there's nothing to say (no
/// exact-date anniversary today, no unrewatched loved title old enough to
/// qualify) -- consistent with the rest of Your Space never showing a
/// blocking/empty placeholder for an optional surface.
class MemoryMomentsSection extends ConsumerWidget {
  const MemoryMomentsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(mediaProvider);
    final onThisDay = computeOnThisDay(state);
    final forgotten = computeForgottenFavorites(state);

    if (onThisDay.isEmpty && forgotten.isEmpty) return const SizedBox.shrink();

    final colors = context.ambianceColors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final memory in onThisDay) ...[
          _OnThisDayCard(memory: memory),
          const SizedBox(height: 10),
        ],
        if (forgotten.isNotEmpty) ...[
          Text(
            'FORGOTTEN FAVORITES',
            style: AppThemes.safeGeist(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: colors.sub,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 178,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: forgotten.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (context, index) =>
                  _ForgottenFavoriteTile(favorite: forgotten[index]),
            ),
          ),
        ],
        const SizedBox(height: 26),
      ],
    );
  }
}

class _OnThisDayCard extends ConsumerWidget {
  final OnThisDayMemory memory;

  const _OnThisDayCard({required this.memory});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final known = _findKnownItem(ref.watch(mediaProvider), memory.mediaId);
    if (known != null) return _build(context, known);

    final asyncItem = ref.watch(mediaDetailsProvider(memory.mediaId));
    return asyncItem.when(
      data: (item) => item != null ? _build(context, item) : const SizedBox.shrink(),
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _build(BuildContext context, MediaItem item) {
    final colors = context.ambianceColors;
    return PressableScale(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => DetailScreen(id: item.prefixedId, initialItem: item),
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: colors.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppRatingColors.loved.withValues(alpha: 0.4)),
        ),
        child: Row(
          children: [
            const Icon(Icons.auto_awesome_rounded, color: AppRatingColors.loved, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: RichText(
                text: TextSpan(
                  style: AppThemes.safeGeist(fontSize: 13, color: colors.ink, height: 1.3),
                  children: [
                    TextSpan(
                      text:
                          '${memory.yearsAgo} year${memory.yearsAgo == 1 ? '' : 's'} ago today, you completed ',
                    ),
                    TextSpan(
                      text: item.title,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    )
        .animate()
        .fadeIn(duration: AppPhysics.houseSpringDuration, curve: AppPhysics.houseSpringCurve)
        .slideY(begin: 0.08, end: 0, curve: AppPhysics.houseSpringCurve);
  }
}

class _ForgottenFavoriteTile extends ConsumerWidget {
  final ForgottenFavorite favorite;

  const _ForgottenFavoriteTile({required this.favorite});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final known = _findKnownItem(ref.watch(mediaProvider), favorite.mediaId);
    if (known != null) return _build(context, known);

    final asyncItem = ref.watch(mediaDetailsProvider(favorite.mediaId));
    return asyncItem.when(
      data: (item) => item != null ? _build(context, item) : const SizedBox.shrink(),
      loading: () => SizedBox(
        width: 104,
        child: Container(
          decoration: BoxDecoration(
            color: context.ambianceColors.card,
            borderRadius: BorderRadius.circular(11),
          ),
        ),
      ),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _build(BuildContext context, MediaItem item) {
    final isDark = context.ambianceColors.isDark;
    return MediaCard(
      item: item,
      width: 104,
      height: 150,
      isDark: isDark,
      showTitle: true,
      showRatingBadge: false,
    );
  }
}
