/// Bump this every time kWhatsNewSections changes for a new release --
/// the What's New dialog shows once per distinct value of this string
/// (tracked in SharedPreferences), not once per app version/build number,
/// so it can be updated independently of pubspec's version field.
const String kWhatsNewVersion = '0.2.0';

class WhatsNewSection {
  final String title;
  final List<String> items;

  const WhatsNewSection({required this.title, required this.items});
}

/// Curated, user-facing summary of everything visibly new/fixed since the
/// previous alpha build testers had (commit b5ce374). Plain-language only
/// -- no internal ticket IDs, file names, or engineering framing.
const List<WhatsNewSection> kWhatsNewSections = [
  WhatsNewSection(
    title: 'New',
    items: [
      'The Lounge is now the app\'s home base: a redesigned Sanctuary Gateway landing page with quick access to your Archive, Tools, and Browse & Discovery.',
      'The old Home tab is now called Lobby.',
      'New Archive and Tools hubs, restyled to match the rest of the app\'s screening-room look.',
      'The floating navigation capsule now follows you everywhere -- every screen except The Lounge landing page -- instead of just the old top-level tabs.',
      'Swipe left or right on blank space in Lobby, Search, or Calendar to move directly between them, with a new depth/parallax motion; Browse, Archive piles, and Tools support the same swipe to move through their sections.',
      'Rate anything you\'ve watched with a 4-tier personal rating, right from a title\'s page or a new batch Rate Titles tool -- including a rating per season for TV shows.',
      'New Rewatch Log: quickly log a rewatch with a date picker, and see your full watch history on a title\'s page.',
      'New Custom Folders: create, rename, reorder, and organize titles into your own folders, independent of Watchlist/Watched/etc.',
      'New sort and grouping options for Watchlist and Saved, including sorting by your own rating and grouping by language, plus a cleanup tool for trimming an overgrown Saved pile.',
      'TV show pages now show a seasonal rating bar -- your rating for every season at a glance.',
      'New "On This Day" and "Forgotten Favorites" sections on The Lounge, surfacing titles you finished exactly a year (or more) ago, or loved titles you\'ve never revisited.',
      'The Rate Titles, Custom Folders, Cleanup, and Rewatch Vault tools now respect the Movies/TV toggle instead of always mixing both.',
      'New app icon.',
    ],
  ),
  WhatsNewSection(
    title: 'Fixed',
    items: [
      'Tapping a title now opens instantly with its poster and basic info already visible, instead of a blank loading screen.',
      'Search now shows a loading indicator while results come in.',
      'Searching by a cast or crew member no longer misses titles where they weren\'t in the main credited cast.',
      'Restoring a backup with TV shows in it no longer shows an empty list.',
      'The empty-state "Discover Titles" button now returns you cleanly to Discover instead of leaving a stray screen behind.',
      'Fixed occasional stuttering when importing a large backup, and repeated failed lookups no longer retry instantly over and over.',
      'Naming a folder no longer hides the input field behind the on-screen keyboard.',
      'Fixed a crash when creating a folder on the web version.',
      'Fixed sort and grouping (Top Rated, Release Date, Genre, Language) silently breaking after restarting the app.',
      'Fixed the rating banner jumping to a different spot depending on the title.',
      'Fixed per-season rating prompts only ever appearing for Season 1.',
      'Fixed a stray yellow underline occasionally appearing under text in dialogs and the navigation capsule.',
    ],
  ),
];
