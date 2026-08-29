# Theme Authoring Guide

This directory implements The Lounge's ambiance/theme system. It's the one
place in the app where "luxury, high-polish, no stock defaults" (see the
repo's `CLAUDE.md`, Standing Principle SP-2) is judged purely by the eye —
there's no functional test for "does this feel premium." This guide exists
because three new themes shipped in one sprint (2026-08-28/29) and every one
of them needed a real fix after review: two collided in hue with an existing
theme, one had a background animation that was technically running but
invisible, and every theme's primary button needed a shared redesign. The
mistakes are cheap to repeat if the reasoning behind the fixes isn't written
down somewhere a future session will actually read.

**Read this before adding, redesigning, or removing a theme.** It is not a
substitute for looking at an existing theme file — `orchid_bloom_theme.dart`
and `verdant_manor_theme.dart` are good ones to copy the shape of — but it
covers the rules that aren't obvious from reading one file in isolation,
because they're about how a new theme relates to the *other seven*.

---

## Architecture, in one paragraph

`AppTheme` (`app_theme.dart`) pairs a display name/id/description with an
`AmbianceColors` (a `ThemeExtension`, `ambiance_colors.dart`) and a real
Flutter `ThemeData`. `AmbianceColors` is the single source of truth every
themed widget reads via `context.ambianceColors` — screens and widgets never
branch on theme id, only on these tokens, which is what makes the whole
system swappable and lerp-able (theme switching cross-fades every token,
including `signatureMotif`, over `AppPhysics.houseSpringDuration`). A new
theme is one new `lib/themes/<name>_theme.dart` file exporting an
`AmbianceColors` instance and an `AppTheme` instance, registered in
`theme_registry.dart`'s `allThemes` list. Nothing else in the app needs to
know it exists.

---

## The current roster (check this before picking colors)

| Theme | Mode | Font | Accent | Grain |
|---|---|---|---|---|
| Screening Room | dark | Fraunces *italic* | `#CBA86A` warm gold | 0.034 |
| Violet Dusk | dark | Playfair Display | `#C2528F` rose-magenta | 0.028 |
| Midnight Cinema | dark | Bricolage Grotesque | `#00B4D8` cyan | 0.022 |
| Orchid Bloom | light | Cormorant Garamond *italic* | `#4B1F6F` violet | 0.012 |
| Tuscany | dark | Lora | `#BB8B7A` dusty terracotta | 0.031 |
| Glacier Dawn | light | DM Serif Display | `#1F6E96` cerulean | 0.014 |
| Nebula Tide | dark | Marcellus | `#5468E0` electric indigo | 0.027 |
| Verdant Manor | dark | Ibarra Real Nova *italic* | `#5C4028` aged timber | 0.029 |

Each of these owns a hue/material identity. **A new theme must not restate
one.** This is the single most common mistake — three of the first drafts of
the current three newest themes failed this exact check:

- *Opal Frost* (pink + lilac, light) read as a paler Orchid Bloom — fixed by
  rebuilding around ice-blue + coral as **Glacier Dawn**.
- *Cobalt Tide* (single-hue blue, dark) read as Midnight Cinema with the
  magenta removed — fixed by adding a genuine violet-nebula/cyan-starlight
  duality and a 3-stop layered gradient as **Nebula Tide**.
- *Amethyst Veil* (magenta-purple, dark) sat too close to Violet Dusk, and
  independently collided with Nebula Tide once both were blue-violet —
  removed entirely and replaced by **Verdant Manor** (green/wood).

Gold and brown-as-a-*dominant* surface color belong to Screening Room and
Tuscany specifically — don't restate that territory in a new theme's
base/card/accent. That said, Verdant Manor legitimately needed real wood/bark
tones (see its own file comments for how that was reconciled with the rule:
its base and interactive accent are wood, but the *dominant* background stays
green, so the two themes still read as different materials, not a shared
palette). The rule is "don't duplicate an existing theme's identity," not
"never use a warm color" — every theme in the table above, including the
coolest ones, uses a warm tone somewhere for `starRating` (see below).

---

## Non-negotiable rules

### 1. `starRating` is always warm, regardless of the theme's own palette

Every theme, even icy or violet ones, uses a gold/amber/honey-adjacent color
for `starRating` — it's a tiny icon-sized rating indicator, not a surface, so
it doesn't compete with Screening Room/Tuscany's gold/brown identity. Don't
invent a cool-toned star rating "for consistency with the palette" — it reads
as a bug, not a design choice, because every other theme in the app has
trained the user to expect a warm star.

### 2. `AmbientGlowWidget` needs real hue separation between `glow1`/`glow2`

`lib/widgets/ambient_glow.dart` renders two radial-gradient blobs (`glow1`,
`glow2`) that drift in *position* over a 15s loop — **the alpha is constant,
it never pulses.** The only thing that makes the effect read as "flowing" is
the hue differential between the two blobs as they cross paths. If `glow1`
and `glow2` are close in hue (e.g. two shades of green, two shades of purple),
the animation is technically running but functionally invisible — this was a
real, shipped bug in both Verdant Manor (foliage green + sage-green "mist")
and Orchid Bloom (orchid-purple + "Dusted Lavender," only ~19° apart) until
caught by live review.

**When picking `glow1`/`glow2`: put them on genuinely different hues** — 40°+
apart on the color wheel, or if they must share a hue family, give them a
large lightness/saturation swing (Violet Dusk's `#C2528F` → `#F4D9E8` works
because the second is nearly white, not because the hue differs). If a
theme's concept calls for a same-family pairing (e.g. "mist" as a paler
version of "foliage"), pick a *different* material for the second glow
instead (Verdant Manor's fix: mist became blue-gray, not pale green) rather
than forcing a monochromatic pair to also be the ambient-glow duality.

### 3. Primary buttons use `buildAccentButtonGradient()`, never a hand-rolled decoration

`shadow_tokens.dart` exports `buildAccentButtonGradient(Color accent)` — call
it for every theme's `primaryButtonDecoration`. Do not use a flat
`BoxDecoration(color: accent, ...)` (reads monotonous/plasticky — this was
the state of 5 of the 8 themes before the 2026-08-29 fix) and do not
hand-write a `LinearGradient` between two unrelated hues (reads like a
generic modern-SaaS blend — this was the other 3 themes, and the one that
prompted the fix: a stark blue-to-orange gradient on Glacier Dawn's CTA). The
shared function derives a 3-stop *tonal* gradient — a lightened highlight, the
true accent, a deepened shade, all one hue — from the accent color alone, so
every theme's button has real dimension without introducing a second color.

### 4. Shadows come from `buildThemeShadows()`, not hand-rolled `BoxShadow`s

Call `buildThemeShadows(accent: <theme accent>, isDark: <bool>)` from
`shadow_tokens.dart` for `cardShadow`/`ambientGlowShadow`/`dialogShadow`. Dark
themes get a two-layer colored-glow-plus-contact-shadow; light themes get a
single soft diffuse shadow. Don't invent a fourth pattern — `theme_shadows_test.dart`
asserts on the layer count per brightness.

### 5. Grain opacity and tint must be numerically unique across the roster

`theme_depth_test.dart` asserts every theme's `grainOpacity` and `grainTint`
are distinct from every other theme's — copy-pasting a value (even
approximately) will fail the test. Light themes should sit noticeably lower
than dark ones (`0.012`–`0.014` vs `0.022`–`0.034` in the table above) —
grain is meant to feel like a fine paper texture in daylight and a richer
velvet/canvas texture at night, not the same intensity regardless of theme.

### 6. Display font must be a distinct `GoogleFonts` family, and italics are a deliberate choice, not a default

`theme_typography_test.dart` asserts all 8 themes have distinct
`displayLarge.fontFamily` values — check the table above before picking one.
`italicDisplay: true` isn't cosmetic filler: the two themes the dev has
specifically called out as having "the strong vibe" (Screening Room, Orchid
Bloom) are both italic, and reused deliberately for Verdant Manor's rework
after its original upright serif was flagged as "uninspiring." Consider
italic for a theme that wants to read as *elegant/grand*; leave it upright
for one that wants to read as *clean/modern* (Midnight Cinema, Nebula Tide).

### 7. Background gradient: 2-stop is the default, 3-stop for themes that need real atmospheric depth

Every theme's `background` is a `RadialGradient` centered at
`Alignment(0, -1.16)` with `radius` ~1.2–1.3, fading a brighter blob into the
base color. Two stops (`[blob, base]`) is standard and reads fine for most
themes. Reach for a 3-stop gradient (`[blob, midtone, base]`) specifically
when the theme's concept is about *layering* — Nebula Tide's nebula depth and
Verdant Manor's canopy-light-to-shadow both use this, and it was the direct
fix for Cobalt Tide's original "too flat" background. Don't reach for 3 stops
by default; it's a tool for a specific problem, not a uniform upgrade.

### 8. Signature motif: bespoke, small, and thematically specific — not decorative filler

Every theme provides a `WidgetBuilder signatureMotif` — a small
(~100×20–24px) `CustomPaint` rendered either via the `SignatureMotif` widget
(`lib/widgets/signature_motif.dart`, used in `lounge_screen.dart` and
`detail_screen.dart`) or by calling `ambiance.signatureMotif!(context)`
directly (`atmospheric_empty_state.dart`'s pattern). It should
be a literal, recognizable shape tied to the theme's concept (Screening
Room's marquee-light dash-diamond-dash, Orchid Bloom's flower, Verdant
Manor's pine sprig with a dew drop and rain streaks) — not an abstract
squiggle. A soft glow via `Paint()..maskFilter = MaskFilter.blur(...)` behind
a focal point (a jewel, a star, a dewdrop) adds presence cheaply; see Nebula
Tide's constellation stars or Verdant Manor's dew drop for the pattern. Wire
it to both
`AppTheme.signatureMotif` and `AmbianceColors.signatureMotif` — they're
tested separately (`theme_motifs_test.dart`).

---

## Naming

Two words, Title Case, atmospheric — not a literal ingredient list. Avoid
reusing a root word another theme already owns: *Room, Dusk, Cinema, Bloom,
Screening, Violet, Midnight, Orchid, Tuscany, Glacier, Dawn, Nebula, Tide,
Verdant, Manor* are all taken as of this writing (check `theme_registry.dart`
for the live list — this guide will go stale before that file does). A theme
built from a moodboard doesn't need to keep the moodboard's own filename or
literal palette names ("Opal Frost" → "Glacier Dawn" once the palette itself
changed) — rename it if the redesign changes what it's actually about.

---

## Checklist: adding a new theme

1. Write `lib/themes/<name>_theme.dart` — copy the shape of an existing file
   (`verdant_manor_theme.dart` is the most fully-worked example: background,
   motif with glow, all tokens, comments explaining non-obvious choices).
   Run every color past the roster table and the 8 rules above *before*
   writing the file, not after.
2. Register in `theme_registry.dart`: import the file, add both the theme
   instance to `allThemes` and (if the file exports one) the palette instance
   name other code might reference.
3. Update the 5 test files that hardcode the roster — search each for the
   existing 8 theme names and add the 9th in the same pattern:
   - `test/theme_tokens_test.dart` (`allAmbianceColors` map)
   - `test/theme_typography_test.dart` (`_getThemes()` map, the
     `RenderFlex`-overflow loop list, a font-specific `testWidgets`, and the
     "all N themes have distinct fonts" count — bump the literal number)
   - `test/theme_motifs_test.dart` (`_allThemeNames` const list, `getThemes()`
     map)
   - `test/theme_shadows_test.dart` (`allAmbianceColors` map, the
     `FrostedGlassSurface` rendering loop list)
   - `test/theme_depth_test.dart` (`allAmbianceColors` map)
4. `flutter analyze` — zero issues, no exceptions, per this project's
   standing policy.
5. `flutter test` — full suite, not just the theme files; a roster change
   touches shared fixtures.
6. **Verify live**, not just via tests — start the web preview
   (`.claude/launch.json`'s `the-lounge-web` config), select the new theme,
   and check at minimum: Settings (the theme card itself, plus every row's
   contrast), Lounge home (the signature motif, the ambient glow behind the
   hero icon), and Browse/Lobby (the primary CTA button, star ratings against
   real posters). A theme that passes every test can still look wrong — the
   3 newest themes each needed a live-review round the automated suite
   couldn't have caught.
7. Clean up: no stray scratch files, no leftover unused consts from a
   previous iteration (Dart will flag genuinely unused ones via `flutter
   analyze`, but double-check anyway).

## Checklist: removing or renaming a theme

Same 5 test files, in reverse — remove/rename every reference, don't just
delete the theme file and `theme_registry.dart` entry. `flutter analyze`
after a straight deletion will not catch a stale entry in a test file's
hardcoded map; only `flutter test` will, once you get to that file.
