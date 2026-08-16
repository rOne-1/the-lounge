// Regression coverage for E3/TF-7-a: strict anime exclusion, while
// preserving the explicit scope boundary from the triage report -- Western
// animation (Disney/Pixar/DreamWorks) must NOT be caught, only anime
// (Japanese-original-language animation) should be.
import 'package:flutter_test/flutter_test.dart';
import 'package:the_lounge/models/discover_filter_params.dart';
import 'package:the_lounge/models/media_item.dart';
import 'package:the_lounge/repositories/anime_filtered_movie_repository.dart';
import 'package:the_lounge/repositories/mock_movie_repository.dart';
import 'package:the_lounge/utils/anime_filter.dart';

const animeTitle = MediaItem(
  id: 'tv-anime',
  title: 'Attack on Titan',
  type: MediaType.tv,
  rating: 9.0,
  overview: '',
  genres: ['Animation', 'Action'],
  originalLanguage: 'ja',
);

const westernAnimationTitle = MediaItem(
  id: 'movie-pixar',
  title: 'Coco',
  type: MediaType.movie,
  rating: 8.5,
  overview: '',
  genres: ['Animation', 'Family'],
  originalLanguage: 'en',
);

const japaneseLiveActionTitle = MediaItem(
  id: 'movie-godzilla',
  title: 'Godzilla Minus One',
  type: MediaType.movie,
  rating: 8.0,
  overview: '',
  genres: ['Action', 'Sci-Fi'],
  originalLanguage: 'ja',
);

const regularWesternShow = MediaItem(
  id: 'tv-drama',
  title: 'Breaking Bad',
  type: MediaType.tv,
  rating: 9.5,
  overview: '',
  genres: ['Drama'],
  originalLanguage: 'en',
);

class _FakeInnerRepository extends MockMovieRepository {
  final List<MediaItem> items;

  _FakeInnerRepository(this.items);

  @override
  Future<List<MediaItem>> getTrendingMovies({int page = 1}) async => items;

  @override
  Future<List<MediaItem>> getTrendingTvShows({int page = 1}) async => items;

  @override
  Future<List<MediaItem>> searchMedia(String query) async => items;

  @override
  Future<List<MediaItem>> discoverMedia({
    required bool isMovies,
    required DiscoverFilterParams params,
    int page = 1,
  }) async =>
      items;

  @override
  Future<List<MediaItem>> getSimilarMedia(String mediaId) async => items;

  @override
  Future<List<MediaItem>> getRecommendations(String mediaId) async => items;

  @override
  Future<MediaItem?> getMediaDetails(String id) async =>
      items.where((i) => i.id == id).firstOrNull;
}

void main() {
  group('isAnime heuristic', () {
    test('flags Japanese-original-language animation', () {
      expect(isAnime(animeTitle), isTrue);
    });

    test('does NOT flag Western animation (Disney/Pixar/DreamWorks)', () {
      expect(isAnime(westernAnimationTitle), isFalse);
    });

    test('does NOT flag Japanese live-action', () {
      expect(isAnime(japaneseLiveActionTitle), isFalse);
    });

    test('does NOT flag a regular non-animated Western show', () {
      expect(isAnime(regularWesternShow), isFalse);
    });
  });

  group('AnimeFilteredMovieRepository', () {
    final allTitles = [
      animeTitle,
      westernAnimationTitle,
      japaneseLiveActionTitle,
      regularWesternShow,
    ];

    late AnimeFilteredMovieRepository repo;

    setUp(() {
      repo = AnimeFilteredMovieRepository(_FakeInnerRepository(allTitles));
    });

    test('excludes anime from getTrendingMovies', () async {
      final result = await repo.getTrendingMovies();
      expect(result.map((i) => i.id), isNot(contains('tv-anime')));
      expect(result.length, allTitles.length - 1);
    });

    test('excludes anime from getTrendingTvShows', () async {
      final result = await repo.getTrendingTvShows();
      expect(result.map((i) => i.id), isNot(contains('tv-anime')));
    });

    test('excludes anime from searchMedia', () async {
      final result = await repo.searchMedia('anything');
      expect(result.map((i) => i.id), isNot(contains('tv-anime')));
    });

    test('excludes anime from discoverMedia', () async {
      final result = await repo.discoverMedia(
        isMovies: true,
        params: const DiscoverFilterParams(),
      );
      expect(result.map((i) => i.id), isNot(contains('tv-anime')));
    });

    test('excludes anime from getSimilarMedia and getRecommendations', () async {
      final similar = await repo.getSimilarMedia('anything');
      final recommendations = await repo.getRecommendations('anything');
      expect(similar.map((i) => i.id), isNot(contains('tv-anime')));
      expect(recommendations.map((i) => i.id), isNot(contains('tv-anime')));
    });

    test('preserves Western animation and Japanese live-action', () async {
      final result = await repo.getTrendingMovies();
      expect(result.map((i) => i.id), contains('movie-pixar'));
      expect(result.map((i) => i.id), contains('movie-godzilla'));
    });

    test(
        'does NOT filter getMediaDetails -- an already-saved anime title by '
        'ID must stay reachable, not become a broken reference', () async {
      final details = await repo.getMediaDetails('tv-anime');
      expect(details, isNotNull);
      expect(details!.id, 'tv-anime');
    });
  });
}
