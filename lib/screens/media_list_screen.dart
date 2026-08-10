import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:animations/animations.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/media_item.dart';
import '../constants.dart';
import '../providers/repository_provider.dart';
import '../widgets/fallback_widgets.dart';
import '../widgets/pressable_scale.dart';
import '../widgets/quick_status_sheet.dart';
import 'detail_screen.dart';

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

  Future<List<MediaItem>> _fetchNextPage(int page) async {
    if (widget.fetchPage != null) {
      return widget.fetchPage!(page);
    }
    final repo = ref.read(movieRepositoryProvider);
    final t = widget.title.toLowerCase();
    if (t.contains('trending') && (t.contains('tv') || t.contains('show'))) {
      return repo.getTrendingTvShows(page: page);
    } else if (t.contains('trending')) {
      return repo.getTrendingMovies(page: page);
    } else if (t.contains('top rated') && (t.contains('tv') || t.contains('show'))) {
      return repo.getTopRatedTvShows(page: page);
    } else if (t.contains('top rated')) {
      return repo.getTopRatedMovies(page: page);
    } else if (t.contains('now playing')) {
      return repo.getNowPlayingMovies(page: page);
    } else if (t.contains('airing today')) {
      return repo.getAiringTodayTvShows(page: page);
    } else if (t.contains('upcoming')) {
      return repo.getUpcomingMovies(page: page);
    } else if (t.contains('on the air')) {
      return repo.getOnTheAirTvShows(page: page);
    }
    return repo.getTrendingMovies(page: page);
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore || !_hasMore) return;
    setState(() {
      _isLoadingMore = true;
    });
    try {
      final nextPage = _currentPage + 1;
      final newItems = await _fetchNextPage(nextPage);
      if (mounted) {
        final existingIds = _accumulatedItems.map((e) => e.id).toSet();
        final fresh = newItems.where((e) => !existingIds.contains(e.id)).toList();
        setState(() {
          if (fresh.isEmpty) {
            _hasMore = false;
          } else {
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
    final phColor = context.ambianceColors.ph;
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
                          child: Icon(Icons.arrow_back, color: inkColor, size: 18),
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
                        return PressableScale(
                          child: OpenContainer(
                            transitionDuration: AppPhysics.houseSpringDuration,
                            closedElevation: 0,
                            openElevation: 0,
                            closedColor: Colors.transparent,
                            openColor: bgColor,
                            middleColor: Colors.transparent,
                            closedShape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            closedBuilder: (context, openContainer) {
                              return GestureDetector(
                                onTap: openContainer,
                                onLongPress: () => showQuickStatusSheet(context, ref, item),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: phColor,
                                    border: Border.all(color: lineRgba),
                                    borderRadius: BorderRadius.circular(12),
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
                                  child: Stack(
                                    fit: StackFit.expand,
                                    children: [
                                      MediaImage(
                                        item: item,
                                        fit: BoxFit.cover,
                                      ),
                                      if (item.rating > 0)
                                        Positioned(
                                          top: 6,
                                          right: 6,
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: isDark
                                                  ? const Color.fromRGBO(0, 0, 0, 0.65)
                                                  : const Color.fromRGBO(44, 32, 22, 0.75),
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                const Icon(Icons.star,
                                                    size: 10, color: Color(0xFFFFB800)),
                                                const SizedBox(width: 3),
                                                Text(
                                                  item.rating.toStringAsFixed(1),
                                                  style: AppThemes.safeGeist(
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.w600,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              );
                            },
                            openBuilder: (context, _) =>
                                DetailScreen(id: item.prefixedId),
                          ),
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
                      padding: EdgeInsets.fromLTRB(16, 8, 16, 20.0 + bottomPadding),
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
                                    Icon(Icons.expand_more, color: inkColor, size: 20),
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
                    ),
                ],
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) {
              final message = err.toString().replaceAll('Exception: ', '');
              return FullScreenErrorWidget(
                message: message.isNotEmpty
                    ? message
                    : 'Failed to load media list.',
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
