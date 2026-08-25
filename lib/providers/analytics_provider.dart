import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/media_item.dart';
import '../utils/analytics_engine.dart';
import 'media_provider.dart';

/// EXP-FRANCHISE-1: one franchise/collection's completion standing. Lives
/// outside [AnalyticsResult] deliberately -- unlike every other metric,
/// computing this needs a live network fetch per collection
/// (`getCollectionDetails`), so it can't run inside
/// [runAnalyticsCompute]'s isolate-safe, purely-local-data pipeline. See
/// [AnalyticsNotifier._fetchCollectionCompletions].
class CollectionCompletion {
  final int collectionId;
  final String collectionName;
  final int watchedCount;
  final int totalCount;

  const CollectionCompletion({
    required this.collectionId,
    required this.collectionName,
    required this.watchedCount,
    required this.totalCount,
  });
}

/// ANLY-PROVIDER-1: cached generation state for the Analytics epic.
class AnalyticsState {
  final AnalyticsResult? result;
  final List<CollectionCompletion> collectionCompletions;
  final DateTime? generatedAt;
  final bool isGenerating;
  final Object? error;

  const AnalyticsState({
    this.result,
    this.collectionCompletions = const [],
    this.generatedAt,
    this.isGenerating = false,
    this.error,
  });

  AnalyticsState copyWith({
    AnalyticsResult? result,
    List<CollectionCompletion>? collectionCompletions,
    DateTime? generatedAt,
    bool? isGenerating,
    Object? error,
    bool clearError = false,
  }) {
    return AnalyticsState(
      result: result ?? this.result,
      collectionCompletions:
          collectionCompletions ?? this.collectionCompletions,
      generatedAt: generatedAt ?? this.generatedAt,
      isGenerating: isGenerating ?? this.isGenerating,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

/// ANLY-PROVIDER-1 / SP-1: deliberately does NOT auto-generate in [build] --
/// this is the one point that must never compute Analytics as a side
/// effect. [generate] is the only path into [runAnalyticsCompute], and it
/// only ever runs from an explicit user tap (see AnalyticsScreen's
/// "Generate Analytics" button).
class AnalyticsNotifier extends Notifier<AnalyticsState> {
  @override
  AnalyticsState build() => const AnalyticsState();

  /// EXP-FRANCHISE-1 / DATA-FRAN-1: fetches completion standing for the 5
  /// distinct collections most recently touched (bounding worst-case
  /// Generate latency -- a franchise-heavy library doesn't fetch every
  /// collection it's ever touched). A failed/slow fetch for one collection
  /// just omits that row; it never blocks the others or fails Generate as
  /// a whole.
  ///
  /// DATA-FRAN-1: a collection *qualifies* for tracking if any shelf has a
  /// part in it, not just Watched (a franchise you've only started via
  /// Watchlist/Watching still deserves a completion standing) -- but
  /// [CollectionCompletion.watchedCount] itself still means literally
  /// watched, matching this feature's own "3 of 8 Watched" framing.
  /// Priority for the top-5 cap still favors recently-*watched*
  /// collections (falls back to insertion order for collections with no
  /// watch activity at all, via the null-date branch below).
  Future<List<CollectionCompletion>> _fetchCollectionCompletions(
    MediaState mediaState,
  ) async {
    final anyShelfItems = <MediaItem>[
      ...mediaState.watchlist.values,
      ...mediaState.maybeList.values,
      ...mediaState.watchedList.values,
      ...mediaState.watchingList.values,
      ...mediaState.droppedList.values,
      ...mediaState.onHoldList.values,
    ];

    final anyShelfByCollection = <int, List<MediaItem>>{};
    for (final item in anyShelfItems) {
      final collection = item.belongsToCollection;
      if (collection != null) {
        anyShelfByCollection.putIfAbsent(collection.id, () => []).add(item);
      }
    }
    if (anyShelfByCollection.isEmpty) return [];

    final watchedByCollection = <int, List<MediaItem>>{};
    for (final item in mediaState.watchedList.values) {
      final collection = item.belongsToCollection;
      if (collection != null) {
        watchedByCollection.putIfAbsent(collection.id, () => []).add(item);
      }
    }

    DateTime? mostRecentWatchDate(List<MediaItem>? items) {
      if (items == null) return null;
      DateTime? latest;
      for (final item in items) {
        final records = mediaState.watchHistory[item.id];
        if (records == null) continue;
        for (final record in records) {
          final date = record.date ?? record.recordedAt;
          if (latest == null || date.isAfter(latest)) latest = date;
        }
      }
      return latest;
    }

    final sortedIds = anyShelfByCollection.keys.toList()
      ..sort((a, b) {
        final dateA = mostRecentWatchDate(watchedByCollection[a]);
        final dateB = mostRecentWatchDate(watchedByCollection[b]);
        if (dateA == null && dateB == null) return 0;
        if (dateA == null) return 1;
        if (dateB == null) return -1;
        return dateB.compareTo(dateA);
      });

    final repo = ref.read(movieRepositoryProvider);
    final results = <CollectionCompletion>[];
    for (final id in sortedIds.take(5)) {
      try {
        final detail = await repo.getCollectionDetails(id);
        if (detail == null || detail.parts.isEmpty) continue;
        results.add(CollectionCompletion(
          collectionId: id,
          collectionName: detail.name,
          watchedCount: watchedByCollection[id]?.length ?? 0,
          totalCount: detail.parts.length,
        ));
      } catch (_) {
        // Skip this collection only -- the others still get a chance.
      }
    }
    return results;
  }

  Future<void> generate() async {
    state = state.copyWith(isGenerating: true, clearError: true);
    try {
      // ANLY-DATA-2: backfill any Watched titles still missing
      // runtime/cast/director (real for anything marked Watched from a
      // list/grid card rather than the Detail screen -- TMDB's list
      // endpoints never include that data) before reading mediaProvider's
      // state, so Time Investment and Cast/Auteur Constellations reflect
      // it. Still gated entirely behind this explicit Generate tap (SP-1).
      await ref.read(mediaProvider.notifier).backfillMissingWatchedMetadata();

      final mediaState = ref.read(mediaProvider);
      final input = AnalyticsInput(
        watchedList: mediaState.watchedList,
        watchHistory: mediaState.watchHistory,
        watchedEpisodes: mediaState.watchedEpisodes,
        seasonStartDates: mediaState.seasonStartDates,
        seasonEndDates: mediaState.seasonEndDates,
        // EXP-FUNNEL-2: an already-tracked count, no new state read here.
        skippedCount: ref.read(skippedMediaIdsProvider).length,
        watchlist: mediaState.watchlist,
        maybeList: mediaState.maybeList,
        startDates: mediaState.startDates,
        watchingList: mediaState.watchingList,
      );
      final result = await runAnalyticsCompute(input);
      // EXP-FRANCHISE-1: network-dependent, so it runs on the main isolate
      // after the pure compute() pipeline, not inside it.
      final collectionCompletions =
          await _fetchCollectionCompletions(mediaState);
      state = state.copyWith(
        result: result,
        collectionCompletions: collectionCompletions,
        generatedAt: DateTime.now(),
        isGenerating: false,
      );
    } catch (e) {
      state = state.copyWith(isGenerating: false, error: e);
    }
  }
}

final analyticsProvider =
    NotifierProvider<AnalyticsNotifier, AnalyticsState>(() {
  return AnalyticsNotifier();
});
