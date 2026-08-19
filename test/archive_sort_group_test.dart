import 'package:flutter_test/flutter_test.dart';
import 'package:the_lounge/models/media_item.dart';
import 'package:the_lounge/utils/archive_sort_group.dart';

void main() {
  group('SORT-1 & SORT-2: ArchiveSortOption.lastAdded and Collection Timestamp Aggregation', () {
    test('ArchiveSortOption.lastAdded sorts items newest timestamp first', () {
      final itemOld = MediaItem(
        id: '1',
        title: 'Old Movie',
        type: MediaType.movie,
        rating: 7.0,
        overview: '',
        genres: const ['Drama'],
        addedDate: DateTime(2025, 1, 1),
      );
      final itemNew = MediaItem(
        id: '2',
        title: 'New Movie',
        type: MediaType.movie,
        rating: 8.0,
        overview: '',
        genres: const ['Action'],
        addedDate: DateTime(2026, 5, 20),
      );

      final sorted = sortArchiveBucket([itemOld, itemNew], ArchiveSortOption.lastAdded);
      expect(sorted.first.id, '2');
      expect(sorted.last.id, '1');
    });

    test('getCollectionLastAdded extracts latest timestamp across all collection items', () {
      final dune1 = MediaItem(
        id: 'd1',
        title: 'Dune: Part One',
        type: MediaType.movie,
        rating: 8.0,
        overview: '',
        genres: const ['Sci-Fi'],
        belongsToCollection: const MediaCollection(id: 1, name: 'Dune Collection'),
        addedDate: DateTime(2024, 3, 1),
      );
      final dune2 = MediaItem(
        id: 'd2',
        title: 'Dune: Part Two',
        type: MediaType.movie,
        rating: 8.5,
        overview: '',
        genres: const ['Sci-Fi'],
        belongsToCollection: const MediaCollection(id: 1, name: 'Dune Collection'),
        addedDate: DateTime(2026, 8, 1),
      );

      final latest = getCollectionLastAdded([dune1, dune2]);
      expect(latest, DateTime(2026, 8, 1));
    });

    test('getCollectionLastAdded falls back to releaseDate if addedDate is null', () {
      final item = MediaItem(
        id: '10',
        title: 'Interstellar',
        type: MediaType.movie,
        rating: 8.6,
        overview: '',
        genres: const ['Sci-Fi'],
        releaseOrAirDate: DateTime(2014, 11, 7),
      );

      final latest = getCollectionLastAdded([item]);
      expect(latest.year, 2014);
      expect(latest.month, 11);
      expect(latest.day, 7);
    });
  });
}
