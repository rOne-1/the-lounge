import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animations/animations.dart';
import '../constants.dart';
import '../models/media_item.dart';
import '../providers/media_provider.dart';
import '../providers/navigation_provider.dart';
import '../screens/detail_screen.dart';
import 'ambient_glow.dart';
import 'media_image.dart';
import 'pressable_scale.dart';

/// A feature card styled with Screening Room aesthetics (champagne gold accent border,
/// dark glass backdrop #161312, poster image, title, rating, tagline, and re-roll button)
/// that randomly selects a movie from the user's Watchlist (falling back to Saved/Maybe list).
class PickForMeCard extends ConsumerStatefulWidget {
  final bool? enableAnimation;

  const PickForMeCard({
    super.key,
    this.enableAnimation,
  });

  @override
  ConsumerState<PickForMeCard> createState() => _PickForMeCardState();
}

class _PickForMeCardState extends ConsumerState<PickForMeCard> {
  String? _selectedMovieId;

  void _reroll(List<MediaItem> pool) {
    if (pool.isEmpty) return;
    if (pool.length == 1) {
      setState(() {
        _selectedMovieId = pool.first.id;
      });
      return;
    }
    final random = Random();
    int newIndex;
    do {
      newIndex = random.nextInt(pool.length);
    } while (pool[newIndex].id == _selectedMovieId);

    setState(() {
      _selectedMovieId = pool[newIndex].id;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final mediaState = ref.watch(mediaProvider);

    final watchlistMovies = mediaState.watchlist.values
        .where((item) => item.type == MediaType.movie)
        .toList();
    final maybeMovies = mediaState.maybeList.values
        .where((item) => item.type == MediaType.movie)
        .toList();

    final pool = watchlistMovies.isNotEmpty ? watchlistMovies : maybeMovies;

    if (pool.isEmpty) {
      _selectedMovieId = null;
      return _buildEmptyState(context, isDark);
    }

    // Ensure selected item exists in current pool
    MediaItem? selectedItem;
    if (_selectedMovieId != null) {
      final index = pool.indexWhere((item) => item.id == _selectedMovieId);
      if (index != -1) {
        selectedItem = pool[index];
      }
    }

    if (selectedItem == null) {
      final randomIndex = Random().nextInt(pool.length);
      selectedItem = pool[randomIndex];
      _selectedMovieId = selectedItem.id;
    }

    final subColor = isDark ? AppColors.srSub : AppColors.rrSub;
    final inkColor = isDark ? AppColors.srInk : AppColors.rrInk;
    final phColor = isDark ? AppColors.srPh : AppColors.rrPh;
    final accColor = isDark ? AppColors.srAcc : AppColors.rrAcc;

    return AmbientGlowWidget(
      enableAnimation: widget.enableAnimation,
      padding: const EdgeInsets.all(16),
      borderRadius: BorderRadius.circular(18),
      baseColor: isDark ? const Color(0xFF161312) : AppColors.rrCard,
      border: Border.all(
        color: isDark
            ? const Color.fromRGBO(203, 168, 106, 0.45)
            : const Color.fromRGBO(176, 81, 43, 0.35),
        width: 1.2,
      ),
      boxShadow: [
        BoxShadow(
          color: isDark
              ? const Color.fromRGBO(203, 168, 106, 0.08)
              : const Color.fromRGBO(0, 0, 0, 0.05),
          blurRadius: 12,
          offset: const Offset(0, 4),
        )
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Framing Header Text
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color.fromRGBO(203, 168, 106, 0.15)
                      : const Color.fromRGBO(176, 81, 43, 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'PICK FOR ME',
                  style: AppThemes.safeGeist(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                    color: accColor,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Decide from your Watchlist — We picked this for you.',
                  style: AppThemes.safeGeist(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    fontStyle: FontStyle.italic,
                    color: subColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Main Card Content
          OpenContainer(
            transitionDuration: AppPhysics.houseSpringDuration,
            closedElevation: 0,
            openElevation: 0,
            closedColor: Colors.transparent,
            openColor: isDark ? AppColors.srBase : AppColors.rrBase,
            middleColor: Colors.transparent,
            closedShape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            closedBuilder: (context, openContainer) {
              return GestureDetector(
                onTap: openContainer,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Poster Image
                    Container(
                      width: 72,
                      height: 108,
                      decoration: BoxDecoration(
                        color: phColor,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isDark
                              ? AppColors.srLineRgba
                              : AppColors.rrLineRgba,
                        ),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: MediaImage(
                        item: selectedItem!,
                        fit: BoxFit.cover,
                        showFallbackTitle: false,
                      ),
                    ),
                    const SizedBox(width: 14),

                    // Details Column
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            selectedItem.title,
                            style: GoogleFonts.bodoniModa(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: inkColor,
                              height: 1.15,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),

                          // Rating & Release Info
                          Row(
                            children: [
                              if (selectedItem.rating > 0) ...[
                                Icon(
                                  Icons.star,
                                  size: 13,
                                  color: accColor,
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  selectedItem.rating.toStringAsFixed(1),
                                  style: AppThemes.safeGeist(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: inkColor,
                                  ),
                                ),
                                Text(
                                  ' / 10',
                                  style: AppThemes.safeGeist(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w400,
                                    color: subColor,
                                  ),
                                ),
                                const SizedBox(width: 8),
                              ],
                              if (selectedItem.releaseOrAirDate != null)
                                Text(
                                  '${selectedItem.releaseOrAirDate!.year}',
                                  style: AppThemes.safeGeist(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w400,
                                    color: subColor,
                                  ),
                                ),
                              if (selectedItem.runtime != null) ...[
                                Text(
                                  ' · ${selectedItem.runtime} min',
                                  style: AppThemes.safeGeist(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w400,
                                    color: subColor,
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 6),

                          // Tagline or Genres
                          if (selectedItem.tagline != null &&
                              selectedItem.tagline!.trim().isNotEmpty)
                            Text(
                              '"${selectedItem.tagline!.trim()}"',
                              style: AppThemes.safeGeist(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w400,
                                fontStyle: FontStyle.italic,
                                color: subColor,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            )
                          else if (selectedItem.genres.isNotEmpty)
                            Text(
                              selectedItem.genres.take(3).join(' · '),
                              style: AppThemes.safeGeist(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w400,
                                color: subColor,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          if (selectedItem.overview.trim().isNotEmpty) ...[
                            const SizedBox(height: 6),
                            ConstrainedBox(
                              constraints: const BoxConstraints(maxHeight: 64),
                              child: SingleChildScrollView(
                                physics: const BouncingScrollPhysics(),
                                child: Text(
                                  selectedItem.overview.trim(),
                                  style: AppThemes.safeGeist(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w400,
                                    height: 1.35,
                                    color: subColor,
                                  ),
                                ),
                              ),
                            ),
                          ],
                          const SizedBox(height: 10),

                          // Re-roll Button
                          PressableScale(
                            onTap: () => _reroll(pool),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 7,
                              ),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? const Color.fromRGBO(203, 168, 106, 0.15)
                                    : const Color.fromRGBO(176, 81, 43, 0.12),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: isDark
                                      ? const Color.fromRGBO(203, 168, 106, 0.4)
                                      : const Color.fromRGBO(176, 81, 43, 0.3),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.shuffle,
                                    size: 15,
                                    color: accColor,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Re-roll',
                                    style: AppThemes.safeGeist(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: accColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
            openBuilder: (context, _) => DetailScreen(id: selectedItem!.prefixedId),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, bool isDark) {
    final subColor = isDark ? AppColors.srSub : AppColors.rrSub;
    final inkColor = isDark ? AppColors.srInk : AppColors.rrInk;
    final accColor = isDark ? AppColors.srAcc : AppColors.rrAcc;

    return AmbientGlowWidget(
      enableAnimation: widget.enableAnimation,
      padding: const EdgeInsets.all(18),
      borderRadius: BorderRadius.circular(18),
      baseColor: isDark ? const Color(0xFF161312) : AppColors.rrCard,
      border: Border.all(
        color: isDark
            ? const Color.fromRGBO(203, 168, 106, 0.45)
            : const Color.fromRGBO(176, 81, 43, 0.35),
        width: 1.2,
      ),
      boxShadow: [
        BoxShadow(
          color: isDark
              ? const Color.fromRGBO(203, 168, 106, 0.08)
              : const Color.fromRGBO(0, 0, 0, 0.05),
          blurRadius: 12,
          offset: const Offset(0, 4),
        )
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color.fromRGBO(203, 168, 106, 0.15)
                      : const Color.fromRGBO(176, 81, 43, 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'PICK FOR ME',
                  style: AppThemes.safeGeist(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                    color: accColor,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Decide from your Watchlist — We picked this for you.',
                  style: AppThemes.safeGeist(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    fontStyle: FontStyle.italic,
                    color: subColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            'Your movie watchlist is empty. Save titles to enable Pick for me!',
            style: AppThemes.safeGeist(
              fontSize: 13,
              fontWeight: FontWeight.w400,
              color: inkColor,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 14),
          PressableScale(
            onTap: () => ref
                .read(navigationProvider.notifier)
                .setTab(AppTab.discover),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: AppColors.primaryButtonDecoration(
                isDark: isDark,
                borderRadius: 999,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.explore,
                    size: 15,
                    color: isDark ? const Color(0xFF1A140C) : Colors.white,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Discover Movies',
                    style: AppThemes.safeGeist(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: isDark ? const Color(0xFF1A140C) : Colors.white,
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
