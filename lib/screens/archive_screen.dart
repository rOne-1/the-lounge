import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants.dart';
import '../models/media_item.dart';
import '../providers/media_provider.dart';
import '../providers/navigation_provider.dart';
import '../widgets/dashed_border_card.dart';
import '../widgets/pile_summary_card.dart';
import '../widgets/pressable_scale.dart';
import '../widgets/watching_hero_card.dart';
import 'pile_screen.dart';

/// YSR-HUB-1: The Archive Hub (`your collection.png`) - a dedicated visual
/// overview dashboard across all 6 status piles. Features the Hero Watching
/// card, a 2x2 main status grid, and a bottom muted Dropped card. Tapping any
/// card pushes the full-featured [PileScreen].
class ArchiveScreen extends ConsumerWidget {
  const ArchiveScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mediaState = ref.watch(mediaProvider);
    final navState = ref.watch(navigationProvider);
    final isMovies = navState.activeMediaType == MediaTypeToggle.movies;
    final activeType = isMovies ? MediaType.movie : MediaType.tv;
    final colors = context.ambianceColors;
    final isLarge = MediaQuery.of(context).size.width >= 600;
    final paddingHorizontal = isLarge ? 24.0 : 18.0;

    int typeFilteredCount(Map<String, MediaItem> itemsMap) =>
        itemsMap.values.where((item) => item.type == activeType).length;

    final watchlistCount = typeFilteredCount(mediaState.watchlist);
    final savedCount = typeFilteredCount(mediaState.maybeList);
    final watchingCount = typeFilteredCount(mediaState.watchingList);
    final onHoldCount = typeFilteredCount(mediaState.onHoldList);
    final droppedCount = typeFilteredCount(mediaState.droppedList);
    final watchedCount = typeFilteredCount(mediaState.watchedList);

    final totalTitles = watchlistCount +
        savedCount +
        watchingCount +
        onHoldCount +
        droppedCount +
        watchedCount;

    return Scaffold(
      backgroundColor: colors.base,
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            paddingHorizontal,
            16.0,
            paddingHorizontal,
            100.0 + MediaQuery.of(context).padding.bottom,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Bar with Back Button & Header
              _buildTopBar(context, totalTitles),
              const SizedBox(height: 28),

              // 1. Hero Watching Card
              WatchingHeroCard(
                count: watchingCount,
                onTap: () => _openPile(context, PileKind.watching),
              ),
              const SizedBox(height: 14),

              // 2. 2x2 Main Piles Grid (Watched, Watchlist, Saved, On-Hold)
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.18,
                children: [
                  PileSummaryCard(
                    label: PileKind.watched.label,
                    subtitle: '$watchedCount title${watchedCount == 1 ? '' : 's'}',
                    count: watchedCount,
                    icon: PileKind.watched.icon,
                    statusColor: PileKind.watched.statusColor,
                    onTap: () => _openPile(context, PileKind.watched),
                  ),
                  PileSummaryCard(
                    label: PileKind.watchlist.label,
                    subtitle: '$watchlistCount title${watchlistCount == 1 ? '' : 's'}',
                    count: watchlistCount,
                    icon: PileKind.watchlist.icon,
                    statusColor: PileKind.watchlist.statusColor,
                    onTap: () => _openPile(context, PileKind.watchlist),
                  ),
                  PileSummaryCard(
                    label: PileKind.saved.label,
                    subtitle: '$savedCount title${savedCount == 1 ? '' : 's'}',
                    count: savedCount,
                    icon: PileKind.saved.icon,
                    statusColor: PileKind.saved.statusColor,
                    onTap: () => _openPile(context, PileKind.saved),
                  ),
                  PileSummaryCard(
                    label: PileKind.onHold.label,
                    subtitle: '$onHoldCount title${onHoldCount == 1 ? '' : 's'}',
                    count: onHoldCount,
                    icon: PileKind.onHold.icon,
                    statusColor: PileKind.onHold.statusColor,
                    onTap: () => _openPile(context, PileKind.onHold),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // 3. Dropped Pile Dashed Card
              DashedBorderCard(
                borderColor: AppStatusColors.dropped.withValues(alpha: 0.35),
                backgroundColor: colors.card.withValues(alpha: 0.6),
                onTap: () => _openPile(context, PileKind.dropped),
                child: Row(
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: AppStatusColors.dropped.withValues(alpha: 0.16),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.remove_circle_outline_rounded,
                        color: AppStatusColors.dropped,
                        size: 19,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Text(
                      'Dropped',
                      style: AppThemes.safeGeist(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w600,
                        color: colors.ink,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        droppedCount == 0
                            ? 'nothing here — a clean record'
                            : '$droppedCount title${droppedCount == 1 ? '' : 's'}',
                        style: AppThemes.safeGeist(
                          fontSize: 12.5,
                          color: colors.sub,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      color: colors.sub.withValues(alpha: 0.4),
                      size: 13,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context, int totalTitles) {
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
            ),
            child: Icon(
              Icons.arrow_back_ios_new_rounded,
              color: colors.ink,
              size: 16,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Archive',
                style: GoogleFonts.bodoniModa(
                  fontSize: 28,
                  fontWeight: FontWeight.w400,
                  fontStyle: FontStyle.italic,
                  color: colors.ink,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '$totalTitles titles · 6 piles',
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

  void _openPile(BuildContext context, PileKind kind) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => PileScreen(kind: kind)),
    );
  }
}
