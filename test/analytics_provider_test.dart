import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:the_lounge/models/media_collection_detail.dart';
import 'package:the_lounge/models/media_item.dart';
import 'package:the_lounge/providers/ambiance_provider.dart';
import 'package:the_lounge/providers/analytics_provider.dart';
import 'package:the_lounge/providers/media_provider.dart';
import 'package:the_lounge/repositories/mock_movie_repository.dart';

/// EXP-FRANCHISE-1: fake returning controlled collection data, and letting
/// a specific collection id simulate a fetch failure -- proves one bad
/// fetch doesn't block the others.
class _FakeCollectionRepository extends MockMovieRepository {
  final Map<int, MediaCollectionDetail> collections;
  final int? failingCollectionId;

  _FakeCollectionRepository(this.collections, {this.failingCollectionId});

  @override
  Future<MediaCollectionDetail?> getCollectionDetails(int collectionId) async {
    if (collectionId == failingCollectionId) {
      throw Exception('simulated network failure');
    }
    return collections[collectionId];
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SharedPreferences prefs;

  setUp(() async {
    GoogleFonts.config.allowRuntimeFetching = false;
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  test(
      'ANLY-PROVIDER-1 / SP-1: idle state has no result and never auto-generates',
      () {
    final container = ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    );
    addTearDown(container.dispose);

    // Reading the provider must not trigger generation on its own.
    final state = container.read(analyticsProvider);
    expect(state.result, isNull);
    expect(state.generatedAt, isNull);
    expect(state.isGenerating, isFalse);
    expect(state.error, isNull);
  });

  test('generate() populates result and generatedAt', () async {
    final container = ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    );
    addTearDown(container.dispose);

    const movie = MediaItem(
      id: 'movie_1',
      title: 'A Movie',
      type: MediaType.movie,
      rating: 7.0,
      overview: '',
      genres: [],
      runtime: 100,
    );
    container.read(mediaProvider.notifier).addToWatchedList(movie);

    await container.read(analyticsProvider.notifier).generate();

    final state = container.read(analyticsProvider);
    expect(state.result, isNotNull);
    expect(state.result!.timeInvestment.movieMinutes, 100);
    expect(state.generatedAt, isNotNull);
    expect(state.isGenerating, isFalse);
    expect(state.error, isNull);
  });

  test('calling generate() again overwrites the previous result', () async {
    final container = ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    );
    addTearDown(container.dispose);

    await container.read(analyticsProvider.notifier).generate();
    final firstGeneratedAt = container.read(analyticsProvider).generatedAt;

    const movie = MediaItem(
      id: 'movie_1',
      title: 'A Movie',
      type: MediaType.movie,
      rating: 7.0,
      overview: '',
      genres: [],
      runtime: 90,
    );
    container.read(mediaProvider.notifier).addToWatchedList(movie);
    await container.read(analyticsProvider.notifier).generate();

    final state = container.read(analyticsProvider);
    expect(state.result!.timeInvestment.movieMinutes, 90);
    expect(state.generatedAt, isNotNull);
    expect(firstGeneratedAt, isNotNull);
  });

  group('EXP-FRANCHISE-1: collection completion', () {
    test('generate() fetches completion for a watched title\'s collection',
        () async {
      final fakeRepo = _FakeCollectionRepository({
        10: const MediaCollectionDetail(
          id: 10,
          name: 'Test Collection',
          parts: [
            MediaItem(
                id: '1',
                title: 'Part 1',
                type: MediaType.movie,
                rating: 7,
                overview: '',
                genres: []),
            MediaItem(
                id: '2',
                title: 'Part 2',
                type: MediaType.movie,
                rating: 7,
                overview: '',
                genres: []),
          ],
        ),
      });
      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          movieRepositoryProvider.overrideWithValue(fakeRepo),
        ],
      );
      addTearDown(container.dispose);

      container.read(mediaProvider.notifier).addToWatchedList(
            const MediaItem(
              id: '1',
              title: 'Part 1',
              type: MediaType.movie,
              rating: 7,
              overview: '',
              genres: [],
              belongsToCollection:
                  MediaCollection(id: 10, name: 'Test Collection'),
            ),
          );

      await container.read(analyticsProvider.notifier).generate();

      final completions =
          container.read(analyticsProvider).collectionCompletions;
      expect(completions, hasLength(1));
      expect(completions.single.collectionName, 'Test Collection');
      expect(completions.single.watchedCount, 1);
      expect(completions.single.totalCount, 2);
    });

    test('a fetch failure for one collection does not block the others',
        () async {
      final fakeRepo = _FakeCollectionRepository(
        {
          20: const MediaCollectionDetail(
            id: 20,
            name: 'Good Collection',
            parts: [
              MediaItem(
                  id: '3',
                  title: 'Part 3',
                  type: MediaType.movie,
                  rating: 7,
                  overview: '',
                  genres: []),
            ],
          ),
        },
        failingCollectionId: 10,
      );
      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          movieRepositoryProvider.overrideWithValue(fakeRepo),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(mediaProvider.notifier);
      notifier.addToWatchedList(
        const MediaItem(
          id: '1',
          title: 'Failing Part',
          type: MediaType.movie,
          rating: 7,
          overview: '',
          genres: [],
          belongsToCollection:
              MediaCollection(id: 10, name: 'Failing Collection'),
        ),
      );
      notifier.addToWatchedList(
        const MediaItem(
          id: '3',
          title: 'Part 3',
          type: MediaType.movie,
          rating: 7,
          overview: '',
          genres: [],
          belongsToCollection: MediaCollection(id: 20, name: 'Good Collection'),
        ),
      );

      // generate() must not throw/error out just because one collection
      // fetch failed.
      await container.read(analyticsProvider.notifier).generate();

      final state = container.read(analyticsProvider);
      expect(state.error, isNull);
      expect(state.collectionCompletions, hasLength(1));
      expect(
          state.collectionCompletions.single.collectionName, 'Good Collection');
    });
  });
}
