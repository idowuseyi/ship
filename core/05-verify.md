# Phase 05 — Verify (QA + Bug Hunt + Security)

## Purpose
Exercise the built project, hunt for bugs, run the adversarial security
review, and record results and fixes.

## Inputs
- `.workflow/04-implementation.md` (what was built, how to run).
- `.workflow/03-design.md` (intended behavior to check against).
- `.workflow/memory.md` and `.workflow/state.md`.

## Process
1. Turn each **measurable success criterion** in `01-brief.md` into a concrete
   **automated test** in the project's real test suite (not prose). Record the
   mapping in `## Acceptance` as
   `criterion — test (path/id) — pass|fail|blocked(<reason>)`. If a criterion
   cannot be verified, record `blocked(<reason>)` — never fabricate a result
   (see Result Integrity in `_conventions.md`).
2. Run the project; cover happy paths, edge cases, and the listed error modes.
3. Hunt for bugs: boundary inputs, race conditions, silent failures, wrong
   error handling. For each bug, note repro, severity, and fix.
4. Run the **full adversarial security pass** in `core/_security-review.md`.
   Record results in `## Security` per its output contract (finding lines
   with severity and status, "reviewed and found solid" list, non-code
   follow-ups). Fix every `Critical`/`High` finding, or obtain the user's
   explicit deferral at the gate — recorded inline as
   `deferred(<reason + flip condition>)`.
5. Apply fixes (re-entering Implement conventions as needed); re-test until
   every acceptance line reads `pass`. Fix the underlying defect —
   **never edit a test or weaken a criterion to make it pass**; if a test
   itself is wrong, say so explicitly here and justify the change. A prior
   `pass` is stale the moment the behavior it covered changes — re-run and
   overwrite.
6. Record in `## Not Covered` whatever was not tested or security-reviewed,
   and why. Never leave gaps implicit.
7. Write `.workflow/05-verify.md` using its template sections, then run
   `.workflow/check-gate.sh` — it fails Verify if tests are missing/red, any
   acceptance line reads `fail`/`blocked`, `## Security` is empty or has an
   open Critical/High finding, or the secret scan hits. Do not advance until
   it exits 0.

*Information currency (see `_conventions.md`):* check the build against
currently-known vulnerabilities/CVEs and current tooling behavior, not
remembered ones. Record sources in `## Sources`.

## Output
`.workflow/05-verify.md` with: `## Test Coverage`, `## Bugs Found`,
`## Fixes Applied`, `## Residual Risks`, `## Acceptance`, `## Security`,
`## Not Covered`, `## Sources`.

## Gate
None during Verify. But the **next** phase (Go-to-Market) is gated: do not
start it automatically.

## Handoff
In `state.md` set `current_phase: 06-gtm`, check `05-verify.md`, add a Log
line. Update `.workflow/memory.md` per the Memory Protocol in
`_conventions.md`: append any non-obvious learnings from this phase; prune
entries now proven false, dismissed, or attended to. Do not start
Go-to-Market automatically — it has a pre-flight gate. Wait for the user to
invoke the Go-to-Market phase.
