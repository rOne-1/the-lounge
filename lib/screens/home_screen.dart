import 'package:flutter/foundation.dart';
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
import '../widgets/quick_status_sheet.dart';
import '../widgets/pick_for_me_card.dart';

class DeduplicatedHomeRails {
  final bool isMovies;
  final List<MediaItem> rail1Items;
  final AsyncValue<List<MediaItem>> trendingAsync;
  final AsyncValue<List<MediaItem>> topRatedDeduplicated;
  final AsyncValue<List<MediaItem>> rail4Deduplicated;
  // E3/TF-25: "On The Air" (the TV-mode content of this rail slot) is
  // removed -- null in TV mode. Movies mode keeps "Upcoming" here.
  final AsyncValue<List<MediaItem>>? rail5Deduplicated;

  const DeduplicatedHomeRails({
    required this.isMovies,
    required this.rail1Items,
    required this.trendingAsync,
    required this.topRatedDeduplicated,
    required this.rail4Deduplicated,
    required this.rail5Deduplicated,
  });
}

class HomeRailsInput {
  final bool isMovies;
  final List<MediaItem> rail1Items;
  final AsyncValue<List<MediaItem>> trendingAsync;
  final AsyncValue<List<MediaItem>> topRatedAsync;
  final AsyncValue<List<MediaItem>> rail4Async;
  final AsyncValue<List<MediaItem>>? rail5Async;

  const HomeRailsInput({
    required this.isMovies,
    required this.rail1Items,
    required this.trendingAsync,
    required this.topRatedAsync,
    required this.rail4Async,
    required this.rail5Async,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HomeRailsInput &&
          runtimeType == other.runtimeType &&
          isMovies == other.isMovies &&
          listEquals(rail1Items, other.rail1Items) &&
          trendingAsync == other.trendingAsync &&
          topRatedAsync == other.topRatedAsync &&
          rail4Async == other.rail4Async &&
          rail5Async == other.rail5Async;

  @override
  int get hashCode => Object.hash(
        isMovies,
        Object.hashAll(rail1Items),
        trendingAsync,
        topRatedAsync,
        rail4Async,
        rail5Async,
      );
}

final deduplicatedHomeRailsProvider = Provider.autoDispose
    .family<DeduplicatedHomeRails, HomeRailsInput>((ref, input) {
  final priorSeenIds = <String>{};
  for (final item in input.rail1Items) {
    priorSeenIds.add(item.id);
    priorSeenIds.add(item.prefixedId);
    priorSeenIds.add(item.id.replaceFirst(RegExp(r'^(movie_|tv_)'), ''));
  }
  final trendingItems = input.trendingAsync.asData?.value ?? [];
  for (final item in trendingItems) {
    priorSeenIds.add(item.id);
    priorSeenIds.add(item.prefixedId);
    priorSeenIds.add(item.id.replaceFirst(RegExp(r'^(movie_|tv_)'), ''));
  }

  List<MediaItem> deduplicateRailList(List<MediaItem> list) {
    final fresh = list.where((item) {
      final cleanId = item.id.replaceFirst(RegExp(r'^(movie_|tv_)'), '');
      return !priorSeenIds.contains(item.id) &&
          !priorSeenIds.contains(item.prefixedId) &&
          !priorSeenIds.contains(cleanId);
    }).toList();
    return fresh.isNotEmpty ? fresh : list;
  }

  final topRatedDeduplicated = input.topRatedAsync.whenData(deduplicateRailList);
  final rail4Deduplicated = input.rail4Async.whenData(deduplicateRailList);
  final rail5Deduplicated = input.rail5Async?.whenData(deduplicateRailList);

  return DeduplicatedHomeRails(
    isMovies: input.isMovies,
    rail1Items: input.rail1Items,
    trendingAsync: input.trendingAsync,
    topRatedDeduplicated: topRatedDeduplicated,
    rail4Deduplicated: rail4Deduplicated,
    rail5Deduplicated: rail5Deduplicated,
  );
});

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
    // E3/TF-25: "On The Air" TV carousel removed -- movies mode keeps
    // "Upcoming" in this rail slot, TV mode no longer fetches or renders
    // anything here.
    final rail5Async = isMovies ? ref.watch(upcomingMoviesProvider) : null;

    final popularAsync = ref.watch(popularMoviesProvider);
    final mediaState = ref.watch(mediaProvider);

    final activeType = isMovies ? MediaType.movie : MediaType.tv;
    final rail1Items = mediaState.watchingList.values
        .where((m) => m.type == activeType)
        .toList();
    // E12: same source and ordering as YourSpaceScreen's own Watchlist tab
    // (insertion order, no re-sort) so "See all" doesn't reorder things
    // relative to what was just shown in the carousel.
    final watchlistItems = mediaState.watchlist.values
        .where((m) => m.type == activeType)
        .toList();

    final railsInput = HomeRailsInput(
      isMovies: isMovies,
      rail1Items: rail1Items,
      trendingAsync: trendingAsync,
      topRatedAsync: topRatedAsync,
      rail4Async: rail4Async,
      rail5Async: rail5Async,
    );

    final homeRails = ref.watch(deduplicatedHomeRailsProvider(railsInput));
    final topRatedDeduplicated = homeRails.topRatedDeduplicated;
    final rail4Deduplicated = homeRails.rail4Deduplicated;
    final rail5Deduplicated = homeRails.rail5Deduplicated;


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

    final isDark = context.ambianceColors.isDark;

    final subColor = context.ambianceColors.sub;
    final pillColor = context.ambianceColors.pill;
    final accColor = context.ambianceColors.acc;
    final inkColor = context.ambianceColors.ink;

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

            // RAIL 1: Pick For Me (Movies) or Continue Watching (TV)
            if (isMovies) ...[
              PickForMeCard(enableAnimation: enableAnimation),
            ] else ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Expanded(
                    child: Text(
                      'Continue watching',
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
                duration: AppPhysics.houseSpringDuration,
                switchInCurve: AppPhysics.houseSpringCurve,
                switchOutCurve: AppPhysics.houseSpringCurve,
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
                                child: TvContinueWatchingCard(item: item, isDark: isDark),
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
                            'No shows in progress. Explore and start watching!',
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
                  crossFadeState: (!isMovies && rail1Items.isNotEmpty)
                      ? CrossFadeState.showFirst
                      : CrossFadeState.showSecond,
                  firstChild: (!isMovies && rail1Items.isNotEmpty)
                      ? NextEpisodeBannerCarousel(
                          shows: rail1Items,
                          isDark: isDark,
                          enableAnimation: enableAnimation,
                        )
                      : const SizedBox(width: double.infinity, height: 0),
                  secondChild: const SizedBox(width: double.infinity, height: 0),
                ),
              ),
            ],

            // RAIL 1B: Your Watchlist (E12/TF-17) -- local data, not TMDB,
            // wrapped in AsyncValue.data so it can reuse MediaRail (including
            // its empty-state hide-the-whole-rail behavior).
            MediaRail(
              title: 'Your Watchlist',
              itemsAsync: AsyncValue.data(watchlistItems),
              isDark: isDark,
              onSeeAll: () =>
                  ref.read(navigationProvider.notifier).setTab(AppTab.yourSpace),
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
              itemsAsync: topRatedDeduplicated,
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
              itemsAsync: rail4Deduplicated,
              isDark: isDark,
              onSeeAll: () {
                // B8/TF-23: MediaListScreen's default page-fetch routing
                // guesses which repository method to call from the title
                // string and only ever passes `page` -- it has no way to
                // also carry region, the one extra parameter
                // getNowPlayingMovies needs. Without it, "Load More" pages
                // silently fell back to the US region regardless of the
                // user's actual watch-providers country, producing a
                // mismatched/inconsistent list that read as broken
                // pagination. Explicit fetchPage keeps every page on the
                // same region as the initial load.
                final country = ref.read(
                  mediaProvider.select((s) => s.watchProvidersCountry),
                );
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => MediaListScreen(
                      title: isMovies ? 'Now Playing in Theaters' : 'Airing Today',
                      itemsProvider: isMovies
                          ? nowPlayingMoviesProvider
                          : airingTodayTvShowsProvider,
                      fetchPage: isMovies
                          ? (page) => ref
                              .read(movieRepositoryProvider)
                              .getNowPlayingMovies(page: page, region: country)
                          : null,
                    ),
                  ),
                );
              },
            ),

            // RAIL 5: Upcoming (Movies only -- E3/TF-25 removed the TV-mode
            // "On The Air" carousel that used to share this slot).
            if (isMovies && rail5Deduplicated != null)
              MediaRail(
                title: 'Upcoming',
                itemsAsync: rail5Deduplicated,
                isDark: isDark,
                onSeeAll: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => MediaListScreen(
                        title: 'Upcoming Movies',
                        itemsProvider: upcomingMoviesProvider,
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
                color: context.ambianceColors.acc.withValues(alpha: isDark ? 0.4 : 0.36),
              ),
              boxShadow: [
                BoxShadow(
                  color: context.ambianceColors.surfaceHighlight,
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
                      color: isDark ? inkColor : context.ambianceColors.acc,
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
                      decoration: context.ambianceColors.primaryButtonDecoration.copyWith(borderRadius: BorderRadius.circular(999)),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Enter Discover',
                            style: AppThemes.safeGeist(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).colorScheme.onPrimary,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            Icons.arrow_forward,
                            size: 15,
                            color: Theme.of(context).colorScheme.onPrimary,
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
    final subColor = context.ambianceColors.sub;
    final inkColor = context.ambianceColors.ink;
    final phColor = context.ambianceColors.ph;
    final lineRgba = context.ambianceColors.lineRgba;
    final accColor = context.ambianceColors.acc;

    final seasonsAsync = ref.watch(tvShowSeasonsProvider(item));

    return OpenContainer(
      transitionDuration: AppPhysics.houseSpringDuration,
      closedElevation: 0,
      openElevation: 0,
      closedColor: Colors.transparent,
      openColor: context.ambianceColors.base,
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
          onLongPress: () => showQuickStatusSheet(context, ref, item),
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
                        color: context.ambianceColors.surfaceHighlight,
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
                            color: context.ambianceColors.scrim,
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
                          color: context.ambianceColors.scrim.withValues(
                            alpha: context.ambianceColors.scrim.a * 0.3,
                          ),
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

class MovieWatchlistCard extends ConsumerWidget {
  final MediaItem item;
  final bool isDark;

  const MovieWatchlistCard({
    super.key,
    required this.item,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subColor = context.ambianceColors.sub;
    final inkColor = context.ambianceColors.ink;
    final phColor = context.ambianceColors.ph;
    final lineRgba = context.ambianceColors.lineRgba;

    final genreLabel = item.genres.isNotEmpty ? item.genres.first : 'Movie';
    final runtimeLabel = item.runtime != null ? '${item.runtime} min' : 'Up Next';

    return OpenContainer(
      transitionDuration: AppPhysics.houseSpringDuration,
      closedElevation: 0,
      openElevation: 0,
      closedColor: Colors.transparent,
      openColor: context.ambianceColors.base,
      middleColor: Colors.transparent,
      closedShape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      closedBuilder: (context, openContainer) {
        return GestureDetector(
          onTap: openContainer,
          onLongPress: () => showQuickStatusSheet(context, ref, item),
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
                        color: context.ambianceColors.surfaceHighlight,
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

class MediaRail extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
    final subColor = context.ambianceColors.sub;
    final inkColor = context.ambianceColors.ink;
    final phColor = context.ambianceColors.ph;
    final lineRgba = context.ambianceColors.lineRgba;

    // Hide the whole rail -- header, "See all", everything -- once data has
    // genuinely resolved empty, rather than leaving the header floating
    // over blank space with no explanation (loading/error states still
    // render normally below).
    if (itemsAsync.asData?.value.isEmpty ?? false) {
      return const SizedBox.shrink();
    }

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
          duration: AppPhysics.houseSpringDuration,
          switchInCurve: AppPhysics.houseSpringCurve,
          switchOutCurve: Curves.easeOut,
          child: SizedBox(
            key: ValueKey('${title}_${itemsAsync.isLoading}'),
            height: 144,
            child: itemsAsync.when(
              // Empty is handled by the whole-widget guard at the top of
              // build() -- data here is guaranteed non-empty.
              data: (items) {
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
                          openColor: context.ambianceColors.base,
                          middleColor: Colors.transparent,
                          closedShape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(11),
                          ),
                          closedBuilder: (context, openContainer) {
                            return GestureDetector(
                              onTap: openContainer,
                              onLongPress: () => showQuickStatusSheet(context, ref, item),
                              child: Container(
                                width: 96,
                                height: 144,
                                decoration: BoxDecoration(
                                  color: phColor,
                                  border: Border.all(color: lineRgba),
                                  borderRadius: BorderRadius.circular(11),
                                  boxShadow: [
                                    BoxShadow(
                                      color: context.ambianceColors.surfaceHighlight,
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

class NextEpisodeBannerCarousel extends ConsumerStatefulWidget {
  final List<MediaItem> shows;
  final bool isDark;
  final bool? enableAnimation;

  const NextEpisodeBannerCarousel({
    super.key,
    required this.shows,
    required this.isDark,
    this.enableAnimation,
  });

  @override
  ConsumerState<NextEpisodeBannerCarousel> createState() =>
      _NextEpisodeBannerCarouselState();
}

class _NextEpisodeBannerCarouselState
    extends ConsumerState<NextEpisodeBannerCarousel> {
  late PageController _pageController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final validShows = <MediaItem>[];
    for (final show in widget.shows) {
      final seasonsAsync = ref.watch(tvShowSeasonsProvider(show));
      final seasons = seasonsAsync.value ?? [];
      if (seasonsAsync.isLoading) {
        validShows.add(show);
      } else {
        final nextEp = ref
            .read(mediaProvider.notifier)
            .getNextUnwatchedEpisode(showId: show.id, seasons: seasons);
        if (nextEp != null) {
          validShows.add(show);
        }
      }
    }

    if (validShows.isEmpty) {
      return const SizedBox(width: double.infinity, height: 0);
    }

    if (validShows.length == 1) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 22),
          NextEpisodeBannerCard(
            show: validShows.first,
            isDark: widget.isDark,
            enableAnimation: widget.enableAnimation,
          ),
        ],
      );
    }

    final activeIndex = _currentPage.clamp(0, validShows.length - 1);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 22),
        SizedBox(
          height: 116,
          child: PageView.builder(
            controller: _pageController,
            itemCount: validShows.length,
            onPageChanged: (index) {
              setState(() {
                _currentPage = index;
              });
            },
            itemBuilder: (context, index) {
              return NextEpisodeBannerCard(
                show: validShows[index],
                isDark: widget.isDark,
                enableAnimation: widget.enableAnimation,
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(validShows.length, (index) {
            final isSelected = index == activeIndex;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: isSelected ? 16 : 6,
              height: 6,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(3),
                color: isSelected
                    ? context.ambianceColors.acc
                    : context.ambianceColors.sub.withValues(alpha: 0.31),
              ),
            );
          }),
        ),
      ],
    );
  }
}

class NextEpisodeBannerCard extends ConsumerWidget {
  final MediaItem show;
  final bool isDark;
  final bool? enableAnimation;

  const NextEpisodeBannerCard({
    super.key,
    required this.show,
    required this.isDark,
    this.enableAnimation,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subColor = context.ambianceColors.sub;
    final inkColor = context.ambianceColors.ink;
    final phColor = context.ambianceColors.ph;

    final seasonsAsync = ref.watch(tvShowSeasonsProvider(show));

    return seasonsAsync.when(
      data: (seasons) {
        final nextEp = ref.read(mediaProvider.notifier).getNextUnwatchedEpisode(
              showId: show.id,
              seasons: seasons,
            );

        if (nextEp == null) {
          return const SizedBox(width: double.infinity, height: 0);
        }

        final episodeCode = 'S${nextEp.seasonNumber} E${nextEp.episodeNumber}';
        final String airDateStr;
        if (nextEp.airDate != null) {
          final formatted = _formatEpisodeDate(nextEp.airDate!);
          airDateStr = nextEp.airDate!.isAfter(DateTime.now())
              ? 'Airs $formatted · ${nextEp.name}'
              : 'Aired $formatted · ${nextEp.name}';
        } else {
          airDateStr = nextEp.name;
        }

        return PressableScale(
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => DetailScreen(id: show.prefixedId)),
          ),
          onLongPress: () => showQuickStatusSheet(context, ref, show),
          child: AmbientGlowWidget(
            enableAnimation: enableAnimation,
            padding: const EdgeInsets.all(14),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: context.ambianceColors.statusSave.withValues(alpha: 0.42),
            ),
            boxShadow: [
              BoxShadow(
                color: context.ambianceColors.surfaceHighlight,
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
                      color: context.ambianceColors.statusSave.withValues(alpha: 0.33),
                    ),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: MediaImage(
                    item: show,
                    imageUrl: nextEp.stillUrl ?? show.posterUrl ?? show.backdropUrl,
                    fit: BoxFit.cover,
                    showFallbackTitle: false,
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
                          color: context.ambianceColors.statusSave,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${show.title} · $episodeCode',
                        style: AppThemes.safeGeist(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: inkColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        airDateStr,
                        style: AppThemes.safeGeist(
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          color: subColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                PressableScale(
                  onTap: () => ref
                      .read(navigationProvider.notifier)
                      .setTab(AppTab.calendar),
                  child: Column(
                    children: [
                      Icon(
                        Icons.calendar_today_outlined,
                        color: context.ambianceColors.statusSave,
                        size: 22,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Calendar',
                        style: AppThemes.safeGeist(
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          color: context.ambianceColors.statusSave,
                        ),
                      ),
                    ],
                  ),
                )
              ],
            ),
          ),
        );
      },
      loading: () => const SizedBox(width: double.infinity, height: 0),
      error: (_, __) => const SizedBox(width: double.infinity, height: 0),
    );
  }

  String _formatEpisodeDate(DateTime dt) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final w = weekdays[dt.weekday - 1];
    final m = months[dt.month - 1];
    return '$w, $m ${dt.day}';
  }
}
