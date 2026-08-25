/// Bump this every time kWhatsNewSections changes for a new release --
/// the What's New dialog shows once per distinct value of this string
/// (tracked in SharedPreferences), not once per app version/build number,
/// so it can be updated independently of pubspec's version field.
const String kWhatsNewVersion = '0.3.3';

class WhatsNewSection {
  final String title;
  final List<String> items;

  const WhatsNewSection({required this.title, required this.items});
}

/// Curated, user-facing summary of everything visibly new/fixed since the
/// last version testers actually saw this dialog for ('0.2.3') -- the
/// 0.3.0/0.3.1/0.3.2 version bumps were never actually distributed, so
/// this consolidates all of it into one release: the Analytics epic, the
/// Beta 3 Launch Readiness sprint, the new theme roster and Theme Depth
/// pass, a round of dev-feedback fixes, TMDB data enrichment (cast/crew,
/// regional certification, images/reviews/keywords, franchise
/// completion), a feature-depth pass (Tools Hub, Calendar, Rewatch
/// Vault, Archive), a craft/polish pass (Continue Watching hero,
/// haptics, ClearLogo hero title, episode carousel, Pick For Me
/// roulette), and stability fixes. Plain-language only -- no internal
/// ticket IDs, file names, or engineering framing.
const List<WhatsNewSection> kWhatsNewSections = [
  WhatsNewSection(
    title: 'New',
    items: [
      'Analytics: a new "Discover Your Habits" hub reachable from the Lobby, with a chronological heatmap and binge-velocity view, taste metrics (favorite cast and directors, how your ratings compare to critics, genre breakdown), franchise completion tracking, a watchlist funnel and shelf-life drop-off chart, studio/label affinity, and a Legend sheet explaining every metric. Results can be exported as a shareable image.',
      'Two new themes, Orchid Bloom and Tuscany -- each with its own display typeface, tactile grain texture, ambient shadow, and a signature decorative flourish. Reading Room, Café Calm, and Alpine Chalet have been retired.',
      'A new Continue Watching card on the Lounge home screen jumps you straight to your next unwatched episode.',
      'Discover and your ratings now have their own haptic feel -- distinct swipe and commit vibrations, tuned per theme.',
      'Pick For Me is now a full constraint roulette: filter by type, runtime, streaming service, and mood before it picks for you.',
      'The Detail screen now opens with a full-bleed title logo that collapses into the top bar as you scroll.',
      'Episodes are now browsed as a 16:9 still carousel with watched-state badges, and you can long-press a season tab to mark the whole season watched at once.',
    ],
  ),
  WhatsNewSection(
    title: 'Improved',
    items: [
      'Settings has a new card-based theme picker; Violet Dusk and Midnight Cinema got a contrast pass so their accent colors and star ratings stand out clearly.',
      'TV shows now show cast aggregated across every season, plus extended crew (writer, composer, cinematographer, producer), an uncapped "show all" cast list, and guest stars/crew per episode.',
      'Age ratings now resolve for your actual watch region instead of always showing the US rating.',
      'Detail pages gained more images, user reviews, and alternative/translated titles that are now searchable against your own library.',
      'Franchise and collection completion tracking now works across every shelf, with real completion gauges on the Collection screen and the Detail screen\'s franchise banner.',
      'The signature grain texture now follows you onto every screen, not just the main tabs.',
      'Tools Hub cards now show live, up-to-date counts instead of static placeholders.',
      'Calendar\'s agenda cards now show poster thumbnails instead of a plain status dot.',
      'Rewatch Vault has a new hero summary card and can be sorted by Most Recent, Most Rewatched, or Title A-Z; its empty state now links straight to Discover.',
      'Archive\'s sort and group controls are now always reachable no matter which view you\'re in, and your choice is remembered across visits. The "Date Added" sort was removed in favor of the more meaningful "Last Added."',
      'Rate Titles and Saved cleanup both gained an Undo button for your last action, matching Discover.',
      'The shareable Analytics image now includes twice as many stats -- Titles Watched, Favorite Era, Top Studio, and Avg. Binge Pace joined the existing ones -- and no longer shows the on-device attribution footer.',
      'Improved screen reader support throughout the app -- navigation, media cards, the swipe deck, the hall selector, and summary cards now announce themselves properly.',
      'The Detail screen loads faster -- sections below the fold now load as you scroll instead of all at once.',
      'A brief "confirming" indicator now appears on a TV show right after you mark it Watched, while the app double-checks its season data in the background.',
    ],
  ),
  WhatsNewSection(
    title: 'Fixed',
    items: [
      '"Reset Everything" in Settings now actually clears all your data. It previously appeared to work, but your watchlists and history could silently reappear afterward.',
      'Fixed a rare case where a movie and an unrelated TV show sharing the same catalog id could silently overwrite each other in your watchlists, saved list, or watch history.',
      'Undoing a Discover swipe now reliably removes the title from wherever it was just added, instead of occasionally leaving it behind.',
      'Calendar no longer shows already-released titles as "upcoming."',
      'Runtime, cast, and director data now backfills correctly for Watched titles that were added through a list import.',
      'Fixed a TMDB connection-reset storm caused by a genre-list race condition; failed requests now retry automatically.',
      'Fixed two separate causes of an occasional blank/black screen when opening Search.',
      'Discover\'s grid now reliably refreshes when you change a filter, without needing an app restart.',
      'Importing a partial backup no longer drops any of your standard Halls.',
      'Switching a Hall\'s language now reactively refreshes shelf items that were already loaded.',
      'TV shows with incomplete season data on TMDB no longer get incorrectly marked as fully watched.',
    ],
  ),
];
