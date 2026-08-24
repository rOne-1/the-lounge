/// Bump this every time kWhatsNewSections changes for a new release --
/// the What's New dialog shows once per distinct value of this string
/// (tracked in SharedPreferences), not once per app version/build number,
/// so it can be updated independently of pubspec's version field.
const String kWhatsNewVersion = '0.3.2';

class WhatsNewSection {
  final String title;
  final List<String> items;

  const WhatsNewSection({required this.title, required this.items});
}

/// Curated, user-facing summary of everything visibly new/fixed since the
/// last version testers actually saw this dialog for ('0.3.0') -- covers
/// the "Theme Depth" pass (grain texture, ambient shadows, typography, and
/// a signature decorative motif per theme) plus the id-collision fix.
/// Plain-language only -- no internal ticket IDs, file names, or
/// engineering framing.
const List<WhatsNewSection> kWhatsNewSections = [
  WhatsNewSection(
    title: 'New',
    items: [
      'Every theme now has a fully considered identity, not just a different color palette -- its own display typeface (an elegant italic serif for Screening Room, a bold geometric face for Midnight Cinema, delicate serifs for Orchid Bloom, and more), a tactile grain texture and ambient shadow tuned to its palette, and a small signature decorative flourish.',
      'Violet Dusk and Midnight Cinema got a contrast pass -- their accent colors and star ratings now stand out clearly instead of blending into the background.',
    ],
  ),
  WhatsNewSection(
    title: 'Fixed',
    items: [
      'Fixed a rare case where a movie and an unrelated TV show sharing the same catalog id could silently overwrite each other in your watchlists, saved list, or watch history.',
      'Undoing a Discover swipe now reliably removes the title from wherever it was just added, instead of occasionally leaving it behind.',
    ],
  ),
];
