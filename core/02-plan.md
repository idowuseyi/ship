# Phase 02 — Plan / Architect

## Purpose
Decompose the chosen direction into a work breakdown and choose the architecture
and tech.

## Inputs
- `.workflow/01-brief.md` (requirements, chosen direction).
- `.workflow/state.md`.

## Process
1. Break the work into independently shippable pieces; note dependencies and order.
2. Choose architecture and key technologies; justify each in one line. Prefer the
   project's existing patterns if applying to an existing codebase.
3. Identify the top risks and how each is mitigated.
4. Write `.workflow/02-plan.md` using its template sections.

## Output
`.workflow/02-plan.md` with: `## Work Breakdown`, `## Architecture`,
`## Tech Choices`, `## Sequence & Milestones`, `## Risks`.

## Gate
None. Flows directly to Design.

## Handoff
In `state.md` set `current_phase: 03-design`, check `02-plan.md`, add a Log line.
Next phase is `03-design`.
