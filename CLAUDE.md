# CLAUDE.md — The Lounge

Project context for Claude Code working in this repo. Read this before starting
any work here.

---

## What this project is

**The Lounge** — a cross-platform Flutter/Dart entertainment tracker (Android,
Web, Windows), built by a solo indie developer, currently in active beta with
real testers. Product identity is deliberately luxury/high-polish — a personal
screening room, not a utility app.

**`/documentation` is the intended home for tracked, git-committed project
docs** (Changelog, Requirements Specification, System Architecture Document,
API Documentation, User Manual) — but as of this writing it's mostly aspirational:
only `requirements_specification.md` and a wireframes/design-decisions export
actually exist there. There's no Changelog, no API Documentation, no User
Manual yet. **The System Architecture Document currently lives in
`local-notes/architecture/` instead** — meaning it hasn't actually followed the
project's own stated policy of being a tracked `/documentation` file. Don't
assume `/documentation` reflects current architecture; check
`local-notes/architecture/system_architecture_document.md` for the real thing,
and flag it if you think it's worth actually migrating that file (and starting
the other missing docs) into `/documentation` properly.

**`/local-notes`** (gitignored) holds working material, not tracked deliverables:
- `development_rules_for_antigravity.md` — universal dev rules (see below,
  mostly still relevant even though it's Antigravity-branded)
- `the_lounge_multi_profile_medium_partitioned_triage.md` — **the CURRENT MASTER
  SOURCE OF TRUTH for active work.** The Multi-Profile & Medium-Partitioned Architecture
  sprint triage report (5 packages: Terminology/Lounge naming refactor, 2D Partitioned
  ProfileSpace engine & ProfileStorageService, Medium-reactive counts & pluralization,
  Watched Collections "Last Added" sorting, and smooth search top bar animation).
- `the_lounge_uiux_and_animation_master_audit.md` — the master UI/UX & motion
  audit baseline establishing the benchmark architecture and quality bar.
- `outstanding_issues_notepad.md` — **still lives at the top level, still
  active** (check here for known-but-non-urgent findings before starting
  new work).
- `completed pile/` — archive of fully completed/reviewed triage sprints,
  including prior bug, UI/UX, IA-1 floating nav, systems sweeps, Personalization
  Epic, Your Space Redesign, and Multi-Issue Reliability/UX Polish.
- `architecture/` — system architecture doc + Mermaid diagrams (see note
  above — this is the real architecture doc, `/documentation` is not).

---

## ⚠️ First: confirm which mode this session is running in

This project normally runs on a two-agent split: a planning/architecture agent
(Claude, in chat) scopes work and writes prompts, and a separate implementation
agent (Antigravity) executes them, with the planning agent verifying actual
changed files afterward — never trusting self-reported "done."

When working as Claude Code in this repo, you may be asked to operate in one
of two modes. **If it isn't already clear from the request, ask which one
applies before starting:**

- **Mirror mode** — you're standing in for the planning agent. Pick the next
  item from the triage report, scope it, write a standalone Antigravity-style
  prompt (see format below), and stop. Don't implement it yourself.
- **Direct-implementation mode** — you're doing the actual code work yourself,
  bypassing the Antigravity round-trip for this session. In this mode, the
  verification discipline below still applies to *your own* work — don't
  mark something done without actually re-reading the changed files
  afterward and checking it against the Definition of Done, the same
  scrutiny that's normally applied to a second agent's output.

---

## Non-negotiable: verification discipline

This is the most important standing rule in this project, developer-stated and
repeatedly reinforced: **self-reported "done" has repeatedly diverged from
actual code state** (invented package names, claimed-but-unimplemented
features, understated gaps, session-interruption false completions). Whether
you're verifying someone else's change or your own:

- Read the actual changed files. Don't trust a walkthrough/summary alone.
- **Two-Pass Root Cause Verification**: Treat all initial triage root-cause
  diagnoses as 1st-pass assessments only. Always conduct a mandatory 2nd and
  final pass investigating live runtime execution, data pipelines, and real
  API payloads before writing code.
- Cite specific file/line locations when confirming or disputing a claim.
- Flag discrepancies plainly, the way you'd point out a bug — don't soften or
  bury them under positive framing.
- A claim following a mentioned session/context restart deserves *extra*
  skepticism, not less — this project has caught a case where a "completion"
  report was actually just a recap of an earlier task from memory.
- This applies to project *documentation claims* too, not just code — e.g.
  don't assume `/documentation` is complete or current just because the
  project's own principles doc says it should be. Verify state, don't infer
  it from stated policy.

---

## Standing principles (apply to all work, not just specific items)

These came out of real recurring failure patterns in this project. Carry them
into anything you scope or build here:

- **SP-1 — Fixes must be systemic, not screen-isolated.** Past fixes were
  repeatedly scoped to only the reported screen/feature, causing the same bug
  to resurface elsewhere later (a similar-titles fix that worked for movies
  but not TV; a blank-card bug recurring from an already-"fixed" pattern).
  When fixing something, actively search for and fix every related instance,
  not just the one reported — and say explicitly what you checked.
- **SP-2 — Uniform high-polish; no stock defaults.** The app's identity is
  luxury/high-polish. Every interactable element gets advanced,
  spring-consistent animation (see `AppPhysics` constants for the existing
  motion language). Partial polish reads *worse* than uniform — don't default
  to the path of least implementation effort here.
- **SP-3 — Weighted rating, applied everywhere ratings are used.** Locked
  formula: **IMDb-style Bayesian weighted rating**,
  `WR = (v/(v+m)) * R + (m/(v+m)) * C` (`R` = title's own average, `v` = vote
  count, `m` = minimum-votes threshold for full weight, `C` = mean rating
  across the candidate pool). Implement once as a shared utility, consume
  everywhere ratings rank or filter content — Discover, search relevance,
  any rating-ordered list. Don't reimplement per screen.
- **SP-4 — Clean up one-time-use files.** No stale scratch/test/audit files
  left in the tree after a task. This includes cleaning up dead scaffolding
  inside test files themselves (leftover trial-and-error containers/mocks
  that never got removed once the final approach was found).
- **SP-5 — Re-read the dev rules every session/task.** See
  `local-notes/development_rules_for_antigravity.md` — rules on sequential
  execution, no hardcoding, latest-stable verification, deprecation handling,
  and test/self-heal retry caps still apply generally, even outside
  Antigravity's specific orchestration model.

---

## Tech stack & coding standards

- **Flutter 3.44.x (Stable)**, **Dart 3.12**, **Supabase Flutter v2**.
- Effective Dart style guide; Conventional Commits; Semantic Versioning.
- `flutter_lints` is the enforced baseline — don't introduce lint violations.
- No hardcoding unless explicitly told to. Secrets stay in `.env`, never in
  code. Always use relative paths.
- Always verify current stable versions of packages/APIs via the web rather
  than relying on training knowledge, which may be outdated.
- Never leave a deprecation warning unaddressed — trivial/mechanical fixes
  (renamed method, non-breaking bump) can be auto-remediated; structural ones
  (auth provider swap, breaking schema migration) need explicit approval
  first, not a silent decision.
- All applicable tests must pass before a task is considered done. No fixed
  coverage threshold, but unit/integration/E2E/regression/smoke categories
  all matter — see `tech_stack_and_coding_principles.md` for the full
  breakdown.
- Layer-first project structure (`screens/`, `widgets/`, `services/`, etc.).

---

## Antigravity prompt format (for Mirror mode)

If scoping work for Antigravity rather than implementing directly, prompts are
standalone markdown files (not inline chat text), and must include:

1. A **"Before starting"** section instructing re-reading
   `local-notes/development_rules_for_antigravity.md` and confirming
   subagent dispatch (Rule 2) + sequential execution (Rule 3).
2. **Context** — what's actually broken/needed, with file references where
   already known.
3. **Goal** — the actual objective, plus any product/design decisions already
   locked (state them, don't leave them for the implementer to guess).
4. **Out of scope** — what NOT to touch, so already-finished work doesn't get
   re-touched.
5. **Cleanup instruction** (SP-4) — explicit, every time.
6. **Definition of Done** — a checklist, specific enough that "done" is
   verifiable against real files afterward, not just self-reported.

Flag genuine product/design judgment calls rather than silently deciding them.
Small, easily-reversible technical calls can just be made and noted inline.

---

## Where to start

1. Read `local-notes/the_lounge_multi_profile_medium_partitioned_triage.md` for current
   active priorities, architectural specifications, naming conventions, and sprint packages.
2. Check `local-notes/outstanding_issues_notepad.md` (top level, still
   active) for known residual issues near whatever you're about to
   touch.
3. Confirm session mode (see above) if not already stated.
4. Do the work; verify against real files before calling anything done; update
   the triage report and/or notepad to reflect what actually happened.
