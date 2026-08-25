// DATA-CONT-3: the Discover deck's keyword-overlap boost. Verifies
// loadPool() (1) queries TMDB's /discover with_keywords for the user's
// top watched-shelf keyword, and (2) places titles matching it earlier in
// the resulting pool (pool.first is the next card shown -- see
// DiscoverScreen), rather than just widening inclusion.
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:the_lounge/models/discover_filter_params.dart';
import 'package:the_lounge/models/media_item.dart';
import 'package:the_lounge/providers/ambiance_provider.dart';
import 'package:the_lounge/providers/media_provider.dart';
import 'package:the_lounge/repositories/mock_movie_repository.dart';

MediaItem _movie(String id, {List<MediaKeyword>? keywords}) => MediaItem(
      id: id,
      title: 'Movie $id',
      type: MediaType.movie,
      rating: 8.0,
      overview: '',
      genres: const [],
      voteCount: 5000,
      keywords: keywords,
    );

class _KeywordAwareRepository extends MockMovieRepository {
  final List<int?> requestedKeywordIds = [];

  @override
  Future<List<MediaItem>> discoverMedia({
    required bool isMovies,
    required DiscoverFilterParams params,
    int page = 1,
  }) async {
    requestedKeywordIds.add(params.keywordId);
    if (params.keywordId == 42) {
      // Only returned when the boost query actually fires -- a distinct id
      // proves it came from the keyword-scoped call, not the regular pool.
      return [_movie('boosted')];
    }
    // Regular (non-keyword) discover calls seed enough plain candidates to
    // satisfy loadPool's while-loop exit condition (>= 5 items) in one pass.
    return List.generate(6, (i) => _movie('plain_${page}_$i'));
  }

  @override
  Future<List<MediaItem>> getPopularMovies(
          {int page = 1, String? originalLanguage}) async =>
      [];
  @override
  Future<List<MediaItem>> getTopRatedTvShows(
          {int page = 1, String? originalLanguage}) async =>
      [];
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Future<void> waitUntilSettled(bool Function() isLoading) async {
    for (var i = 0; i < 60; i++) {
      if (!isLoading()) return;
      await Future<void>.delayed(const Duration(milliseconds: 25));
    }
  }

  test(
      'loadPool queries with_keywords for the top watched-shelf keyword and boosts matches to the front of the pool',
      () async {
    final prefs = await SharedPreferences.getInstance();
    final repo = _KeywordAwareRepository();
    final container = ProviderContainer(overrides: [
      movieRepositoryProvider.overrideWithValue(repo),
      sharedPreferencesProvider.overrideWithValue(prefs),
    ]);
    addTearDown(container.dispose);

    // Seed the watched shelf with a title carrying keyword id 42 BEFORE the
    // deck's first build() -- loadPool reads mediaProvider's current
    // in-memory state fresh on every call.
    container.read(mediaProvider.notifier).addToWatchedList(
          _movie('watched_seed',
              keywords: const [MediaKeyword(id: 42, name: 'heist')]),
        );

    await waitUntilSettled(
        () => container.read(discoverMoviesDeckProvider).isLoading);

    expect(repo.requestedKeywordIds, contains(42),
        reason:
            'the top watched keyword id must be passed as with_keywords on at least one discoverMedia call');

    final pool = container.read(discoverMoviesDeckProvider).pool;
    final boostedIndex = pool.indexWhere((i) => i.id == 'boosted');
    expect(boostedIndex, isNot(-1),
        reason: 'the keyword-matched title must be in the pool');
    // Every non-boosted title in the same batch must sort after it.
    final firstPlainIndex = pool.indexWhere((i) => i.id.startsWith('plain_'));
    expect(boostedIndex, lessThan(firstPlainIndex),
        reason:
            'keyword-matched titles must surface earlier than the regular pool, not just be included');
  });

  test(
      'a user with no watched keywords never fires a with_keywords discover call',
      () async {
    final prefs = await SharedPreferences.getInstance();
    final repo = _KeywordAwareRepository();
    final container = ProviderContainer(overrides: [
      movieRepositoryProvider.overrideWithValue(repo),
      sharedPreferencesProvider.overrideWithValue(prefs),
    ]);
    addTearDown(container.dispose);

    await waitUntilSettled(
        () => container.read(discoverMoviesDeckProvider).isLoading);

    expect(repo.requestedKeywordIds.every((id) => id == null), isTrue);
  });
}
