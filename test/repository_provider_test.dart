import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:the_lounge/providers/repository_provider.dart';
import 'package:the_lounge/repositories/mock_movie_repository.dart';
import 'package:the_lounge/repositories/tmdb_movie_repository.dart';
import 'package:the_lounge/services/tmdb_api_service.dart';

void main() {
  group('B6: movieRepositoryProvider build-mode gating', () {
    test('debug build + no token falls back to MockMovieRepository', () {
      final container = ProviderContainer(overrides: [
        tmdbApiServiceProvider.overrideWithValue(TmdbApiService(token: null)),
        isReleaseBuildProvider.overrideWithValue(false),
      ]);
      addTearDown(container.dispose);

      final repo = container.read(movieRepositoryProvider);

      expect(repo, isA<MockMovieRepository>());
      expect(container.read(isUsingMockRepositoryProvider), isTrue);
      expect(container.read(shouldShowConfigurationErrorProvider), isFalse);
    });

    test(
        'release build + no token stays on an unconfigured TmdbMovieRepository, '
        'never silently falls back to MockMovieRepository', () {
      final container = ProviderContainer(overrides: [
        tmdbApiServiceProvider.overrideWithValue(TmdbApiService(token: null)),
        isReleaseBuildProvider.overrideWithValue(true),
      ]);
      addTearDown(container.dispose);

      final repo = container.read(movieRepositoryProvider);

      expect(repo, isA<TmdbMovieRepository>());
      expect(repo, isNot(isA<MockMovieRepository>()));
      expect((repo as TmdbMovieRepository).isConfigured, isFalse);
      expect(container.read(isUsingMockRepositoryProvider), isTrue);
      expect(container.read(shouldShowConfigurationErrorProvider), isTrue);
    });

    test('release build + placeholder token also triggers the configuration-error state', () {
      final container = ProviderContainer(overrides: [
        tmdbApiServiceProvider.overrideWithValue(
          TmdbApiService(token: 'your_tmdb_read_access_token_here'),
        ),
        isReleaseBuildProvider.overrideWithValue(true),
      ]);
      addTearDown(container.dispose);

      expect(container.read(shouldShowConfigurationErrorProvider), isTrue);
    });

    test('release build + valid token uses a configured TmdbMovieRepository, no configuration error', () {
      final container = ProviderContainer(overrides: [
        tmdbApiServiceProvider.overrideWithValue(
          TmdbApiService(token: 'eyJvalidtoken'),
        ),
        isReleaseBuildProvider.overrideWithValue(true),
      ]);
      addTearDown(container.dispose);

      final repo = container.read(movieRepositoryProvider);

      expect(repo, isA<TmdbMovieRepository>());
      expect((repo as TmdbMovieRepository).isConfigured, isTrue);
      expect(container.read(isUsingMockRepositoryProvider), isFalse);
      expect(container.read(shouldShowConfigurationErrorProvider), isFalse);
    });

    test('debug build + valid token uses a configured TmdbMovieRepository', () {
      final container = ProviderContainer(overrides: [
        tmdbApiServiceProvider.overrideWithValue(
          TmdbApiService(token: 'eyJvalidtoken'),
        ),
        isReleaseBuildProvider.overrideWithValue(false),
      ]);
      addTearDown(container.dispose);

      final repo = container.read(movieRepositoryProvider);

      expect(repo, isA<TmdbMovieRepository>());
      expect((repo as TmdbMovieRepository).isConfigured, isTrue);
      expect(container.read(shouldShowConfigurationErrorProvider), isFalse);
    });
  });
}
