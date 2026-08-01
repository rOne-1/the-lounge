# Tech Stack & Coding Principles

## Primary Tech Stack

1. **SDK:** Flutter 3.44.x (Stable) — stability for Windows/Web; Impeller for Android
2. **Language:** Dart 3.12 — support for async generators
3. **Database:** Supabase Flutter v2 — native support for pgvector (AI embeddings) & Realtime

> **Note:** Supabase is deprecating explicit version-pinning on Postgres extensions (e.g. pgvector). Never pin an explicit extension version in migrations — install the project's default version, then verify the resulting version matches what the code expects.

---

## Principles

1. **Naming & linting.** Consistent, readable naming convention, enforced via `flutter_lints` (Google's official baseline), wired into CI as a gate — not a manual suggestion.

2. **Defensive error handling.** Always take defensive measures for silent errors and have thorough exception handling.

3. **Centralized constants.** A dedicated file for constants and their initialization, imported wherever needed (required for tracking and standardization).

4. **Secrets.** A dedicated `.env` file for sensitive information. Never expose sensitive information in code or on GitHub.

5. **Relative paths.** Always use relative paths — never expose local directories used during development.

6. **Documentation folder structure:**
   - **`/documentation`** — tracked in git. Contains the core development documents below, kept current as the project evolves:
     1. **Changelog** — all changes, updates, fixes, and new features per version.
     2. **Requirements Specification** — what the software must do: user needs and system rules.
     3. **System Architecture Document** — high-level design, databases, and how different parts of the system communicate.
     4. **API Documentation** — code interfaces, endpoints, and data formats.
     5. **User Manual** — install, run, and troubleshoot the software.
   - **`/local-notes`** (or similar) — git-ignored. Personal working notes, scratch material, and the development rule files (this file and `development_rules_for_antigravity.md`) live here, not in the tracked repo.

7. **Thorough error handling.**

8. **Fix, never silence.** Fix any and all errors. Never ignore or silence an error.

9. **Deprecation policy.** Avoid deprecated features, modules, and components. If any are detected, fix by migrating to a supported alternative, or remove if the deprecated component has no impact. Never silence the alerts.
   > See `development_rules_for_antigravity.md`, rule 8, for the trivial-vs-structural remediation split.

10. **Project structure:** layer-first (group by type — `screens/`, `widgets/`, `services/`, etc.) — universal across projects.

11. **State management:** chosen per project, not standardized universally. To be decided explicitly when each project is scoped.

12. **Testing and self-heal** is extremely important and must always be followed. No fixed numeric coverage threshold is required, but **all applicable tests must pass before a task is considered done.**

    **Core Test Categories**
    | Type | Purpose |
    |---|---|
    | Unit | Smallest code blocks (functions, methods, classes) in isolation. Fast, catches basic logic errors early. |
    | Integration | How separate modules/services interact — database connections, internal APIs, microservice communication. |
    | End-to-End (E2E) | Real user journeys through the full stack (UI, backend, database) — sign-up, checkout, payment, etc. |

    **Specialized & Supporting Test Cases**
    | Type | Purpose |
    |---|---|
    | Regression | Re-run past test cases to confirm new changes haven't broken existing features. |
    | Smoke / Sanity | Quick checks on critical paths after a new build, to confirm basic stability. |
    | Performance & Load | Response times and behavior under heavy traffic. |
    | Security | Vulnerabilities, broken authentication, data leaks. |
