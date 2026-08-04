# Phase 04 — Implement

## Purpose
Build the project per the approved design, logging decisions and changes.

## Inputs
- `.workflow/03-design.md` (the contract to build to).
- `.workflow/02-plan.md` (sequence).
- `.workflow/memory.md` and `.workflow/state.md`.

## Process
1. Implement in the sequence from the plan, following the design's interfaces.
2. Prefer test-driven steps where a runtime exists; keep changes small and committed.
3. Record files changed, key decisions, and any deviation from the design (with why).
   Never hard-code secrets into code or artifacts — `check-gate.sh`
   secret-scans the working tree, including `.workflow/`.
4. Write `.workflow/04-implementation.md` using its template sections.

*Information currency (see `_conventions.md`):* do not write imports, package
names, or API calls from memory — verify each against current docs/package
registries first, and confirm installed versions with CLI checks. Record sources
in `## Sources`.

## Output
`.workflow/04-implementation.md` with: `## Files Changed`, `## Key Decisions`,
`## Deviations from Design`, `## How to Run`, `## Sources`.

## Gate
None. When implementation is complete, **proceed directly to Verify**
(`05-verify`) without stopping.

## Handoff
In `state.md` set `current_phase: 05-verify`, check `04-implementation.md`, add a
Log line. Next phase is `05-verify`. Update `.workflow/memory.md` per the
Memory Protocol in `_conventions.md`: append any non-obvious learnings from
this phase; prune entries now proven false, dismissed, or attended to.
