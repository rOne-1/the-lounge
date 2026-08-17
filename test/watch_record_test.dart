import 'package:flutter_test/flutter_test.dart';
import 'package:the_lounge/models/personal_rating.dart';
import 'package:the_lounge/models/watch_record.dart';

void main() {
  group('PersonalRating', () {
    test('ordinal mapping round-trips for every tier', () {
      for (final rating in PersonalRating.values) {
        expect(PersonalRating.fromOrdinal(rating.ordinal), rating);
      }
    });

    test('fromOrdinal returns null for null input', () {
      expect(PersonalRating.fromOrdinal(null), isNull);
    });

    test('labels are the confirmed 4-tier copy', () {
      expect(PersonalRating.loved.label, 'Loved it');
      expect(PersonalRating.liked.label, 'Liked it');
      expect(PersonalRating.okay.label, 'It was okay');
      expect(PersonalRating.notForMe.label, 'Not for me');
    });
  });

  group('WatchRecord', () {
    test('recordedAt defaults to now when not supplied', () {
      final before = DateTime.now();
      final record = WatchRecord(rating: PersonalRating.loved);
      final after = DateTime.now();
      expect(
        record.recordedAt.isAfter(before.subtract(const Duration(seconds: 1))),
        isTrue,
      );
      expect(
        record.recordedAt.isBefore(after.add(const Duration(seconds: 1))),
        isTrue,
      );
    });

    test('toJson/fromJson round-trips every field', () {
      final date = DateTime(2026, 1, 15);
      final recordedAt = DateTime(2026, 1, 15, 20, 30);
      final record = WatchRecord(
        date: date,
        rating: PersonalRating.liked,
        seasonNumber: 2,
        isFirstWatch: true,
        recordedAt: recordedAt,
      );

      final restored = WatchRecord.fromJson(record.toJson());

      expect(restored.date, date);
      expect(restored.rating, PersonalRating.liked);
      expect(restored.seasonNumber, 2);
      expect(restored.isFirstWatch, isTrue);
      expect(restored.recordedAt, recordedAt);
    });

    test('toJson/fromJson round-trips null date, rating, and seasonNumber', () {
      final recordedAt = DateTime(2026, 3, 1);
      final record = WatchRecord(recordedAt: recordedAt);

      final restored = WatchRecord.fromJson(record.toJson());

      expect(restored.date, isNull);
      expect(restored.rating, isNull);
      expect(restored.seasonNumber, isNull);
      expect(restored.isFirstWatch, isFalse);
      expect(restored.recordedAt, recordedAt);
    });

    test('recordedAt is immutable across copyWith', () {
      final recordedAt = DateTime(2026, 2, 1);
      final record = WatchRecord(recordedAt: recordedAt);
      final copy = record.copyWith(rating: PersonalRating.okay);
      expect(copy.recordedAt, recordedAt);
      expect(copy.rating, PersonalRating.okay);
    });

    test('copyWith clearDate/clearRating explicitly null out fields', () {
      final record = WatchRecord(
        date: DateTime(2026, 1, 1),
        rating: PersonalRating.loved,
      );
      final cleared = record.copyWith(clearDate: true, clearRating: true);
      expect(cleared.date, isNull);
      expect(cleared.rating, isNull);
    });

    test('fromJson tolerates malformed date/recordedAt strings', () {
      final restored = WatchRecord.fromJson({
        'date': 'not-a-date',
        'rating': 3,
        'seasonNumber': 1,
        'isFirstWatch': true,
        'recordedAt': 'also-not-a-date',
      });
      expect(restored.date, isNull);
      expect(restored.rating, PersonalRating.loved);
      expect(restored.recordedAt, isNotNull);
    });
  });
}
