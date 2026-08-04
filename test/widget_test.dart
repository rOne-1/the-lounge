import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:the_lounge/main.dart';
import 'package:the_lounge/providers/ambiance_provider.dart';
import 'package:the_lounge/providers/repository_provider.dart';
import 'package:the_lounge/repositories/movie_repository.dart';
import 'package:the_lounge/models/media_item.dart';

class TestRepository implements MovieRepository {
  @override
  Future<List<MediaItem>> getTrendingMovies() async => [];
  @override
  Future<List<MediaItem>> getPopularMovies() async => [];
  @override
  Future<List<MediaItem>> getTrendingTvShows() async => [];
  @override
  Future<List<MediaItem>> getTopRatedMovies() async => [];
  @override
  Future<List<MediaItem>> getTopRatedTvShows() async => [];
  @override
  Future<List<MediaItem>> getNowPlayingMovies() async => [];
  @override
  Future<List<MediaItem>> getAiringTodayTvShows() async => [];
  @override
  Future<List<MediaItem>> getUpcomingMovies() async => [];
  @override
  Future<List<MediaItem>> getOnTheAirTvShows() async => [];
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
      [];
  @override
  Future<List<Map<String, dynamic>>> searchPersons(String query) async => [];
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
