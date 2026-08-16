import '../models/media_item.dart';

/// E3/TF-7-a: strict anime exclusion. TMDB has no clean "is anime" flag, so
/// this uses the standard heuristic other trackers rely on: Japanese-
/// language animation.
///
/// Deliberately narrower than "any Animation-genre title" so Western
/// animation (Disney, Pixar, DreamWorks -- an explicit scope boundary in
/// the triage report: anime specifically, not animation broadly) is never
/// caught. Deliberately narrower than "any Japanese-original-language
/// title" so Japanese live-action stays. This will miss anime whose
/// original_language isn't 'ja' (rare international co-productions) and
/// can't distinguish it from that gap without a real "is anime" signal --
/// flagged in the triage report itself as needing a heuristic, not a single
/// flag. Anime becomes its own AniList-based module later (D1); this is the
/// interim exclusion for the TMDB-backed Movies/TV module.
bool isAnime(MediaItem item) {
  return item.genres.contains('Animation') && item.originalLanguage == 'ja';
}

extension AnimeFilterList on List<MediaItem> {
  /// Returns this list with anime titles excluded (E3/TF-7-a).
  List<MediaItem> excludingAnime() => where((item) => !isAnime(item)).toList();
}
