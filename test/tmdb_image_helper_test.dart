import 'package:flutter_test/flutter_test.dart';
import 'package:the_lounge/utils/tmdb_image_helper.dart';

void main() {
  group('TmdbImageHelper', () {
    test('getPosterThumbnailUrl formats path with w342 size tier', () {
      expect(
        TmdbImageHelper.getPosterThumbnailUrl('/poster.jpg'),
        equals('https://image.tmdb.org/t/p/w342/poster.jpg'),
      );
      expect(
        getPosterThumbnailUrl('poster.jpg'),
        equals('https://image.tmdb.org/t/p/w342/poster.jpg'),
      );
    });

    test('getDetailPosterUrl formats path with w500 size tier', () {
      expect(
        TmdbImageHelper.getDetailPosterUrl('/poster.jpg'),
        equals('https://image.tmdb.org/t/p/w500/poster.jpg'),
      );
      expect(
        getDetailPosterUrl('poster.jpg'),
        equals('https://image.tmdb.org/t/p/w500/poster.jpg'),
      );
    });

    test('getBackdropUrl formats path with w780 size tier', () {
      expect(
        TmdbImageHelper.getBackdropUrl('/backdrop.jpg'),
        equals('https://image.tmdb.org/t/p/w780/backdrop.jpg'),
      );
      expect(
        getBackdropUrl('backdrop.jpg'),
        equals('https://image.tmdb.org/t/p/w780/backdrop.jpg'),
      );
    });

    test('getCastHeadshotUrl formats path with w185 size tier', () {
      expect(
        TmdbImageHelper.getCastHeadshotUrl('/headshot.jpg'),
        equals('https://image.tmdb.org/t/p/w185/headshot.jpg'),
      );
      expect(
        getCastHeadshotUrl('headshot.jpg'),
        equals('https://image.tmdb.org/t/p/w185/headshot.jpg'),
      );
    });

    test('returns null for null or empty paths', () {
      expect(TmdbImageHelper.getPosterThumbnailUrl(null), isNull);
      expect(TmdbImageHelper.getPosterThumbnailUrl(''), isNull);
      expect(TmdbImageHelper.getPosterThumbnailUrl('   '), isNull);

      expect(TmdbImageHelper.getDetailPosterUrl(null), isNull);
      expect(TmdbImageHelper.getBackdropUrl(null), isNull);
      expect(TmdbImageHelper.getCastHeadshotUrl(null), isNull);
    });

    test('returns full URL unchanged if already absolute HTTP/HTTPS', () {
      const fullUrl = 'https://example.com/image.png';
      expect(TmdbImageHelper.getPosterThumbnailUrl(fullUrl), equals(fullUrl));
      expect(TmdbImageHelper.getDetailPosterUrl(fullUrl), equals(fullUrl));
      expect(TmdbImageHelper.getBackdropUrl(fullUrl), equals(fullUrl));
      expect(TmdbImageHelper.getCastHeadshotUrl(fullUrl), equals(fullUrl));
    });
  });
}
