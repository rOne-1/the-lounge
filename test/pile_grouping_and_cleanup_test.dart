import 'package:flutter_test/flutter_test.dart';
import 'package:the_lounge/models/media_item.dart';
import 'package:the_lounge/models/personal_rating.dart';
import 'package:the_lounge/models/watch_record.dart';
import 'package:the_lounge/utils/pile_sort_group.dart';
import 'package:the_lounge/screens/cleanup_swipe_screen.dart' show kPileCleanupThreshold;

void main() {
  const action1 = MediaItem(
    id: 'm1',
    title: 'Action One',
    type: MediaType.movie,
    rating: 9.0,
    voteCount: 1000,
    genres: ['Action', 'Thriller'],
    overview: '',
  );
  const action2 = MediaItem(
    id: 'm2',
    title: 'Action Two',
    type: MediaType.movie,
    rating: 7.0,
    voteCount: 500,
    genres: ['Action'],
    overview: '',
  );
  const comedy1 = MediaItem(
    id: 'm3',
    title: 'Comedy One',
    type: MediaType.movie,
    rating: 5.0,
    voteCount: 200,
    genres: ['Comedy'],
    overview: '',
  );
  const unrated = MediaItem(
    id: 'm4',
    title: 'Unrated One',
    type: MediaType.movie,
    rating: 0.0,
    genres: [],
    overview: '',
  );

  group('PERS-SORT-1: sortPile', () {
    test('dateAdded reverses insertion order (most-recently-added first)', () {
      final items = [action1, action2, comedy1];
      expect(sortPile(items, PileSortOption.dateAdded), [comedy1, action2, action1]);
    });

    test('weightedRating sorts descending by weighted rating', () {
      final sorted = sortPile([comedy1, action1, action2], PileSortOption.weightedRating);
      // action1 has the highest raw rating and highest vote count, so it
      // should clearly lead regardless of the exact weighted formula output.
      expect(sorted.first, action1);
    });

    test('releaseDate sorts newest first, nulls last', () {
      final withDate1 = action1.copyWith(releaseOrAirDate: DateTime(2020, 1, 1));
      final withDate2 = action2.copyWith(releaseOrAirDate: DateTime(2022, 1, 1));
      final noDate = comedy1.copyWith();

      final sorted = sortPile([withDate1, noDate, withDate2], PileSortOption.releaseDate);

      expect(sorted, [withDate2, withDate1, noDate]);
    });
  });

  group('PERS-SORT-1: grouping', () {
    test('groupByGenre gives multi-membership for titles with several genres', () {
      final grouped = groupByGenre([action1, action2, comedy1]);

      expect(grouped['Action'], containsAll([action1, action2]));
      expect(grouped['Thriller'], [action1]);
      expect(grouped['Comedy'], [comedy1]);
    });

    test('groupByGenre buckets genre-less titles under "Other"', () {
      final grouped = groupByGenre([unrated]);
      expect(grouped['Other'], [unrated]);
    });

    test('groupByRatingBand buckets by whole-point rating, unrated separately', () {
      final grouped = groupByRatingBand([action1, action2, comedy1, unrated]);

      expect(grouped['9-10'], [action1]);
      expect(grouped['7-8'], [action2]);
      expect(grouped['5-6'], [comedy1]);
      expect(grouped['Unrated'], [unrated]);
    });

    test('groupByLanguage buckets by display language, unknowns separately', () {
      final english = action1.copyWith(originalLanguage: 'en');
      final korean = action2.copyWith(originalLanguage: 'ko');
      final alsoEnglish = comedy1.copyWith(originalLanguage: 'en');

      final grouped = groupByLanguage([english, korean, alsoEnglish, unrated]);

      expect(grouped['English'], [english, alsoEnglish]);
      expect(grouped['Korean'], [korean]);
      expect(grouped['Unknown'], [unrated]);
    });
  });

  group('PERS-SORT-1: personalRatingSort (Watched pile only)', () {
    test('sorts Loved -> Liked -> Okay -> Not for me -> Unrated', () {
      final watchHistory = <String, List<WatchRecord>>{
        action1.id: [WatchRecord(rating: PersonalRating.okay, isFirstWatch: true)],
        action2.id: [WatchRecord(rating: PersonalRating.loved, isFirstWatch: true)],
        comedy1.id: [WatchRecord(rating: PersonalRating.notForMe, isFirstWatch: true)],
        // unrated: no history entry at all.
      };

      final sorted = personalRatingSort(
        [action1, action2, comedy1, unrated],
        watchHistory,
      );

      expect(sorted, [action2, action1, comedy1, unrated]);
    });

    test('a rewatch-only record (isFirstWatch: false) does not count as the primary rating', () {
      // action1's primary (first-watch) record has no rating -- ranks as
      // unrated despite its rewatch being rated Loved. Compared against a
      // genuinely Loved first-watch (comedy1) rather than another unrated
      // title, so the assertion doesn't depend on sort stability between
      // two equally-unrated items.
      final watchHistory = <String, List<WatchRecord>>{
        action1.id: [
          WatchRecord(rating: null, isFirstWatch: true),
          WatchRecord(rating: PersonalRating.loved, isFirstWatch: false),
        ],
        comedy1.id: [WatchRecord(rating: PersonalRating.loved, isFirstWatch: true)],
      };

      final sorted = personalRatingSort([action1, comedy1], watchHistory);

      expect(sorted, [comedy1, action1]);
    });

    test('a season-scoped record does not count as the overall primary rating', () {
      final watchHistory = <String, List<WatchRecord>>{
        action1.id: [
          WatchRecord(rating: PersonalRating.loved, seasonNumber: 1, isFirstWatch: true),
        ],
        comedy1.id: [WatchRecord(rating: PersonalRating.loved, isFirstWatch: true)],
      };

      final sorted = personalRatingSort([action1, comedy1], watchHistory);

      expect(sorted, [comedy1, action1]);
    });
  });

  group('PERS-SORT-1: cleanup threshold', () {
    test('kPileCleanupThreshold is 50', () {
      expect(kPileCleanupThreshold, 50);
    });
  });
}
