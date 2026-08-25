// Widget/unit tests for PERS-DIFF-1: the Visual Seasonal Rating Bar,
// Forgotten Favorites, and On This Day memory-differentiation features.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:the_lounge/screens/detail_screen.dart';
import 'package:the_lounge/models/media_item.dart';
import 'package:the_lounge/providers/media_provider.dart';
import 'package:the_lounge/providers/ambiance_provider.dart';
import 'package:the_lounge/repositories/mock_movie_repository.dart';
import 'package:the_lounge/utils/memory_differentiation.dart';
import 'package:the_lounge/widgets/media_card.dart';
import 'package:the_lounge/widgets/memory_moments_section.dart';
import 'package:the_lounge/widgets/seasonal_rating_bar.dart';

class _SeededMediaNotifier extends MediaNotifier {
  final MediaState seed;
  _SeededMediaNotifier(this.seed);

  @override
  MediaState build() => seed;
}

class _TestRepository extends MockMovieRepository {
  final Map<String, MediaItem> items;
  _TestRepository(this.items);

  @override
  Future<MediaItem?> getMediaDetails(String id, {String? region}) async => items[id];

  @override
  Future<TvSeason?> getTvSeasonDetails(String tvId, int seasonNumber) async => null;
}

void main() {
  setUp(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  final now = DateTime(2026, 8, 17);

  final movie = MediaItem(
    id: 'movie-1',
    title: 'The Forgotten Reel',
    type: MediaType.movie,
    rating: 8.0,
    overview: 'A movie worth remembering.',
    genres: const ['Drama'],
  );

  final show = MediaItem(
    id: 'show-1',
    title: 'The Long Season',
    type: MediaType.tv,
    rating: 7.5,
    overview: 'A show with many seasons.',
    genres: const ['Drama'],
    seasonsCount: 3,
  );

  group('PERS-DIFF-1: computeForgottenFavorites', () {
    test('includes a title loved more than a year ago with no rewatch', () {
      final state = MediaState(watchHistory: {
        movie.id: [
          WatchRecord(
            date: now.subtract(const Duration(days: 400)),
            rating: PersonalRating.loved,
            isFirstWatch: true,
          ),
        ],
      });

      final result = computeForgottenFavorites(state, now: now);

      expect(result, hasLength(1));
      expect(result.first.mediaId, movie.id);
    });

    test('excludes a title loved less than a year ago', () {
      final state = MediaState(watchHistory: {
        movie.id: [
          WatchRecord(
            date: now.subtract(const Duration(days: 100)),
            rating: PersonalRating.loved,
            isFirstWatch: true,
          ),
        ],
      });

      expect(computeForgottenFavorites(state, now: now), isEmpty);
    });

    test('excludes a loved title that has since been rewatched', () {
      final state = MediaState(watchHistory: {
        movie.id: [
          WatchRecord(
            date: now.subtract(const Duration(days: 400)),
            rating: PersonalRating.loved,
            isFirstWatch: true,
          ),
          WatchRecord(
            date: now.subtract(const Duration(days: 10)),
            isFirstWatch: false,
          ),
        ],
      });

      expect(computeForgottenFavorites(state, now: now), isEmpty);
    });

    test('excludes a title rated something other than Loved', () {
      final state = MediaState(watchHistory: {
        movie.id: [
          WatchRecord(
            date: now.subtract(const Duration(days: 400)),
            rating: PersonalRating.liked,
            isFirstWatch: true,
          ),
        ],
      });

      expect(computeForgottenFavorites(state, now: now), isEmpty);
    });
  });

  group('PERS-DIFF-1: computeOnThisDay', () {
    test('includes a title completed exactly 1 year ago today', () {
      final state = MediaState(endDates: {
        movie.id: DateTime(now.year - 1, now.month, now.day),
      });

      final result = computeOnThisDay(state, now: now);

      expect(result, hasLength(1));
      expect(result.first.mediaId, movie.id);
      expect(result.first.yearsAgo, 1);
    });

    test('includes a title completed exactly 3 years ago today', () {
      final state = MediaState(endDates: {
        movie.id: DateTime(now.year - 3, now.month, now.day),
      });

      expect(computeOnThisDay(state, now: now).first.yearsAgo, 3);
    });

    test('excludes a title completed on a different day', () {
      final state = MediaState(endDates: {
        movie.id: DateTime(now.year - 1, now.month, now.day + 1),
      });

      expect(computeOnThisDay(state, now: now), isEmpty);
    });

    test('excludes a title completed less than a year ago', () {
      final state = MediaState(endDates: {
        movie.id: now.subtract(const Duration(days: 30)),
      });

      expect(computeOnThisDay(state, now: now), isEmpty);
    });
  });

  Future<ProviderContainer> pumpMemoryMoments(
    WidgetTester tester,
    MediaState seed,
    Map<String, MediaItem> knownItems,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        movieRepositoryProvider.overrideWithValue(_TestRepository(knownItems)),
        mediaProvider.overrideWith(() => _SeededMediaNotifier(seed)),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: Scaffold(body: MemoryMomentsSection())),
      ),
    );
    await tester.pumpAndSettle();
    return container;
  }

  group('PERS-DIFF-1: MemoryMomentsSection', () {
    testWidgets('renders nothing when there are no memories to surface', (tester) async {
      await pumpMemoryMoments(tester, const MediaState(), {});
      expect(find.byType(MemoryMomentsSection), findsOneWidget);
      expect(find.text('FORGOTTEN FAVORITES'), findsNothing);
      expect(find.textContaining('ago today, you completed'), findsNothing);
    });

    testWidgets('shows an On This Day card for a title completed a year ago today',
        (tester) async {
      final today = DateTime.now();
      final seed = MediaState(
        watchedList: {movie.id: movie},
        endDates: {movie.id: DateTime(today.year - 1, today.month, today.day)},
      );
      await pumpMemoryMoments(tester, seed, {});

      final richText = tester.widgetList<RichText>(find.byType(RichText)).firstWhere(
            (w) => w.text.toPlainText().contains('ago today, you completed'),
            orElse: () => throw StateError('On This Day RichText not found'),
          );
      expect(richText.text.toPlainText(), '1 year ago today, you completed ${movie.title}');
    });

    testWidgets('shows a Forgotten Favorites tile for an unrewatched loved title',
        (tester) async {
      final seed = MediaState(
        watchedList: {movie.id: movie},
        watchHistory: {
          movie.id: [
            WatchRecord(
              date: DateTime.now().subtract(const Duration(days: 400)),
              rating: PersonalRating.loved,
              isFirstWatch: true,
            ),
          ],
        },
      );
      await pumpMemoryMoments(tester, seed, {});

      expect(find.text('FORGOTTEN FAVORITES'), findsOneWidget);
      expect(find.text(movie.title), findsOneWidget);
    });

    testWidgets('tapping a Forgotten Favorites tile navigates to DetailScreen', (tester) async {
      final seed = MediaState(
        watchedList: {movie.id: movie},
        watchHistory: {
          movie.id: [
            WatchRecord(
              date: DateTime.now().subtract(const Duration(days: 400)),
              rating: PersonalRating.loved,
              isFirstWatch: true,
            ),
          ],
        },
      );
      await pumpMemoryMoments(tester, seed, {});

      // The caption text sits outside the tappable poster area of MediaCard
      // -- tap the card itself, which hits the poster (the tappable region).
      await tester.tap(find.byType(MediaCard));
      await tester.pumpAndSettle();

      expect(find.byType(DetailScreen), findsOneWidget);
    });
  });

  Future<ProviderContainer> pumpSeasonalBar(WidgetTester tester, MediaItem item) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        movieRepositoryProvider.overrideWithValue(_TestRepository({item.id: item})),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(home: Scaffold(body: SeasonalRatingBar(item: item))),
      ),
    );
    await tester.pumpAndSettle();
    return container;
  }

  group('PERS-DIFF-1: SeasonalRatingBar', () {
    testWidgets('renders nothing for a movie', (tester) async {
      await pumpSeasonalBar(tester, movie);
      expect(find.text('Your Season Ratings'), findsNothing);
    });

    testWidgets('renders nothing for a single-season show', (tester) async {
      final singleSeasonShow = MediaItem(
        id: 'show-single',
        title: 'One Season Wonder',
        type: MediaType.tv,
        rating: 6.0,
        overview: 'Just one season.',
        genres: const ['Comedy'],
        seasonsCount: 1,
      );
      await pumpSeasonalBar(tester, singleSeasonShow);
      expect(find.text('Your Season Ratings'), findsNothing);
    });

    testWidgets('renders a segment per season with tooltips reflecting each rating',
        (tester) async {
      final container = await pumpSeasonalBar(tester, show);
      container.read(mediaProvider.notifier).addWatchRecord(
            show.id,
            WatchRecord(seasonNumber: 1, rating: PersonalRating.loved, isFirstWatch: true),
          );
      container.read(mediaProvider.notifier).addWatchRecord(
            show.id,
            WatchRecord(seasonNumber: 2, rating: PersonalRating.liked, isFirstWatch: true),
          );
      await tester.pumpAndSettle();

      expect(find.text('Your Season Ratings'), findsOneWidget);
      expect(find.text('S1'), findsOneWidget);
      expect(find.text('S2'), findsOneWidget);
      expect(find.text('S3'), findsOneWidget);
      expect(find.byTooltip('Season 1: Loved it'), findsOneWidget);
      expect(find.byTooltip('Season 2: Liked it'), findsOneWidget);
      expect(find.byTooltip('Season 3: not rated'), findsOneWidget);
    });
  });
}
