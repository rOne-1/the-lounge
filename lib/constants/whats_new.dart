/// Bump this every time kWhatsNewSections changes for a new release --
/// the What's New dialog shows once per distinct value of this string
/// (tracked in SharedPreferences), not once per app version/build number,
/// so it can be updated independently of pubspec's version field.
const String kWhatsNewVersion = '0.1.0';

class WhatsNewSection {
  final String title;
  final List<String> items;

  const WhatsNewSection({required this.title, required this.items});
}

/// Curated, user-facing summary of everything visibly new/fixed since the
/// previous alpha build testers had (commit 72fb2c5). Plain-language only
/// -- no internal ticket IDs, file names, or engineering framing.
const List<WhatsNewSection> kWhatsNewSections = [
  WhatsNewSection(
    title: 'New',
    items: [
      'Redesigned navigation: a single floating, draggable capsule replaces the old top bar and bottom tabs, giving your movies and shows the full screen.',
      'Every card, dialog, toast, slider, and dropdown across the app has been rebuilt with a consistent, luxury screening-room look.',
      'Ratings now use a weighted formula everywhere they\'re shown or sorted, so a title with a handful of votes can\'t outrank one with tens of thousands.',
      'Discover: skipped titles now stay skipped for 6 months (or for good after 5 skips), with a once-a-day manual reload for a fresh deck.',
      'A new "Your Watchlist" carousel on Home.',
      'Collapse All / Expand All for your Watched collections.',
      'Network badges on a title\'s detail page are now tappable, filtering Browse by that network.',
      'Expanded language filter, from 21 languages to 65.',
      'A quick Settings entry point from Your Space.',
    ],
  ),
  WhatsNewSection(
    title: 'Fixed',
    items: [
      'Multi-season shows no longer falsely show "Done" after finishing just Season 1.',
      'The Upcoming Movies rail now shows real, far-out titles, not just ones opening in the next few weeks.',
      'Cast member photos no longer look stretched.',
      'Continue Watching and Next Episode cards are no longer cramped.',
      'Undoing a Discover swipe no longer leaves the card stuck invisible off-screen.',
      'The back button now returns to Home before exiting the app.',
      'Tapping a cast or crew member no longer strands you on the wrong tab after backing out.',
      'Switching bottom-nav tabs no longer resets whatever you were doing on other tabs.',
      'Browse\'s "Load More" no longer scrambles already-loaded results.',
      'Fixed crashes and blank cards in Browse\'s Cast & Crew filter.',
      'Numerous performance and animation-smoothness improvements throughout.',
    ],
  ),
];
