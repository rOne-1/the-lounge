import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/media_item.dart';

/// E4/CO-8: lightweight offline skeleton cache for TV shows the user is
/// actively tracking (Watching/On-Hold/Dropped).
///
/// Stores ONLY season/episode counts and numbers -- no cast, images, or
/// overviews -- refreshed whenever real season data is fetched online
/// ([tvShowSeasonsProvider] in repository_provider.dart writes it on
/// success). Read back as a fallback when the real fetch fails (no
/// connectivity), so the episode list can still render with real season
/// structure and specific episodes can still be marked watched offline,
/// instead of falling all the way back to a single synthesized season built
/// from a raw total episode count.
///
/// Deliberately a separate store from [TmdbLocalCacheService]'s generic
/// raw-JSON cache: that cache is reactive (only holds what's been recently
/// fetched) and TTL-bound (7 days for season data), so a show a user is
/// tracking but hasn't opened recently can silently fall out of it. This
/// store isn't tied to that TTL and is scoped specifically to shows the
/// user is tracking, not every show ever viewed.
class EpisodeSkeletonCacheService {
  static const _keyPrefix = 'episode_skeleton_';

  final SharedPreferences prefs;

  const EpisodeSkeletonCacheService({required this.prefs});

  Future<void> saveSkeleton(String showId, List<TvSeason> seasons) async {
    final skeleton = seasons
        .map((season) => {
              'seasonNumber': season.seasonNumber,
              'name': season.name,
              'episodeNumbers':
                  season.episodes.map((e) => e.episodeNumber).toList(),
            })
        .toList();
    await prefs.setString('$_keyPrefix$showId', jsonEncode(skeleton));
  }

  /// Returns a previously-saved skeleton as [TvSeason]s, each episode
  /// carrying only its number (name defaults to "Episode N", everything
  /// else null) -- or null if nothing has been cached for this show yet.
  List<TvSeason>? getSkeleton(String showId) {
    final raw = prefs.getString('$_keyPrefix$showId');
    if (raw == null) return null;
    try {
      final decoded = jsonDecode(raw) as List;
      return decoded.map((entry) {
        final map = entry as Map<String, dynamic>;
        final seasonNumber = map['seasonNumber'] as int;
        final episodeNumbers = (map['episodeNumbers'] as List).cast<int>();
        return TvSeason(
          id: seasonNumber,
          seasonNumber: seasonNumber,
          name: map['name'] as String? ?? 'Season $seasonNumber',
          episodes: episodeNumbers
              .map((n) => TvEpisode(
                    id: n,
                    episodeNumber: n,
                    seasonNumber: seasonNumber,
                    name: 'Episode $n',
                  ))
              .toList(),
        );
      }).toList();
    } catch (_) {
      // Corrupt/unreadable entry -- treat as absent rather than throwing.
      return null;
    }
  }

  Future<void> clearSkeleton(String showId) async {
    await prefs.remove('$_keyPrefix$showId');
  }
}
