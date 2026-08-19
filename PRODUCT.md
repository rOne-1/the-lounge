# Product

<!-- impeccable:product-schema 1 -->

## Platform

web

## Users

Primary user is the solo indie developer building this for personal use — a single-user app by design (no accounts, no multi-user support, no social features). The project is currently in active beta with real external testers giving feedback, but there is no curated record of that feedback yet (see Evidence on Hand).

## Product Purpose

The Lounge consolidates movie/TV discovery and tracking into one personal app, cleanly divided by content type ("sectioned off, not blended"). It exists to solve three specific gaps the developer identified in existing tools:

- No app offers a personalized "my space" for movies/TV combining detailed info, watch-status tracking, and quick discovery in one place.
- Screenshots/social saves of interesting titles are never revisited — there's no dedicated capture-and-browse flow for them.
- Existing tracking apps feel generic and document-like; this app is meant to feel tactile, premium, and inviting rather than utilitarian.

A Books module (cataloguing via Google Books API, mood/genre-tag discovery, reading analytics) is planned as Phase 2 and is explicitly out of scope for current work.

## Positioning

No single existing app combines swipe-based discovery, personal tracking (save-for-later / watchlist / watched), cast & rating detail, and release-date awareness with calendar sync in one place. The recommendation logic is deliberately transparent and non-adaptive — genre/cast/creator similarity against the user's own explicit signals (watchlist, watched history), never hidden ML weighting — which the product treats as a durable philosophical stance, not just a v1 simplification (it's meant to also govern Phase 2's book discovery).

## Operating Context

- Cross-platform: Android, Web, and Windows are all primary targets with full feature parity (one documented exception: the trailer player, see Capabilities and Constraints).
- External data dependencies: TMDB API (search, discover, cast/crew, ratings, genres, seasons/episodes, trailers, regional watch providers) and Google Calendar API (push-only sync for release/air dates, explicit OAuth opt-in).
- Core workflows: Home (continue watching, next-episode highlight, trending rails), Search (title + cast/director name matching), Browse & filter, Discover (the signature swipe deck), Detail view (movie/TV templates), Your space (watchlist / maybe pile / watched history), Calendar (read-only release/air-date agenda).
- Responsive across phone, foldable/tablet, and desktop/Windows following Material 3 breakpoints.

## Capabilities and Constraints

- Confirmed functional scope (Phase 1, Movies & TV only): discovery/search/browse, swipe-based Discover deck with a fixed four-gesture mapping (skip / save-for-later / watchlist / watched), detail views with independent (non-mutually-exclusive) status toggles, in-app calendar with explicit-action-only Google Calendar sync, responsive layout across breakpoints.
- Explicitly out of scope for Phase 1: user accounts/multi-user, social features, person/actor profile pages (search still matches names, but resolves to titles, never a person's own page), offline playback or media hosting/streaming of any kind.
- No adaptive/ML recommendation engine, by design — see Positioning.
- Windows platform constraint: `webview_flutter` doesn't support Windows, so the trailer player is a dedicated full-screen takeover route (not an inline-expanding player) to keep behavior identical across all three platforms rather than branching per-platform.
- Every network call (TMDB, Google Calendar, and any persistence layer) must resolve to one of three reusable fallback patterns — full-screen load failure, inline partial-section failure, or trailer/playback-unavailable — never an unhandled exception or silent no-op.
- **Documentation-vs-code discrepancy, unresolved:** `documentation/requirements_specification.md` and this repo's CLAUDE.md both state Supabase Flutter v2 as the persistence/sync layer, but `pubspec.yaml` has no Supabase dependency and `lib/repositories/` / `lib/providers/` show no Supabase-backed repository — current persistence appears to be local-only (`shared_preferences`). Treat "Supabase-backed sync" as an unconfirmed/stale claim, not a current capability, until verified against the actual data layer.
- **Feature set has grown past the original Phase 1 spec** (per the developer, 2026-08-16): the project has moved from initial build-out into an active triage/polish/bugfix cycle (see `local-notes/the_lounge_uiux_and_animation_triage.md`), and capabilities now exist that requirements_specification.md doesn't mention, including an offline episode-skeleton cache, physics-driven ambient-glow motion, an app-wide Bayesian weighted-rating system, and an ambiance/theme system expanded from the original 2 named ambiances to 6 registered themes. Treat requirements_specification.md as Phase 1 baseline intent, not a complete or current inventory of what's built.

## Brand Commitments

- Name: **The Lounge**.
- Identity is deliberately luxury/high-polish — pitched as a personal screening room, not a utility app. This is a standing, non-negotiable product stance (restated in this repo's CLAUDE.md), not a preference to be traded off for implementation ease.

## Evidence on Hand

No curated testimonials, case studies, or press exist. The repo root has a handful of stray screenshots (`before_kill.png`, `after_relaunch.png`, `browse_screen.png`, `live_detail_refetch.png`) and a `window_dump.xml` — these read as ad hoc QA/verification artifacts from prior sessions, not curated product evidence, and should not be treated as approved marketing or reference assets. Future work must not fabricate testimonials, benchmarks, pricing, or customer claims — none exist.

## Product Principles

- **Fixes must be systemic, not screen-isolated.** A bug or gap fixed in one place must be searched for and fixed everywhere the same pattern recurs, not just the reported instance.
- **Uniform high-polish over path-of-least-effort.** Every interactable surface gets the same level of tactile, premium craft — partial polish reads worse than uniform polish, so it's not an acceptable shortcut.
- **Recommendation and discovery logic stays transparent and explainable**, never a black box — applies across Movies/TV now and is meant to carry into Books later.
- **Side-effectful sync actions require explicit user confirmation**, never silent/automatic behavior (e.g., Google Calendar push only happens via an explicit "Add to calendar" action).
- **The app must never fail silently** — every failure mode resolves to one of the three defined fallback patterns rather than an unhandled exception or a stuck/ambiguous state.

## Accessibility & Inclusion

The Discover deck's swipe gestures are mirrored by a redundant row of tap-target buttons specifically so the deck remains fully usable without gesture input. Elsewhere, standard Material 3 accessibility primitives apply — the app's heavy reskinning sits on top of Material 3, not as a replacement for its accessibility handling.
