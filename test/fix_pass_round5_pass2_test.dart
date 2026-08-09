import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:the_lounge/models/media_item.dart';
import 'package:the_lounge/models/discover_filter_params.dart';
import 'package:the_lounge/repositories/mock_movie_repository.dart';
import 'package:the_lounge/providers/repository_provider.dart';
import 'package:the_lounge/screens/detail_screen.dart';
import 'package:the_lounge/screens/discover_screen.dart';

class TestSyncMovieRepository extends MockMovieRepository {
  @override
  Future<TvSeason?> getTvSeasonDetails(String tvId, int seasonNumber) async => null;

  @override
  Future<List<MediaItem>> discoverMedia({
    required bool isMovies,
    required DiscoverFilterParams params,
    int page = 1,
  }) async => [];

  @override
  Future<List<MediaItem>> getPopularMovies({int page = 1}) async => [];

  @override
  Future<List<MediaItem>> getTopRatedTvShows({int page = 1}) async => [];
}

void main() {
  group('Fix Pass Round 5 - Pass 2 Unit & Widget Tests', () {
    test('Item 7: MediaItem directors field & TMDB repo parsing', () {
      const directorMember = MediaCastMember(
        id: '123',
        name: 'Christopher Nolan',
        role: 'Director',
      );

      const item = MediaItem(
        id: '1',
        title: 'Test Movie',
        type: MediaType.movie,
        rating: 8.5,
        overview: 'Overview',
        genres: ['Action'],
        directors: [directorMember],
      );

      expect(item.directors, isNotNull);
      expect(item.directors!.length, 1);
      expect(item.directors!.first.name, 'Christopher Nolan');
      expect(item.directors!.first.role, 'Director');

      final copied = item.copyWith(title: 'Updated Title');
      expect(copied.directors, isNotNull);
      expect(copied.directors!.first.name, 'Christopher Nolan');
    });

    test('Item 7: MockMovieRepository sample data contains directors', () async {
      final mockRepo = MockMovieRepository();
      final pool = await mockRepo.discoverMedia(isMovies: true, params: const DiscoverFilterParams());
      final inception = pool.firstWhere((e) => e.title == 'Inception');
      expect(inception.directors, isNotNull);
      expect(inception.directors!.any((d) => d.name == 'Christopher Nolan'), isTrue);
    });

    testWidgets('Item 7: DetailScreen renders individual tappable directors', (tester) async {
      const director1 = MediaCastMember(id: '100', name: 'Director One', role: 'Director');
      const director2 = MediaCastMember(id: '101', name: 'Director Two', role: 'Director');

      final item = MediaItem(
        id: '99',
        title: 'Multi Director Film',
        type: MediaType.movie,
        rating: 9.0,
        overview: 'Overview',
        genres: const ['Drama'],
        directors: const [director1, director2],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            movieRepositoryProvider.overrideWithValue(TestSyncMovieRepository()),
          ],
          child: MaterialApp(
            home: DetailScreen(id: item.prefixedId, initialItem: item),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Director One'), findsOneWidget);
      expect(find.text('Director Two'), findsOneWidget);
    });

    testWidgets('Item 5 & Item 6: DiscoverScreen builds action buttons & handles empty deck', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            movieRepositoryProvider.overrideWithValue(TestSyncMovieRepository()),
          ],
          child: const MaterialApp(
            home: Scaffold(body: DiscoverScreen()),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('↓ Watchlist'), findsOneWidget);
    });
  });
}
