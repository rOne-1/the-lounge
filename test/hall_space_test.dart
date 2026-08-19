import 'package:flutter_test/flutter_test.dart';
import 'package:the_lounge/models/media_item.dart';
import 'package:the_lounge/models/hall_space.dart';
import 'package:the_lounge/models/user_folder.dart';
import 'package:the_lounge/models/watch_record.dart';
import 'package:the_lounge/providers/navigation_provider.dart';

void main() {
  group('NOMEN-1 & NOMEN-2: MediumDomain & ArchiveShelfKind models', () {
    test('MediumDomain conversions & labels', () {
      expect(MediumDomain.fromMediaTypeToggle(MediaTypeToggle.movies), MediumDomain.movies);
      expect(MediumDomain.fromMediaTypeToggle(MediaTypeToggle.tv), MediumDomain.tv);
      expect(MediumDomain.fromMediaType(MediaType.movie), MediumDomain.movies);
      expect(MediumDomain.fromMediaType(MediaType.tv), MediumDomain.tv);

      expect(MediumDomain.movies.toMediaTypeToggle(), MediaTypeToggle.movies);
      expect(MediumDomain.tv.toMediaTypeToggle(), MediaTypeToggle.tv);
      expect(MediumDomain.anime.toMediaTypeToggle(), MediaTypeToggle.tv);

      expect(MediumDomain.movies.label, 'Movies');
      expect(MediumDomain.tv.label, 'TV');
      expect(MediumDomain.anime.label, 'Anime');

      expect(MediumDomain.movies.singularLabel, 'Movie');
      expect(MediumDomain.tv.singularLabel, 'TV Show');
      expect(MediumDomain.anime.singularLabel, 'Anime');

      expect(MediumDomain.movies.pluralLabel, 'Movies');
      expect(MediumDomain.tv.pluralLabel, 'TV Shows');
      expect(MediumDomain.anime.pluralLabel, 'Anime Series');
    });

    test('ArchiveShelfKind labels and shelfLabels', () {
      expect(ArchiveShelfKind.watching.label, 'Watching');
      expect(ArchiveShelfKind.watchlist.label, 'Watchlist');
      expect(ArchiveShelfKind.watched.label, 'Watched');
      expect(ArchiveShelfKind.saved.label, 'Saved');
      expect(ArchiveShelfKind.onHold.label, 'On-Hold');
      expect(ArchiveShelfKind.dropped.label, 'Dropped');

      expect(ArchiveShelfKind.watching.shelfLabel, 'Watching Shelf');
      expect(ArchiveShelfKind.watchlist.shelfLabel, 'Watchlist Shelf');
      expect(ArchiveShelfKind.watched.shelfLabel, 'Watched Shelf');
      expect(ArchiveShelfKind.saved.shelfLabel, 'Saved Shelf');
      expect(ArchiveShelfKind.onHold.shelfLabel, 'On-Hold Shelf');
      expect(ArchiveShelfKind.dropped.shelfLabel, 'Dropped Shelf');
    });
  });

  group('NOMEN-1: DomainArchive & HallSpace serialization', () {
    const sampleMovie = MediaItem(
      id: 'movie-1',
      title: 'Inception',
      type: MediaType.movie,
      rating: 8.8,
      overview: '',
      genres: ['Sci-Fi'],
    );

    test('DomainArchive serialization and shelf lookup', () {
      final archive = DomainArchive(
        watchlist: const {'movie-1': sampleMovie},
        watched: const {'movie-1': sampleMovie},
        watchedEpisodes: const {'tv-1': {'S1E1', 'S1E2'}},
        startDates: {'movie-1': DateTime(2026, 1, 1)},
        endDates: {'movie-1': DateTime(2026, 1, 2)},
        seasonStartDates: {
          'tv-1': {1: DateTime(2026, 1, 1)}
        },
        seasonEndDates: {
          'tv-1': {1: DateTime(2026, 1, 10)}
        },
      );

      expect(archive.isEmpty, isFalse);
      expect(archive.isNotEmpty, isTrue);
      expect(archive.totalCount, 2);
      expect(archive.shelf(ArchiveShelfKind.watchlist)['movie-1']?.title, 'Inception');
      expect(archive.shelf(ArchiveShelfKind.watching).isEmpty, isTrue);

      final json = archive.toJson();
      final reconstructed = DomainArchive.fromJson(json);

      expect(reconstructed.watchlist['movie-1']?.title, 'Inception');
      expect(reconstructed.watchedEpisodes['tv-1']?.contains('S1E1'), isTrue);
      expect(reconstructed.startDates['movie-1'], DateTime(2026, 1, 1));
      expect(reconstructed.seasonStartDates['tv-1']?[1], DateTime(2026, 1, 1));
    });

    test('HallSpace default instances & full serialization', () {
      final grandHall = HallSpace.defaultGrandHall();
      expect(grandHall.id, 'common');
      expect(grandHall.name, 'The Grand Hall');
      expect(grandHall.iconKey, 'arch');
      expect(grandHall.isCommon, isTrue);

      final mezzanine = HallSpace.defaultMezzanineHall();
      expect(mezzanine.id, 'custom_1');
      expect(mezzanine.name, 'The Mezzanine Hall');
      expect(mezzanine.iconKey, 'reel');
      expect(mezzanine.isCommon, isFalse);

      final privateScreening = HallSpace.defaultPrivateScreeningHall();
      expect(privateScreening.id, 'custom_2');
      expect(privateScreening.name, 'The Private Screening Hall');
      expect(privateScreening.iconKey, 'curtain');
      expect(privateScreening.isCommon, isFalse);

      final folder = UserFolder(
        id: 'f-1',
        name: 'Sci-Fi Hits',
        createdAt: DateTime(2026, 2, 1),
        mediaIds: const ['movie-1'],
      );

      final record = WatchRecord(
        date: DateTime(2026, 2, 2),
        rating: null,
        isFirstWatch: true,
      );

      final populated = grandHall.copyWith(
        name: 'The Velvet Cinema',
        customFolders: [folder],
        watchHistory: {
          'movie-1': [record]
        },
        domains: {
          MediumDomain.movies: const DomainArchive(
            watchlist: {'movie-1': sampleMovie},
          ),
        },
      );

      final json = populated.toJson();
      final fromJson = HallSpace.fromJson(json);

      expect(fromJson.name, 'The Velvet Cinema');
      expect(fromJson.customFolders.length, 1);
      expect(fromJson.customFolders.first.name, 'Sci-Fi Hits');
      expect(fromJson.watchHistory['movie-1']?.length, 1);
      expect(fromJson.domainArchive(MediumDomain.movies).watchlist['movie-1']?.title, 'Inception');
      expect(fromJson.domainArchive(MediumDomain.tv).isEmpty, isTrue);
    });
  });
}
