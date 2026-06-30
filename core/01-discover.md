# Phase 01 — Discover (Brainstorm + Ideate)

## Purpose
Turn a raw idea into an agreed problem statement, requirements, and a chosen
direction.

## Inputs
- `.workflow/state.md` (confirm `current_phase: 01-discover`).
- Any existing project notes/README the user points to.

## Process
1. Ask the user, one question at a time (prefer multiple choice):
   - What problem is this solving, and for whom?
   - What does success look like? How will we know it worked?
   - Hard constraints (time, budget, platform, must-use tech)?
   - What is explicitly out of scope?
2. Propose 2–3 candidate directions with trade-offs and a recommendation.
3. Converge on one direction with the user.
4. Write `.workflow/01-brief.md` using its template sections.

*Information currency (see `_conventions.md`):* verify the problem space against
current reality — whether it is already solved, who the current alternatives and
competitors are, and what users expect now — using web search/docs. Record
findings in `## Sources`.

## Output
`.workflow/01-brief.md` with: `## Problem`, `## Users & Context`,
`## Requirements`, `## Success Criteria`, `## Options Considered`,
`## Chosen Direction`, `## Sources`.

## Gate
HARD GATE. Present a 3–5 line summary of the brief, then stop:
> **GATE — reply `approved` to continue, or tell me what to change.**

## Handoff
On `approved`: in `state.md` set `last_gate_passed: discover`,
`current_phase: 02-plan`, `next_gate: design`, check `01-brief.md`, add a Log
line. Next phase is `02-plan`.
