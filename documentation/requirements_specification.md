# Requirements Specification — Entertainment Hub

**Module:** Movies & TV (Phase 1)
**Status:** Draft — ready for Antigravity handoff after review
**Document location (in repo):** `/documentation/requirements-specification.md`

---

## 1. Purpose

Entertainment Hub is a personal, cross-platform Flutter app (Android, Web, Windows) that consolidates movie/TV discovery and tracking, and — in a later phase — book cataloguing, into one app, cleanly divided by content type ("sectioned off, not blended").

This document specifies **Phase 1: the Movies & TV module only.** The Books module is Phase 2 and is explicitly out of scope here (see §9).

The core problems this module solves:
- No existing app offers a personalized "my space" for movies/TV with detailed info, watch-status tracking, and quick discovery
- Screenshots/social-media saves of interesting titles are never revisited — there's no dedicated capture-and-browse flow
- Existing tracking apps feel generic and document-like; this app is meant to feel tactile, premium, and inviting to use
- No app currently combines discovery, tracking, cast/rating detail, and release-date awareness (with calendar sync) into one place

---

## 2. Scope

**In scope (Phase 1):**
- Movies & TV discovery, search, browsing, and detailed information
- A swipe-based discovery mode (gesture browsing)
- Personal tracking: save-for-later, watchlist, watched history
- In-app calendar + Google Calendar sync for release/air dates
- Two selectable visual ambiances (not light/dark — see §7)
- Responsive layout across phone, foldable/tablet, and desktop/Windows

**Out of scope (Phase 1):**
- Books module (Phase 2 — separate requirements doc)
- User accounts / multi-user support (this is a personal, single-user app)
- Social features (following, sharing, reviews visible to others)
- Person/actor profile pages (see §5.3 — search still matches on names, but there's no browsable filmography page)
- Offline playback or media hosting of any kind (this app tracks and links to where content is available — it never streams or stores video itself, aside from trailer playback)

---

## 3. Platforms & environment

| Platform | Priority | Notes |
|---|---|---|
| Android | Primary | Full feature parity |
| Web | Primary | Full feature parity |
| Windows | Primary | Full feature parity, with one documented exception (see §8.3 — trailer player) |

**Tech stack** (see also `/local-notes/tech_stack_and_coding_principles.md` for universal rules):
- Flutter 3.44.x (stable), Dart 3.12
- Supabase Flutter v2 (data persistence, sync)
- Material 3 as structural foundation, heavily reskinned per §7

---

## 4. External data sources

| Source | Purpose | Terms |
|---|---|---|
| **TMDB API** | Movie/TV metadata: search, discover, cast/crew, ratings, genres, seasons/episodes, videos (trailers), watch providers (regional) | Free for non-commercial use; requires in-app attribution (TMDB logo/credit) |
| **Google Calendar API** | Push release/air-date events to the user's Google Calendar (OAuth) | Standard OAuth consent flow; user must explicitly connect their account |

No other third-party movie/TV data sources are used. There is no local caching requirement beyond what's needed for reasonable performance and offline resilience (see §8.1).

---

## 5. Functional requirements

### 5.1 Navigation & responsive layout

- Top-level split: **Movies & TV** / **Books** (Books is a stub/placeholder in Phase 1)
- Within Movies & TV, a persistent **Movies | TV segmented toggle** on Home, Search, Browse & filter, and Discover — these two content types are structurally separate (different detail templates, different TMDB endpoints), not blended into one list
- Five primary destinations: Home, Discover, Search, Your space, Calendar
- **Responsive behavior follows Material 3 breakpoints:**

  | Breakpoint | Width | Nav pattern |
  |---|---|---|
  | Compact | <600dp | Bottom nav (5 tabs) |
  | Medium | 600–839dp | Bottom nav retained; Discover deck gains a side detail-preview panel |
  | Expanded | 840–1199dp | Inherits Large pattern |
  | Large | 1200–1599dp | Left nav rail; Movies\|TV toggle relocates to top app bar; Home/Detail/Your space gain multi-column layouts |
  | Extra-large | 1600dp+ | Inherits Large pattern, more breathing room |

### 5.2 Home

- Personalized greeting header
- "Continue watching" horizontal rail — poster/thumbnail, progress indicator, episode badge for in-progress TV
- "Next episode" highlight card — countdown/air-date callout, "Add to calendar" action. Uses the secondary accent (dusty rose/copper — see §7.3), not the primary module accent, to stay visually distinct as the focal card
- Trending / popular rails (respecting the Movies\|TV toggle)
- Entry point into Discover (should read as an invitation, not a buried menu item)
- Quick search entry

### 5.3 Search

- Instant, as-you-type results
- Matches on **title AND cast/director name** — a person-name query surfaces their filmography inline, sorted by role prominence, with minor/bit-part credits visually dimmed
- **No dedicated person/profile page** — results always resolve to titles, never to a person's own browsable page
- Scope toggle: **All / Movies / TV** (defaults to All so a person query isn't forced into one type first)
- Empty state: recent searches + trending searches as launch points
- No-results state: clear message, one recovery action (clear search)

### 5.4 Browse & filter

- Filters: genre, year range, rating, language, sort by (popularity / rating / release date)
- Filter panel: bottom sheet (mobile/tablet), docks right on Large/desktop
- Live result count shown on the filter apply action
- Results grid shares visual language with Search results

### 5.5 Discover (swipe deck)

The signature interaction of the app — full-bleed, one title at a time, poster/backdrop-forward. **Movies & TV only** (not applicable to Books).

**Gesture mapping (final):**

| Gesture | Action | Persistence |
|---|---|---|
| Swipe left | Skip for now | Session-only — does not persist, title can reappear later |
| Swipe right | Save for later ("maybe" bookmark) | Persists — lands in the Maybe pile |
| Swipe down | Add to watchlist | Persists — committed intent to watch |
| Swipe up | Mark as already watched | Persists — logs to Watched history |
| Tap | Open full detail view | — |

- On-card persistent gesture hints at all four edges (icon + label) for discoverability
- Redundant tap-target buttons below the deck mirror all four gestures (accessibility / non-gesture fallback)
- **First-run legend overlay** explains all four gestures once; reachable again anytime via a "Legend" (ⓘ) affordance in the top bar
- **Deck composition logic (no black-box learning):** the pool draws from trending/genre-filtered TMDB results, transparently biased toward genre/cast/creator similarity to titles already in the watchlist and watched history. A left-swipe ("skip for now") does **not** influence future deck composition — it's treated as a deliberately non-committal, low-signal gesture, consistent with the app's general preference for legible, non-adaptive recommendation logic over hidden ML weighting (see also §5.7 re: book mood-tag discovery, Phase 2, which follows the same philosophy)
- At Medium/Large breakpoints, a persistent side panel shows the current card's synopsis and labelled action buttons, so the extra width does real work rather than leaving a lone centered card

### 5.6 Detail view

Two templates — **Movie** and **TV** — sharing a common structure with type-specific sections.

**Shared elements:**
- **Hero banner:** collapsed state is a static backdrop image with a play-button overlay — no video player is instantiated until tapped (see §8.3 for the full-screen takeover behavior and platform constraint)
- Title, rating badge, genres
- Top-billed cast strip (horizontal scroll: headshot, name, character), sorted by role prominence
- **Watch providers** section, region-aware:
  - Country selector dropdown
  - Last-selected country **persists locally** across sessions
  - Defaults to device locale's country on first use, before any manual selection
- **Status action row — three independent toggles**, each with its own color (see §7.3): Save for later, Add to watchlist, Mark as watched. These are independent states, not a single mutually-exclusive status (e.g., a title can be both saved and watchlisted simultaneously). The specific interaction logic for how "watched" interacts with the other two (whether it should prompt to clear them, dim them, etc.) is an **implementation decision for the Antigravity build**, not specified visually in wireframes — the wireframes only establish that all three exist as independently-styled toggles
- Similar/recommended titles rail

**Movie-specific:** runtime, release date. If already released, "Add to calendar" is not shown (n/a) — the similar-titles rail takes that space instead. If upcoming/unreleased, "Add to calendar" is shown.

**TV-specific:** seasons/episode count, next-air-date countdown card with its own "Add to calendar" action, season selector, per-episode list (title, air date, runtime; unaired episodes shown dimmed/TBA where data is unavailable)

### 5.7 Your space

- Sectioned view (tabbed or segmented): **Watchlist**, **Maybe pile** (save-for-later), **Watched history**
- Each section: grid/list of poster cards, counts shown per section
- Consistent visual language with Home/Search/Browse

### 5.8 Calendar

- In-app **read-only agenda**, grouped by date, showing upcoming releases/air dates for anything watchlisted or otherwise tracked
- Visual sync indicator per entry: filled dot = pushed to Google Calendar, hollow dot = not yet added
- No scheduling affordances — this is a quick-reference view, not a calendar editor
- Google Calendar push happens via explicit user action ("Add to calendar" buttons elsewhere in the app), consistent with the standing rule that side-effectful actions require explicit confirmation, never silent/automatic sync

### 5.9 Fallback & error states

Per the standing principle that the app must **never fail silently**, three reusable patterns apply across all screens:

1. **Full-screen load failure** — icon, plain-language message, primary "Try again" action, plus a safe secondary path (e.g., a downloads/offline view) where applicable
2. **Inline partial failure** — when only one section of a screen fails to load (e.g., a single rail on Home), that section degrades to a compact retry strip while the rest of the screen remains fully functional. This is the default behavior for partial failures — a whole-screen failure state is reserved for when the primary content itself can't load
3. **Trailer/playback unavailable** — the full-screen player takeover opens directly to a clear "not available" message (never a stuck loading spinner) with an alternative action (add to watchlist / where to watch). The same pattern covers both "no trailer exists" and "playback failed to start"

These three patterns are the baseline; any new screen or feature added later should reuse one of them rather than inventing a new failure treatment.

---

## 6. Non-functional requirements

- **Defensive error handling everywhere** — every network call (TMDB, Google Calendar, Supabase) must have explicit failure handling resolving to one of the three fallback patterns in §5.9, never an unhandled exception or silent no-op
- **No hardcoded secrets** — TMDB API key and Google OAuth credentials live in `.env`, never committed to source
- **Testing** — unit, integration, and applicable E2E coverage per the universal testing principles; no fixed coverage %, but all applicable tests must pass before a task is considered done
- **Accessibility** — the swipe deck's redundant button row exists specifically so Discover remains usable without gesture input; standard Material 3 accessibility primitives apply elsewhere (the reskin sits on top of Material 3, not a replacement for its accessibility handling)
- **Attribution** — TMDB attribution displayed per their non-commercial terms

---

## 7. Design system reference

*(Full detail lives in the wireframe briefs; summarized here for traceability.)*

### 7.1 Ambiance system

Not light/dark mode — **ambiance-based theming**. Two ambiances at launch, each a full material/color reinterpretation, not a palette swap:

- **Screening Room** — dark, velvet-lounge material: near-black warm espresso base, subtle grain texture, ambient pooled glow (not hard neon). Primary accent: champagne gold.
- **The Reading Room** — warm, light, parchment/library material: paper-grain texture, brass details. Primary accent: deep rust/terracotta.

Both ambiances apply to Movies & TV; Books (Phase 2) will use its own accent within each ambiance (wine/burgundy in Screening Room, forest green in The Reading Room) — **these colors are reserved for Books and must not be reused for Movies & TV states.**

### 7.2 Typography & foundation

- Display face: Bodoni Moda (italic) — couture/editorial character
- Body face: Geist — clean, neutral
- Foundation: Material 3 structurally, heavily reskinned (standard accessibility/gesture/layout primitives retained)
- Motion: subtle, restrained micro-interactions — quiet, not scroll-jacking or maximalist

### 7.3 Status color system (Movies & TV)

Three independent hues, one per status, consistent across both ambiances:

| Status | Screening Room | The Reading Room | Role |
|---|---|---|---|
| Watchlist (committed) | Champagne gold | Rust/terracotta | Module's primary accent — strongest/most saturated |
| Save for later (tentative) | Dusty rose/copper | Copper-rose | Secondary accent — also used for the Home "Next episode" card |
| Watched (completed) | Cool steel/slate blue | Cool steel/slate blue | Deliberately different temperature from the warm gold/rose family |

---

## 8. Technical constraints & decisions

### 8.1 TMDB & Google Calendar integration
Standard REST/OAuth integration. TMDB search/discover results should be cached briefly client-side to avoid redundant calls during a single browsing session, particularly for the Discover deck.

### 8.2 No adaptive/ML recommendation engine
Per §5.5, deck and recommendation logic must remain transparent and explainable (genre/cast/creator similarity against explicit signals only — watchlist and watched history). No hidden weighting, no black-box learning, consistent with the same design philosophy applied to Phase 2's book discovery.

### 8.3 Trailer player — Windows platform constraint
Flutter's official `webview_flutter` does not support Windows (confirmed gap as of Feb 2026). Community workarounds exist but cannot guarantee proper Flutter-widget layering/clipping over an embedded web view on Windows.

**Resolution:** the trailer player is a **full-screen takeover state**, not an inline-expanding player. The collapsed hero shows only a static thumbnail (no player instantiated). Tapping play transitions to a dedicated full-screen route with its own player — identical behavior across Android, Web, and Windows. This sidesteps the Windows constraint by design rather than by platform-specific exception.

### 8.4 Deprecation & dependency policy
Per universal dev rules: trivial/mechanical deprecations may be auto-remediated by Antigravity; structural deprecations (e.g., swapping the TMDB or Calendar integration approach) require explicit approval before acting.

---

## 9. Deferred / Phase 2

- **Books module** — separate requirements doc. Will become the single source of truth for cataloguing (replacing manual entry into Goodreads, StoryGraph, and Book Tracker), using Google Books API for metadata, manual mood/genre tag filters for discovery (no algorithmic recommendation, consistent with §8.2), and reading analytics computed from the app's own logged data.
- Person/actor profile pages (explicitly excluded from Phase 1 per §2 — may be reconsidered later)
- "As Director / As Actor" filter chip for prolific-person search results (noted as a possible future refinement, not required for v1)

---

## 10. Open risks

- TMDB rate limits under heavy Discover-deck usage — should be monitored once real usage patterns exist; client-side caching (§8.1) mitigates but doesn't eliminate this
- Google Calendar OAuth consent UX needs its own explicit design pass (not yet covered in wireframes) — the "Add to calendar" action triggers this flow and needs a clear first-time-connection state
- Supabase Postgres extension version pinning is being deprecated (per universal tech stack notes) — not directly relevant to this module's data model unless pgvector or similar is introduced later, but worth keeping in mind if embeddings are ever added for smarter search
