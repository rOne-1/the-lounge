import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:animations/animations.dart';
import 'package:google_fonts/google_fonts.dart';

import '../constants.dart';
import '../models/discover_filter_params.dart';
import '../models/media_item.dart';
import '../providers/navigation_provider.dart';
import '../providers/repository_provider.dart';
import '../widgets/drag_to_dismiss_sheet.dart';
import '../widgets/fallback_widgets.dart';
import '../widgets/person_search_autocomplete.dart';
import '../widgets/pressable_scale.dart';
import '../widgets/quick_status_sheet.dart';
import 'detail_screen.dart';

int? getGenreIdForName(String name) {
  final lower = name.toLowerCase().trim();
  switch (lower) {
    case 'action':
      return 28;
    case 'adventure':
      return 12;
    case 'animation':
      return 16;
    case 'comedy':
      return 35;
    case 'crime':
      return 80;
    case 'documentary':
      return 99;
    case 'drama':
      return 18;
    case 'family':
      return 10751;
    case 'fantasy':
      return 14;
    case 'history':
      return 36;
    case 'horror':
      return 27;
    case 'music':
      return 10402;
    case 'mystery':
      return 9648;
    case 'romance':
      return 10749;
    case 'sci-fi':
    case 'science fiction':
      return 878;
    case 'tv movie':
      return 10770;
    case 'thriller':
      return 53;
    case 'war':
      return 10752;
    case 'western':
      return 37;
    case 'action & adventure':
      return 10759;
    case 'kids':
      return 10762;
    case 'news':
      return 10763;
    case 'reality':
      return 10764;
    case 'sci-fi & fantasy':
      return 10765;
    case 'soap':
      return 10766;
    case 'talk':
      return 10767;
    case 'war & politics':
      return 10768;
    default:
      return null;
  }
}

class BrowseScreen extends ConsumerStatefulWidget {
  const BrowseScreen({super.key});

  @override
  ConsumerState<BrowseScreen> createState() => _BrowseScreenState();
}

class _BrowseScreenState extends ConsumerState<BrowseScreen> {
  int _currentPage = 1;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  final List<MediaItem> _accumulatedItems = [];
  String? _lastParamsKey;

  // Search mode state
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  List<MediaItem>? _searchResults;
  bool _isSearching = false;
  Object? _searchError;

  void _onSearchChanged(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      setState(() {
        _searchQuery = '';
        _searchResults = null;
        _isSearching = false;
        _searchError = null;
      });
      return;
    }

    setState(() {
      _searchQuery = trimmed;
      _isSearching = true;
      _searchError = null;
    });

    try {
      final repo = ref.read(movieRepositoryProvider);
      final results = await repo.searchMedia(trimmed);
      if (mounted) {
        setState(() {
          _searchResults = results;
          _isSearching = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _searchError = e;
          _isSearching = false;
        });
      }
    }
  }

  static const int _maxAccumulatedItems = 200;
  static const int _maxPages = 10;

  Future<void> _loadMorePage(bool isMovies) async {
    if (_isLoadingMore || !_hasMore) return;
    if (_currentPage >= _maxPages || _accumulatedItems.length >= _maxAccumulatedItems) {
      setState(() {
        _hasMore = false;
      });
      return;
    }
    setState(() {
      _isLoadingMore = true;
    });
    try {
      final repo = ref.read(movieRepositoryProvider);
      final filterParams = ref.read(discoverFilterProvider);
      final nextPage = _currentPage + 1;
      final newItems = await repo.discoverMedia(
        isMovies: isMovies,
        params: filterParams,
        page: nextPage,
      );
      if (mounted) {
        final existingIds = _accumulatedItems.map((e) => e.id).toSet();
        final fresh = newItems.where((e) => !existingIds.contains(e.id)).toList();
        setState(() {
          if (fresh.isEmpty) {
            _hasMore = false;
          } else {
            _currentPage = nextPage;
            _accumulatedItems.addAll(fresh);
            if (_accumulatedItems.length >= _maxAccumulatedItems || _currentPage >= _maxPages) {
              _hasMore = false;
            }
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

  final List<String> _baseGenres = [
    'All',
    'Action',
    'Adventure',
    'Animation',
    'Comedy',
    'Crime',
    'Documentary',
    'Drama',
    'Family',
    'Fantasy',
    'History',
    'Horror',
    'Music',
    'Mystery',
    'Romance',
    'Sci-Fi',
    'Thriller',
    'War',
    'Western',
  ];

  final List<Map<String, String>> _regions = const [
    {'code': 'US', 'name': 'United States'},
    {'code': 'GB', 'name': 'United Kingdom'},
    {'code': 'CA', 'name': 'Canada'},
    {'code': 'AU', 'name': 'Australia'},
    {'code': 'DE', 'name': 'Germany'},
    {'code': 'FR', 'name': 'France'},
    {'code': 'JP', 'name': 'Japan'},
  ];

  final List<Map<String, dynamic>> _providers = const [
    {'id': 8, 'name': 'Netflix'},
    {'id': 337, 'name': 'Disney+'},
    {'id': 9, 'name': 'Amazon Prime'},
    {'id': 2, 'name': 'Apple TV+'},
    {'id': 384, 'name': 'HBO Max'},
    {'id': 15, 'name': 'Hulu'},
    {'id': 531, 'name': 'Paramount+'},
    {'id': 387, 'name': 'Peacock'},
  ];

  final List<Map<String, String>> _languages = const [
    {'code': 'en', 'name': 'English'},
    {'code': 'ja', 'name': 'Japanese'},
    {'code': 'fr', 'name': 'French'},
    {'code': 'es', 'name': 'Spanish'},
    {'code': 'de', 'name': 'German'},
    {'code': 'ko', 'name': 'Korean'},
  ];

  final List<Map<String, dynamic>> _tvNetworks = const [
    {'id': 49, 'name': 'HBO'},
    {'id': 213, 'name': 'Netflix'},
    {'id': 174, 'name': 'AMC'},
    {'id': 4, 'name': 'BBC One'},
    {'id': 6, 'name': 'NBC'},
    {'id': 2552, 'name': 'Apple TV+'},
  ];

  void _syncPreFilters() {
    final browseGenre = ref.read(browseGenreProvider);
    final browseKeyword = ref.read(browseKeywordProvider);
    final filterNotifier = ref.read(discoverFilterProvider.notifier);
    final currentParams = ref.read(discoverFilterProvider);

    if (browseGenre != 'All') {
      final genreId = getGenreIdForName(browseGenre);
      if (currentParams.genreName != browseGenre) {
        filterNotifier.setGenre(genreId: genreId, genreName: browseGenre);
      }
    }

    if (browseKeyword != null && browseKeyword.isNotEmpty) {
      if (currentParams.keywordName != browseKeyword) {
        filterNotifier.setKeyword(keywordId: null, keywordName: browseKeyword);
      }
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncPreFilters();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _resetAllFilters() {
    ref.read(discoverFilterProvider.notifier).resetFilters();
    ref.read(browseGenreProvider.notifier).setGenre('All');
    ref.read(browseKeywordProvider.notifier).clearKeyword();
  }

  void _showFilterBottomSheet(BuildContext context, bool isDark, bool isMovies) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        final cardBg = isDark ? AppColors.srCard : AppColors.rrCard;
        final inkColor = isDark ? AppColors.srInk : AppColors.rrInk;
        final subColor = isDark ? AppColors.srSub : AppColors.rrSub;

        return DragToDismissSheet(
          isDark: isDark,
          onDismiss: () => Navigator.pop(context),
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.85,
            ),
            padding: EdgeInsets.fromLTRB(
              20,
              8,
              20,
              24.0 + MediaQuery.of(context).padding.bottom,
            ),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              border: Border(
                top: BorderSide(
                  color: isDark ? AppColors.srLineRgba : AppColors.rrLineRgba,
                ),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Filter Catalog',
                      style: GoogleFonts.bodoniModa(
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                        fontStyle: FontStyle.italic,
                        color: inkColor,
                      ),
                    ),
                    PressableScale(
                      onTap: () => Navigator.pop(context),
                      child: Icon(Icons.close, color: subColor, size: 20),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: SingleChildScrollView(
                    child: _buildAccordionFilterPanel(isDark, isMovies),
                  ),
                ),
                const SizedBox(height: 16),
                PressableScale(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: AppColors.primaryButtonDecoration(
                      isDark: isDark,
                      borderRadius: 12,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      'Apply Filters',
                      style: AppThemes.safeGeist(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isDark ? const Color(0xFF1A140C) : Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  List<MediaItem> _applyClientFilters(
    List<MediaItem> items,
    DiscoverFilterParams params,
    bool isMovies,
  ) {
    final expectedType = isMovies ? MediaType.movie : MediaType.tv;

    final filtered = items.where((item) {
      // 1. Media Type toggle matching
      if (item.type != expectedType) return false;

      // 2. Genre filter
      if (params.genreName != null &&
          params.genreName!.isNotEmpty &&
          params.genreName != 'All') {
        final target = params.genreName!.toLowerCase();
        final matchesGenre = item.genres.any((g) => g.toLowerCase() == target);
        if (!matchesGenre) return false;
      }

      // 3. Min Rating filter
      if (params.minRating != null) {
        if (item.rating < params.minRating!) return false;
      }

      // 4. Min Vote Count filter
      if (params.minVoteCount != null) {
        if ((item.voteCount ?? 0) < params.minVoteCount!) return false;
      }

      // 5. Runtime filter
      if (params.minRuntime != null) {
        if (item.runtime != null && item.runtime! < params.minRuntime!) {
          return false;
        }
      }
      if (params.maxRuntime != null) {
        if (item.runtime != null && item.runtime! > params.maxRuntime!) {
          return false;
        }
      }

      // 8. Person filter
      if (params.personName != null && params.personName!.isNotEmpty) {
        final targetPerson = params.personName!.toLowerCase();
        final inCast =
            item.cast.any((c) => c.toLowerCase().contains(targetPerson));
        final inDirector =
            item.director?.toLowerCase().contains(targetPerson) ?? false;
        if (!inCast && !inDirector) return false;
      }

      // 9. Provider filter
      if (params.providerName != null && params.providerName!.isNotEmpty) {
        final targetProvider = params.providerName!.toLowerCase();
        final hasProvider = item.watchProviders
            .any((wp) => wp.toLowerCase().contains(targetProvider));
        if (!hasProvider) return false;
      }

      return true;
    }).toList();

    filtered.sort((a, b) {
      switch (params.sortBy) {
        case 'vote_average.desc':
          return b.rating.compareTo(a.rating);
        case 'primary_release_date.desc':
        case 'first_air_date.desc':
          final aDate = a.releaseOrAirDate ?? DateTime(1900);
          final bDate = b.releaseOrAirDate ?? DateTime(1900);
          return bDate.compareTo(aDate);
        case 'revenue.desc':
        case 'popularity.desc':
        default:
          return (b.voteCount ?? 0).compareTo(a.voteCount ?? 0);
      }
    });

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(browseGenreProvider, (previous, next) {
      if (next != 'All') {
        final genreId = getGenreIdForName(next);
        ref
            .read(discoverFilterProvider.notifier)
            .setGenre(genreId: genreId, genreName: next);
      } else if (previous != 'All') {
        ref
            .read(discoverFilterProvider.notifier)
            .setGenre(genreId: null, genreName: null);
      }
    });

    ref.listen(browseKeywordProvider, (previous, next) {
      if (next != null && next.isNotEmpty) {
        ref
            .read(discoverFilterProvider.notifier)
            .setKeyword(keywordId: null, keywordName: next);
      } else if (previous != null) {
        ref
            .read(discoverFilterProvider.notifier)
            .setKeyword(keywordId: null, keywordName: null);
      }
    });

    final isLarge = MediaQuery.of(context).size.width > 800;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final inkColor = isDark ? AppColors.srInk : AppColors.rrInk;
    final mediaType = ref.watch(navigationProvider).activeMediaType;
    final isMovies = mediaType == MediaTypeToggle.movies;

    return SizedBox.expand(
      child: DecoratedBox(
        decoration: isDark
            ? AppThemes.screeningRoomBackground()
            : AppThemes.readingRoomBackground(),
        child: Scaffold(
          backgroundColor: isDark ? AppColors.srBase : AppColors.rrBase,
          appBar: AppBar(
            title: Text(
              _searchQuery.isNotEmpty
                  ? (isMovies ? 'Search Movies' : 'Search TV Shows')
                  : (isMovies ? 'Browse Movies' : 'Browse TV Shows'),
              style: GoogleFonts.bodoniModa(
                fontStyle: FontStyle.italic,
                color: inkColor,
              ),
            ),
            backgroundColor: Colors.transparent,
            elevation: 0,
            iconTheme: IconThemeData(color: inkColor),
            actions: [
              if (!isLarge)
                PressableScale(
                  onTap: () => _showFilterBottomSheet(context, isDark, isMovies),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.filter_list, color: inkColor, size: 20),
                        const SizedBox(width: 4),
                        Text(
                          'Filters',
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
            ],
          ),
          body: isLarge
              ? _buildLargeLayout(isDark, isMovies)
              : _buildCompactLayout(isDark, isMovies),
        ),
      ),
    );
  }

  Widget _buildTopSearchBar(bool isDark) {
    final inkColor = isDark ? AppColors.srInk : AppColors.rrInk;
    final subColor = isDark ? AppColors.srSub : AppColors.rrSub;
    final lineRgba = isDark ? AppColors.srLineRgba : AppColors.rrLineRgba;
    final phColor = isDark ? AppColors.srPh : AppColors.rrPh;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: phColor,
          border: Border.all(color: lineRgba),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Icon(Icons.search, color: subColor, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: _searchController,
                style: AppThemes.safeGeist(fontSize: 14, color: inkColor),
                decoration: InputDecoration(
                  hintText: 'Search across the catalog',
                  hintStyle: AppThemes.safeGeist(fontSize: 14, color: subColor),
                  border: InputBorder.none,
                ),
                onChanged: _onSearchChanged,
              ),
            ),
            if (_searchQuery.isNotEmpty)
              PressableScale(
                onTap: () {
                  _searchController.clear();
                  _onSearchChanged('');
                },
                child: Icon(Icons.close, color: subColor, size: 20),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchModeBadge(bool isDark) {
    final inkColor = isDark ? AppColors.srInk : AppColors.rrInk;
    final accColor = isDark ? AppColors.srAcc : AppColors.rrAcc;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: accColor.withAlpha(25),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: accColor.withAlpha(100)),
      ),
      child: Row(
        children: [
          Icon(Icons.flash_on, size: 16, color: accColor),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '⚡ Search Mode: Filtering is scoped to search results for "$_searchQuery"',
              style: AppThemes.safeGeist(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: inkColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactLayout(bool isDark, bool isMovies) {
    return Column(
      children: [
        _buildTopSearchBar(isDark),
        if (_searchQuery.isNotEmpty) _buildSearchModeBadge(isDark),
        _buildActiveFilterChipBar(isDark),
        Expanded(child: _buildBody(isDark, isMovies)),
      ],
    );
  }

  Widget _buildLargeLayout(bool isDark, bool isMovies) {
    return Row(
      children: [
        Expanded(
          child: Column(
            children: [
              _buildTopSearchBar(isDark),
              if (_searchQuery.isNotEmpty) _buildSearchModeBadge(isDark),
              _buildActiveFilterChipBar(isDark),
              Expanded(child: _buildBody(isDark, isMovies)),
            ],
          ),
        ),
        VerticalDivider(
          width: 1,
          thickness: 1,
          color: isDark ? AppColors.srLineRgba : AppColors.rrLineRgba,
        ),
        SizedBox(
          width: 320,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Filters',
                      style: GoogleFonts.bodoniModa(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        fontStyle: FontStyle.italic,
                        color: isDark ? AppColors.srInk : AppColors.rrInk,
                      ),
                    ),
                    if (ref.watch(discoverFilterProvider).hasActiveFilters)
                      PressableScale(
                        onTap: _resetAllFilters,
                        child: Text(
                          'Reset All',
                          style: AppThemes.safeGeist(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isDark ? AppColors.srAcc : AppColors.rrAcc,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _buildAccordionFilterPanel(isDark, isMovies),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBody(bool isDark, bool isMovies) {
    if (_searchQuery.isNotEmpty) {
      return _buildSearchModeBody(isDark, isMovies);
    } else {
      return _buildDiscoverModeBody(isDark, isMovies);
    }
  }

  Widget _buildSearchModeBody(bool isDark, bool isMovies) {
    final inkColor = isDark ? AppColors.srInk : AppColors.rrInk;
    final subColor = isDark ? AppColors.srSub : AppColors.rrSub;
    final filterParams = ref.watch(discoverFilterProvider);

    if (_isSearching) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_searchError != null) {
      final errorMessage =
          _searchError.toString().replaceAll('Exception: ', '');
      return FullScreenErrorWidget(
        message: errorMessage.isNotEmpty
            ? errorMessage
            : 'Failed to perform search. Please check your connection.',
        onRetry: () => _onSearchChanged(_searchQuery),
      );
    }

    final rawResults = _searchResults ?? [];
    final filteredResults =
        _applyClientFilters(rawResults, filterParams, isMovies);

    if (filteredResults.isEmpty) {
      return Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.search_off, size: 64, color: subColor),
              const SizedBox(height: 16),
              Text(
                'No results found for "$_searchQuery"',
                textAlign: TextAlign.center,
                style: AppThemes.safeGeist(
                  color: inkColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Check spelling or try searching for another title or actor.',
                textAlign: TextAlign.center,
                style: AppThemes.safeGeist(color: subColor, fontSize: 13),
              ),
              const SizedBox(height: 20),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                alignment: WrapAlignment.center,
                children: [
                  FilledButton.icon(
                    onPressed: () {
                      _searchController.clear();
                      _onSearchChanged('');
                    },
                    icon: const Icon(Icons.clear),
                    label: const Text('Clear search'),
                  ),
                  if (filterParams.hasActiveFilters)
                    OutlinedButton.icon(
                      onPressed: _resetAllFilters,
                      icon: const Icon(Icons.filter_alt_off),
                      label: const Text('Reset All Filters'),
                    ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(18),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 140,
              childAspectRatio: 2 / 3,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: filteredResults.length,
            itemBuilder: (context, index) {
              final item = filteredResults[index];
              return _buildGridCard(item, isDark);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDiscoverModeBody(bool isDark, bool isMovies) {
    final subColor = isDark ? AppColors.srSub : AppColors.rrSub;

    final filterParams = ref.watch(discoverFilterProvider);
    final currentParamKey = '${isMovies}_${filterParams.toString()}';
    if (_lastParamsKey != currentParamKey) {
      _lastParamsKey = currentParamKey;
      _currentPage = 1;
      _hasMore = true;
      _accumulatedItems.clear();
    }

    final discoverAsync = ref.watch(discoverMediaProvider(isMovies));

    return discoverAsync.when(
      data: (items) {
        if (_accumulatedItems.isEmpty && items.isNotEmpty) {
          _accumulatedItems.addAll(items);
        }

        final displayItems =
            _accumulatedItems.isNotEmpty ? _accumulatedItems : items;

        if (displayItems.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.movie_filter_outlined,
                  size: 48,
                  color: subColor,
                ),
                const SizedBox(height: 12),
                Text(
                  'No media found matching your filters.',
                  style: AppThemes.safeGeist(
                    fontSize: 14,
                    color: subColor,
                  ),
                ),
                const SizedBox(height: 16),
                PressableScale(
                  onTap: _resetAllFilters,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: AppColors.primaryButtonDecoration(
                      isDark: isDark,
                      borderRadius: 999,
                    ),
                    child: Text(
                      'Reset All Filters',
                      style: AppThemes.safeGeist(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isDark ? const Color(0xFF1A140C) : Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        return Column(
          children: [
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.all(18),
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 140,
                  childAspectRatio: 2 / 3,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: displayItems.length,
                itemBuilder: (context, index) {
                  final item = displayItems[index];
                  return _buildGridCard(item, isDark);
                },
              ),
            ),
            if (_hasMore) _buildLoadMoreFooter(isDark, isMovies),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => FullScreenErrorWidget(
        message: err.toString().replaceAll('Exception: ', ''),
        onRetry: () => ref.refresh(discoverMediaProvider(isMovies)),
      ),
    );
  }

  Widget _buildLoadMoreFooter(bool isDark, bool isMovies) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        16,
        12.0,
        16,
        90.0 + MediaQuery.of(context).padding.bottom,
      ),
      child: _isLoadingMore
          ? const SizedBox(
              height: 24,
              width: 24,
              child: CircularProgressIndicator(strokeWidth: 2.5),
            )
          : PressableScale(
              onTap: () => _loadMorePage(isMovies),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.srPill : AppColors.rrPill,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isDark ? AppColors.srLineRgba : AppColors.rrLineRgba,
                  ),
                ),
                child: Text(
                  'Load More',
                  style: AppThemes.safeGeist(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.srInk : AppColors.rrInk,
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildGridCard(MediaItem item, bool isDark) {
    final phColor = isDark ? AppColors.srPh : AppColors.rrPh;
    final lineRgba = isDark ? AppColors.srLineRgba : AppColors.rrLineRgba;

    return PressableScale(
      child: OpenContainer(
        transitionDuration: AppPhysics.houseSpringDuration,
        closedElevation: 0,
        openElevation: 0,
        closedColor: Colors.transparent,
        openColor: isDark ? AppColors.srBase : AppColors.rrBase,
        middleColor: Colors.transparent,
        closedShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        closedBuilder: (context, openContainer) {
          return InkWell(
            onTap: openContainer,
            onLongPress: () => showQuickStatusSheet(context, ref, item),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              decoration: BoxDecoration(
                color: phColor,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: lineRgba),
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
    );
  }

  Widget _buildActiveFilterChipBar(bool isDark) {
    final filterParams = ref.watch(discoverFilterProvider);
    final lineRgba = isDark ? AppColors.srLineRgba : AppColors.rrLineRgba;
    final pillColor = isDark ? AppColors.srPill : AppColors.rrPill;

    final chips = <Widget>[];

    if (filterParams.genreName != null && filterParams.genreName!.isNotEmpty) {
      chips.add(_buildChip(
        label: 'Genre: ${filterParams.genreName}',
        onDelete: () {
          ref
              .read(discoverFilterProvider.notifier)
              .setGenre(genreId: null, genreName: null);
          ref.read(browseGenreProvider.notifier).setGenre('All');
        },
        isDark: isDark,
      ));
    }

    if (filterParams.keywordName != null &&
        filterParams.keywordName!.isNotEmpty) {
      chips.add(_buildChip(
        label: 'Keyword: #${filterParams.keywordName}',
        onDelete: () {
          ref
              .read(discoverFilterProvider.notifier)
              .setKeyword(keywordId: null, keywordName: null);
          ref.read(browseKeywordProvider.notifier).clearKeyword();
        },
        isDark: isDark,
      ));
    }

    if (filterParams.personName != null &&
        filterParams.personName!.isNotEmpty) {
      chips.add(_buildChip(
        label: 'Person: ${filterParams.personName}',
        onDelete: () {
          ref
              .read(discoverFilterProvider.notifier)
              .setPerson(personId: null, personName: null);
        },
        isDark: isDark,
      ));
    }

    if (filterParams.providerName != null &&
        filterParams.providerName!.isNotEmpty) {
      chips.add(_buildChip(
        label: 'Provider: ${filterParams.providerName}',
        onDelete: () {
          ref.read(discoverFilterProvider.notifier).setProvider(
                providerId: null,
                providerName: null,
                watchRegion: filterParams.watchRegion,
              );
        },
        isDark: isDark,
      ));
    }

    if (filterParams.watchRegion != null &&
        filterParams.watchRegion!.isNotEmpty) {
      chips.add(_buildChip(
        label: 'Region: ${filterParams.watchRegion}',
        onDelete: () {
          ref.read(discoverFilterProvider.notifier).setProvider(
                providerId: filterParams.providerId,
                providerName: filterParams.providerName,
                watchRegion: null,
              );
        },
        isDark: isDark,
      ));
    }

    if (filterParams.minRating != null) {
      chips.add(_buildChip(
        label: 'Rating: ≥ ${filterParams.minRating!.toStringAsFixed(1)} ★',
        onDelete: () {
          ref.read(discoverFilterProvider.notifier).setMinRating(null);
        },
        isDark: isDark,
      ));
    }

    if (filterParams.minVoteCount != null) {
      chips.add(_buildChip(
        label: 'Votes: ≥ ${filterParams.minVoteCount}',
        onDelete: () {
          ref.read(discoverFilterProvider.notifier).setMinVoteCount(null);
        },
        isDark: isDark,
      ));
    }

    if (filterParams.sortBy != 'popularity.desc') {
      String sortLabel = filterParams.sortBy;
      if (sortLabel == 'vote_average.desc') sortLabel = 'Rating';
      if (sortLabel == 'primary_release_date.desc' ||
          sortLabel == 'first_air_date.desc') {
        sortLabel = 'Release Date';
      }
      if (sortLabel == 'revenue.desc') sortLabel = 'Revenue';

      chips.add(_buildChip(
        label: 'Sort: $sortLabel',
        onDelete: () {
          ref
              .read(discoverFilterProvider.notifier)
              .setSortBy('popularity.desc');
        },
        isDark: isDark,
      ));
    }

    if (filterParams.minRuntime != null || filterParams.maxRuntime != null) {
      final minR = filterParams.minRuntime ?? 0;
      final maxR = filterParams.maxRuntime != null
          ? '${filterParams.maxRuntime}m'
          : '∞';
      chips.add(_buildChip(
        label: 'Runtime: ${minR}m - $maxR',
        onDelete: () {
          ref
              .read(discoverFilterProvider.notifier)
              .setRuntime(minRuntime: null, maxRuntime: null);
        },
        isDark: isDark,
      ));
    }

    if (filterParams.originalLanguage != null &&
        filterParams.originalLanguage!.isNotEmpty) {
      chips.add(_buildChip(
        label: 'Language: ${filterParams.originalLanguage}',
        onDelete: () {
          ref.read(discoverFilterProvider.notifier).setOriginalLanguage(null);
        },
        isDark: isDark,
      ));
    }

    if (filterParams.tvStatus != null && filterParams.tvStatus!.isNotEmpty) {
      chips.add(_buildChip(
        label: 'Status: ${filterParams.tvStatus}',
        onDelete: () {
          ref.read(discoverFilterProvider.notifier).setTvStatus(null);
        },
        isDark: isDark,
      ));
    }

    if (filterParams.tvNetworkName != null &&
        filterParams.tvNetworkName!.isNotEmpty) {
      chips.add(_buildChip(
        label: 'Network: ${filterParams.tvNetworkName}',
        onDelete: () {
          ref.read(discoverFilterProvider.notifier).setTvNetwork(
                tvNetworkId: null,
                tvNetworkName: null,
              );
        },
        isDark: isDark,
      ));
    }

    if (chips.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: pillColor.withAlpha(50),
        border: Border(bottom: BorderSide(color: lineRgba)),
      ),
      child: Row(
        children: [
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  ...chips.map((c) => Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: c,
                      )),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          PressableScale(
            onTap: _resetAllFilters,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: isDark ? AppColors.srPill : AppColors.rrPill,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: lineRgba),
              ),
              child: Text(
                'Reset All',
                style: AppThemes.safeGeist(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.srAcc : AppColors.rrAcc,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChip({
    required String label,
    required VoidCallback onDelete,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: AppColors.primaryButtonDecoration(
        isDark: isDark,
        borderRadius: 999,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: AppThemes.safeGeist(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isDark ? const Color(0xFF1A140C) : Colors.white,
            ),
          ),
          const SizedBox(width: 6),
          PressableScale(
            onTap: onDelete,
            child: Icon(
              Icons.close,
              size: 14,
              color: isDark ? const Color(0xFF1A140C) : Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  BoxDecoration _buildFilterChipDecoration({
    required bool isSelected,
    required bool isDark,
    required Color pillColor,
    required Color lineRgba,
  }) {
    final accColor = isDark ? AppColors.srAcc : AppColors.rrAcc;
    if (isSelected) {
      return AppColors.primaryButtonDecoration(isDark: isDark, borderRadius: 999).copyWith(
        border: Border.all(color: accColor, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: accColor.withAlpha(80),
            blurRadius: 6,
            spreadRadius: 1,
          ),
        ],
      );
    }
    return BoxDecoration(
      color: pillColor,
      borderRadius: BorderRadius.circular(999),
      border: Border.all(color: lineRgba),
    );
  }

  Widget _buildAccordionFilterPanel(bool isDark, bool isMovies) {
    final filterParams = ref.watch(discoverFilterProvider);
    final filterNotifier = ref.read(discoverFilterProvider.notifier);
    final inkColor = isDark ? AppColors.srInk : AppColors.rrInk;
    final subColor = isDark ? AppColors.srSub : AppColors.rrSub;
    final lineRgba = isDark ? AppColors.srLineRgba : AppColors.rrLineRgba;
    final pillColor = isDark ? AppColors.srPill : AppColors.rrPill;

    return Theme(
      data: Theme.of(context).copyWith(
        dividerColor: Colors.transparent,
      ),
      child: Column(
        children: [
          // 1. Genres & Keywords
          _buildExpansionSection(
            title: 'Genres & Keywords',
            icon: Icons.category_outlined,
            isDark: isDark,
            initiallyExpanded: true,
            children: [
              Text(
                'Genre',
                style: AppThemes.safeGeist(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: subColor,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: _baseGenres.map((genre) {
                  final isSelected = (genre == 'All' &&
                          (filterParams.genreName == null ||
                              filterParams.genreName!.isEmpty)) ||
                      filterParams.genreName == genre;
                  return PressableScale(
                    onTap: () {
                      if (genre == 'All') {
                        filterNotifier.setGenre(genreId: null, genreName: null);
                        ref.read(browseGenreProvider.notifier).setGenre('All');
                      } else {
                        final genreId = getGenreIdForName(genre);
                        filterNotifier.setGenre(genreId: genreId, genreName: genre);
                        ref.read(browseGenreProvider.notifier).setGenre(genre);
                      }
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: _buildFilterChipDecoration(
                        isSelected: isSelected,
                        isDark: isDark,
                        pillColor: pillColor,
                        lineRgba: lineRgba,
                      ),
                      child: Text(
                        genre,
                        style: AppThemes.safeGeist(
                          fontSize: 12,
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.w400,
                          color: isSelected
                              ? (isDark ? const Color(0xFF1A140C) : Colors.white)
                              : inkColor,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              if (filterParams.keywordName != null &&
                  filterParams.keywordName!.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  'Active Keyword',
                  style: AppThemes.safeGeist(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: subColor,
                  ),
                ),
                const SizedBox(height: 8),
                _buildChip(
                  label: '#${filterParams.keywordName}',
                  onDelete: () {
                    filterNotifier.setKeyword(keywordId: null, keywordName: null);
                    ref.read(browseKeywordProvider.notifier).clearKeyword();
                  },
                  isDark: isDark,
                ),
              ],
            ],
          ),

          // 2. Cast & Crew
          _buildExpansionSection(
            title: 'Cast & Crew',
            icon: Icons.person_search_outlined,
            isDark: isDark,
            initiallyExpanded: filterParams.personName != null,
            children: [
              PersonSearchAutocomplete(isDark: isDark),
            ],
          ),

          // 3. Where to Watch
          _buildExpansionSection(
            title: 'Where to Watch',
            icon: Icons.tv_outlined,
            isDark: isDark,
            initiallyExpanded: filterParams.providerId != null ||
                filterParams.watchRegion != null,
            children: [
              Text(
                'Watch Region',
                style: AppThemes.safeGeist(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: subColor,
                ),
              ),
              const SizedBox(height: 8),
              Builder(
                builder: (context) {
                  final isRegionActive = filterParams.watchRegion != null && filterParams.watchRegion!.isNotEmpty;
                  final accColor = isDark ? AppColors.srAcc : AppColors.rrAcc;
                  return DropdownButtonFormField<String>(
                    initialValue: filterParams.watchRegion,
                    dropdownColor: isDark ? AppColors.srCard : AppColors.rrCard,
                    style: AppThemes.safeGeist(fontSize: 13, color: inkColor),
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      filled: true,
                      fillColor: isRegionActive ? accColor.withAlpha(35) : pillColor,
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(
                          color: isRegionActive ? accColor : lineRgba,
                          width: isRegionActive ? 1.5 : 1.0,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(
                          color: accColor,
                        ),
                      ),
                    ),
                    hint: Text(
                      'Select Region (Default: US)',
                      style: AppThemes.safeGeist(fontSize: 13, color: subColor),
                    ),
                    items: [
                      DropdownMenuItem<String>(
                        value: null,
                        child: Text('Any Region',
                            style: AppThemes.safeGeist(color: subColor)),
                      ),
                      ..._regions.map(
                        (r) => DropdownMenuItem<String>(
                          value: r['code'],
                          child: Text('${r['name']} (${r['code']})',
                              style: AppThemes.safeGeist(color: inkColor)),
                        ),
                      ),
                    ],
                    onChanged: (val) {
                      filterNotifier.setProvider(
                        providerId: filterParams.providerId,
                        providerName: filterParams.providerName,
                        watchRegion: val,
                      );
                    },
                  );
                },
              ),
              const SizedBox(height: 16),
              Text(
                'Streaming Provider',
                style: AppThemes.safeGeist(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: subColor,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  PressableScale(
                    onTap: () {
                      filterNotifier.setProvider(
                        providerId: null,
                        providerName: null,
                        watchRegion: filterParams.watchRegion,
                      );
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: _buildFilterChipDecoration(
                        isSelected: filterParams.providerId == null,
                        isDark: isDark,
                        pillColor: pillColor,
                        lineRgba: lineRgba,
                      ),
                      child: Text(
                        'Any Provider',
                        style: AppThemes.safeGeist(
                          fontSize: 12,
                          color: filterParams.providerId == null
                              ? (isDark ? const Color(0xFF1A140C) : Colors.white)
                              : inkColor,
                        ),
                      ),
                    ),
                  ),
                  ..._providers.map((p) {
                    final isSelected = filterParams.providerId == p['id'];
                    return PressableScale(
                      onTap: () {
                        filterNotifier.setProvider(
                          providerId: p['id'] as int,
                          providerName: p['name'] as String,
                          watchRegion: filterParams.watchRegion,
                        );
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: _buildFilterChipDecoration(
                          isSelected: isSelected,
                          isDark: isDark,
                          pillColor: pillColor,
                          lineRgba: lineRgba,
                        ),
                        child: Text(
                          p['name'] as String,
                          style: AppThemes.safeGeist(
                            fontSize: 12,
                            fontWeight:
                                isSelected ? FontWeight.w600 : FontWeight.w400,
                            color: isSelected
                                ? (isDark ? const Color(0xFF1A140C) : Colors.white)
                                : inkColor,
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ],
          ),

          // 4. Rating & Popularity
          _buildExpansionSection(
            title: 'Rating & Popularity',
            icon: Icons.star_outline,
            isDark: isDark,
            initiallyExpanded: filterParams.minRating != null ||
                filterParams.minVoteCount != null ||
                filterParams.sortBy != 'popularity.desc',
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Minimum Rating',
                    style: AppThemes.safeGeist(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: subColor,
                    ),
                  ),
                  Text(
                    filterParams.minRating != null
                        ? '${filterParams.minRating!.toStringAsFixed(1)} ★'
                        : 'Any',
                    style: AppThemes.safeGeist(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppColors.srAcc : AppColors.rrAcc,
                    ),
                  ),
                ],
              ),
              Slider(
                value: filterParams.minRating ?? 0.0,
                min: 0.0,
                max: 10.0,
                divisions: 20,
                activeColor: isDark ? AppColors.srAcc : AppColors.rrAcc,
                inactiveColor: lineRgba,
                onChanged: (val) {
                  filterNotifier
                      .setMinRating(val == 0.0 ? null : (val * 10).round() / 10);
                },
              ),
              const SizedBox(height: 12),
              Text(
                'Minimum Vote Count',
                style: AppThemes.safeGeist(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: subColor,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  null,
                  50,
                  100,
                  500,
                  1000,
                ].map((vc) {
                  final isSelected = filterParams.minVoteCount == vc;
                  final label = vc == null ? 'Any' : '$vc+';
                  return PressableScale(
                    onTap: () => filterNotifier.setMinVoteCount(vc),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: _buildFilterChipDecoration(
                        isSelected: isSelected,
                        isDark: isDark,
                        pillColor: pillColor,
                        lineRgba: lineRgba,
                      ),
                      child: Text(
                        label,
                        style: AppThemes.safeGeist(
                          fontSize: 12,
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.w400,
                          color: isSelected
                              ? (isDark ? const Color(0xFF1A140C) : Colors.white)
                              : inkColor,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              Text(
                'Sort By',
                style: AppThemes.safeGeist(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: subColor,
                ),
              ),
              const SizedBox(height: 8),
              Builder(
                builder: (context) {
                  final isSortActive = filterParams.sortBy != 'popularity.desc';
                  final accColor = isDark ? AppColors.srAcc : AppColors.rrAcc;
                  return DropdownButtonFormField<String>(
                    initialValue: filterParams.sortBy,
                    dropdownColor: isDark ? AppColors.srCard : AppColors.rrCard,
                    style: AppThemes.safeGeist(fontSize: 13, color: inkColor),
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      filled: true,
                      fillColor: isSortActive ? accColor.withAlpha(35) : pillColor,
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(
                          color: isSortActive ? accColor : lineRgba,
                          width: isSortActive ? 1.5 : 1.0,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(
                          color: accColor,
                        ),
                      ),
                    ),
                    items: [
                      DropdownMenuItem(
                        value: 'popularity.desc',
                        child: Text('Most Popular',
                            style: AppThemes.safeGeist(color: inkColor)),
                      ),
                      DropdownMenuItem(
                        value: 'vote_average.desc',
                        child: Text('Highest Rated',
                            style: AppThemes.safeGeist(color: inkColor)),
                      ),
                      DropdownMenuItem(
                        value: isMovies
                            ? 'primary_release_date.desc'
                            : 'first_air_date.desc',
                        child: Text('Release Date (Newest)',
                            style: AppThemes.safeGeist(color: inkColor)),
                      ),
                      DropdownMenuItem(
                        value: 'revenue.desc',
                        child: Text('Highest Revenue',
                            style: AppThemes.safeGeist(color: inkColor)),
                      ),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        filterNotifier.setSortBy(val);
                      }
                    },
                  );
                },
              ),
            ],
          ),

          // 5. Runtime & Language
          _buildExpansionSection(
            title: 'Runtime & Language',
            icon: Icons.timer_outlined,
            isDark: isDark,
            initiallyExpanded: filterParams.minRuntime != null ||
                filterParams.maxRuntime != null ||
                filterParams.originalLanguage != null,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Runtime Range',
                    style: AppThemes.safeGeist(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: subColor,
                    ),
                  ),
                  Text(
                    '${filterParams.minRuntime ?? 0}m - ${filterParams.maxRuntime != null ? '${filterParams.maxRuntime}m' : '240m+'}',
                    style: AppThemes.safeGeist(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppColors.srAcc : AppColors.rrAcc,
                    ),
                  ),
                ],
              ),
              RangeSlider(
                values: RangeValues(
                  (filterParams.minRuntime ?? 0).toDouble(),
                  (filterParams.maxRuntime ?? 240).toDouble(),
                ),
                min: 0.0,
                max: 240.0,
                divisions: 24,
                activeColor: isDark ? AppColors.srAcc : AppColors.rrAcc,
                inactiveColor: lineRgba,
                onChanged: (values) {
                  final minR = values.start == 0.0 ? null : values.start.toInt();
                  final maxR = values.end == 240.0 ? null : values.end.toInt();
                  filterNotifier.setRuntime(
                    minRuntime: minR,
                    maxRuntime: maxR,
                  );
                },
              ),
              const SizedBox(height: 12),
              Text(
                'Original Language',
                style: AppThemes.safeGeist(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: subColor,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  PressableScale(
                    onTap: () => filterNotifier.setOriginalLanguage(null),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: _buildFilterChipDecoration(
                        isSelected: filterParams.originalLanguage == null,
                        isDark: isDark,
                        pillColor: pillColor,
                        lineRgba: lineRgba,
                      ),
                      child: Text(
                        'Any Language',
                        style: AppThemes.safeGeist(
                          fontSize: 12,
                          color: filterParams.originalLanguage == null
                              ? (isDark ? const Color(0xFF1A140C) : Colors.white)
                              : inkColor,
                        ),
                      ),
                    ),
                  ),
                  ..._languages.map((lang) {
                    final isSelected =
                        filterParams.originalLanguage == lang['code'];
                    return PressableScale(
                      onTap: () =>
                          filterNotifier.setOriginalLanguage(lang['code']),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: _buildFilterChipDecoration(
                          isSelected: isSelected,
                          isDark: isDark,
                          pillColor: pillColor,
                          lineRgba: lineRgba,
                        ),
                        child: Text(
                          lang['name']!,
                          style: AppThemes.safeGeist(
                            fontSize: 12,
                            fontWeight:
                                isSelected ? FontWeight.w600 : FontWeight.w400,
                            color: isSelected
                                ? (isDark ? const Color(0xFF1A140C) : Colors.white)
                                : inkColor,
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ],
          ),

          // 6. TV Specifics (visible when !isMovies)
          if (!isMovies)
            _buildExpansionSection(
              title: 'TV Specifics',
              icon: Icons.live_tv_outlined,
              isDark: isDark,
              initiallyExpanded: filterParams.tvStatus != null ||
                  filterParams.tvNetworkId != null,
              children: [
                Text(
                  'Show Status',
                  style: AppThemes.safeGeist(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: subColor,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    null,
                    'Ended',
                    'Returning Series',
                  ].map((status) {
                    final isSelected = filterParams.tvStatus == status;
                    final label = status ?? 'Any Status';
                    return PressableScale(
                      onTap: () => filterNotifier.setTvStatus(status),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: _buildFilterChipDecoration(
                          isSelected: isSelected,
                          isDark: isDark,
                          pillColor: pillColor,
                          lineRgba: lineRgba,
                        ),
                        child: Text(
                          label,
                          style: AppThemes.safeGeist(
                            fontSize: 12,
                            fontWeight:
                                isSelected ? FontWeight.w600 : FontWeight.w400,
                            color: isSelected
                                ? (isDark ? const Color(0xFF1A140C) : Colors.white)
                                : inkColor,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                Text(
                  'TV Network',
                  style: AppThemes.safeGeist(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: subColor,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    PressableScale(
                      onTap: () {
                        filterNotifier.setTvNetwork(
                          tvNetworkId: null,
                          tvNetworkName: null,
                        );
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: _buildFilterChipDecoration(
                          isSelected: filterParams.tvNetworkId == null,
                          isDark: isDark,
                          pillColor: pillColor,
                          lineRgba: lineRgba,
                        ),
                        child: Text(
                          'Any Network',
                          style: AppThemes.safeGeist(
                            fontSize: 12,
                            color: filterParams.tvNetworkId == null
                                ? (isDark ? const Color(0xFF1A140C) : Colors.white)
                                : inkColor,
                          ),
                        ),
                      ),
                    ),
                    ..._tvNetworks.map((net) {
                      final isSelected =
                          filterParams.tvNetworkId == net['id'];
                      return PressableScale(
                        onTap: () {
                          filterNotifier.setTvNetwork(
                            tvNetworkId: net['id'] as int,
                            tvNetworkName: net['name'] as String,
                          );
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: _buildFilterChipDecoration(
                            isSelected: isSelected,
                            isDark: isDark,
                            pillColor: pillColor,
                            lineRgba: lineRgba,
                          ),
                          child: Text(
                            net['name'] as String,
                            style: AppThemes.safeGeist(
                              fontSize: 12,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                              color: isSelected
                                  ? (isDark ? const Color(0xFF1A140C) : Colors.white)
                                  : inkColor,
                            ),
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildExpansionSection({
    required String title,
    required IconData icon,
    required bool isDark,
    required List<Widget> children,
    bool initiallyExpanded = false,
  }) {
    final inkColor = isDark ? AppColors.srInk : AppColors.rrInk;
    final lineRgba = isDark ? AppColors.srLineRgba : AppColors.rrLineRgba;
    final cardColor = isDark ? AppColors.srCard : AppColors.rrCard;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: lineRgba),
      ),
      child: Material(
        color: cardColor,
        borderRadius: BorderRadius.circular(14),
        clipBehavior: Clip.antiAlias,
        child: ExpansionTile(
          initiallyExpanded: initiallyExpanded,
          iconColor: inkColor,
          collapsedIconColor: isDark ? AppColors.srSub : AppColors.rrSub,
          title: Row(
            children: [
              Icon(
                icon,
                size: 18,
                color: isDark ? AppColors.srAcc : AppColors.rrAcc,
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: AppThemes.safeGeist(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: inkColor,
                ),
              ),
            ],
          ),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          expandedCrossAxisAlignment: CrossAxisAlignment.start,
          children: children,
        ),
      ),
    );
  }
}
