import 'package:flutter_test/flutter_test.dart';
import 'package:the_lounge/models/media_item.dart';
import 'package:the_lounge/utils/pile_sort_group.dart';

void main() {
  group('SORT-1 & SORT-2: PileSortOption.lastAdded and Collection Timestamp Aggregation', () {
    test('PileSortOption.lastAdded sorts items newest timestamp first', () {
      final itemOld = MediaItem(
        id: '1',
        title: 'Old Movie',
        type: MediaType.movie,
        addedDate: DateTime(2025, 1, 1),
      );
      final itemNew = MediaItem(
        id: '2',
        title: 'New Movie',
        type: MediaType.movie,
        addedDate: DateTime(2026, 5, 20),
      );

      final sorted = sortPile([itemOld, itemNew], PileSortOption.lastAdded);
      expect(sorted.first.id, '2');
      expect(sorted.last.id, '1');
    });

    test('getCollectionLastAdded extracts latest timestamp across all collection items', () {
      final dune1 = MediaItem(
        id: 'd1',
        title: 'Dune: Part One',
        type: MediaType.movie,
        collectionName: 'Dune Collection',
        addedDate: DateTime(2024, 3, 1),
      );
      final dune2 = MediaItem(
        id: 'd2',
        title: 'Dune: Part Two',
        type: MediaType.movie,
        collectionName: 'Dune Collection',
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
        releaseDate: '2014-11-07',
      );

      final latest = getCollectionLastAdded([item]);
      expect(latest.year, 2014);
      expect(latest.month, 11);
      expect(latest.day, 7);
    });
  });
}
