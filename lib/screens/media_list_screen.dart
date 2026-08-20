import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/media_item.dart';
import '../constants.dart';
import '../providers/hall_provider.dart';
import '../providers/repository_provider.dart';
import '../widgets/fallback_widgets.dart';
import '../widgets/media_card.dart';
import '../widgets/pressable_scale.dart';

typedef RailFullListScreen = MediaListScreen;

class MediaListScreen extends ConsumerStatefulWidget {
  final String title;
  final FutureProvider<List<MediaItem>> itemsProvider;
  final Future<List<MediaItem>> Function(int page)? fetchPage;

  const MediaListScreen({
    super.key,
    required this.title,
    required this.itemsProvider,
    this.fetchPage,
  });

  @override
  ConsumerState<MediaListScreen> createState() => _MediaListScreenState();
}

class _MediaListScreenState extends ConsumerState<MediaListScreen> {
  final List<MediaItem> _accumulatedItems = [];
  int _currentPage = 1;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  bool _initialLoaded = false;
  // B8/TF-23: distinct from `_currentPage > 1` -- a list that exhausts on
  // the very first "Load More" tap never advances _currentPage, but the
  // user still made an attempt and deserves the explicit "reached the end"
  // state, not silence.
  bool _hasAttemptedLoadMore = false;

  Future<List<MediaItem>> _fetchNextPage(int page) async {
    if (widget.fetchPage != null) {
      return widget.fetchPage!(page);
    }
    final repo = ref.read(movieRepositoryProvider);
    // LANG-2 (2nd pass): threaded through so Load More's later pages stay
    // scoped to the Hall's language lock server-side, same as the initial
    // itemsProvider fetch -- see MovieRepository's originalLanguage param.
    final lockedLanguageCode =
        ref.read(activeHallSpaceProvider).lockedLanguageCode;
    final t = widget.title.toLowerCase();
    if (t.contains('trending') && (t.contains('tv') || t.contains('show'))) {
      return repo.getTrendingTvShows(
          page: page, originalLanguage: lockedLanguageCode);
    } else if (t.contains('trending')) {
      return repo.getTrendingMovies(
          page: page, originalLanguage: lockedLanguageCode);
    } else if (t.contains('top rated') &&
        (t.contains('tv') || t.contains('show'))) {
      return repo.getTopRatedTvShows(
          page: page, originalLanguage: lockedLanguageCode);
    } else if (t.contains('top rated')) {
      return repo.getTopRatedMovies(
          page: page, originalLanguage: lockedLanguageCode);
    } else if (t.contains('now playing')) {
      return repo.getNowPlayingMovies(
          page: page, originalLanguage: lockedLanguageCode);
    } else if (t.contains('airing today')) {
      return repo.getAiringTodayTvShows(
          page: page, originalLanguage: lockedLanguageCode);
    } else if (t.contains('upcoming')) {
      return repo.getUpcomingMovies(
          page: page, originalLanguage: lockedLanguageCode);
    } else if (t.contains('on the air')) {
      return repo.getOnTheAirTvShows(
          page: page, originalLanguage: lockedLanguageCode);
    }
    return repo.getTrendingMovies(
        page: page, originalLanguage: lockedLanguageCode);
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore || !_hasMore) return;
    setState(() {
      _isLoadingMore = true;
      _hasAttemptedLoadMore = true;
    });
    try {
      final nextPage = _currentPage + 1;
      final rawItems = await _fetchNextPage(nextPage);
      // LANG-2 (2nd pass): _fetchNextPage already scopes the fetch itself
      // to the Hall's language lock server-side (see MovieRepository's
      // originalLanguage param), so this is a defensive client-side
      // backstop, not the primary filter -- catches anything that slips
      // through (e.g. a future fetchPage override that forgets to thread
      // the lock), rather than trusting every call site to get it right.
      final lockedLanguageCode =
          ref.read(activeHallSpaceProvider).lockedLanguageCode;
      final newItems =
          (lockedLanguageCode != null && lockedLanguageCode.isNotEmpty)
              ? rawItems
                  .where((e) => e.originalLanguage == lockedLanguageCode)
                  .toList()
              : rawItems;
      if (mounted) {
        final existingIds = _accumulatedItems.map((e) => e.id).toSet();
        final fresh =
            newItems.where((e) => !existingIds.contains(e.id)).toList();
        setState(() {
          if (rawItems.isEmpty) {
            // TMDB itself is exhausted -- genuinely no more pages.
            _hasMore = false;
          } else {
            // The raw page had content (all language-filtered out, or all
            // duplicates, is possible) -- advance so the next tap tries the
            // following page instead of getting stuck here.
            _currentPage = nextPage;
            _accumulatedItems.addAll(fresh);
          }
          _isLoadingMore = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoadingMore = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.ambianceColors.isDark;
    final inkColor = context.ambianceColors.ink;
    final subColor = context.ambianceColors.sub;
    final lineRgba = context.ambianceColors.lineRgba;
    final bgColor = context.ambianceColors.base;
    final pillColor = context.ambianceColors.pill;

    final itemsAsync = ref.watch(widget.itemsProvider);
    final width = MediaQuery.of(context).size.width;
    final crossAxisCount = width > 900 ? 5 : (width > 600 ? 4 : 3);
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return SizedBox.expand(
      child: DecoratedBox(
        decoration: context.ambianceColors.background,
        child: Scaffold(
          backgroundColor: bgColor,
          extendBodyBehindAppBar: true,
          appBar: PreferredSize(
            preferredSize: const Size.fromHeight(60),
            // B4: RepaintBoundary isolates this into its own compositing
            // layer -- BackdropFilter composited underneath a page-route's
            // own animated transition (fade/slide when this screen is
            // pushed) can otherwise render fully black and stay that way
            // until something forces a full scene recomposite. Same fix as
            // search_screen.dart's header.
            child: RepaintBoundary(
              child: ClipRRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                  child: Container(
                    color: context.ambianceColors.base.withValues(alpha: 0.75),
                    child: AppBar(
                      backgroundColor: Colors.transparent,
                      elevation: 0,
                      scrolledUnderElevation: 0,
                      leading: Center(
                        child: PressableScale(
                          onTap: () => Navigator.maybePop(context),
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: pillColor,
                            ),
                            child: Icon(Icons.arrow_back,
                                color: inkColor, size: 18),
                          ),
                        ),
                      ),
                      title: Text(
                        widget.title,
                        style: GoogleFonts.bodoniModa(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          fontStyle: FontStyle.italic,
                          color: inkColor,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          body: itemsAsync.when(
            data: (initialItems) {
              if (!_initialLoaded) {
                _initialLoaded = true;
                _accumulatedItems.clear();
                _accumulatedItems.addAll(initialItems);
              }

              final displayItems = _accumulatedItems.isNotEmpty
                  ? _accumulatedItems
                  : initialItems;

              if (displayItems.isEmpty) {
                return Center(
                  child: Text(
                    'No items found.',
                    style: AppThemes.safeGeist(
                      fontSize: 14,
                      color: subColor,
                    ),
                  ),
                );
              }

              return Column(
                children: [
                  Expanded(
                    child: GridView.builder(
                      padding: EdgeInsets.fromLTRB(
                        16,
                        MediaQuery.of(context).padding.top + 68,
                        16,
                        16,
                      ),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        childAspectRatio: 0.65,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                      ),
                      itemCount: displayItems.length,
                      itemBuilder: (context, index) {
                        final item = displayItems[index];
                        return MediaCard(
                          key: ValueKey(item.prefixedId),
                          item: item,
                          isDark: isDark,
                          borderRadius: 12,
                        ).animate().fade(duration: 250.ms).slideY(
                              begin: 0.1,
                              end: 0,
                              delay: (index.clamp(0, 8) * 30).ms,
                            );
                      },
                    ),
                  ),
                  if (_hasMore)
                    Padding(
                      padding:
                          EdgeInsets.fromLTRB(16, 8, 16, 20.0 + bottomPadding),
                      child: PressableScale(
                        onTap: _isLoadingMore ? null : _loadMore,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: pillColor,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: lineRgba),
                          ),
                          alignment: Alignment.center,
                          child: _isLoadingMore
                              ? SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: inkColor,
                                  ),
                                )
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.expand_more,
                                        color: inkColor, size: 20),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Load More (Page ${_currentPage + 1})',
                                      style: AppThemes.safeGeist(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: inkColor,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    )
                  else if (_hasAttemptedLoadMore)
                    // B8/TF-23: previously the button just vanished once the
                    // list was exhausted, with nothing marking that as
                    // intentional rather than a stalled/broken load.
                    Padding(
                      padding:
                          EdgeInsets.fromLTRB(16, 8, 16, 20.0 + bottomPadding),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_circle_outline,
                              color: subColor, size: 16),
                          const SizedBox(width: 6),
                          Text(
                            'You\'ve reached the end',
                            style: AppThemes.safeGeist(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: subColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) {
              final message = err.toString().replaceAll('Exception: ', '');
              return FullScreenErrorWidget(
                message:
                    message.isNotEmpty ? message : 'Failed to load media list.',
                onRetry: () {
                  setState(() {
                    _initialLoaded = false;
                    _currentPage = 1;
                    _hasMore = true;
                  });
                  ref.invalidate(widget.itemsProvider);
                },
              );
            },
          ),
        ),
      ),
    );
  }
}
