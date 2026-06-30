# Phase 05 — Verify (QA + Bug Hunt)

## Purpose
Exercise the built project, hunt for bugs, and record results and fixes.

## Inputs
- `.workflow/04-implementation.md` (what was built, how to run).
- `.workflow/03-design.md` (intended behavior to check against).
- `.workflow/state.md`.

## Process
1. Derive test cases from the brief's success criteria and the design's contracts.
2. Run the project; cover happy paths, edge cases, and the listed error modes.
3. Hunt for bugs: boundary inputs, race conditions, silent failures, wrong
   error handling. For each bug, note repro, severity, and fix.
4. Apply fixes (re-entering Implement conventions as needed); re-test.
5. Write `.workflow/05-verify.md` using its template sections.

## Output
`.workflow/05-verify.md` with: `## Test Coverage`, `## Bugs Found`,
`## Fixes Applied`, `## Residual Risks`.

## Gate
None during Verify. But the **next** phase (Go-to-Market) is gated: do not start
it automatically.

## Handoff
In `state.md` set `current_phase: 06-gtm`, check `05-verify.md`, add a Log line.
Then present the Go-to-Market gate (see `06-gtm`).
