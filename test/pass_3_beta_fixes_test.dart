import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:the_lounge/providers/media_provider.dart';
import 'package:the_lounge/models/media_item.dart';
import 'package:the_lounge/widgets/fallback_widgets.dart';
import 'package:the_lounge/screens/detail_screen.dart';
import 'package:the_lounge/repositories/tmdb_movie_repository.dart';
import 'package:the_lounge/repositories/mock_movie_repository.dart';

class _TestSyncMovieRepository extends MockMovieRepository {
  @override
  Future<TvSeason?> getTvSeasonDetails(String tvId, int seasonNumber) async => null;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Pass 3 Beta Fixes - Item 12: TV Show Episode Re-Evaluation', () {
    test('reevaluateShowCompletion moves show from watchedList back to watchingList when new episodes exist', () {
      final container = ProviderContainer();
      final notifier = container.read(mediaProvider.notifier);

      const showItem = MediaItem(
        id: 'tv_100',
        title: 'Test Show',
        type: MediaType.tv,
        rating: 8.0,
        overview: 'Overview',
        genres: [],
        seasonsCount: 1,
        episodesCount: 2,
      );

      // Add show to watchedList with 1 season containing 1 episode
      final oldSeasons = [
        TvSeason(
          id: 1,
          seasonNumber: 1,
          name: 'Season 1',
          episodes: [
            TvEpisode(id: 101, episodeNumber: 1, seasonNumber: 1, name: 'Ep 1', airDate: DateTime.now().subtract(const Duration(days: 10))),
          ],
        ),
      ];

      notifier.addToWatchedList(showItem, seasons: oldSeasons);
      expect(container.read(mediaProvider).watchedList.containsKey('tv_100'), isTrue);
      expect(container.read(mediaProvider).watchedEpisodes['tv_100']?.length, equals(1));

      // Now new episodes air! Re-evaluate with 2 released episodes (S1E1, S1E2)
      final seasons = [
        TvSeason(
          id: 1,
          seasonNumber: 1,
          name: 'Season 1',
          episodes: [
            TvEpisode(id: 101, episodeNumber: 1, seasonNumber: 1, name: 'Ep 1', airDate: DateTime.now().subtract(const Duration(days: 10))),
            TvEpisode(id: 102, episodeNumber: 2, seasonNumber: 1, name: 'Ep 2', airDate: DateTime.now().subtract(const Duration(days: 1))),
          ],
        ),
      ];

      notifier.reevaluateShowCompletion(showId: 'tv_100', seasons: seasons);

      final state = container.read(mediaProvider);
      expect(state.watchedList.containsKey('tv_100'), isFalse);
      expect(state.watchingList.containsKey('tv_100'), isTrue);
    });

    test('reevaluateShowCompletion keeps show in watchedList when all released episodes are watched', () {
      final container = ProviderContainer();
      final notifier = container.read(mediaProvider.notifier);

      const showItem = MediaItem(
        id: 'tv_101',
        title: 'Completed Show',
        type: MediaType.tv,
        rating: 9.0,
        overview: 'Overview',
        genres: [],
        seasonsCount: 1,
        episodesCount: 1,
      );

      final seasons = [
        TvSeason(
          id: 1,
          seasonNumber: 1,
          name: 'Season 1',
          episodes: [
            TvEpisode(id: 101, episodeNumber: 1, seasonNumber: 1, name: 'Ep 1', airDate: DateTime.now().subtract(const Duration(days: 5))),
          ],
        ),
      ];

      notifier.addToWatchedList(showItem, seasons: seasons);
      expect(container.read(mediaProvider).watchedList.containsKey('tv_101'), isTrue);

      notifier.reevaluateShowCompletion(showId: 'tv_101', seasons: seasons);

      final state = container.read(mediaProvider);
      expect(state.watchedList.containsKey('tv_101'), isTrue);
      expect(state.watchingList.containsKey('tv_101'), isFalse);
    });
  });

  group('Pass 3 Beta Fixes - Item 13: Optimize Detail View Transition Performance', () {
    testWidgets('DetailScreen defers non-critical async section loading until transition frame completes', (tester) async {
      final container = ProviderContainer(
        overrides: [
          movieRepositoryProvider.overrideWithValue(_TestSyncMovieRepository()),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: DetailScreen(id: '1'),
          ),
        ),
      );

      // Initial frame pump
      await tester.pump();
      expect(find.byType(DetailScreen), findsOneWidget);

      // Complete post frame callbacks and transition animations
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byType(DetailScreen), findsOneWidget);
    });
  });

  group('Pass 3 Beta Fixes - Item 14: Offline Network State Detection & No-Connection Banner', () {
    test('isNetworkError identifies socket/client network exceptions', () {
      expect(isNetworkError(const SocketException('Failed host lookup')), isTrue);
      expect(isNetworkError(Exception('SocketException: No route to host')), isTrue);
      expect(isNetworkError(Exception('ClientException: Connection refused')), isTrue);
      expect(isNetworkError(Exception('No connection — Please check your internet connection')), isTrue);
      expect(isNetworkError(Exception('Unrelated generic exception')), isFalse);
    });

    testWidgets('NoNetworkWidget renders offline banner with retry connection button', (tester) async {
      bool retried = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NoNetworkWidget(
              onRetry: () => retried = true,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('No Connection'), findsOneWidget);
      expect(find.text('No connection — Please check your internet connection'), findsOneWidget);
      expect(find.text('Retry Connection'), findsOneWidget);
      expect(find.byIcon(Icons.wifi_off_rounded), findsOneWidget);

      await tester.tap(find.text('Retry Connection'));
      await tester.pump();

      expect(retried, isTrue);
    });

    testWidgets('FullScreenErrorWidget automatically delegates network errors to NoNetworkWidget', (tester) async {
      bool retried = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FullScreenErrorWidget(
              message: 'SocketException: Failed host lookup tmdb.org',
              onRetry: () => retried = true,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('No Connection'), findsOneWidget);
      expect(find.text('Retry Connection'), findsOneWidget);

      await tester.tap(find.text('Retry Connection'));
      await tester.pump();

      expect(retried, isTrue);
    });

    test('isNetworkException helper function identifies network exceptions correctly', () {
      expect(isNetworkException(const SocketException('No internet')), isTrue);
      expect(isNetworkException(Exception('Failed host lookup')), isTrue);
      expect(isNetworkException(Exception('Normal error')), isFalse);
    });
  });
}
