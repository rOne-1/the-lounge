import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../utils/analytics_engine.dart';
import 'media_provider.dart';

/// ANLY-PROVIDER-1: cached generation state for the Analytics epic.
class AnalyticsState {
  final AnalyticsResult? result;
  final DateTime? generatedAt;
  final bool isGenerating;
  final Object? error;

  const AnalyticsState({
    this.result,
    this.generatedAt,
    this.isGenerating = false,
    this.error,
  });

  AnalyticsState copyWith({
    AnalyticsResult? result,
    DateTime? generatedAt,
    bool? isGenerating,
    Object? error,
    bool clearError = false,
  }) {
    return AnalyticsState(
      result: result ?? this.result,
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
      );
      final result = await runAnalyticsCompute(input);
      state = state.copyWith(
        result: result,
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
