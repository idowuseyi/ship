# Phase 03 — Design

## Purpose
Produce a concrete design: components, interfaces, data, and UX — enough to build
from.

## Inputs
- `.workflow/01-brief.md` and `.workflow/02-plan.md`.
- `.workflow/state.md`.

## Process
1. Break the system into units, each with one clear responsibility and a defined
   interface. State, for each, what it does, how it's used, and what it depends on.
2. Define interfaces/contracts (signatures, request/response shapes, events).
3. Specify data structures/schemas and the main UX flows.
4. Describe error handling for the primary failure modes.
5. Write `.workflow/03-design.md` using its template sections.

## Output
`.workflow/03-design.md` with: `## Components`, `## Interfaces & Contracts`,
`## Data`, `## UX / Flows`, `## Error Handling`.

## Gate
HARD GATE. Present a short summary of the design, then stop:
> **GATE — reply `approved` to continue, or tell me what to change.**

## Handoff
On `approved`: in `state.md` set `last_gate_passed: design`,
`current_phase: 04-implement`, `next_gate: gtm`, check `03-design.md`, add a Log
line. Next phase is `04-implement`.
