import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:the_lounge/screens/calendar_screen.dart';
import 'package:the_lounge/providers/navigation_provider.dart';
import 'package:the_lounge/providers/repository_provider.dart';
import 'package:the_lounge/models/media_item.dart';
import 'package:the_lounge/repositories/movie_repository.dart';

class MockCalendarRepository implements MovieRepository {
  final List<MediaItem> movies;
  final List<MediaItem> tvShows;

  MockCalendarRepository({required this.movies, required this.tvShows});

  @override
  Future<List<MediaItem>> getTrendingMovies() async => movies;

  @override
  Future<List<MediaItem>> getPopularMovies() async => movies;

  @override
  Future<List<MediaItem>> getTrendingTvShows() async => tvShows;

  @override
  Future<List<MediaItem>> getTopRatedMovies() async => movies;

  @override
  Future<List<MediaItem>> getTopRatedTvShows() async => tvShows;

  @override
  Future<List<MediaItem>> getNowPlayingMovies() async => movies;

  @override
  Future<List<MediaItem>> getAiringTodayTvShows() async => tvShows;

  @override
  Future<List<MediaItem>> getUpcomingMovies() async => movies;

  @override
  Future<List<MediaItem>> getOnTheAirTvShows() async => tvShows;

  @override
  Future<MediaItem?> getMediaDetails(String id) async => null;

  @override
  Future<TvSeason?> getTvSeasonDetails(String tvId, int seasonNumber) async => null;

  @override
  Future<List<MediaItem>> searchMedia(String query) async => [];

  @override
  Future<List<Map<String, String>>> getWatchProviderRegions() async => [];

  @override
  Future<List<MediaItem>> discoverMedia({
    required bool isMovies,
    required dynamic params,
  }) async =>
      isMovies ? movies : tvShows;

  @override
  Future<List<Map<String, dynamic>>> searchPersons(String query) async => [];
}

void main() {
  setUp(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  final testMovie = MediaItem(
    id: 'm1',
    title: 'Inception Premiere',
    type: MediaType.movie,
    rating: 8.8,
    releaseOrAirDate: DateTime.now().add(const Duration(days: 1)),
    overview: 'Movie premiere',
    genres: const ['Action'],
  );

  final testTvShow = MediaItem(
    id: 'tv1',
    title: 'Stranger Things Episode',
    type: MediaType.tv,
    rating: 8.7,
    releaseOrAirDate: DateTime.now().add(const Duration(days: 2)),
    overview: 'TV episode air date',
    genres: const ['Sci-Fi'],
  );

  testWidgets('CalendarScreen filters agenda items based on active media type toggle',
      (WidgetTester tester) async {
    final mockRepo = MockCalendarRepository(
      movies: [testMovie],
      tvShows: [testTvShow],
    );

    final container = ProviderContainer(
      overrides: [
        movieRepositoryProvider.overrideWithValue(mockRepo),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: CalendarScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 1));

    // Default active type is Movies -> Should display movie premiere item and not TV show
    expect(find.text('Inception Premiere'), findsOneWidget);
    expect(find.text('Movie Premiere'), findsOneWidget);
    expect(find.text('Stranger Things Episode'), findsNothing);

    // Switch media type toggle to TV
    container.read(navigationProvider.notifier).setMediaType(MediaTypeToggle.tv);
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 1));

    // Active type is TV -> Should display TV episode item and not Movie premiere
    expect(find.text('Stranger Things Episode'), findsOneWidget);
    expect(find.text('New Episode'), findsOneWidget);
    expect(find.text('Inception Premiere'), findsNothing);
    await tester.pump(const Duration(seconds: 1));
  });
}
