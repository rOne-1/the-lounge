// Unit coverage for E4/CO-8's lightweight offline episode-skeleton store.
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:the_lounge/models/media_item.dart';
import 'package:the_lounge/services/episode_skeleton_cache_service.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  const season1 = TvSeason(
    id: 1,
    seasonNumber: 1,
    name: 'Season 1',
    episodes: [
      TvEpisode(id: 101, episodeNumber: 1, seasonNumber: 1, name: 'Pilot', overview: 'x'),
      TvEpisode(id: 102, episodeNumber: 2, seasonNumber: 1, name: 'Episode Two'),
    ],
  );
  const season2 = TvSeason(
    id: 2,
    seasonNumber: 2,
    name: 'Season 2',
    episodes: [
      TvEpisode(id: 201, episodeNumber: 1, seasonNumber: 2, name: 'Return'),
    ],
  );

  test('round-trips season/episode numbers, without cast/images/overviews',
      () async {
    final prefs = await SharedPreferences.getInstance();
    final service = EpisodeSkeletonCacheService(prefs: prefs);

    await service.saveSkeleton('tv-1', [season1, season2]);
    final result = service.getSkeleton('tv-1');

    expect(result, isNotNull);
    expect(result!.length, 2);
    expect(result[0].seasonNumber, 1);
    expect(result[0].episodes.map((e) => e.episodeNumber), [1, 2]);
    expect(result[1].seasonNumber, 2);
    expect(result[1].episodes.map((e) => e.episodeNumber), [1]);

    // Lightweight: no overview/stillUrl/airDate carried over, even though
    // the original season1 episode 1 had an overview.
    for (final season in result) {
      for (final ep in season.episodes) {
        expect(ep.overview, isNull);
        expect(ep.stillUrl, isNull);
        expect(ep.airDate, isNull);
      }
    }
  });

  test('returns null for a show with no saved skeleton', () async {
    final prefs = await SharedPreferences.getInstance();
    final service = EpisodeSkeletonCacheService(prefs: prefs);

    expect(service.getSkeleton('never-saved'), isNull);
  });

  test('a later save overwrites the previous skeleton for the same show',
      () async {
    final prefs = await SharedPreferences.getInstance();
    final service = EpisodeSkeletonCacheService(prefs: prefs);

    await service.saveSkeleton('tv-1', [season1]);
    await service.saveSkeleton('tv-1', [season1, season2]);

    final result = service.getSkeleton('tv-1');
    expect(result!.length, 2);
  });

  test('clearSkeleton removes the stored entry', () async {
    final prefs = await SharedPreferences.getInstance();
    final service = EpisodeSkeletonCacheService(prefs: prefs);

    await service.saveSkeleton('tv-1', [season1]);
    expect(service.getSkeleton('tv-1'), isNotNull);

    await service.clearSkeleton('tv-1');
    expect(service.getSkeleton('tv-1'), isNull);
  });

  test('corrupt stored data is treated as absent, not thrown', () async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('episode_skeleton_tv-1', 'not valid json{{{');
    final service = EpisodeSkeletonCacheService(prefs: prefs);

    expect(service.getSkeleton('tv-1'), isNull);
  });
}
