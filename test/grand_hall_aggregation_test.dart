import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:the_lounge/models/hall_space.dart';
import 'package:the_lounge/models/media_item.dart';
import 'package:the_lounge/providers/ambiance_provider.dart';
import 'package:the_lounge/providers/hall_provider.dart';
import 'package:the_lounge/providers/media_provider.dart';
import 'package:the_lounge/services/hall_storage_service.dart';

/// ORG-AGG-1: the Grand Hall (id 'common') is an aggregate of the Mezzanine
/// and Private Screening Halls plus its own native saves. This covers the
/// aggregation itself (union across halls/domains, own-data-wins on
/// conflict, readOnlyMediaIds/readOnlySourceHallName bookkeeping) and the
/// anti-corruption guarantee that aggregated titles never get written into
/// the Grand Hall's own storage.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SharedPreferences prefs;

  // TH-58: ids are given already domain-prefixed (matching what every
  // real construction site produces now) so the fixtures exercise the
  // same shape production code actually sees.
  final movieNative = const MediaItem(
    id: 'movie_native',
    title: 'Native To Grand Hall',
    type: MediaType.movie,
    rating: 7.5,
    overview: '',
    genres: [],
  );

  final movieMezzanine = const MediaItem(
    id: 'movie_mezzanine',
    title: 'From The Mezzanine',
    type: MediaType.movie,
    rating: 8.1,
    overview: '',
    genres: [],
  );

  final showPrivate = const MediaItem(
    id: 'tv_private',
    title: 'From Private Screening',
    type: MediaType.tv,
    rating: 8.4,
    overview: '',
    genres: [],
  );

  final movieConflict = const MediaItem(
    id: 'movie_conflict',
    title: 'Own Version Wins',
    type: MediaType.movie,
    rating: 6.0,
    overview: '',
    genres: [],
  );

  final movieConflictMezzanineVersion = const MediaItem(
    id: 'movie_conflict',
    title: 'Mezzanine Version Should Be Shadowed',
    type: MediaType.movie,
    rating: 9.9,
    overview: '',
    genres: [],
  );

  Future<void> seedHall(
    String hallId, {
    Map<String, MediaItem> movieWatchlist = const {},
    Map<String, MediaItem> tvWatching = const {},
  }) async {
    final movieArchive = DomainArchive(watchlist: movieWatchlist);
    final tvArchive = DomainArchive(watching: tvWatching);
    await prefs.setString(
      HallStorageService.domainStorageKey(hallId, MediumDomain.movies),
      jsonEncode(movieArchive.toJson()),
    );
    await prefs.setString(
      HallStorageService.domainStorageKey(hallId, MediumDomain.tv),
      jsonEncode(tvArchive.toJson()),
    );
  }

  setUp(() async {
    GoogleFonts.config.allowRuntimeFetching = false;
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  test('Grand Hall aggregates Mezzanine + Private Screening, own data wins on conflict', () async {
    await seedHall('custom_1', movieWatchlist: {
      'movie_mezzanine': movieMezzanine,
      'movie_conflict': movieConflictMezzanineVersion,
    });
    await seedHall('custom_2', tvWatching: {'tv_private': showPrivate});
    await seedHall('common', movieWatchlist: {
      'movie_native': movieNative,
      'movie_conflict': movieConflict,
    });

    final container = ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    );
    addTearDown(container.dispose);

    // Force a fresh load from the seeded prefs (build() already ran once
    // against empty prefs before setUp's mock values existed for this
    // container instance -- loadFromPrefs() re-reads them).
    await container.read(mediaProvider.notifier).loadFromPrefs();
    final state = container.read(mediaProvider);

    // Union: native + both other halls' titles all visible.
    expect(state.watchlist.containsKey('movie_native'), isTrue);
    expect(state.watchlist.containsKey('movie_mezzanine'), isTrue);
    expect(state.watchingList.containsKey('tv_private'), isTrue);

    // Own data wins on id conflict.
    expect(state.watchlist['movie_conflict']?.title, 'Own Version Wins');

    // Read-only bookkeeping: only the genuinely-aggregated ids are marked.
    expect(state.readOnlyMediaIds.contains('movie_native'), isFalse);
    expect(state.readOnlyMediaIds.contains('movie_conflict'), isFalse);
    expect(state.readOnlyMediaIds.contains('movie_mezzanine'), isTrue);
    expect(state.readOnlyMediaIds.contains('tv_private'), isTrue);
    expect(state.readOnlySourceHallName['movie_mezzanine'], 'The Mezzanine Hall');
    expect(state.readOnlySourceHallName['tv_private'], 'The Private Screening Hall');
  });

  test('Aggregated titles never get persisted into the Grand Hall\'s own storage', () async {
    await seedHall('custom_1', movieWatchlist: {'movie_mezzanine': movieMezzanine});

    final container = ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    );
    addTearDown(container.dispose);

    final notifier = container.read(mediaProvider.notifier);
    await notifier.loadFromPrefs();
    expect(container.read(mediaProvider).watchlist.containsKey('movie_mezzanine'), isTrue);

    // A completely unrelated native save while the aggregated title is
    // sitting in the merged in-memory state.
    notifier.addToWatchlist(movieNative);

    final grandMovieRaw = prefs.getString(
      HallStorageService.domainStorageKey('common', MediumDomain.movies),
    );
    expect(grandMovieRaw, isNotNull);
    expect(grandMovieRaw!.contains('movie_mezzanine'), isFalse,
        reason: 'aggregated Mezzanine title must not leak into the Grand Hall\'s own archive');
    expect(grandMovieRaw.contains('movie_native'), isTrue);

    // And it's untouched in its real home.
    final mezzanineRaw = prefs.getString(
      HallStorageService.domainStorageKey('custom_1', MediumDomain.movies),
    );
    expect(mezzanineRaw!.contains('movie_mezzanine'), isTrue);
  });

  group('HALL-SAVE-1: saveToHallShelf', () {
    test('saves to a non-active Hall without disturbing an unrelated active Hall\'s own state', () async {
      // Active Hall is the Private Screening Hall (custom_2) -- unrelated
      // to both the Grand Hall (whose aggregation would otherwise pull the
      // write in) and the save target (Mezzanine/custom_1), so no
      // reactivity is expected here at all.
      await prefs.setString(HallStorageService.kLoungeActiveHallIdKey, 'custom_2');
      final container = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      );
      addTearDown(container.dispose);
      final notifier = container.read(mediaProvider.notifier);
      await notifier.loadFromPrefs();

      await notifier.saveToHallShelf(
        hallId: 'custom_1',
        item: movieMezzanine,
        shelf: ArchiveShelfKind.watchlist,
      );

      // The active (but unrelated) Hall's own in-memory state is untouched.
      expect(container.read(mediaProvider).watchlist.containsKey('movie_mezzanine'), isFalse);

      // But it genuinely landed in the Mezzanine Hall's own storage.
      final raw = prefs.getString(
        HallStorageService.domainStorageKey('custom_1', MediumDomain.movies),
      );
      expect(raw, isNotNull);
      expect(raw!.contains('movie_mezzanine'), isTrue);

      // Loading (not switching, to avoid pulling in the theme/ambiance
      // machinery this plain-`test()` file isn't set up for) the Mezzanine
      // Hall directly on mediaProvider confirms it's really there, on the
      // right shelf.
      await notifier.loadForHall('custom_1');
      expect(container.read(mediaProvider).watchlist.containsKey('movie_mezzanine'), isTrue);
    });

    test('HALL-SYNC-1: saving to another Hall while viewing the Grand Hall reflects immediately, no reload needed', () async {
      final container = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      );
      addTearDown(container.dispose);
      final notifier = container.read(mediaProvider.notifier);

      // Load fresh into the Grand Hall (the default active Hall).
      await notifier.loadFromPrefs();
      expect(container.read(mediaProvider).watchingList.containsKey('tv_private'), isFalse);

      // Save a TV show into the Private Screening Hall while still "in"
      // the Grand Hall -- this is exactly the cross-hall save + Grand Hall
      // sync combination items 2/3/15 describe.
      await notifier.saveToHallShelf(
        hallId: 'custom_2',
        item: showPrivate,
        shelf: ArchiveShelfKind.watching,
      );

      // No loadForHall/switchHall call in between -- state must already
      // reflect it.
      final state = container.read(mediaProvider);
      expect(state.watchingList.containsKey('tv_private'), isTrue);
      expect(state.readOnlyMediaIds.contains('tv_private'), isTrue);
      expect(state.readOnlySourceHallName['tv_private'], 'The Private Screening Hall');
    });

    test('a shelf change replaces any prior shelf placement for that title in the target Hall', () async {
      final container = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      );
      addTearDown(container.dispose);
      final notifier = container.read(mediaProvider.notifier);

      await notifier.saveToHallShelf(
        hallId: 'custom_1',
        item: movieMezzanine,
        shelf: ArchiveShelfKind.watchlist,
      );
      await notifier.saveToHallShelf(
        hallId: 'custom_1',
        item: movieMezzanine,
        shelf: ArchiveShelfKind.watched,
      );

      await notifier.loadForHall('custom_1');
      final state = container.read(mediaProvider);
      expect(state.watchedList.containsKey('movie_mezzanine'), isTrue);
      expect(state.watchlist.containsKey('movie_mezzanine'), isFalse);
    });

    test('saving to the currently-active Hall delegates to the normal full-featured mutation path', () async {
      final container = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      );
      addTearDown(container.dispose);
      final notifier = container.read(mediaProvider.notifier);

      // Active Hall defaults to 'common'.
      await notifier.saveToHallShelf(
        hallId: 'common',
        item: movieNative,
        shelf: ArchiveShelfKind.watchlist,
      );

      expect(container.read(mediaProvider).watchlist.containsKey('movie_native'), isTrue);
    });
  });

  test('Non-Grand halls are never aggregated', () async {
    await seedHall('custom_1', movieWatchlist: {'movie_mezzanine': movieMezzanine});
    await seedHall('custom_2', tvWatching: {'tv_private': showPrivate});

    final container = ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    );
    addTearDown(container.dispose);

    final hallNotifier = container.read(hallProvider.notifier);
    await hallNotifier.switchHall('custom_1');

    final state = container.read(mediaProvider);
    expect(state.watchlist.containsKey('movie_mezzanine'), isTrue);
    expect(state.watchingList.containsKey('tv_private'), isFalse);
    expect(state.readOnlyMediaIds.isEmpty, isTrue);
  });
}
