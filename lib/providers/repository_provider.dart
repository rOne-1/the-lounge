import 'dart:developer' as developer;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/media_item.dart';
import '../repositories/mock_movie_repository.dart';
import '../repositories/movie_repository.dart';
import '../repositories/tmdb_movie_repository.dart';
import '../services/tmdb_api_service.dart';

/// Provider for [TmdbApiService] using environment token if available.
final tmdbApiServiceProvider = Provider<TmdbApiService>((ref) {
  String? token;
  try {
    if (dotenv.isInitialized) {
      token = dotenv.env['TMDB_READ_ACCESS_TOKEN'];
    }
  } catch (_) {}

  token ??= const String.fromEnvironment('TMDB_READ_ACCESS_TOKEN');

  return TmdbApiService(token: token);
});

/// Provider for [MovieRepository], automatically using [TmdbMovieRepository]
/// if TMDB token is valid, or falling back to [MockMovieRepository].
final movieRepositoryProvider = Provider<MovieRepository>((ref) {
  final apiService = ref.watch(tmdbApiServiceProvider);

  if (!apiService.hasToken) {
    developer.log(
      'TMDB_READ_ACCESS_TOKEN not found or default placeholder used. Falling back to MockMovieRepository.',
      name: 'RepositoryProvider',
    );
    return MockMovieRepository();
  }

  return TmdbMovieRepository(apiService: apiService);
});

/// Provider indicating whether the app is currently running in mock repository mode.
final isUsingMockRepositoryProvider = Provider<bool>((ref) {
  final repo = ref.watch(movieRepositoryProvider);
  if (repo is MockMovieRepository) return true;
  if (repo is TmdbMovieRepository) return !repo.isConfigured;
  return false;
});

final trendingMoviesProvider = FutureProvider<List<MediaItem>>((ref) async {
  final repo = ref.watch(movieRepositoryProvider);
  return repo.getTrendingMovies();
});

final trendingTvShowsProvider = FutureProvider<List<MediaItem>>((ref) async {
  final repo = ref.watch(movieRepositoryProvider);
  return repo.getTrendingTvShows();
});

final popularMoviesProvider = FutureProvider<List<MediaItem>>((ref) async {
  final repo = ref.watch(movieRepositoryProvider);
  return repo.getPopularMovies();
});

final mediaDetailsProvider =
    FutureProvider.family<MediaItem?, String>((ref, id) async {
  final repo = ref.watch(movieRepositoryProvider);
  return repo.getMediaDetails(id);
});

final watchProviderRegionsProvider =
    FutureProvider<List<Map<String, String>>>((ref) async {
  final repo = ref.watch(movieRepositoryProvider);
  return repo.getWatchProviderRegions();
});

