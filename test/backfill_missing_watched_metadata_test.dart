import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:the_lounge/models/media_item.dart';
import 'package:the_lounge/providers/ambiance_provider.dart';
import 'package:the_lounge/providers/media_provider.dart';
import 'package:the_lounge/repositories/mock_movie_repository.dart';

/// Fake repository returning controlled, predictable "details" data for
/// ANLY-DATA-2's backfill -- MockMovieRepository's own getMediaDetails
/// looks up a fixed built-in dataset, not attacker-controllable per test.
///
/// Note: addToWatchedList already fires its own, unrelated
/// _enrichWatchedItemCollection call for every movie (backfills
/// belongsToCollection, fire-and-forget) -- so a raw call-count on this
/// fake is contaminated by that pre-existing feature and not a reliable
/// signal for these tests. Assertions below check the actual outcome
/// (which fields got enriched) instead of call counts.
class _FakeDetailsRepository extends MockMovieRepository {
  final Map<String, MediaItem> detailsById;

  _FakeDetailsRepository(this.detailsById);

  @override
  Future<MediaItem?> getMediaDetails(String id) async {
    return detailsById[id];
  }
}

void main() {
  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  const thinItem = MediaItem(
    id: 'movie_1',
    title: 'A Movie',
    type: MediaType.movie,
    rating: 7.0,
    overview: '',
    genres: [],
  );

  test('backfills runtime/cast/director for a Watched title missing them',
      () async {
    final fakeRepo = _FakeDetailsRepository({
      'movie_1': const MediaItem(
        id: 'movie_1',
        title: 'A Movie',
        type: MediaType.movie,
        rating: 7.0,
        overview: '',
        genres: [],
        runtime: 120,
        cast: ['Alice', 'Bob'],
        director: 'Nolan',
      ),
    });
    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        movieRepositoryProvider.overrideWithValue(fakeRepo),
      ],
    );
    addTearDown(container.dispose);

    final notifier = container.read(mediaProvider.notifier);
    notifier.addToWatchedList(thinItem);
    expect(
        container.read(mediaProvider).watchedList['movie_1']?.runtime, isNull);

    await notifier.backfillMissingWatchedMetadata();

    final enriched = container.read(mediaProvider).watchedList['movie_1']!;
    expect(enriched.runtime, 120);
    expect(enriched.cast, ['Alice', 'Bob']);
    expect(enriched.director, 'Nolan');
  });

  test(
      'EXP-DATA-2: backfills seasonsCount/episodesCount/productionCompanyNames '
      'for a Watched TV title missing them', () async {
    const thinTvItem = MediaItem(
      id: 'tv_1',
      title: 'A Show',
      type: MediaType.tv,
      rating: 7.5,
      overview: '',
      genres: [],
    );
    final fakeRepo = _FakeDetailsRepository({
      'tv_1': const MediaItem(
        id: 'tv_1',
        title: 'A Show',
        type: MediaType.tv,
        rating: 7.5,
        overview: '',
        genres: [],
        runtime: 45,
        cast: ['Alice'],
        director: 'Someone',
        seasonsCount: 3,
        episodesCount: 24,
        productionCompanyNames: ['A24'],
      ),
    });
    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        movieRepositoryProvider.overrideWithValue(fakeRepo),
      ],
    );
    addTearDown(container.dispose);

    final notifier = container.read(mediaProvider.notifier);
    notifier.addToWatchedList(thinTvItem);
    expect(container.read(mediaProvider).watchedList['tv_1']?.seasonsCount,
        isNull);

    await notifier.backfillMissingWatchedMetadata();

    final enriched = container.read(mediaProvider).watchedList['tv_1']!;
    expect(enriched.seasonsCount, 3);
    expect(enriched.episodesCount, 24);
    expect(enriched.productionCompanyNames, ['A24']);
  });

  test('does not overwrite a title that already has complete metadata',
      () async {
    const alreadyRich = MediaItem(
      id: 'movie_2',
      title: 'Rich Movie',
      type: MediaType.movie,
      rating: 7.0,
      overview: '',
      genres: [],
      runtime: 100,
      cast: ['Someone'],
      director: 'Someone Else',
    );
    // Deliberately different data than what's already on the item -- if the
    // filter wrongly includes an already-complete title, this would
    // overwrite it and the test would catch that.
    final fakeRepo = _FakeDetailsRepository({
      'movie_2': const MediaItem(
        id: 'movie_2',
        title: 'Rich Movie',
        type: MediaType.movie,
        rating: 7.0,
        overview: '',
        genres: [],
        runtime: 999,
        cast: ['Wrong Actor'],
        director: 'Wrong Director',
      ),
    });
    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        movieRepositoryProvider.overrideWithValue(fakeRepo),
      ],
    );
    addTearDown(container.dispose);

    final notifier = container.read(mediaProvider.notifier);
    notifier.addToWatchedList(alreadyRich);

    await notifier.backfillMissingWatchedMetadata();

    final stillRich = container.read(mediaProvider).watchedList['movie_2']!;
    expect(stillRich.runtime, 100);
    expect(stillRich.cast, ['Someone']);
    expect(stillRich.director, 'Someone Else');
  });

  test('maxItems bounds how many titles are enriched in one call', () async {
    final detailsById = {
      for (var i = 0; i < 5; i++)
        'movie_$i': MediaItem(
          id: 'movie_$i',
          title: 'Movie $i',
          type: MediaType.movie,
          rating: 7.0,
          overview: '',
          genres: const [],
          runtime: 100 + i,
          cast: const ['Someone'],
          director: 'Someone',
        ),
    };
    final fakeRepo = _FakeDetailsRepository(detailsById);
    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        movieRepositoryProvider.overrideWithValue(fakeRepo),
      ],
    );
    addTearDown(container.dispose);

    final notifier = container.read(mediaProvider.notifier);
    for (var i = 0; i < 5; i++) {
      notifier.addToWatchedList(MediaItem(
        id: 'movie_$i',
        title: 'Movie $i',
        type: MediaType.movie,
        rating: 7.0,
        overview: '',
        genres: const [],
      ));
    }

    await notifier.backfillMissingWatchedMetadata(maxItems: 2);

    final enrichedCount = container
        .read(mediaProvider)
        .watchedList
        .values
        .where((item) => item.runtime != null)
        .length;
    expect(enrichedCount, 2);
  });

  test(
      'a fetch failure for one title does not stop the others from being enriched',
      () async {
    final fakeRepo = _FakeDetailsRepository({
      // movie_1 deliberately absent -> getMediaDetails returns null for it.
      'movie_2': const MediaItem(
        id: 'movie_2',
        title: 'Movie 2',
        type: MediaType.movie,
        rating: 7.0,
        overview: '',
        genres: [],
        runtime: 90,
        cast: ['Someone'],
        director: 'Director',
      ),
    });
    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        movieRepositoryProvider.overrideWithValue(fakeRepo),
      ],
    );
    addTearDown(container.dispose);

    final notifier = container.read(mediaProvider.notifier);
    notifier.addToWatchedList(thinItem);
    notifier.addToWatchedList(const MediaItem(
      id: 'movie_2',
      title: 'Movie 2',
      type: MediaType.movie,
      rating: 7.0,
      overview: '',
      genres: [],
    ));

    await notifier.backfillMissingWatchedMetadata();

    final state = container.read(mediaProvider);
    expect(state.watchedList['movie_1']?.runtime, isNull);
    expect(state.watchedList['movie_2']?.runtime, 90);
  });
}
