// Regression coverage for notepad item 15: marking a title Watched/
// Watchlisted/etc. from OUTSIDE Discover (Detail screen buttons, Browse's
// Quick Status Sheet) must evict it from an already-loaded Discover pool
// immediately, not just on the next full reload -- mirrors what popCard()
// already does for Discover-triggered swipes.
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:the_lounge/models/discover_filter_params.dart';
import 'package:the_lounge/models/media_item.dart';
import 'package:the_lounge/providers/ambiance_provider.dart';
import 'package:the_lounge/providers/media_provider.dart';
import 'package:the_lounge/repositories/mock_movie_repository.dart';

class _SingleMovieRepository extends MockMovieRepository {
  static const movie1 = MediaItem(
    id: '1',
    title: 'Movie 1',
    type: MediaType.movie,
    rating: 8.0,
    overview: '',
    genres: [],
    voteCount: 5000,
  );

  @override
  Future<List<MediaItem>> discoverMedia({
    required bool isMovies,
    required DiscoverFilterParams params,
    int page = 1,
  }) async {
    if (!isMovies || page > 1) return [];
    return [movie1];
  }

  @override
  Future<List<MediaItem>> getPopularMovies({int page = 1, String? originalLanguage}) async => [];
  @override
  Future<List<MediaItem>> getTrendingMovies({int page = 1, String? originalLanguage}) async => [];
  @override
  Future<List<MediaItem>> getTopRatedMovies({int page = 1, String? originalLanguage}) async => [];
  @override
  Future<List<MediaItem>> getNowPlayingMovies({int page = 1, String? region, String? originalLanguage}) async => [];
  @override
  Future<List<MediaItem>> getUpcomingMovies({int page = 1, String? originalLanguage}) async => [];
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  // DiscoverDeckNotifier.build() always kicks off its own
  // Future.microtask(loadPool) the first time a deck provider is read --
  // unconditionally, regardless of whether the caller also calls loadPool()
  // explicitly. Calling it explicitly too (as an earlier version of this
  // test, and the pre-fix TF-2 test, both did) creates a SECOND concurrent
  // invocation racing the first on the same notifier -- isLoading flips to
  // false as soon as EITHER finishes, so polling it isn't a reliable
  // "everything settled" signal when a second invocation is still in
  // flight, and it can still be using its Ref after the container is
  // disposed. Fix: never call loadPool() explicitly here -- just read the
  // state provider once (triggering build()'s single auto-load) and poll
  // that one invocation to completion. loadPool itself retries up to 5
  // attempts x 3 sequential repo calls each when results come up short, so
  // a fixed short delay isn't reliable either -- poll until isLoading
  // actually flips false.
  Future<void> waitUntilSettled(bool Function() isLoading) async {
    for (var i = 0; i < 60; i++) {
      if (!isLoading()) return;
      await Future<void>.delayed(const Duration(milliseconds: 25));
    }
  }

  Future<ProviderContainer> buildSeededContainer() async {
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(overrides: [
      movieRepositoryProvider.overrideWithValue(_SingleMovieRepository()),
      sharedPreferencesProvider.overrideWithValue(prefs),
    ]);
    await waitUntilSettled(
        () => container.read(discoverMoviesDeckProvider).isLoading);
    // Touch and settle the TV deck here too, upfront, so
    // _excludeFromDiscoverPools touching it later (inside a mutation call)
    // just reads the already-built notifier instead of triggering a fresh
    // build() whose auto-load could still be in flight when the container
    // is disposed.
    await waitUntilSettled(
        () => container.read(discoverTvDeckProvider).isLoading);
    expect(
      container.read(discoverMoviesDeckProvider).pool.any((i) => i.id == '1'),
      isTrue,
      reason: 'Precondition: movie_1 must be in the pool before mutating',
    );
    return container;
  }

  test('addToWatchlist evicts a pooled title from the Discover pool immediately',
      () async {
    final container = await buildSeededContainer();
    addTearDown(container.dispose);

    container.read(mediaProvider.notifier).addToWatchlist(_SingleMovieRepository.movie1);

    final pool = container.read(discoverMoviesDeckProvider).pool;
    expect(pool.any((i) => i.id == '1'), isFalse);
  });

  test('toggleWatched (add path) evicts a pooled title from the Discover pool',
      () async {
    final container = await buildSeededContainer();
    addTearDown(container.dispose);

    container.read(mediaProvider.notifier).toggleWatched(_SingleMovieRepository.movie1);

    final pool = container.read(discoverMoviesDeckProvider).pool;
    expect(pool.any((i) => i.id == '1'), isFalse);
  });

  test('addToOnHoldList evicts a pooled title from the Discover pool', () async {
    final container = await buildSeededContainer();
    addTearDown(container.dispose);

    container.read(mediaProvider.notifier).addToOnHoldList(_SingleMovieRepository.movie1);

    final pool = container.read(discoverMoviesDeckProvider).pool;
    expect(pool.any((i) => i.id == '1'), isFalse);
  });

  test('a title NOT in the pool is a harmless no-op (no crash, pool unchanged)',
      () async {
    final container = await buildSeededContainer();
    addTearDown(container.dispose);

    const otherMovie = MediaItem(
      id: 'not-in-pool',
      title: 'Elsewhere',
      type: MediaType.movie,
      rating: 7.0,
      overview: '',
      genres: [],
    );
    container.read(mediaProvider.notifier).addToWatchlist(otherMovie);

    final pool = container.read(discoverMoviesDeckProvider).pool;
    expect(pool.any((i) => i.id == '1'), isTrue);
    expect(pool.length, 1);
  });

  test('importBackupJson round-trip: the existing TF-2 path still works '
      'alongside the new mutation-triggered removal', () async {
    final container = await buildSeededContainer();
    addTearDown(container.dispose);

    final backupJson = jsonEncode({
      'version': 1,
      'watchlist': {
        '1': {
          'id': '1',
          'title': 'Movie 1',
          'type': 'movie',
          'rating': 8.0,
          'posterUrl': null,
        },
      },
      'maybeList': {},
      'watchingList': {},
      'watchedList': {},
      'droppedList': {},
      'onHoldList': {},
      'watchedEpisodes': {},
      'watchProvidersCountry': 'US',
      'selectedAmbiance': null,
    });

    final result =
        await container.read(mediaProvider.notifier).importBackupJson(backupJson);
    expect(result, isTrue);

    await container
        .read(discoverMoviesDeckProvider.notifier)
        .loadPool(isReload: false);
    await waitUntilSettled(
        () => container.read(discoverMoviesDeckProvider).isLoading);
    await container
        .read(discoverTvDeckProvider.notifier)
        .loadPool(isReload: false);
    await waitUntilSettled(
        () => container.read(discoverTvDeckProvider).isLoading);

    final pool = container.read(discoverMoviesDeckProvider).pool;
    expect(pool.any((i) => i.id == '1'), isFalse);
  });
}
