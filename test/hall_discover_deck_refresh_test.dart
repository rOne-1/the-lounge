import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:the_lounge/models/discover_filter_params.dart';
import 'package:the_lounge/models/media_item.dart';
import 'package:the_lounge/providers/ambiance_provider.dart';
import 'package:the_lounge/providers/hall_provider.dart';
import 'package:the_lounge/providers/media_provider.dart';
import 'package:the_lounge/repositories/mock_movie_repository.dart';

MediaItem _movie(String id) => MediaItem(
      id: id,
      title: 'Movie $id',
      type: MediaType.movie,
      rating: 8.0,
      overview: '',
      genres: const [],
      voteCount: 5000,
    );

/// Counts discoverMedia calls (Discover's real fetch path) so tests can
/// prove a fresh loadPool() actually fired, rather than just checking the
/// pool's contents happen to differ.
class _CountingRepository extends MockMovieRepository {
  int discoverMediaCallCount = 0;

  @override
  Future<List<MediaItem>> discoverMedia({
    required bool isMovies,
    required DiscoverFilterParams params,
    int page = 1,
  }) async {
    discoverMediaCallCount++;
    return List.generate(10, (i) => _movie('m${discoverMediaCallCount}_$i'));
  }

  @override
  Future<List<MediaItem>> getPopularMovies({int page = 1, String? originalLanguage}) async => [];
  @override
  Future<List<MediaItem>> getTopRatedTvShows({int page = 1, String? originalLanguage}) async => [];
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SharedPreferences prefs;
  late _CountingRepository repo;

  setUp(() async {
    GoogleFonts.config.allowRuntimeFetching = false;
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    repo = _CountingRepository();
  });

  group('Discover deck refresh on hall switch', () {
    testWidgets('switching halls invalidates and reloads the Discover deck instead of leaving it stale',
        (tester) async {
      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          movieRepositoryProvider.overrideWithValue(repo),
        ],
      );
      addTearDown(container.dispose);

      // A plain container.read() doesn't keep a listener subscription alive,
      // so ref.invalidate() would just mark it dirty without eagerly
      // rebuilding until something reads it again -- container.listen()
      // mirrors what DiscoverScreen's ref.watch(...) does in the real app
      // (an active subscription for as long as the screen is mounted),
      // which is what makes invalidate() trigger an immediate rebuild.
      container.listen(discoverMoviesDeckProvider, (_, __) {});
      // testWidgets runs in a fake-async clock -- tester.pump() (bounded, one
      // tick at a time) is the safe way to let pending Futures/microtasks
      // resolve here, unlike pumpEventQueue()/real delays, which can hang
      // forever if anything in the tree (theme build, animations) schedules
      // a periodic timer.
      await tester.pump(Duration.zero);
      await tester.pump(Duration.zero);
      expect(repo.discoverMediaCallCount, greaterThan(0),
          reason: 'initial build() must fetch a pool before we can prove a switch refetches it');
      final callsBeforeSwitch = repo.discoverMediaCallCount;

      await container.read(hallProvider.notifier).switchHall('custom_1');
      await tester.pump(Duration.zero);
      await tester.pump(Duration.zero);

      expect(repo.discoverMediaCallCount, greaterThan(callsBeforeSwitch),
          reason: 'switching halls must trigger a fresh Discover fetch, not silently keep '
              'showing the previous hall\'s pool');
    });

    test('editing the active hall\'s language lock in place also refreshes the deck', () async {
      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          movieRepositoryProvider.overrideWithValue(repo),
        ],
      );
      addTearDown(container.dispose);

      container.listen(discoverMoviesDeckProvider, (_, __) {});
      await pumpEventQueue();
      final callsBefore = repo.discoverMediaCallCount;

      // 'common' is the default active hall.
      await container.read(hallProvider.notifier).updateHallLanguage('common', 'ja', 'Japanese');
      await pumpEventQueue();

      expect(repo.discoverMediaCallCount, greaterThan(callsBefore));
    });

    test('editing a non-active hall\'s language lock does NOT refresh the deck you are looking at', () async {
      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          movieRepositoryProvider.overrideWithValue(repo),
        ],
      );
      addTearDown(container.dispose);

      container.listen(discoverMoviesDeckProvider, (_, __) {});
      await pumpEventQueue();
      final callsBefore = repo.discoverMediaCallCount;

      // Active hall is 'common'; editing 'custom_1' (not active) shouldn't
      // touch the deck currently being shown.
      await container.read(hallProvider.notifier).updateHallLanguage('custom_1', 'hi', 'Hindi');
      await pumpEventQueue();

      expect(repo.discoverMediaCallCount, callsBefore);
    });
  });
}
