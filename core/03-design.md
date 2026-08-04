# Phase 03 — Design

## Purpose
Produce a concrete design: components, interfaces, data, and UX — enough to build
from.

## Inputs
- `.workflow/01-brief.md` and `.workflow/02-plan.md`.
- `.workflow/memory.md` and `.workflow/state.md`.

## Process
1. Break the system into units, each with one clear responsibility and a defined
   interface. State, for each, what it does, how it's used, and what it depends on.
2. Define interfaces/contracts (signatures, request/response shapes, events).
3. Specify data structures/schemas and the main UX flows.
4. Describe error handling for the primary failure modes.
5. Specify the design's security posture: trust boundaries (who talks to
   what, with which privileges), authn/authz per interface, and how sensitive
   data is stored, transported, and logged. Record it inside
   `## Interfaces & Contracts` and `## Data`. The Design gate runs the
   design-time checks in `core/_security-review.md` against exactly this.
6. Write `.workflow/03-design.md` using its template sections.

*Information currency (see `_conventions.md`):* verify current API contracts,
framework idioms, and security best practices for the chosen stack against
official docs before specifying them. Record sources in `## Sources`.

## Output
`.workflow/03-design.md` with: `## Components`, `## Interfaces & Contracts`,
`## Data`, `## UX / Flows`, `## Error Handling`, `## Sources`.

## Gate
HARD GATE. Follow the Gate Protocol in `_conventions.md`: first run
`.workflow/check-gate.sh` (fix any FAIL and re-run until it passes), then run the
critic pass in `core/_gate-review.md` — check especially that the design satisfies
every requirement in `01-brief.md` and is not over-engineered. Only then present a
short summary of the design **plus the gate rubric**, and stop:
> **GATE — reply `approved` to continue, or tell me what to change.**

## Handoff
On `approved`: in `state.md` set `last_gate_passed: design`,
`current_phase: 04-implement`, `next_gate: gtm`, check `03-design.md`, add a Log
line. Next phase is `04-implement`. Update `.workflow/memory.md` per the Memory Protocol
in `_conventions.md`: append any non-obvious learnings from this
phase; prune entries now proven false, dismissed, or attended to.
