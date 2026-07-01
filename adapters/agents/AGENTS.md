# ship — Lifecycle Workflow (for any agent)

This project may use the `ship` workflow. If a `.workflow/` directory exists,
follow it; if the user asks to start/resume/advance with ship, follow it.

## Rules
- The single source of truth is the ship repo's `core/` directory. Read
  `core/_conventions.md` for the phase contract, gate protocol, and `state.md`
  schema. Never duplicate or improvise phase logic.
- Always read `.workflow/state.md` first to learn the current phase, then read
  the checked artifacts, then execute the current phase's `core/NN-*.md`.
- **Gates are enforced, not advisory.** At every hard gate you MUST run
  `.workflow/check-gate.sh` and fix any FAIL before proceeding, run the
  `core/_gate-review.md` critic pass, and present its human rubric. A red check
  blocks the gate.
- **Information Currency:** verify every external fact against a current source
  and record it in the artifact's `## Sources`; never assert from memory.

This file works natively in Cline, OpenCode, and any tool that reads `AGENTS.md`.
Continue users: see `adapters/continue/`. Weak/local models: see `adapters/local/`.

## Phases (in order)
- Bootstrap → `core/00-bootstrap.md`
- Discover → `core/01-discover.md`   (HARD GATE after)
- Plan → `core/02-plan.md`
- Design → `core/03-design.md`       (HARD GATE after)
- Implement → `core/04-implement.md`
- Verify → `core/05-verify.md`       (flows automatically after Implement)
- Go-to-Market → `core/06-gtm.md`    (HARD GATE before starting)

## Triggers
"start ship", "resume the workflow", "run the discover/plan/design/implement/
verify/gtm phase", or any `/ship-*` request.
