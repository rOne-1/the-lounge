import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:animations/animations.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/navigation_provider.dart';
import '../providers/media_provider.dart';
import '../models/media_item.dart';
import 'detail_screen.dart';
import 'media_list_screen.dart';
import '../constants.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/fallback_widgets.dart';
import '../widgets/segmented_toggle.dart';
import '../widgets/pressable_scale.dart';
import '../widgets/ambient_glow.dart';

class HomeScreen extends ConsumerWidget {
  final bool? enableAnimation;

  const HomeScreen({super.key, this.enableAnimation});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final navState = ref.watch(navigationProvider);
    final isMovies = navState.activeMediaType == MediaTypeToggle.movies;

    final trendingAsync = isMovies
        ? ref.watch(trendingMoviesProvider)
        : ref.watch(trendingTvShowsProvider);
    final topRatedAsync = isMovies
        ? ref.watch(topRatedMoviesProvider)
        : ref.watch(topRatedTvShowsProvider);
    final rail4Async = isMovies
        ? ref.watch(nowPlayingMoviesProvider)
        : ref.watch(airingTodayTvShowsProvider);
    final rail5Async = isMovies
        ? ref.watch(upcomingMoviesProvider)
        : ref.watch(onTheAirTvShowsProvider);

    final popularAsync = ref.watch(popularMoviesProvider);
    final mediaState = ref.watch(mediaProvider);

    String greeting() {
      final now = DateTime.now();
      const dayNames = [
        'Monday',
        'Tuesday',
        'Wednesday',
        'Thursday',
        'Friday',
        'Saturday',
        'Sunday',
      ];
      final dayName = dayNames[now.weekday - 1];
      final timeOfDay = now.hour < 12
          ? 'morning'
          : (now.hour < 17 ? 'afternoon' : 'evening');
      return '$dayName $timeOfDay';
    }

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final subColor = isDark ? AppColors.srSub : AppColors.rrSub;
    final pillColor = isDark ? AppColors.srPill : AppColors.rrPill;
    final accColor = isDark ? AppColors.srAcc : AppColors.rrAcc;
    final inkColor = isDark ? AppColors.srInk : AppColors.rrInk;
    final phColor = isDark ? AppColors.srPh : AppColors.rrPh;

    final bottomPadding = MediaQuery.of(context).padding.bottom;

    if (trendingAsync.hasError && popularAsync.hasError) {
      final err = trendingAsync.error ?? popularAsync.error;
      final message = err.toString().replaceAll('Exception: ', '');
      return FullScreenErrorWidget(
        message: message.isNotEmpty
            ? message
            : 'Failed to load content. Please check your connection.',
        onRetry: () {
          ref.invalidate(trendingMoviesProvider);
          ref.invalidate(trendingTvShowsProvider);
          ref.invalidate(popularMoviesProvider);
          ref.invalidate(topRatedMoviesProvider);
          ref.invalidate(topRatedTvShowsProvider);
        },
      );
    }

    final isLarge = MediaQuery.of(context).size.width >= 600;

    // Collect Rail 1 items based on active media type
    List<MediaItem> getRail1Items() {
      if (isMovies) {
        final watchlistMovies = mediaState.watchlist.values
            .where((m) => m.type == MediaType.movie)
            .toList();
        if (watchlistMovies.isNotEmpty) {
          return watchlistMovies;
        }
        // Fallback to popular movies if watchlist is empty
        return popularAsync.maybeWhen(
          data: (items) => items.where((m) => m.type == MediaType.movie).toList(),
          orElse: () => const [],
        );
      } else {
        // TV mode: collect TV shows from watchedEpisodes keys or watchedList/watchlist
        final watchedTvIds = mediaState.watchedEpisodes.keys.toSet();
        final tvItems = <MediaItem>[];

        for (final id in watchedTvIds) {
          final item = mediaState.watchedList[id] ?? mediaState.watchlist[id];
          if (item != null && item.type == MediaType.tv) {
            tvItems.add(item);
          }
        }

        // Add any other TV shows in watchedList/watchlist not yet added
        for (final item in [...mediaState.watchedList.values, ...mediaState.watchlist.values]) {
          if (item.type == MediaType.tv && !tvItems.any((i) => i.id == item.id)) {
            tvItems.add(item);
          }
        }

        if (tvItems.isNotEmpty) {
          return tvItems;
        }

        // Fallback to trending TV shows if no watched TV shows in state
        return trendingAsync.maybeWhen(
          data: (items) => items.where((m) => m.type == MediaType.tv).toList(),
          orElse: () => const [],
        );
      }
    }

    final rail1Items = getRail1Items();

    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
            isLarge ? 24.0 : 18.0, 4.0, isLarge ? 24.0 : 18.0, 4.0 + bottomPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Greeting Header
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      greeting().toUpperCase(),
                      style: AppThemes.safeGeist(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 1.9,
                        color: subColor,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'What are we\nwatching?',
                      style: GoogleFonts.bodoniModa(
                        fontSize: 30,
                        fontWeight: FontWeight.w600,
                        fontStyle: FontStyle.italic,
                        color: inkColor,
                        height: 1.05,
                      ),
                    ),
                  ],
                ),
                PressableScale(
                  onTap: () => ref
                      .read(navigationProvider.notifier)
                      .setTab(AppTab.search),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: pillColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.search, color: accColor, size: 19),
                  ),
                ),
              ],
            ),
            if (!isLarge) ...[
              const SizedBox(height: 16),
              // Movie / TV Toggle
              SegmentedMediaTypeToggle(
                activeType: navState.activeMediaType,
                onChanged: (type) => ref
                    .read(navigationProvider.notifier)
                    .setMediaType(type),
                isDark: isDark,
              ),
              const SizedBox(height: 22),
            ] else
              const SizedBox(height: 16),

            // RAIL 1: Continue Watching / Up Next From Your Watchlist
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Expanded(
                  child: Text(
                    isMovies ? 'Up Next From Your Watchlist' : 'Continue watching',
                    style: AppThemes.safeGeist(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: inkColor,
                    ),
                  ),
                ),
                PressableScale(
                  onTap: () => ref
                      .read(navigationProvider.notifier)
                      .setTab(AppTab.yourSpace),
                  child: Text(
                    'See all',
                    style: AppThemes.safeGeist(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: subColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              switchInCurve: Curves.easeInOutCubic,
              switchOutCurve: Curves.easeInOutCubic,
              child: SizedBox(
                key: ValueKey('continue_watching_${isMovies}_${rail1Items.length}'),
                height: 140,
                child: rail1Items.isNotEmpty
                    ? ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: rail1Items.length,
                        itemBuilder: (context, index) {
                          final item = rail1Items[index];
                          return Padding(
                            padding: const EdgeInsets.only(right: 12.0),
                            child: PressableScale(
                              child: isMovies
                                  ? MovieWatchlistCard(item: item, isDark: isDark)
                                  : TvContinueWatchingCard(item: item, isDark: isDark),
                            ),
                          ).animate().fade(duration: 250.ms).slideY(
                              begin: 0.1,
                              end: 0,
                              delay: (index.clamp(0, 5) * 40).ms);
                        },
                      )
                    : Container(
                        alignment: Alignment.centerLeft,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          isMovies
                              ? 'Your watchlist is empty. Save movies to see them here!'
                              : 'No shows in progress. Explore and start watching!',
                          style: AppThemes.safeGeist(
                            fontSize: 12.5,
                            fontStyle: FontStyle.italic,
                            color: subColor,
                          ),
                        ),
                      ),
              ),
            ),

            // Next episode highlight banner (TV Mode)
            AnimatedSize(
              duration: const Duration(milliseconds: 350),
              curve: AppPhysics.houseSpringCurve,
              child: AnimatedCrossFade(
                duration: const Duration(milliseconds: 350),
                firstCurve: Curves.easeInOutCubic,
                secondCurve: Curves.easeInOutCubic,
                sizeCurve: AppPhysics.houseSpringCurve,
                crossFadeState: !isMovies
                    ? CrossFadeState.showFirst
                    : CrossFadeState.showSecond,
                firstChild: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 22),
                    PressableScale(
                      onTap: () => ref
                          .read(navigationProvider.notifier)
                          .setTab(AppTab.calendar),
                      child: AmbientGlowWidget(
                        enableAnimation: enableAnimation,
                        padding: const EdgeInsets.all(14),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isDark
                              ? const Color.fromRGBO(214, 151, 132, 0.42)
                              : const Color.fromRGBO(167, 106, 80, 0.42),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: isDark
                                ? const Color.fromRGBO(255, 255, 255, 0.08)
                                : const Color.fromRGBO(255, 255, 255, 0.5),
                            offset: const Offset(0, 1),
                            blurStyle: BlurStyle.inner,
                          )
                        ],
                        child: Row(
                          children: [
                            Container(
                              width: 56,
                              height: 84,
                              decoration: BoxDecoration(
                                color: phColor,
                                borderRadius: BorderRadius.circular(9),
                                border: Border.all(
                                  color: isDark
                                      ? const Color.fromRGBO(214, 151, 132, 0.32)
                                      : const Color.fromRGBO(167, 106, 80, 0.34),
                                ),
                              ),
                            ),
                            const SizedBox(width: 13),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'NEXT EPISODE',
                                    style: AppThemes.safeGeist(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 1.1,
                                      color: isDark
                                          ? const Color(0xFFE0A894)
                                          : const Color(0xFFA76A50),
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    'Severance · S2 E6',
                                    style: AppThemes.safeGeist(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: inkColor,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Airs in 2 days · Fri, Aug 2',
                                    style: AppThemes.safeGeist(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w400,
                                      color: subColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              children: [
                                Icon(
                                  Icons.calendar_today_outlined,
                                  color: isDark
                                      ? const Color(0xFFE0A894)
                                      : const Color(0xFFA76A50),
                                  size: 22,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Calendar',
                                  style: AppThemes.safeGeist(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w600,
                                    color: isDark
                                        ? const Color(0xFFE0A894)
                                        : const Color(0xFFA76A50),
                                  ),
                                ),
                              ],
                            )
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                secondChild: const SizedBox(width: double.infinity, height: 0),
              ),
            ),

            // RAIL 2: Trending This Week
            MediaRail(
              title: 'Trending This Week',
              itemsAsync: trendingAsync,
              isDark: isDark,
              onSeeAll: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => MediaListScreen(
                      title: isMovies ? 'Trending Movies' : 'Trending TV Shows',
                      itemsProvider: isMovies
                          ? trendingMoviesProvider
                          : trendingTvShowsProvider,
                    ),
                  ),
                );
              },
            ),

            // RAIL 3: Top Rated
            MediaRail(
              title: 'Top Rated',
              itemsAsync: topRatedAsync,
              isDark: isDark,
              onSeeAll: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => MediaListScreen(
                      title: isMovies ? 'Top Rated Movies' : 'Top Rated TV Shows',
                      itemsProvider: isMovies
                          ? topRatedMoviesProvider
                          : topRatedTvShowsProvider,
                    ),
                  ),
                );
              },
            ),

            // RAIL 4: Now Playing (Movies) / Airing Today (TV)
            MediaRail(
              title: isMovies ? 'Now Playing' : 'Airing Today',
              itemsAsync: rail4Async,
              isDark: isDark,
              onSeeAll: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => MediaListScreen(
                      title: isMovies ? 'Now Playing in Theaters' : 'Airing Today',
                      itemsProvider: isMovies
                          ? nowPlayingMoviesProvider
                          : airingTodayTvShowsProvider,
                    ),
                  ),
                );
              },
            ),

            // RAIL 5: Upcoming (Movies) / On The Air (TV)
            MediaRail(
              title: isMovies ? 'Upcoming' : 'On The Air',
              itemsAsync: rail5Async,
              isDark: isDark,
              onSeeAll: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => MediaListScreen(
                      title: isMovies ? 'Upcoming Movies' : 'On The Air',
                      itemsProvider: isMovies
                          ? upcomingMoviesProvider
                          : onTheAirTvShowsProvider,
                    ),
                  ),
                );
              },
            ),

            // Discover Invitation
            const SizedBox(height: 22),
            AmbientGlowWidget(
              enableAnimation: enableAnimation,
              padding: const EdgeInsets.all(18),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isDark
                    ? const Color.fromRGBO(203, 168, 106, 0.4)
                    : const Color.fromRGBO(176, 81, 43, 0.36),
              ),
              boxShadow: [
                BoxShadow(
                  color: isDark
                      ? const Color.fromRGBO(255, 255, 255, 0.1)
                      : const Color.fromRGBO(255, 255, 255, 0.5),
                  offset: const Offset(0, 1),
                  blurStyle: BlurStyle.inner,
                )
              ],
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Not sure what to pick?',
                    style: GoogleFonts.bodoniModa(
                      fontSize: 21,
                      fontWeight: FontWeight.w600,
                      fontStyle: FontStyle.italic,
                      color: isDark ? inkColor : const Color(0xFF7A3418),
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'Swipe through tonight\'s stack. Skip, save, or add — one title at a time.',
                    style: AppThemes.safeGeist(
                      fontSize: 12.5,
                      height: 1.5,
                      fontWeight: FontWeight.w400,
                      color: subColor,
                    ),
                  ),
                  const SizedBox(height: 13),
                  PressableScale(
                    onTap: () => ref
                        .read(navigationProvider.notifier)
                        .setTab(AppTab.discover),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 9),
                      decoration: AppColors.primaryButtonDecoration(
                          isDark: isDark, borderRadius: 999),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Enter Discover',
                            style: AppThemes.safeGeist(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? const Color(0xFF1A140C)
                                  : Colors.white,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            Icons.arrow_forward,
                            size: 15,
                            color: isDark
                                ? const Color(0xFF1A140C)
                                : Colors.white,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class TvContinueWatchingCard extends ConsumerWidget {
  final MediaItem item;
  final bool isDark;

  const TvContinueWatchingCard({
    super.key,
    required this.item,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subColor = isDark ? AppColors.srSub : AppColors.rrSub;
    final inkColor = isDark ? AppColors.srInk : AppColors.rrInk;
    final phColor = isDark ? AppColors.srPh : AppColors.rrPh;
    final lineRgba = isDark ? AppColors.srLineRgba : AppColors.rrLineRgba;
    final accColor = isDark ? AppColors.srAcc : AppColors.rrAcc;

    final seasonsAsync = ref.watch(tvShowSeasonsProvider(item));

    return OpenContainer(
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
        final seasons = seasonsAsync.value ?? [];
        final nextEp = ref.read(mediaProvider.notifier).getNextUnwatchedEpisode(
              showId: item.id,
              seasons: seasons,
            );

        final String subtitle;
        final String badgeText;
        if (nextEp != null) {
          subtitle = 'Next: S${nextEp.seasonNumber} E${nextEp.episodeNumber} · ${nextEp.name}';
          badgeText = 'S${nextEp.seasonNumber} · E${nextEp.episodeNumber}';
        } else {
          subtitle = 'All episodes watched';
          badgeText = 'Done';
        }

        return GestureDetector(
          onTap: openContainer,
          child: SizedBox(
            width: 140,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 85,
                  decoration: BoxDecoration(
                    color: phColor,
                    border: Border.all(color: lineRgba),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: isDark
                            ? const Color.fromRGBO(255, 255, 255, 0.05)
                            : const Color.fromRGBO(255, 255, 255, 0.5),
                        blurRadius: 0,
                        spreadRadius: 0,
                        offset: const Offset(0, 1),
                        blurStyle: BlurStyle.inner,
                      )
                    ],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      MediaImage(
                        item: item,
                        fit: BoxFit.cover,
                        showFallbackTitle: false,
                      ),
                      Positioned(
                        top: 8,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color.fromRGBO(0, 0, 0, 0.65)
                                : const Color.fromRGBO(44, 32, 22, 0.75),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            badgeText,
                            style: AppThemes.safeGeist(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        child: Container(
                          height: 3,
                          color: isDark
                              ? const Color.fromRGBO(0, 0, 0, 0.4)
                              : const Color.fromRGBO(44, 32, 22, 0.18),
                          alignment: Alignment.centerLeft,
                          child: FractionallySizedBox(
                            widthFactor: nextEp != null ? 0.4 : 1.0,
                            child: Container(color: accColor),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  item.title,
                  style: AppThemes.safeGeist(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: inkColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: AppThemes.safeGeist(
                    fontSize: 11,
                    fontWeight: FontWeight.w400,
                    color: subColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        );
      },
      openBuilder: (context, _) => DetailScreen(id: item.prefixedId),
    );
  }
}

class MovieWatchlistCard extends StatelessWidget {
  final MediaItem item;
  final bool isDark;

  const MovieWatchlistCard({
    super.key,
    required this.item,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final subColor = isDark ? AppColors.srSub : AppColors.rrSub;
    final inkColor = isDark ? AppColors.srInk : AppColors.rrInk;
    final phColor = isDark ? AppColors.srPh : AppColors.rrPh;
    final lineRgba = isDark ? AppColors.srLineRgba : AppColors.rrLineRgba;

    final genreLabel = item.genres.isNotEmpty ? item.genres.first : 'Movie';
    final runtimeLabel = item.runtime != null ? '${item.runtime} min' : 'Up Next';

    return OpenContainer(
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
          child: SizedBox(
            width: 132,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 82.5,
                  decoration: BoxDecoration(
                    color: phColor,
                    border: Border.all(color: lineRgba),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: isDark
                            ? const Color.fromRGBO(255, 255, 255, 0.05)
                            : const Color.fromRGBO(255, 255, 255, 0.5),
                        blurRadius: 0,
                        spreadRadius: 0,
                        offset: const Offset(0, 1),
                        blurStyle: BlurStyle.inner,
                      )
                    ],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: MediaImage(
                    item: item,
                    fit: BoxFit.cover,
                    showFallbackTitle: false,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  item.title,
                  style: AppThemes.safeGeist(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: inkColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '$genreLabel · $runtimeLabel',
                  style: AppThemes.safeGeist(
                    fontSize: 11,
                    fontWeight: FontWeight.w400,
                    color: subColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        );
      },
      openBuilder: (context, _) => DetailScreen(id: item.prefixedId),
    );
  }
}

class MediaRail extends StatelessWidget {
  final String title;
  final AsyncValue<List<MediaItem>> itemsAsync;
  final VoidCallback? onSeeAll;
  final bool isDark;

  const MediaRail({
    super.key,
    required this.title,
    required this.itemsAsync,
    this.onSeeAll,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final subColor = isDark ? AppColors.srSub : AppColors.rrSub;
    final inkColor = isDark ? AppColors.srInk : AppColors.rrInk;
    final phColor = isDark ? AppColors.srPh : AppColors.rrPh;
    final lineRgba = isDark ? AppColors.srLineRgba : AppColors.rrLineRgba;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Expanded(
              child: Text(
                title,
                style: AppThemes.safeGeist(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: inkColor,
                ),
              ),
            ),
            PressableScale(
              onTap: onSeeAll,
              child: Text(
                'See all',
                style: AppThemes.safeGeist(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: subColor,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          switchInCurve: Curves.easeInOutCubic,
          switchOutCurve: Curves.easeInOutCubic,
          child: SizedBox(
            key: ValueKey('${title}_${itemsAsync.isLoading}'),
            height: 144,
            child: itemsAsync.when(
              data: (items) {
                if (items.isEmpty) return const SizedBox.shrink();

                return ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: PressableScale(
                        child: OpenContainer(
                          transitionDuration: AppPhysics.houseSpringDuration,
                          closedElevation: 0,
                          openElevation: 0,
                          closedColor: Colors.transparent,
                          openColor: isDark ? AppColors.srBase : AppColors.rrBase,
                          middleColor: Colors.transparent,
                          closedShape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(11),
                          ),
                          closedBuilder: (context, openContainer) {
                            return GestureDetector(
                              onTap: openContainer,
                              child: Container(
                                width: 96,
                                height: 144,
                                decoration: BoxDecoration(
                                  color: phColor,
                                  border: Border.all(color: lineRgba),
                                  borderRadius: BorderRadius.circular(11),
                                  boxShadow: [
                                    BoxShadow(
                                      color: isDark
                                          ? const Color.fromRGBO(255, 255, 255, 0.05)
                                          : const Color.fromRGBO(255, 255, 255, 0.5),
                                      offset: const Offset(0, 1),
                                      blurStyle: BlurStyle.inner,
                                    ),
                                  ],
                                ),
                                clipBehavior: Clip.antiAlias,
                                child: MediaImage(
                                  item: item,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            );
                          },
                          openBuilder: (context, _) => DetailScreen(id: item.prefixedId),
                        ),
                      ),
                    ).animate().fade(duration: 250.ms).slideY(
                          begin: 0.1,
                          end: 0,
                          delay: (index.clamp(0, 5) * 40).ms,
                        );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: InlinePartialErrorWidget(
                  message: title.startsWith('Trending')
                      ? 'Failed to load Trending titles'
                      : 'Failed to load $title',
                  onRetry: () {},
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
