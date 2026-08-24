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
      expect(result.movieCount, 1);
      expect(result.tvCount, 0);
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
      expect(result.tvCount, 1);
      expect(result.movieCount, 0);
    });

    test(
        'items with no runtime contribute no minutes, but EXP-CLARITY-2: '
        'still count toward movieCount/tvCount -- the headline numeral is a '
        'title count and must reflect every watched title, not just the '
        'ones TMDB happened to return a runtime for', () {
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
      expect(result.movieCount, 1);
    });

    test(
        'ANALYTICS-TV-1: a currently-Watching show with real watch progress '
        'counts toward tvMinutes/tvCount, not just fully-Watched shows', () {
      final input = AnalyticsInput(
        watchedList: const {},
        watchingList: const {'tv_1': show},
        watchHistory: const {},
        watchedEpisodes: {
          'tv_1': {'S1E1', 'S1E2'},
        },
        seasonStartDates: const {},
        seasonEndDates: const {},
      );

      final result = computeTimeInvestment(input);
      expect(result.tvMinutes, 45 * 2);
      expect(result.tvCount, 1);
    });

    test(
        'ANALYTICS-TV-1: a Watching show with zero watched episodes contributes nothing '
        '(merely being "in progress" with no real progress does not count)', () {
      final input = AnalyticsInput(
        watchedList: const {},
        watchingList: const {'tv_1': show},
        watchHistory: const {},
        watchedEpisodes: const {},
        seasonStartDates: const {},
        seasonEndDates: const {},
      );

      final result = computeTimeInvestment(input);
      expect(result.tvMinutes, 0);
      expect(result.tvCount, 0);
    });

    test(
        'ANALYTICS-TV-1: a movie sitting in watchingList is not counted -- '
        'only TV has a meaningful partial-watch state', () {
      const movieInProgress = MediaItem(
        id: 'movie_3',
        title: 'Mid-watch Movie',
        type: MediaType.movie,
        rating: 6.0,
        overview: '',
        genres: [],
        runtime: 100,
      );
      final input = AnalyticsInput(
        watchedList: const {},
        watchingList: const {'movie_3': movieInProgress},
        watchHistory: const {},
        watchedEpisodes: const {},
        seasonStartDates: const {},
        seasonEndDates: const {},
      );

      final result = computeTimeInvestment(input);
      expect(result.movieMinutes, 0);
      expect(result.movieCount, 0);
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

    test(
        'ANALYTICS-TV-1: a show still Watching (e.g. mid-air on its latest '
        'season) surfaces its own already-complete earlier seasons', () {
      final input = AnalyticsInput(
        watchedList: const {},
        watchingList: const {'tv_1': show},
        watchHistory: const {},
        watchedEpisodes: {
          'tv_1': {'S1E1'}, // some progress recorded -- genuinely in progress
        },
        seasonStartDates: {
          'tv_1': {1: DateTime(2026, 1, 1)},
        },
        seasonEndDates: {
          'tv_1': {1: DateTime(2026, 1, 4)}, // season 1 finished
          // season 2 (currently airing) has no end date yet
        },
      );

      final velocity = computeBingeVelocity(input);
      expect(velocity.perSeason, hasLength(1));
      expect(velocity.perSeason.single.seasonNumber, 1);
      expect(velocity.perSeason.single.days, 3.0);
    });

    test(
        'ANALYTICS-TV-1: a Watching show with no recorded watch progress at all is excluded',
        () {
      final input = AnalyticsInput(
        watchedList: const {},
        watchingList: const {'tv_1': show},
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
      expect(velocity.perSeason, isEmpty);
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
    test('maps the 4-tier PersonalRating onto weightedRating\'s 0-10 scale',
        () {
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
      expect(points.single.delta,
          points.single.personalPoint - points.single.weightedRatingValue);
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

  group('computeDecadeDistribution', () {
    test('buckets by decade, excludes titles with no release date', () {
      const item90s = MediaItem(
        id: 'movie_1',
        title: '90s Movie',
        type: MediaType.movie,
        rating: 7.0,
        overview: '',
        genres: [],
        releaseOrAirDate: null,
      );
      final items = {
        'movie_1': MediaItem(
          id: 'movie_1',
          title: '90s Movie',
          type: MediaType.movie,
          rating: 7.0,
          overview: '',
          genres: const [],
          releaseOrAirDate: DateTime(1995, 1, 1),
        ),
        'movie_2': MediaItem(
          id: 'movie_2',
          title: 'Another 90s Movie',
          type: MediaType.movie,
          rating: 7.0,
          overview: '',
          genres: const [],
          releaseOrAirDate: DateTime(1999, 1, 1),
        ),
        'movie_3': MediaItem(
          id: 'movie_3',
          title: 'Old Movie',
          type: MediaType.movie,
          rating: 7.0,
          overview: '',
          genres: const [],
          releaseOrAirDate: DateTime(1965, 1, 1),
        ),
        'movie_4': item90s.copyWith(id: 'movie_4', title: 'No Date Movie'),
      };

      final input = AnalyticsInput(
        watchedList: items,
        watchHistory: const {},
        watchedEpisodes: const {},
        seasonStartDates: const {},
        seasonEndDates: const {},
      );

      final result = computeDecadeDistribution(input);
      expect(result.counts['1990s'], 2);
      expect(result.counts['Pre-1970s'], 1);
      expect(result.counts.values.reduce((a, b) => a + b), 3);
    });
  });

  group('computeTemporalDistanceIndex', () {
    test('averages days between release and first watch', () {
      final items = {
        'movie_1': MediaItem(
          id: 'movie_1',
          title: 'Movie 1',
          type: MediaType.movie,
          rating: 7.0,
          overview: '',
          genres: const [],
          releaseOrAirDate: DateTime(2020, 1, 1),
        ),
        'movie_2': MediaItem(
          id: 'movie_2',
          title: 'Movie 2',
          type: MediaType.movie,
          rating: 7.0,
          overview: '',
          genres: const [],
          releaseOrAirDate: DateTime(2020, 1, 1),
        ),
      };
      final input = AnalyticsInput(
        watchedList: items,
        watchHistory: {
          // 10 days after release.
          'movie_1': [
            WatchRecord(date: DateTime(2020, 1, 11), isFirstWatch: true),
          ],
          // 30 days after release.
          'movie_2': [
            WatchRecord(date: DateTime(2020, 1, 31), isFirstWatch: true),
          ],
        },
        watchedEpisodes: const {},
        seasonStartDates: const {},
        seasonEndDates: const {},
      );

      final result = computeTemporalDistanceIndex(input);
      expect(result.averageDays, 20.0);
    });

    test('is null when no title has both a release date and a first watch', () {
      const input = AnalyticsInput(
        watchedList: {},
        watchHistory: {},
        watchedEpisodes: {},
        seasonStartDates: {},
        seasonEndDates: {},
      );
      expect(computeTemporalDistanceIndex(input).averageDays, isNull);
    });
  });

  group('computeLanguageDistribution', () {
    test('tallies by originalLanguage, excludes titles with none recorded', () {
      final items = {
        'movie_1': MediaItem(
          id: 'movie_1',
          title: 'Movie 1',
          type: MediaType.movie,
          rating: 7.0,
          overview: '',
          genres: const [],
          originalLanguage: 'en',
        ),
        'movie_2': MediaItem(
          id: 'movie_2',
          title: 'Movie 2',
          type: MediaType.movie,
          rating: 7.0,
          overview: '',
          genres: const [],
          originalLanguage: 'ko',
        ),
        'movie_3': MediaItem(
          id: 'movie_3',
          title: 'Movie 3',
          type: MediaType.movie,
          rating: 7.0,
          overview: '',
          genres: const [],
        ),
      };
      final input = AnalyticsInput(
        watchedList: items,
        watchHistory: const {},
        watchedEpisodes: const {},
        seasonStartDates: const {},
        seasonEndDates: const {},
      );

      final result = computeLanguageDistribution(input);
      expect(result.counts['en'], 1);
      expect(result.counts['ko'], 1);
      expect(result.counts.values.reduce((a, b) => a + b), 2);
    });
  });

  group('computeDayOfWeekDistribution', () {
    test('tallies watch records by weekday, movies and TV kept separate', () {
      final items = {
        'movie_1': const MediaItem(
          id: 'movie_1',
          title: 'Movie 1',
          type: MediaType.movie,
          rating: 7.0,
          overview: '',
          genres: [],
        ),
        'tv_1': const MediaItem(
          id: 'tv_1',
          title: 'TV 1',
          type: MediaType.tv,
          rating: 7.0,
          overview: '',
          genres: [],
        ),
      };
      final input = AnalyticsInput(
        watchedList: items,
        watchHistory: {
          // Monday.
          'movie_1': [
            WatchRecord(date: DateTime(2026, 3, 2), isFirstWatch: true)
          ],
          // Also Monday.
          'tv_1': [WatchRecord(date: DateTime(2026, 3, 2), isFirstWatch: true)],
        },
        watchedEpisodes: const {},
        seasonStartDates: const {},
        seasonEndDates: const {},
      );

      final result = computeDayOfWeekDistribution(input);
      expect(result.movieCounts[DateTime.monday], 1);
      expect(result.tvCounts[DateTime.monday], 1);
      expect(result.movieCounts[DateTime.tuesday], isNull);
    });
  });

  group('computeRuntimePreferences', () {
    test('buckets movie runtimes into short/standard/epic and averages', () {
      final items = {
        'movie_1': const MediaItem(
          id: 'movie_1',
          title: 'Short',
          type: MediaType.movie,
          rating: 7.0,
          overview: '',
          genres: [],
          runtime: 80,
        ),
        'movie_2': const MediaItem(
          id: 'movie_2',
          title: 'Standard',
          type: MediaType.movie,
          rating: 7.0,
          overview: '',
          genres: [],
          runtime: 120,
        ),
        'movie_3': const MediaItem(
          id: 'movie_3',
          title: 'Epic',
          type: MediaType.movie,
          rating: 7.0,
          overview: '',
          genres: [],
          runtime: 180,
        ),
        // TV item with a runtime -- must be excluded (this metric is
        // movies-only per its own name).
        'tv_1': const MediaItem(
          id: 'tv_1',
          title: 'A Show',
          type: MediaType.tv,
          rating: 7.0,
          overview: '',
          genres: [],
          runtime: 45,
        ),
      };
      final input = AnalyticsInput(
        watchedList: items,
        watchHistory: const {},
        watchedEpisodes: const {},
        seasonStartDates: const {},
        seasonEndDates: const {},
      );

      final result = computeRuntimePreferences(input);
      expect(result.shortCount, 1);
      expect(result.standardCount, 1);
      expect(result.epicCount, 1);
      expect(result.averageMinutes, (80 + 120 + 180) / 3);
    });
  });

  group('computeWatchlistFunnel', () {
    test(
        'converted: watched titles with both addedDate and startDate; '
        'backlog days averaged', () {
      final items = {
        'movie_1': MediaItem(
          id: 'movie_1',
          title: 'Movie 1',
          type: MediaType.movie,
          rating: 7.0,
          overview: '',
          genres: const [],
          addedDate: DateTime(2026, 1, 1),
        ),
        'movie_2': MediaItem(
          id: 'movie_2',
          title: 'Movie 2',
          type: MediaType.movie,
          rating: 7.0,
          overview: '',
          genres: const [],
          addedDate: DateTime(2026, 1, 1),
        ),
        // No addedDate -- added before EXP-DATA-1 shipped, must be
        // excluded entirely, not counted as instant conversion.
        'movie_3': const MediaItem(
          id: 'movie_3',
          title: 'Movie 3',
          type: MediaType.movie,
          rating: 7.0,
          overview: '',
          genres: [],
        ),
      };
      final input = AnalyticsInput(
        watchedList: items,
        watchHistory: const {},
        watchedEpisodes: const {},
        seasonStartDates: const {},
        seasonEndDates: const {},
        startDates: {
          'movie_1': DateTime(2026, 1, 11), // 10 days later
          'movie_2': DateTime(2026, 1, 31), // 30 days later
          'movie_3': DateTime(2026, 1, 5),
        },
      );

      final result = computeWatchlistFunnel(input);
      expect(result.convertedCount, 2);
      expect(result.averageBacklogDays, 20.0);
    });

    test('pending: current watchlist/maybe items with addedDate set', () {
      final input = AnalyticsInput(
        watchedList: const {},
        watchHistory: const {},
        watchedEpisodes: const {},
        seasonStartDates: const {},
        seasonEndDates: const {},
        watchlist: {
          'movie_1': MediaItem(
            id: 'movie_1',
            title: 'Movie 1',
            type: MediaType.movie,
            rating: 7.0,
            overview: '',
            genres: const [],
            addedDate: DateTime(2026, 1, 1),
          ),
          // No addedDate -- excluded from the pending count.
          'movie_2': const MediaItem(
            id: 'movie_2',
            title: 'Movie 2',
            type: MediaType.movie,
            rating: 7.0,
            overview: '',
            genres: [],
          ),
        },
        maybeList: {
          'movie_3': MediaItem(
            id: 'movie_3',
            title: 'Movie 3',
            type: MediaType.movie,
            rating: 7.0,
            overview: '',
            genres: const [],
            addedDate: DateTime(2026, 1, 1),
          ),
        },
      );

      final result = computeWatchlistFunnel(input);
      expect(result.pendingCount, 2);
    });
  });

  group('computeAbandonedShows', () {
    MediaItem tvShow(String id, {int? episodesCount}) => MediaItem(
          id: id,
          title: id,
          type: MediaType.tv,
          rating: 7.0,
          overview: '',
          genres: const [],
          episodesCount: episodesCount,
        );

    test('flags a show under the completion threshold, idle past the window',
        () {
      final input = AnalyticsInput(
        watchedList: const {},
        watchHistory: {
          'tv_1': [
            WatchRecord(
              date: DateTime(2026, 1, 1),
              isFirstWatch: true,
              recordedAt: DateTime(2026, 1, 1),
            ),
          ],
        },
        watchedEpisodes: {
          'tv_1': {'S1E1', 'S1E2'},
        },
        seasonStartDates: const {},
        seasonEndDates: const {},
        watchingList: {'tv_1': tvShow('tv_1', episodesCount: 20)},
      );

      final result = computeAbandonedShows(input, now: DateTime(2026, 6, 1));
      expect(result, hasLength(1));
      expect(result.single.showId, 'tv_1');
      expect(result.single.watchedEpisodeCount, 2);
      expect(result.single.totalEpisodes, 20);
    });

    test('does not flag a show still within the idle window', () {
      final input = AnalyticsInput(
        watchedList: const {},
        watchHistory: {
          'tv_1': [
            WatchRecord(
              date: DateTime(2026, 5, 20),
              isFirstWatch: true,
              recordedAt: DateTime(2026, 5, 20),
            ),
          ],
        },
        watchedEpisodes: {
          'tv_1': {'S1E1', 'S1E2'},
        },
        seasonStartDates: const {},
        seasonEndDates: const {},
        watchingList: {'tv_1': tvShow('tv_1', episodesCount: 20)},
      );

      final result = computeAbandonedShows(input, now: DateTime(2026, 6, 1));
      expect(result, isEmpty);
    });

    test('does not flag a show near completion', () {
      final input = AnalyticsInput(
        watchedList: const {},
        watchHistory: {
          'tv_1': [
            WatchRecord(
              date: DateTime(2026, 1, 1),
              isFirstWatch: true,
              recordedAt: DateTime(2026, 1, 1),
            ),
          ],
        },
        watchedEpisodes: {
          'tv_1': {for (var i = 1; i <= 19; i++) 'S1E$i'},
        },
        seasonStartDates: const {},
        seasonEndDates: const {},
        watchingList: {'tv_1': tvShow('tv_1', episodesCount: 20)},
      );

      final result = computeAbandonedShows(input, now: DateTime(2026, 6, 1));
      expect(result, isEmpty);
    });

    test('excludes shows with no episodesCount known (never backfilled)', () {
      final input = AnalyticsInput(
        watchedList: const {},
        watchHistory: {
          'tv_1': [
            WatchRecord(
              date: DateTime(2026, 1, 1),
              isFirstWatch: true,
              recordedAt: DateTime(2026, 1, 1),
            ),
          ],
        },
        watchedEpisodes: {
          'tv_1': {'S1E1'},
        },
        seasonStartDates: const {},
        seasonEndDates: const {},
        watchingList: {'tv_1': tvShow('tv_1')},
      );

      final result = computeAbandonedShows(input, now: DateTime(2026, 6, 1));
      expect(result, isEmpty);
    });
  });

  group('computeStudioAffinity', () {
    test('tallies productionCompanyNames across watched titles, sorted desc',
        () {
      final items = {
        'movie_1': const MediaItem(
          id: 'movie_1',
          title: 'One',
          type: MediaType.movie,
          rating: 7.0,
          overview: '',
          genres: [],
          productionCompanyNames: ['A24', 'Plan B'],
        ),
        'movie_2': const MediaItem(
          id: 'movie_2',
          title: 'Two',
          type: MediaType.movie,
          rating: 7.0,
          overview: '',
          genres: [],
          productionCompanyNames: ['A24'],
        ),
      };
      final input = AnalyticsInput(
        watchedList: items,
        watchHistory: const {},
        watchedEpisodes: const {},
        seasonStartDates: const {},
        seasonEndDates: const {},
      );

      final result = computeStudioAffinity(input);
      expect(result.studios.first.name, 'A24');
      expect(result.studios.first.count, 2);
    });
  });

  group('computeDiscoverSwipeRatio', () {
    test('reflects the skip count and watchlist/maybe sizes on AnalyticsInput',
        () {
      MediaItem stub(String id) => MediaItem(
            id: id,
            title: id,
            type: MediaType.movie,
            rating: 7.0,
            overview: '',
            genres: const [],
          );

      final input = AnalyticsInput(
        watchedList: const {},
        watchHistory: const {},
        watchedEpisodes: const {},
        seasonStartDates: const {},
        seasonEndDates: const {},
        skippedCount: 12,
        watchlist: {for (var i = 0; i < 5; i++) 'w_$i': stub('w_$i')},
        maybeList: {for (var i = 0; i < 3; i++) 'm_$i': stub('m_$i')},
      );

      final result = computeDiscoverSwipeRatio(input);
      expect(result.skippedCount, 12);
      expect(result.watchlistedCount, 5);
      expect(result.savedCount, 3);
      expect(result.totalInteractions, 20);
    });
  });
}
