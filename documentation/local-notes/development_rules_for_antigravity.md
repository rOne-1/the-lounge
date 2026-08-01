# Development Rules for Antigravity

*Universal — applies across projects.*

1. **Subagent-only execution.** Every specific task must be handled by a subagent (e.g. compile testing agent, E2E testing agent, coding agent, etc).

2. **Orchestrator doesn't code.** Antigravity's own internal orchestrator agent must act as coordinator/reviewer only and is strictly not allowed to write code itself — it dispatches to subagents.
   > Scoped to Antigravity's internal architecture only; it does not describe Claude's role, which is defined separately in the cross-platform apps custom instructions.

3. **No parallel agents.** Fully sequential execution only — one subagent runs to completion before the next begins. No exceptions for "non-overlapping files"; sequential is the hard rule, to avoid conflicts, overwrites, and inconsistent shared memory/state between agents.

4. **Git principles and coding standards**, defined concretely as:
   - Code style: [Effective Dart](https://dart.dev/effective-dart) style guide
   - Commit messages: [Conventional Commits](https://www.conventionalcommits.org/)
   - Versioning: [Semantic Versioning](https://semver.org/) (SemVer)

5. **No hardcoding** unless explicitly told to do so.

6. **Secrets stay in `.env`** — never exposed in code.

7. **Always latest stable.** Use the latest stable language and package/import versions. Verify via the web at the time of the task instead of relying on in-memory/training knowledge, since that may be outdated.

8. **Never use deprecated services, features, or modules.** If detected:
   - *Trivial/mechanical* deprecations (e.g. a renamed method, a straightforward dependency bump with no breaking API surface) may be auto-remediated directly.
   - *Structural* deprecations (e.g. swapping an auth provider, a breaking schema migration, replacing a core service) must be flagged for explicit approval before acting — not silently decided.
   - Never simply silence or suppress an alert either way. All deprecation warnings must be addressed, one way or the other.

9. **Test and self-heal before reporting results:**
   - On test failure, attempt to self-heal for a **maximum of 2–3 retry attempts**.
   - If still failing after the cap, stop and escalate to the user with the failure details rather than continuing to retry indefinitely.

10. **Rule files and scratch material** live in a separate, git-ignored local folder — not the tracked `/documentation` folder (see `tech_stack_and_coding_principles.md`, item 6).
