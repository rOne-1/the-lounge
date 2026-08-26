import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants.dart';
import '../models/media_item.dart';
import '../providers/media_provider.dart';
import '../screens/detail_screen.dart';
import 'media_image.dart';
import 'pressable_scale.dart';

/// CRAFT-HERO-1: full-width hero banner on the Lounge landing screen
/// surfacing the user's in-progress TV show(s) with instant one-tap watch
/// progression -- a sibling to [AnalyticsHeroCard], using the same
/// ambiance-accent (not fixed-status-color) hero convention since both live
/// on the same screen. Sourced from the Watching shelf (SP-1: reuses
/// `MediaState.watchingList` and `MediaNotifier.toggleEpisodeWatched`/
/// `getNextUnwatchedEpisode`, the same state-machine methods
/// [TvContinueWatchingCard] on the Lobby rail already uses, rather than a
/// parallel mutation path). Collapses to nothing when no TV show is
/// currently in Watching.
class ContinueWatchingHeroCard extends ConsumerStatefulWidget {
  const ContinueWatchingHeroCard({super.key});

  @override
  ConsumerState<ContinueWatchingHeroCard> createState() =>
      _ContinueWatchingHeroCardState();
}

class _ContinueWatchingHeroCardState
    extends ConsumerState<ContinueWatchingHeroCard> {
  int _pageIndex = 0;
  // ITEM-1: live-tracked (not implicitly animated) so the card follows the
  // finger 1:1 during the drag itself; the snap back to identity (rubber-band
  // release, or the abrupt swap when a page commits) borrows the surrounding
  // AnimatedContainer's own spring via `_isDragging` gating its duration to
  // zero only while a drag is in flight.
  double _dragDx = 0.0;
  bool _isDragging = false;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(mediaProvider);
    final shows = state.watchingList.values
        .where((m) => m.type == MediaType.tv)
        .toList()
      // Most-recently-started first -- the closest proxy this data model
      // has to "most recently updated" (per-episode progress timestamps
      // aren't tracked, only the immutable started-watching date).
      ..sort((a, b) {
        final aStart =
            state.startDates[a.id] ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bStart =
            state.startDates[b.id] ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bStart.compareTo(aStart);
      });

    if (shows.isEmpty) return const SizedBox.shrink();

    final index = _pageIndex.clamp(0, shows.length - 1);
    final item = shows[index];
    final colors = context.ambianceColors;
    final accent = colors.acc;
    final isDark = colors.isDark;
    final seasonsAsync = ref.watch(tvShowSeasonsProvider(item));
    // Distinguish "still fetching" from "genuinely nothing left" -- with an
    // empty `seasons` default, getNextUnwatchedEpisode would otherwise
    // report every in-progress show as falsely "All episodes watched" for
    // one frame while its season data is still in flight.
    final seasonsLoaded = seasonsAsync.hasValue;
    final seasons = seasonsAsync.value ?? const [];
    final notifier = ref.read(mediaProvider.notifier);
    final nextEp = seasonsLoaded
        ? notifier.getNextUnwatchedEpisode(showId: item.id, seasons: seasons)
        : null;

    final now = DateTime.now();
    final releasedCount = seasons
        .expand((s) => s.episodes)
        .where((e) => e.airDate == null || !e.airDate!.isAfter(now))
        .length;
    final watchedCount = state.watchedEpisodes[item.id]?.length ?? 0;
    final completionPct =
        releasedCount > 0 ? ((watchedCount / releasedCount) * 100).round() : 0;

    final episodeLabel = !seasonsLoaded
        ? 'Loading episodes…'
        : nextEp != null
            ? 'S${nextEp.seasonNumber} · E${nextEp.episodeNumber} "${nextEp.name}"'
            : 'All episodes watched';

    return Padding(
      padding: const EdgeInsets.only(bottom: 14.0),
      child: AnimatedContainer(
        key: ValueKey('continue_watching_hero_${item.id}'),
        duration: _isDragging ? Duration.zero : AppPhysics.houseSpringDuration,
        curve: AppPhysics.houseSpringCurve,
        transform: Matrix4.translationValues(_dragDx, 0, 0),
        transformAlignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 18.0),
        decoration: BoxDecoration(
          color: colors.card,
          borderRadius: BorderRadius.circular(24.0),
          border: Border.all(
            color: accent.withValues(alpha: isDark ? 0.35 : 0.45),
            width: 1.2,
          ),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [
                    Color.alphaBlend(
                        accent.withValues(alpha: 0.16), colors.card),
                    colors.card,
                  ]
                : [
                    Color.alphaBlend(
                        accent.withValues(alpha: 0.08), colors.card),
                    colors.card,
                  ],
          ),
          boxShadow: [
            BoxShadow(
              color: accent.withValues(alpha: isDark ? 0.18 : 0.10),
              blurRadius: 28,
              offset: const Offset(0, 10),
            ),
            if (isDark)
              BoxShadow(
                color: colors.surfaceHighlight,
                blurRadius: 0,
                offset: const Offset(0, 1),
                blurStyle: BlurStyle.inner,
              ),
          ],
        ),
        child: PressableScale(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) =>
                    DetailScreen(id: item.prefixedId, initialItem: item),
              ),
            ),
            onHorizontalDragStart: shows.length > 1
                ? (_) => setState(() => _isDragging = true)
                : null,
            onHorizontalDragUpdate: shows.length > 1
                ? (details) => setState(() {
                      _dragDx = (_dragDx + details.delta.dx).clamp(-70.0, 70.0);
                    })
                : null,
            onHorizontalDragEnd: shows.length > 1
                ? (details) {
                    final velocity = details.velocity.pixelsPerSecond.dx;
                    var newIndex = index;
                    if ((_dragDx <= -45 || velocity < -400) &&
                        index < shows.length - 1) {
                      newIndex = index + 1;
                    } else if ((_dragDx >= 45 || velocity > 400) && index > 0) {
                      newIndex = index - 1;
                    }
                    if (newIndex != index) HapticFeedback.selectionClick();
                    setState(() {
                      _pageIndex = newIndex;
                      _isDragging = false;
                      _dragDx = 0.0;
                    });
                  }
                : null,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  color: accent.withValues(
                                      alpha: isDark ? 0.22 : 0.18),
                                  borderRadius: BorderRadius.circular(8.0),
                                  border: Border.all(
                                    color: accent.withValues(alpha: 0.40),
                                    width: 1.0,
                                  ),
                                ),
                                child: Icon(
                                  Icons.play_arrow_rounded,
                                  color: accent,
                                  size: 17,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    'CONTINUE WATCHING',
                                    style: AppThemes.safeGeist(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w700,
                                      color: accent,
                                      letterSpacing: 1.2,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              item.title,
                              style: AppThemes.safeGeist(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: colors.ink,
                                letterSpacing: -0.3,
                              ),
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            episodeLabel,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppThemes.safeGeist(
                              fontSize: 13,
                              color: colors.sub,
                              letterSpacing: 0.1,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16.0),
                      child: SizedBox(
                        width: 90,
                        height: 64,
                        child: MediaImage(
                          imageUrl: nextEp?.stillUrl ??
                              item.backdropUrl ??
                              item.posterUrl,
                          type: item.type,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ],
                ),
                if (releasedCount > 0) ...[
                  const SizedBox(height: 14),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: SizedBox(
                      height: 5,
                      child: Stack(
                        children: [
                          Container(color: colors.lineRgba),
                          AnimatedFractionallySizedBox(
                            duration: AppPhysics.houseSpringDuration,
                            curve: AppPhysics.houseSpringCurve,
                            widthFactor:
                                (watchedCount / releasedCount).clamp(0.0, 1.0),
                            child: Container(color: accent),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '$watchedCount of $releasedCount episodes · $completionPct%',
                    style:
                        AppThemes.safeGeist(fontSize: 11.5, color: colors.sub),
                  ),
                ],
                const SizedBox(height: 14),
                Row(
                  children: [
                    if (nextEp != null)
                      PressableScale(
                        onTap: () => notifier.toggleEpisodeWatched(
                          showId: item.id,
                          seasonNumber: nextEp.seasonNumber,
                          episodeNumber: nextEp.episodeNumber,
                          showItem: item,
                          seasons: seasons,
                        ),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 9),
                          decoration: colors.primaryButtonDecoration.copyWith(
                              borderRadius: BorderRadius.circular(999)),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.add_rounded,
                                size: 15,
                                color: Theme.of(context).colorScheme.onPrimary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Quick Watch',
                                style: AppThemes.safeGeist(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                  color:
                                      Theme.of(context).colorScheme.onPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    const Spacer(),
                    if (shows.length > 1)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          for (var i = 0; i < shows.length; i++)
                            GestureDetector(
                              key: ValueKey(
                                  'continue_watching_dot_${shows[i].id}'),
                              onTap: () => setState(() => _pageIndex = i),
                              child: AnimatedContainer(
                                duration: AppPhysics.houseSpringDuration,
                                curve: AppPhysics.houseSpringCurve,
                                margin:
                                    const EdgeInsets.symmetric(horizontal: 2),
                                width: i == index ? 16 : 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: i == index
                                      ? accent
                                      : accent.withValues(alpha: 0.25),
                                  borderRadius: BorderRadius.circular(3),
                                ),
                              ),
                            ),
                        ],
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
