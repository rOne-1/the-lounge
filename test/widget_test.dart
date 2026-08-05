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
}
