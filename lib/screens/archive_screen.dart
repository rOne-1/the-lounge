import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants.dart';
import '../models/media_item.dart';
import '../models/hall_space.dart';
import '../providers/media_provider.dart';
import '../providers/navigation_provider.dart';
import '../widgets/dashed_border_card.dart';
import '../widgets/archive_summary_card.dart';
import '../widgets/pressable_scale.dart';
import '../widgets/watching_hero_card.dart';
import 'archive_shelf_screen.dart';

/// YSR-HUB-1 / COUNT-1 / COUNT-2 / NOMEN-2: The Archive Hub - a dedicated screening
/// hub providing access to all 6 archive shelves (Watching, Watched, Watchlist,
/// Saved, On-Hold, Dropped). Built with luxury status gradients, squircle icon
/// badges, large Bodoni Moda italic count numerals, dynamic medium-reactive counts,
/// and contextual pluralization per active domain (Movies / TV / Anime).
class ArchiveScreen extends ConsumerWidget {
  const ArchiveScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.ambianceColors;
    final mediaState = ref.watch(mediaProvider);
    final isLarge = MediaQuery.of(context).size.width >= 600;
    final paddingHorizontal = isLarge ? 24.0 : 18.0;

    final activeMediaType = ref.watch(navigationProvider).activeMediaType;
    final activeDomain = MediumDomain.fromMediaTypeToggle(activeMediaType);
    final targetType = activeMediaType == MediaTypeToggle.movies ? MediaType.movie : MediaType.tv;

    int countForType(Map<String, dynamic> itemsMap) =>
        itemsMap.values.where((m) => m is MediaItem && m.type == targetType).length;

    final watchlistCount = countForType(mediaState.watchlist);
    final savedCount = countForType(mediaState.maybeList);
    final watchingCount = countForType(mediaState.watchingList);
    final onHoldCount = countForType(mediaState.onHoldList);
    final droppedCount = countForType(mediaState.droppedList);
    final watchedCount = countForType(mediaState.watchedList);

    final totalTitles = watchlistCount +
        savedCount +
        watchingCount +
        onHoldCount +
        droppedCount +
        watchedCount;

    String subtitleFor(int count) {
      switch (activeDomain) {
        case MediumDomain.movies:
          return count == 1 ? 'movie' : 'movies';
        case MediumDomain.tv:
          return count == 1 ? 'show' : 'shows';
        case MediumDomain.anime:
          return count == 1 ? 'series' : 'series';
      }
    }

    String watchingSubtitle;
    switch (activeDomain) {
      case MediumDomain.movies:
        watchingSubtitle = watchingCount == 1 ? '1 movie in progress' : '$watchingCount movies in progress';
        break;
      case MediumDomain.tv:
        watchingSubtitle = watchingCount == 1 ? '1 show in progress' : '$watchingCount shows in progress';
        break;
      case MediumDomain.anime:
        watchingSubtitle = watchingCount == 1 ? '1 series in progress' : '$watchingCount series in progress';
        break;
    }

    String droppedSubtitle;
    if (droppedCount == 0) {
      droppedSubtitle = 'nothing here — a clean record';
    } else {
      switch (activeDomain) {
        case MediumDomain.movies:
          droppedSubtitle = '$droppedCount ${droppedCount == 1 ? "movie" : "movies"}';
          break;
        case MediumDomain.tv:
          droppedSubtitle = '$droppedCount ${droppedCount == 1 ? "TV show" : "TV shows"}';
          break;
        case MediumDomain.anime:
          droppedSubtitle = '$droppedCount ${droppedCount == 1 ? "anime" : "anime series"}';
          break;
      }
    }

    String topBarSubtitle;
    switch (activeDomain) {
      case MediumDomain.movies:
        topBarSubtitle = '$totalTitles ${totalTitles == 1 ? "movie" : "movies"} · 6 shelves';
        break;
      case MediumDomain.tv:
        topBarSubtitle = '$totalTitles ${totalTitles == 1 ? "TV show" : "TV shows"} · 6 shelves';
        break;
      case MediumDomain.anime:
        topBarSubtitle = '$totalTitles ${totalTitles == 1 ? "anime" : "anime series"} · 6 shelves';
        break;
    }

    return Scaffold(
      backgroundColor: colors.base,
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            paddingHorizontal,
            14.0,
            paddingHorizontal,
            100.0 + MediaQuery.of(context).padding.bottom,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Bar with Back Button & Header
                  _buildTopBar(context, topBarSubtitle),
                  const SizedBox(height: 24),

                  // 1. Hero Watching Card
                  WatchingHeroCard(
                    count: watchingCount,
                    subtitle: watchingSubtitle,
                    onTap: () => _openShelf(context, ArchiveShelfKind.watching),
                  ),
                  const SizedBox(height: 14),

                  // 2. 2x2 Main Shelves Grid (Watched, Watchlist, Saved, On-Hold)
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 1.16,
                    children: [
                      ArchiveSummaryCard(
                        label: ArchiveShelfKind.watched.label,
                        subtitle: subtitleFor(watchedCount),
                        count: watchedCount,
                        icon: Icons.check_rounded,
                        statusColor: ArchiveShelfKind.watched.statusColor,
                        onTap: () => _openShelf(context, ArchiveShelfKind.watched),
                      ),
                      ArchiveSummaryCard(
                        label: ArchiveShelfKind.watchlist.label,
                        subtitle: subtitleFor(watchlistCount),
                        count: watchlistCount,
                        icon: Icons.bookmark_rounded,
                        statusColor: ArchiveShelfKind.watchlist.statusColor,
                        onTap: () => _openShelf(context, ArchiveShelfKind.watchlist),
                      ),
                      ArchiveSummaryCard(
                        label: ArchiveShelfKind.saved.label,
                        subtitle: subtitleFor(savedCount),
                        count: savedCount,
                        icon: Icons.favorite_rounded,
                        statusColor: ArchiveShelfKind.saved.statusColor,
                        onTap: () => _openShelf(context, ArchiveShelfKind.saved),
                      ),
                      ArchiveSummaryCard(
                        label: ArchiveShelfKind.onHold.label,
                        subtitle: subtitleFor(onHoldCount),
                        count: onHoldCount,
                        icon: Icons.pause_rounded,
                        statusColor: ArchiveShelfKind.onHold.statusColor,
                        onTap: () => _openShelf(context, ArchiveShelfKind.onHold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // 3. Dropped Shelf Card (Full-width dashed card)
                  DashedBorderCard(
                    borderColor: AppStatusColors.dropped.withValues(alpha: 0.32),
                    backgroundColor: AppStatusColors.dropped.withValues(alpha: 0.06),
                    borderRadius: const BorderRadius.all(Radius.circular(22.0)),
                    padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 16.0),
                    onTap: () => _openShelf(context, ArchiveShelfKind.dropped),
                    child: Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: AppStatusColors.dropped.withValues(alpha: 0.16),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.remove_circle_outline_rounded,
                            color: AppStatusColors.dropped,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Dropped',
                                style: AppThemes.safeGeist(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: colors.ink,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                droppedSubtitle,
                                style: AppThemes.safeGeist(
                                  fontSize: 12.5,
                                  color: colors.sub,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          '$droppedCount',
                          style: GoogleFonts.bodoniModa(
                            fontSize: 22,
                            fontWeight: FontWeight.w400,
                            fontStyle: FontStyle.italic,
                            color: AppStatusColors.dropped.withValues(alpha: 0.85),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context, String subtitle) {
    final colors = context.ambianceColors;

    return Row(
      children: [
        PressableScale(
          onTap: () => Navigator.of(context).pop(),
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: colors.card,
              shape: BoxShape.circle,
              border: Border.all(color: colors.lineRgba),
              boxShadow: [
                BoxShadow(
                  color: colors.scrim.withValues(alpha: colors.isDark ? 0.25 : 0.06),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              Icons.chevron_left_rounded,
              color: colors.ink,
              size: 24,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Your Archive',
                style: GoogleFonts.bodoniModa(
                  fontSize: 30,
                  fontWeight: FontWeight.w400,
                  fontStyle: FontStyle.italic,
                  color: colors.ink,
                  letterSpacing: -0.4,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: AppThemes.safeGeist(
                  fontSize: 13.5,
                  color: colors.sub,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _openShelf(BuildContext context, ArchiveShelfKind kind) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ArchiveShelfScreen(kind: kind),
      ),
    );
  }
}
