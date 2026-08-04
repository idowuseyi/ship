# Phase 00 — Bootstrap

## Purpose
Scaffold the `.workflow/` artifact trail in the current target project.

## Inputs
- `ship/templates/workflow/` (source templates).
- `ship/core/_conventions.md` (state schema, filenames).

## Process
1. Determine the target project's root (the project being worked on, NOT the
   `ship` repo). Confirm with the user if ambiguous.
2. Create `<target>/.workflow/`.
3. Copy every file from `ship/templates/workflow/` into `<target>/.workflow/`
   (this includes `check-gate.sh`, the machine gate). Mark it executable:
   `chmod +x <target>/.workflow/check-gate.sh`.
4. In `<target>/.workflow/state.md`, replace `<PROJECT_NAME>` with the project's
   name and `<date>` with today's date.
5. Offer to install the CI gate: copy `ship/templates/ci/ship-gate.yml` to
   `<target>/.github/workflows/ship-gate.yml` so the same check runs on every push.
6. Report the created files and tell the user the next step is the Discover phase.

## Output
- Directory `<target>/.workflow/` containing `state.md`, `memory.md`, the six
  artifact templates from `_conventions.md`'s artifact table, and the
  executable `check-gate.sh` machine gate.

## Gate
None. Bootstrap is setup only; proceed when done.

## Handoff
Next phase is `01-discover`. `state.md` already points `current_phase` at
`01-discover` with `next_gate: discover`. `memory.md` starts empty — the
Memory Protocol in `_conventions.md` governs it from here.
