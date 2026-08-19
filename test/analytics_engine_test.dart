import 'package:flutter_test/flutter_test.dart';
import 'package:the_lounge/models/media_item.dart';
import 'package:the_lounge/models/personal_rating.dart';
import 'package:the_lounge/models/watch_record.dart';
import 'package:the_lounge/utils/analytics_engine.dart';

void main() {
  group('computeAnalytics -- empty input', () {
    test('returns zeroed/empty results for a user with no watch data', () {
      const input = AnalyticsInput(
        watchedList: {},
        watchHistory: {},
        watchedEpisodes: {},
        seasonStartDates: {},
        seasonEndDates: {},
      );

      final result = computeAnalytics(input);

      expect(result.heatmap.dailyCounts, isEmpty);
      expect(result.timeInvestment.movieMinutes, 0);
      expect(result.timeInvestment.tvMinutes, 0);
      expect(result.bingeVelocity.averageDays, isNull);
      expect(result.bingeVelocity.perSeason, isEmpty);
      expect(result.castRanking, isEmpty);
      expect(result.directorRanking, isEmpty);
      expect(result.ratingDivergence, isEmpty);
      expect(result.genreFrequency, isEmpty);
    });
  });

  group('computeHeatmap', () {
    test('tallies WatchRecord.date per calendar day, ignoring time of day', () {
      final input = AnalyticsInput(
        watchedList: const {},
        watchHistory: {
          'movie_1': [
            WatchRecord(
              date: DateTime(2026, 3, 1, 9),
              isFirstWatch: true,
              recordedAt: DateTime(2026, 3, 1, 9),
            ),
          ],
          'movie_2': [
            WatchRecord(
              date: DateTime(2026, 3, 1, 22),
              isFirstWatch: true,
              recordedAt: DateTime(2026, 3, 1, 22),
            ),
          ],
        },
        watchedEpisodes: const {},
        seasonStartDates: const {},
        seasonEndDates: const {},
      );

      final heatmap = computeHeatmap(input);
      expect(heatmap.dailyCounts[DateTime(2026, 3, 1)], 2);
    });

    test('falls back to recordedAt when date is null', () {
      final input = AnalyticsInput(
        watchedList: const {},
        watchHistory: {
          'movie_1': [
            WatchRecord(
              date: null,
              isFirstWatch: true,
              recordedAt: DateTime(2026, 5, 10, 14),
            ),
          ],
        },
        watchedEpisodes: const {},
        seasonStartDates: const {},
        seasonEndDates: const {},
      );

      final heatmap = computeHeatmap(input);
      expect(heatmap.dailyCounts[DateTime(2026, 5, 10)], 1);
    });
  });

  group('computeTimeInvestment', () {
    const movie = MediaItem(
      id: 'movie_1',
      title: 'A Movie',
      type: MediaType.movie,
      rating: 7.0,
      overview: '',
      genres: [],
      runtime: 120,
    );

    const show = MediaItem(
      id: 'tv_1',
      title: 'A Show',
      type: MediaType.tv,
      rating: 8.0,
      overview: '',
      genres: [],
      runtime: 45,
    );

    test('movies sum runtime directly', () {
      final input = AnalyticsInput(
        watchedList: const {'movie_1': movie},
        watchHistory: const {},
        watchedEpisodes: const {},
        seasonStartDates: const {},
        seasonEndDates: const {},
      );

      final result = computeTimeInvestment(input);
      expect(result.movieMinutes, 120);
      expect(result.tvMinutes, 0);
    });

    test('TV is watchedEpisodeCount * runtime (documented estimate)', () {
      final input = AnalyticsInput(
        watchedList: const {'tv_1': show},
        watchHistory: const {},
        watchedEpisodes: {
          'tv_1': {'S1E1', 'S1E2', 'S1E3'},
        },
        seasonStartDates: const {},
        seasonEndDates: const {},
      );

      final result = computeTimeInvestment(input);
      expect(result.tvMinutes, 45 * 3);
      expect(result.movieMinutes, 0);
      expect(result.totalMinutes, 135);
    });

    test('items with no runtime contribute nothing (not a crash)', () {
      const noRuntime = MediaItem(
        id: 'movie_2',
        title: 'No Runtime',
        type: MediaType.movie,
        rating: 5.0,
        overview: '',
        genres: [],
      );
      final input = AnalyticsInput(
        watchedList: const {'movie_2': noRuntime},
        watchHistory: const {},
        watchedEpisodes: const {},
        seasonStartDates: const {},
        seasonEndDates: const {},
      );

      final result = computeTimeInvestment(input);
      expect(result.totalMinutes, 0);
    });
  });

  group('computeBingeVelocity', () {
    const show = MediaItem(
      id: 'tv_1',
      title: 'Binge Show',
      type: MediaType.tv,
      rating: 8.0,
      overview: '',
      genres: [],
    );

    test('computes days between season start and end', () {
      final input = AnalyticsInput(
        watchedList: const {'tv_1': show},
        watchHistory: const {},
        watchedEpisodes: const {},
        seasonStartDates: {
          'tv_1': {1: DateTime(2026, 1, 1)},
        },
        seasonEndDates: {
          'tv_1': {1: DateTime(2026, 1, 4)},
        },
      );

      final velocity = computeBingeVelocity(input);
      expect(velocity.perSeason, hasLength(1));
      expect(velocity.perSeason.single.days, 3.0);
      expect(velocity.averageDays, 3.0);
    });

    test('seasons missing a start date are excluded, not counted as 0', () {
      final input = AnalyticsInput(
        watchedList: const {'tv_1': show},
        watchHistory: const {},
        watchedEpisodes: const {},
        seasonStartDates: {
          'tv_1': {1: DateTime(2026, 1, 1)},
          // season 2 has no start date on file
        },
        seasonEndDates: {
          'tv_1': {
            1: DateTime(2026, 1, 4),
            2: DateTime(2026, 2, 10),
          },
        },
      );

      final velocity = computeBingeVelocity(input);
      expect(velocity.perSeason, hasLength(1));
      expect(velocity.perSeason.single.seasonNumber, 1);
      expect(velocity.averageDays, 3.0);
    });

    test('movies are excluded entirely', () {
      const movie = MediaItem(
        id: 'movie_1',
        title: 'A Movie',
        type: MediaType.movie,
        rating: 7.0,
        overview: '',
        genres: [],
      );
      final input = AnalyticsInput(
        watchedList: const {'movie_1': movie},
        watchHistory: const {},
        watchedEpisodes: const {},
        seasonStartDates: {
          'movie_1': {1: DateTime(2026, 1, 1)},
        },
        seasonEndDates: {
          'movie_1': {1: DateTime(2026, 1, 4)},
        },
      );

      final velocity = computeBingeVelocity(input);
      expect(velocity.perSeason, isEmpty);
      expect(velocity.averageDays, isNull);
    });
  });

  group('computeCastAndDirectorRankings', () {
    test('tallies cast and director across watched titles, sorted desc', () {
      const item1 = MediaItem(
        id: 'movie_1',
        title: 'One',
        type: MediaType.movie,
        rating: 7.0,
        overview: '',
        genres: [],
        cast: ['Alice', 'Bob'],
        director: 'Nolan',
      );
      const item2 = MediaItem(
        id: 'movie_2',
        title: 'Two',
        type: MediaType.movie,
        rating: 7.0,
        overview: '',
        genres: [],
        cast: ['Alice'],
        director: 'Nolan',
      );

      final input = AnalyticsInput(
        watchedList: const {'movie_1': item1, 'movie_2': item2},
        watchHistory: const {},
        watchedEpisodes: const {},
        seasonStartDates: const {},
        seasonEndDates: const {},
      );

      final rankings = computeCastAndDirectorRankings(input);
      expect(rankings.cast.first.name, 'Alice');
      expect(rankings.cast.first.count, 2);
      expect(rankings.directors.single.name, 'Nolan');
      expect(rankings.directors.single.count, 2);
    });
  });

  group('computeRatingDivergence', () {
    test('maps the 4-tier PersonalRating onto weightedRating\'s 0-10 scale', () {
      const item = MediaItem(
        id: 'movie_1',
        title: 'Loved It',
        type: MediaType.movie,
        rating: 6.0,
        overview: '',
        genres: [],
        voteCount: 1000,
      );

      final input = AnalyticsInput(
        watchedList: const {'movie_1': item},
        watchHistory: {
          'movie_1': [
            WatchRecord(
              rating: PersonalRating.loved,
              isFirstWatch: true,
              seasonNumber: null,
            ),
          ],
        },
        watchedEpisodes: const {},
        seasonStartDates: const {},
        seasonEndDates: const {},
      );

      final points = computeRatingDivergence(input);
      expect(points, hasLength(1));
      expect(points.single.personalPoint, 9.0);
      expect(points.single.delta, points.single.personalPoint - points.single.weightedRatingValue);
    });

    test('titles with no vote count are excluded', () {
      const item = MediaItem(
        id: 'movie_1',
        title: 'Unvoted',
        type: MediaType.movie,
        rating: 6.0,
        overview: '',
        genres: [],
      );
      final input = AnalyticsInput(
        watchedList: const {'movie_1': item},
        watchHistory: {
          'movie_1': [
            WatchRecord(rating: PersonalRating.loved, isFirstWatch: true),
          ],
        },
        watchedEpisodes: const {},
        seasonStartDates: const {},
        seasonEndDates: const {},
      );

      expect(computeRatingDivergence(input), isEmpty);
    });

    test('unrated titles are excluded', () {
      const item = MediaItem(
        id: 'movie_1',
        title: 'Unrated',
        type: MediaType.movie,
        rating: 6.0,
        overview: '',
        genres: [],
        voteCount: 500,
      );
      final input = AnalyticsInput(
        watchedList: const {'movie_1': item},
        watchHistory: const {'movie_1': []},
        watchedEpisodes: const {},
        seasonStartDates: const {},
        seasonEndDates: const {},
      );

      expect(computeRatingDivergence(input), isEmpty);
    });

    test('a season-scoped rating does not count as the overall rating', () {
      const item = MediaItem(
        id: 'tv_1',
        title: 'Show',
        type: MediaType.tv,
        rating: 6.0,
        overview: '',
        genres: [],
        voteCount: 500,
      );
      final input = AnalyticsInput(
        watchedList: const {'tv_1': item},
        watchHistory: {
          'tv_1': [
            WatchRecord(
              rating: PersonalRating.loved,
              isFirstWatch: true,
              seasonNumber: 1,
            ),
          ],
        },
        watchedEpisodes: const {},
        seasonStartDates: const {},
        seasonEndDates: const {},
      );

      expect(computeRatingDivergence(input), isEmpty);
    });
  });

  group('computeGenreFrequency', () {
    test('multi-membership: a title with N genres counts toward all N', () {
      const item1 = MediaItem(
        id: 'movie_1',
        title: 'One',
        type: MediaType.movie,
        rating: 7.0,
        overview: '',
        genres: ['Action', 'Sci-Fi'],
      );
      const item2 = MediaItem(
        id: 'movie_2',
        title: 'Two',
        type: MediaType.movie,
        rating: 7.0,
        overview: '',
        genres: ['Action'],
      );

      final input = AnalyticsInput(
        watchedList: const {'movie_1': item1, 'movie_2': item2},
        watchHistory: const {},
        watchedEpisodes: const {},
        seasonStartDates: const {},
        seasonEndDates: const {},
      );

      final freq = computeGenreFrequency(input);
      expect(freq['Action'], 2);
      expect(freq['Sci-Fi'], 1);
    });
  });
}
