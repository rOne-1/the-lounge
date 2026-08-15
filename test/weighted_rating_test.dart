import 'package:flutter_test/flutter_test.dart';
import 'package:the_lounge/models/media_item.dart';
import 'package:the_lounge/utils/weighted_rating.dart';

MediaItem _item({required double rating, int? voteCount}) {
  return MediaItem(
    id: 'x',
    title: 'x',
    type: MediaType.movie,
    rating: rating,
    overview: '',
    genres: const [],
    voteCount: voteCount,
  );
}

void main() {
  group('SP-3/E2: weightedRating formula', () {
    test('a title with votes far above m is trusted near its own average', () {
      final wr = weightedRating(r: 9.0, v: 100000, m: 300, c: 6.0);
      expect(wr, closeTo(9.0, 0.05));
    });

    test('a title with zero votes collapses to the pool mean', () {
      final wr = weightedRating(r: 10.0, v: 0, m: 300, c: 6.0);
      expect(wr, equals(6.0));
    });

    test('a title with votes == m is pulled exactly halfway toward the pool mean', () {
      final wr = weightedRating(r: 8.0, v: 300, m: 300, c: 6.0);
      expect(wr, closeTo(7.0, 1e-9));
    });

    test('a low-vote high-average title is pulled well below its raw average', () {
      // 2 votes averaging 9.0 in a pool that otherwise means 6.0 -- this is
      // exactly the "1-2 votes averaging 7 ranks equal to thousands" bug
      // SP-3 exists to fix. The weighted score should sit close to the pool
      // mean, not the raw 9.0.
      final wr = weightedRating(r: 9.0, v: 2, m: 300, c: 6.0);
      expect(wr, lessThan(6.1));
      expect(wr, greaterThan(6.0));
    });

    test('v + m == 0 falls back to the pool mean instead of dividing by zero', () {
      final wr = weightedRating(r: 8.0, v: 0, m: 0, c: 5.5);
      expect(wr, equals(5.5));
    });
  });

  group('SP-3/E2: meanRatingOf', () {
    test('excludes unvoted items from the mean', () {
      final pool = [
        _item(rating: 8.0, voteCount: 100),
        _item(rating: 4.0, voteCount: 0),
        _item(rating: 6.0, voteCount: null),
      ];
      expect(meanRatingOf(pool), equals(8.0));
    });

    test('returns 0.0 for an empty or fully-unvoted pool', () {
      expect(meanRatingOf(const []), equals(0.0));
      expect(meanRatingOf([_item(rating: 7.0, voteCount: 0)]), equals(0.0));
    });

    test('averages across multiple voted items', () {
      final pool = [
        _item(rating: 8.0, voteCount: 10),
        _item(rating: 6.0, voteCount: 10),
      ];
      expect(meanRatingOf(pool), equals(7.0));
    });
  });

  group('SP-3/E2: weightedRatingOf', () {
    test('ranks a well-voted 7.5 above a 2-vote 9.0 against a realistic pool mean', () {
      final wellVoted = _item(rating: 7.5, voteCount: 20000);
      final lowVoted = _item(rating: 9.0, voteCount: 2);
      const poolMean = 6.5;
      const minVotes = 300.0;

      final wrWellVoted = weightedRatingOf(wellVoted,
          poolMean: poolMean, minVotes: minVotes);
      final wrLowVoted = weightedRatingOf(lowVoted,
          poolMean: poolMean, minVotes: minVotes);

      expect(wrWellVoted, greaterThan(wrLowVoted));
    });
  });
}
