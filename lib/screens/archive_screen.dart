import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants.dart';
import '../providers/media_provider.dart';
import '../widgets/dashed_border_card.dart';
import '../widgets/pile_summary_card.dart';
import '../widgets/pressable_scale.dart';
import '../widgets/watching_hero_card.dart';
import 'pile_screen.dart';

/// YSR-HUB-1: The Archive Hub (`your collection.png`) - a dedicated status
/// hub providing access to all 6 status piles (Watching, Watched, Watchlist,
/// Saved, On-Hold, Dropped). Built with luxury status gradients, squircle icon
/// badges, large Bodoni Moda italic count numerals, and a 3-poster depth stack.
/// Fully responsive and width-constrained for multi-device harmony.
class ArchiveScreen extends ConsumerWidget {
  const ArchiveScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.ambianceColors;
    final mediaState = ref.watch(mediaProvider);
    final isLarge = MediaQuery.of(context).size.width >= 600;
    final paddingHorizontal = isLarge ? 24.0 : 18.0;

    int countFor(Map<String, dynamic> itemsMap) => itemsMap.length;

    final watchlistCount = countFor(mediaState.watchlist);
    final savedCount = countFor(mediaState.maybeList);
    final watchingCount = countFor(mediaState.watchingList);
    final onHoldCount = countFor(mediaState.onHoldList);
    final droppedCount = countFor(mediaState.droppedList);
    final watchedCount = countFor(mediaState.watchedList);

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
                  _buildTopBar(context, totalTitles),
                  const SizedBox(height: 24),

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
                    childAspectRatio: 1.16,
                    children: [
                      PileSummaryCard(
                        label: PileKind.watched.label,
                        subtitle: 'titles',
                        count: watchedCount,
                        icon: Icons.check_rounded,
                        statusColor: PileKind.watched.statusColor,
                        onTap: () => _openPile(context, PileKind.watched),
                      ),
                      PileSummaryCard(
                        label: PileKind.watchlist.label,
                        subtitle: 'titles',
                        count: watchlistCount,
                        icon: Icons.bookmark_rounded,
                        statusColor: PileKind.watchlist.statusColor,
                        onTap: () => _openPile(context, PileKind.watchlist),
                      ),
                      PileSummaryCard(
                        label: PileKind.saved.label,
                        subtitle: 'titles',
                        count: savedCount,
                        icon: Icons.favorite_rounded,
                        statusColor: PileKind.saved.statusColor,
                        onTap: () => _openPile(context, PileKind.saved),
                      ),
                      PileSummaryCard(
                        label: PileKind.onHold.label,
                        subtitle: 'titles',
                        count: onHoldCount,
                        icon: Icons.pause_rounded,
                        statusColor: PileKind.onHold.statusColor,
                        onTap: () => _openPile(context, PileKind.onHold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // 3. Dropped Pile Card (Full-width dashed card)
                  DashedBorderCard(
                    borderColor: AppStatusColors.dropped.withValues(alpha: 0.32),
                    backgroundColor: AppStatusColors.dropped.withValues(alpha: 0.06),
                    borderRadius: const BorderRadius.all(Radius.circular(22.0)),
                    padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 16.0),
                    onTap: () => _openPile(context, PileKind.dropped),
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
                                droppedCount == 0
                                    ? 'nothing here — a clean record'
                                    : '$droppedCount title${droppedCount == 1 ? '' : 's'}',
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
              boxShadow: [
                BoxShadow(
                  color: colors.isDark
                      ? const Color(0x18000000)
                      : const Color(0x06000000),
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
                'Your Collection',
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
      MaterialPageRoute(
        builder: (context) => PileScreen(kind: kind),
      ),
    );
  }
}
