/// Bump this every time kWhatsNewSections changes for a new release --
/// the What's New dialog shows once per distinct value of this string
/// (tracked in SharedPreferences), not once per app version/build number,
/// so it can be updated independently of pubspec's version field.
const String kWhatsNewVersion = '0.3.0';

class WhatsNewSection {
  final String title;
  final List<String> items;

  const WhatsNewSection({required this.title, required this.items});
}

/// Curated, user-facing summary of everything visibly new/fixed since the
/// last version testers actually saw this dialog for ('0.2.3') -- covers
/// the full Analytics epic (shipped after v0.2.3), the Beta 3 Launch
/// Readiness sprint (accessibility sweep, Settings redesign, Detail screen
/// lazy loading, TV state-machine hardening), and the new theme roster.
/// Plain-language only -- no internal ticket IDs, file names, or
/// engineering framing.
const List<WhatsNewSection> kWhatsNewSections = [
  WhatsNewSection(
    title: 'New',
    items: [
      'Analytics: a new "Discover Your Habits" hub reachable from the Lobby, with a chronological heatmap and binge-velocity view, taste metrics (favorite cast and directors, how your ratings compare to critics, genre breakdown), franchise completion tracking, a watchlist funnel and shelf-life drop-off chart, studio/label affinity, and a Legend sheet explaining every metric. Results can be exported as a shareable image.',
      'Settings has a new card-based theme picker, and two new themes to choose from: Orchid Bloom and Tuscany. Café Calm, Reading Room, Alpine, Gilded Plum, and Riviera have been retired.',
      'A brief "confirming" indicator now appears on a TV show right after you mark it Watched, while the app double-checks its season data in the background.',
      'Improved screen reader support throughout the app -- navigation, media cards, the swipe deck, the hall selector, and summary cards now announce themselves properly.',
      'The Detail screen loads faster -- the sections below the fold now load as you scroll instead of all at once.',
    ],
  ),
  WhatsNewSection(
    title: 'Fixed',
    items: [
      'Calendar no longer shows already-released titles as "upcoming."',
      'Runtime, cast, and director data now backfills correctly for Watched titles that were added through a list import.',
      'Fixed a TMDB connection-reset storm caused by a genre-list race condition; failed requests now retry automatically.',
      'The Movies/TV Shows numeral on the Analytics hub was mislabeled as a title count -- it correctly shows hours, with clearer copy.',
      'Fixed two separate causes of an occasional blank/black screen when opening Search.',
      'Discover\'s grid now reliably refreshes when you change a filter, without needing an app restart.',
      'Importing a partial backup no longer drops any of your 3 standard Halls.',
      'Switching a Hall\'s language now reactively refreshes shelf items that were already loaded.',
      'TV shows with incomplete season data on TMDB no longer get incorrectly marked as fully watched.',
    ],
  ),
];
