import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/discover_filter_params.dart';
import '../models/media_item.dart';
import '../utils/weighted_rating.dart';
import 'ambiance_provider.dart';
import 'hall_provider.dart';
import 'media_provider.dart';

class SwipeRecord {
  final MediaItem item;
  final String direction;
  const SwipeRecord({required this.item, required this.direction});
}

class DiscoverDeckState {
  final List<MediaItem> pool;
  final SwipeRecord? lastSwipe;
  final bool isLoading;
  final Object? error;
  final int currentPage;
  final String? undoneMediaId;
  final String? undoneDirection;
  final DateTime? lastManualReloadAt;

  const DiscoverDeckState({
    this.pool = const [],
    this.lastSwipe,
    this.isLoading = false,
    this.error,
    this.currentPage = 1,
    this.undoneMediaId,
    this.undoneDirection,
    this.lastManualReloadAt,
  });

  /// B9: normal swipe-triggered pagination (see [DiscoverDeckNotifier.popCard])
  /// stays unlimited within a session -- this only gates the explicit
  /// "Reload deck" action offered once the pool is genuinely empty, to once
  /// per calendar day.
  bool get canManuallyReloadToday {
    final last = lastManualReloadAt;
    if (last == null) return true;
    final now = DateTime.now();
    return last.year != now.year ||
        last.month != now.month ||
        last.day != now.day;
  }

  DiscoverDeckState copyWith({
    List<MediaItem>? pool,
    SwipeRecord? lastSwipe,
    bool? isLoading,
    Object? error,
    int? currentPage,
    String? undoneMediaId,
    String? undoneDirection,
    bool clearUndone = false,
    DateTime? lastManualReloadAt,
  }) {
    return DiscoverDeckState(
      pool: pool ?? this.pool,
      lastSwipe: lastSwipe ?? this.lastSwipe,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      currentPage: currentPage ?? this.currentPage,
      undoneMediaId: clearUndone ? null : (undoneMediaId ?? this.undoneMediaId),
      undoneDirection: clearUndone ? null : (undoneDirection ?? this.undoneDirection),
      lastManualReloadAt: lastManualReloadAt ?? this.lastManualReloadAt,
    );
  }
}

abstract class DiscoverDeckNotifier extends Notifier<DiscoverDeckState> {
  bool get isMovies;

  /// Server-side floor (SP-3/E2, CO-9): only asks TMDB to exclude
  /// effectively-unvoted noise. The real quality bar is the weighted-rating
  /// threshold below, computed client-side once the candidate pool is in
  /// hand — a raw TMDB `vote_average.gte` floor let a 2-vote title occupy
  /// the same space as a 20,000-vote title of the same raw average.
  static const int _minVoteCountFloor = 50;

  /// `m` in the weighted-rating formula — how many votes a title needs
  /// before its own average is trusted close to face value. Deliberately
  /// higher than Search's filter (see search_screen.dart) since the deck is
  /// meant to read as curated, not just "everything above a bar."
  static const double _minVotesForFullWeight = 300.0;

  /// Weighted-rating cutoff a candidate must clear to enter the deck. Lower
  /// than the old raw 7.0 floor it replaces, because WR already discounts
  /// low-vote titles toward the pool mean — an absolute WR of 6.5 stays
  /// meaningfully selective without double-penalizing well-voted titles.
  static const double _weightedRatingThreshold = 6.5;

  /// Hard floor on the title's own raw rating, independent of the weighted
  /// formula above. WR alone isn't enough as a strict floor: a title with
  /// very few votes gets pulled *up* toward the pool mean, so a genuinely
  /// bad (e.g. 1.5-star) title with only a handful of votes could still
  /// clear [_weightedRatingThreshold] if that day's pool mean happened to
  /// be high. This is a strict, unconditional cutoff -- nothing rated below
  /// it is ever allowed into the deck, no matter how few/many votes it has.
  static const double _minRawRatingFloor = 4.0;

  String get _lastManualReloadKey =>
      'the_lounge_last_manual_reload_${isMovies ? 'movies' : 'tv'}';

  @override
  DiscoverDeckState build() {
    DateTime? lastManualReloadAt;
    try {
      final prefs = ref.watch(sharedPreferencesProvider);
      final stored = prefs.getString(_lastManualReloadKey);
      if (stored != null) {
        lastManualReloadAt = DateTime.tryParse(stored);
      }
    } catch (_) {}
    Future.microtask(() => loadPool());
    return DiscoverDeckState(
      isLoading: true,
      lastManualReloadAt: lastManualReloadAt,
    );
  }

  /// B9: the explicit "Reload deck" action, capped to once per calendar
  /// day (see [DiscoverDeckState.canManuallyReloadToday]). Returns false
  /// (and does nothing) if today's manual reload has already been used --
  /// callers show the "come back tomorrow" state in that case instead.
  Future<bool> manualReload() async {
    if (!state.canManuallyReloadToday) return false;
    final now = DateTime.now();
    state = state.copyWith(lastManualReloadAt: now);
    try {
      final prefs = ref.read(sharedPreferencesProvider);
      await prefs.setString(_lastManualReloadKey, now.toIso8601String());
    } catch (_) {}
    await loadPool(isReload: true);
    return true;
  }

  Future<void> loadPool({bool isReload = false}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      int page = isReload ? state.currentPage + 2 : 1;
      if (!isReload) {
        state = state.copyWith(pool: []);
      }

      final repo = ref.read(movieRepositoryProvider);
      final mediaState = ref.read(mediaProvider);
      final skippedIds = ref.read(skippedMediaIdsProvider);

      final excludedIds = <String>{
        ...mediaState.watchlist.keys,
        ...mediaState.maybeList.keys,
        ...mediaState.watchedList.keys,
        ...mediaState.watchingList.keys,
        ...mediaState.droppedList.keys,
        ...mediaState.onHoldList.keys,
        ...skippedIds.keys,
        ...state.pool.map((e) => e.id),
      };

      bool isExcluded(MediaItem item) {
        final cleanId = item.id.replaceFirst(RegExp(r'^(movie_|tv_)'), '');
        return excludedIds.contains(item.id) ||
            excludedIds.contains(item.prefixedId) ||
            excludedIds.contains(cleanId);
      }

      // LANG-2 (2nd pass): pre-filter both the discoverMedia() calls AND the
      // getPopularMovies/getTopRatedTvShows blend-in calls server-side (see
      // MovieRepository's originalLanguage param -- routes fixed-list
      // methods through /discover with with_original_language when set).
      // `filtered` below still re-checks every item's language regardless
      // of source, as a defensive backstop, not the primary filter.
      final lockedLanguageCode =
          ref.read(activeHallSpaceProvider).lockedLanguageCode;
      final discoverParams = DiscoverFilterParams(
        minVoteCount: _minVoteCountFloor,
        minRating: _minRawRatingFloor,
        originalLanguage: lockedLanguageCode,
      );
      List<MediaItem> newItems = [];
      int attempts = 0;

      while (newItems.length < 5 && attempts < 5) {
        final List<MediaItem> rawList = [];
        final p1 = page;
        final p2 = page + 1;

        if (isMovies) {
          final d1 = await repo.discoverMedia(isMovies: true, params: discoverParams, page: p1);
          rawList.addAll(d1);
          try {
            final d2 = await repo.discoverMedia(isMovies: true, params: discoverParams, page: p2);
            rawList.addAll(d2);
          } catch (_) {}
          try {
            final pop1 = await repo.getPopularMovies(page: p1, originalLanguage: lockedLanguageCode);
            rawList.addAll(pop1);
          } catch (_) {}
        } else {
          final d1 = await repo.discoverMedia(isMovies: false, params: discoverParams, page: p1);
          rawList.addAll(d1);
          try {
            final d2 = await repo.discoverMedia(isMovies: false, params: discoverParams, page: p2);
            rawList.addAll(d2);
          } catch (_) {}
          try {
            final top1 = await repo.getTopRatedTvShows(page: p1, originalLanguage: lockedLanguageCode);
            rawList.addAll(top1);
          } catch (_) {}
        }

        final seen = <String>{...state.pool.map((e) => e.id), ...newItems.map((e) => e.id)};
        final poolMean = meanRatingOf(rawList);
        final filtered = rawList.where((item) {
          final wr = weightedRatingOf(
            item,
            poolMean: poolMean,
            minVotes: _minVotesForFullWeight,
          );
          final matchesLanguageLock = lockedLanguageCode == null ||
              item.originalLanguage == lockedLanguageCode;
          return item.rating >= _minRawRatingFloor &&
              wr >= _weightedRatingThreshold &&
              matchesLanguageLock &&
              !isExcluded(item) &&
              seen.add(item.id);
        }).toList();

        newItems.addAll(filtered);
        page += 2;
        attempts++;
      }

      state = state.copyWith(
        pool: isReload ? [...state.pool, ...newItems] : newItems,
        currentPage: page - 2,
        isLoading: false,
      );
    } catch (e) {
      state = DiscoverDeckState(pool: state.pool, isLoading: false, error: e, currentPage: state.currentPage);
    }
  }

  /// Removes [itemId] from the in-memory pool if present, without a network
  /// re-fetch. Used when a title gets marked Watchlisted/Saved/Watched/etc.
  /// from OUTSIDE Discover (Detail screen buttons, Browse's Quick Status
  /// Sheet) while it's sitting in an already-loaded pool -- mirrors
  /// [popCard]'s local removal for Discover-triggered swipes, closing the
  /// staleness gap notepad item 15 flagged (loadPool's own exclusion set
  /// already covers these six status lists; this just keeps an
  /// already-loaded pool in sync without waiting for the next reload).
  void removeFromPoolIfPresent(String itemId) {
    if (state.pool.isEmpty) return;
    final cleanId = itemId.replaceFirst(RegExp(r'^(movie_|tv_)'), '');
    final nextPool = state.pool
        .where((item) =>
            item.id != itemId &&
            item.prefixedId != itemId &&
            item.id != cleanId)
        .toList();
    if (nextPool.length != state.pool.length) {
      state = state.copyWith(pool: nextPool);
    }
  }

  void popCard(MediaItem item, String direction) {
    if (state.pool.isNotEmpty) {
      // Removes by identity, not index 0: _onSwipe (discover_screen.dart)
      // calls MediaNotifier's status-mutation methods (addToWatchlist etc.)
      // BEFORE calling popCard for the same swipe, and those now also
      // evict the item from this pool via _excludeFromDiscoverPools
      // (notepad item 15). Assuming the swiped card is still at index 0
      // would then wrongly evict whatever card is next in line instead --
      // removing by identity is a harmless no-op if it's already gone, and
      // still correct in the normal case where nothing removed it first.
      final nextPool = state.pool
          .where((i) => i.id != item.id && i.prefixedId != item.id)
          .toList();
      state = state.copyWith(
        pool: nextPool,
        lastSwipe: SwipeRecord(item: item, direction: direction),
        clearUndone: true,
      );
      if (nextPool.isEmpty) {
        loadPool(isReload: true);
      }
    }
  }

  void undoLastSwipe() {
    final lastSwipe = state.lastSwipe;
    if (lastSwipe == null) return;

    final mediaNotifier = ref.read(mediaProvider.notifier);
    final skippedNotifier = ref.read(skippedMediaIdsProvider.notifier);

    switch (lastSwipe.direction) {
      case 'Left':
        skippedNotifier.undoSkip(lastSwipe.item.id);
        skippedNotifier.undoSkip(lastSwipe.item.prefixedId);
        break;
      case 'Right':
        mediaNotifier.removeFromMaybeList(lastSwipe.item.id);
        break;
      case 'Down':
        mediaNotifier.removeFromWatchlist(lastSwipe.item.id);
        break;
      case 'Up':
        mediaNotifier.removeFromWatchedList(lastSwipe.item.id);
        break;
    }

    state = DiscoverDeckState(
      pool: [lastSwipe.item, ...state.pool],
      lastSwipe: null,
      isLoading: state.isLoading,
      error: state.error,
      currentPage: state.currentPage,
      undoneMediaId: lastSwipe.item.id,
      undoneDirection: lastSwipe.direction,
    );
  }
}

class DiscoverMoviesDeckNotifier extends DiscoverDeckNotifier {
  @override
  bool get isMovies => true;
}

class DiscoverTvDeckNotifier extends DiscoverDeckNotifier {
  @override
  bool get isMovies => false;
}

final discoverMoviesDeckProvider =
    NotifierProvider<DiscoverMoviesDeckNotifier, DiscoverDeckState>(() {
  return DiscoverMoviesDeckNotifier();
});

final discoverTvDeckProvider =
    NotifierProvider<DiscoverTvDeckNotifier, DiscoverDeckState>(() {
  return DiscoverTvDeckNotifier();
});
