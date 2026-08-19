import 'package:flutter_test/flutter_test.dart';
import 'package:the_lounge/models/media_item.dart';
import 'package:the_lounge/models/profile_space.dart';
import 'package:the_lounge/models/user_folder.dart';
import 'package:the_lounge/models/watch_record.dart';
import 'package:the_lounge/providers/navigation_provider.dart';

void main() {
  group('PROF-1: MediumDomain & ArchiveBucket models', () {
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

    test('ArchiveBucket labels', () {
      expect(ArchiveBucket.watching.label, 'Watching');
      expect(ArchiveBucket.watchlist.label, 'Watchlist');
      expect(ArchiveBucket.watched.label, 'Watched');
      expect(ArchiveBucket.saved.label, 'Saved');
      expect(ArchiveBucket.onHold.label, 'On-Hold');
      expect(ArchiveBucket.dropped.label, 'Dropped');
    });
  });

  group('PROF-1: DomainArchive & ProfileSpace serialization', () {
    final sampleMovie = const MediaItem(
      id: 'movie-1',
      title: 'Inception',
      type: MediaType.movie,
      rating: 8.8,
      overview: '',
      genres: ['Sci-Fi'],
    );

    test('DomainArchive serialization and bucket lookup', () {
      final archive = DomainArchive(
        watchlist: {'movie-1': sampleMovie},
        watched: {'movie-1': sampleMovie},
        watchedEpisodes: {'tv-1': {'S1E1', 'S1E2'}},
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
      expect(archive.bucket(ArchiveBucket.watchlist)['movie-1']?.title, 'Inception');
      expect(archive.bucket(ArchiveBucket.watching).isEmpty, isTrue);

      final json = archive.toJson();
      final reconstructed = DomainArchive.fromJson(json);

      expect(reconstructed.watchlist['movie-1']?.title, 'Inception');
      expect(reconstructed.watchedEpisodes['tv-1']?.contains('S1E1'), isTrue);
      expect(reconstructed.startDates['movie-1'], DateTime(2026, 1, 1));
      expect(reconstructed.seasonStartDates['tv-1']?[1], DateTime(2026, 1, 1));
    });

    test('ProfileSpace default instances & full serialization', () {
      final common = ProfileSpace.defaultCommon();
      expect(common.id, 'common');
      expect(common.isCommon, isTrue);

      final custom1 = ProfileSpace.defaultCustom1();
      expect(custom1.id, 'custom_1');
      expect(custom1.isCommon, isFalse);

      final custom2 = ProfileSpace.defaultCustom2();
      expect(custom2.id, 'custom_2');
      expect(custom2.isCommon, isFalse);

      final folder = UserFolder(
        id: 'f-1',
        name: 'Sci-Fi Hits',
        createdAt: DateTime(2026, 2, 1),
        mediaIds: ['movie-1'],
      );

      final record = WatchRecord(
        date: DateTime(2026, 2, 2),
        rating: null,
        isFirstWatch: true,
      );

      final populated = common.copyWith(
        name: 'Main Lounge',
        customFolders: [folder],
        watchHistory: {
          'movie-1': [record]
        },
        domains: {
          MediumDomain.movies: DomainArchive(
            watchlist: {'movie-1': sampleMovie},
          ),
        },
      );

      final json = populated.toJson();
      final fromJson = ProfileSpace.fromJson(json);

      expect(fromJson.name, 'Main Lounge');
      expect(fromJson.customFolders.length, 1);
      expect(fromJson.customFolders.first.name, 'Sci-Fi Hits');
      expect(fromJson.watchHistory['movie-1']?.length, 1);
      expect(fromJson.domainArchive(MediumDomain.movies).watchlist['movie-1']?.title, 'Inception');
      expect(fromJson.domainArchive(MediumDomain.tv).isEmpty, isTrue);
    });
  });
}
