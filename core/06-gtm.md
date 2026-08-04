# Phase 06 — Go-to-Market

## Purpose
Position the finished project and produce launch and sales assets.

## Inputs
- `.workflow/01-brief.md` (problem, users, success criteria).
- `.workflow/05-verify.md` (what's proven to work).
- `.workflow/state.md`.

## Gate
HARD GATE — this gate fires **before** starting. Per the Gate Protocol in
`_conventions.md`, first run `.workflow/check-gate.sh` (at this pre-flight point it
validates that Verify passed and the build/tests are green) and the
`core/_gate-review.md` critic. Then present a short plan of the GTM assets you
intend to create **plus the gate rubric**, and stop:
> **GATE — reply `approved` to continue, or tell me what to change.**

## Process
(After approval.)
1. Define positioning: the one-line value proposition and target audience.
2. Choose channels and craft messaging tailored to each.
3. Draft launch assets (e.g. landing copy, announcement, demo script).
4. Outline sales next steps (outreach, pricing notes, objections/answers).
5. Write `.workflow/06-gtm.md` using its template sections.

*Information currency (see `_conventions.md`):* verify current market conditions,
pricing, channels, competitor positioning, and platform/store/ad policies before
drafting assets. Record sources in `## Sources`.

## Output
`.workflow/06-gtm.md` with: `## Positioning`, `## Audience & Channels`,
`## Messaging`, `## Launch Assets`, `## Sales / Next Steps`, `## Sources`.

## Handoff
In `state.md` set `last_gate_passed: gtm`, `current_phase: done`,
`next_gate: none`, check `06-gtm.md`, add a Log line. The workflow is complete.
Update `.workflow/memory.md` per the Memory Protocol in `_conventions.md`:
append any non-obvious learnings from this phase; prune entries now proven
false, dismissed, or attended to.
