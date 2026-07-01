# Phase 05 — Verify (QA + Bug Hunt)

## Purpose
Exercise the built project, hunt for bugs, and record results and fixes.

## Inputs
- `.workflow/04-implementation.md` (what was built, how to run).
- `.workflow/03-design.md` (intended behavior to check against).
- `.workflow/state.md`.

## Process
1. Turn each **measurable success criterion** in `01-brief.md` into a concrete
   **automated test** in the project's real test suite (not prose). Record the
   mapping in `## Acceptance` as `criterion — test (path/id) — pass|fail`.
2. Run the project; cover happy paths, edge cases, and the listed error modes.
3. Hunt for bugs: boundary inputs, race conditions, silent failures, wrong
   error handling. For each bug, note repro, severity, and fix.
4. Apply fixes (re-entering Implement conventions as needed); re-test until every
   acceptance line reads `pass`.
5. Write `.workflow/05-verify.md` using its template sections, then run
   `.workflow/check-gate.sh` — it fails Verify if tests are missing/red or any
   acceptance criterion is unmet. Do not advance until it exits 0.

*Information currency (see `_conventions.md`):* check the build against
currently-known vulnerabilities/CVEs and current tooling behavior, not remembered
ones. Record sources in `## Sources`.

## Output
`.workflow/05-verify.md` with: `## Test Coverage`, `## Bugs Found`,
`## Fixes Applied`, `## Residual Risks`, `## Acceptance`, `## Sources`.

## Gate
None during Verify. But the **next** phase (Go-to-Market) is gated: do not start
it automatically.

## Handoff
In `state.md` set `current_phase: 06-gtm`, check `05-verify.md`, add a Log line.
Do not start Go-to-Market automatically — it has a pre-flight gate. Wait for the
user to invoke the Go-to-Market phase.
