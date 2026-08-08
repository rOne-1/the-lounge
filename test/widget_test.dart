import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:the_lounge/main.dart';
import 'package:the_lounge/providers/ambiance_provider.dart';
import 'package:the_lounge/providers/repository_provider.dart';
import 'package:the_lounge/repositories/mock_movie_repository.dart';
import 'package:the_lounge/models/media_item.dart';
import 'package:the_lounge/models/discover_filter_params.dart';
import 'package:the_lounge/widgets/fallback_widgets.dart';
import 'package:the_lounge/widgets/trailer_player.dart';

class TestRepository extends MockMovieRepository {
  @override
  Future<List<MediaItem>> getTrendingMovies({int page = 1}) async => [];
  @override
  Future<List<MediaItem>> getPopularMovies({int page = 1}) async => [];
  @override
  Future<List<MediaItem>> getTrendingTvShows({int page = 1}) async => [];
  @override
  Future<List<MediaItem>> getTopRatedMovies({int page = 1}) async => [];
  @override
  Future<List<MediaItem>> getTopRatedTvShows({int page = 1}) async => [];
  @override
  Future<List<MediaItem>> getNowPlayingMovies({int page = 1, String? region}) async => [];
  @override
  Future<List<MediaItem>> getAiringTodayTvShows({int page = 1}) async => [];
  @override
  Future<List<MediaItem>> getUpcomingMovies({int page = 1}) async => [];
  @override
  Future<List<MediaItem>> getOnTheAirTvShows({int page = 1}) async => [];
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
    required DiscoverFilterParams params,
    int page = 1,
  }) async =>
      [];
  @override
  Future<List<Map<String, dynamic>>> searchPersons(String query) async => [];
  @override
  Future<List<MediaItem>> getRecommendations(String mediaId) async => [];
  @override
  Future<List<MediaItem>> getSimilarMedia(String mediaId) async => [];
}

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    GoogleFonts.config.allowRuntimeFetching = false;
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final mockRepo = TestRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          movieRepositoryProvider.overrideWithValue(mockRepo),
        ],
        child: const MyApp(enableAnimation: false),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Movies'), findsWidgets);
  });

  group('TrailerPlayer timeout fallback tests in widget_test', () {
    testWidgets(
        'PlaybackUnavailableWidget renders when player error or timeout duration triggers',
        (WidgetTester tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;

      const testMediaItem = MediaItem(
        id: 'timeout-item-1',
        title: 'Timeout Test Movie',
        type: MediaType.movie,
        rating: 8.0,
        overview: 'Overview for timeout test',
        genres: ['Drama'],
        hasTrailer: true,
        trailerVideoId: 'trailer_id_123',
      );

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: TrailerPlayer(item: testMediaItem),
          ),
        ),
      );

      // Advance clock past the 6-second timeout duration
      await tester.pump(const Duration(seconds: 6));

      expect(find.byType(PlaybackUnavailableWidget), findsOneWidget);
      expect(find.text('Playback unavailable in app'), findsOneWidget);
      expect(find.text('Watch on YouTube'), findsOneWidget);

      debugDefaultTargetPlatformOverride = null;
    });
  });
}
