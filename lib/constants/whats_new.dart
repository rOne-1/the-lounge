/// Bump this every time kWhatsNewSections changes for a new release --
/// the What's New dialog shows once per distinct value of this string
/// (tracked in SharedPreferences), not once per app version/build number,
/// so it can be updated independently of pubspec's version field.
const String kWhatsNewVersion = '0.2.2';

class WhatsNewSection {
  final String title;
  final List<String> items;

  const WhatsNewSection({required this.title, required this.items});
}

/// Curated, user-facing summary of everything visibly new/fixed since the
/// last version testers actually saw this dialog for ('0.2.0') -- covers
/// the v0.2.1 nav-capsule fix (never surfaced in-app before) plus
/// everything new in v0.2.2. Plain-language only -- no internal ticket
/// IDs, file names, or engineering framing.
const List<WhatsNewSection> kWhatsNewSections = [
  WhatsNewSection(
    title: 'New',
    items: [
      'Multiple Halls: create separate spaces for different moods or people, each with its own fully separate Watchlist, Watching, Watched, and every other shelf -- switch between them from the floating navigation capsule.',
      'Each Hall can have its own theme, so switching Halls can also switch your whole look automatically.',
      'Each Hall can be locked to a single language, so Lobby, Discover, Search, and Calendar only ever show titles in that language while you\'re in it.',
      'Renamed "Piles" to "Shelves" throughout the app to match the screening-room theme.',
    ],
  ),
  WhatsNewSection(
    title: 'Fixed',
    items: [
      'The floating navigation pill\'s Settings button and tab switching now work correctly from inside a pushed screen (Archive, Tools, Settings, Detail, Folders, Rewatch Vault, etc.) -- previously they did nothing at all in that case.',
      'Switching Halls partway through a Discover deck now refreshes the deck instead of continuing to show the previous Hall\'s picks.',
      'A language-locked Hall\'s Lobby rails (Now Playing, Upcoming, Trending, etc.) and Calendar agenda no longer show almost nothing -- they now correctly surface titles in the locked language instead of getting lost in a mostly-other-language list.',
    ],
  ),
];
