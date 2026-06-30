# ship — Reusable Project Lifecycle Workflow

`ship` takes a project from idea to go-to-market through six gated phases,
usable with **any** coding agent or chat tool. The phase prompts in `core/` are
the single source of truth; thin adapters let each tool invoke them natively.

## The six phases

| # | Phase | Output artifact | Gate |
|---|---|---|---|
| 1 | Discover (brainstorm + ideate) | `.workflow/01-brief.md` | stop & approve after |
| 2 | Plan / Architect | `.workflow/02-plan.md` | flows |
| 3 | Design | `.workflow/03-design.md` | stop & approve after |
| 4 | Implement | `.workflow/04-implementation.md` | flows |
| 5 | Verify (QA + bug hunt) | `.workflow/05-verify.md` | flows (auto after Implement) |
| 6 | Go-to-Market | `.workflow/06-gtm.md` | stop & approve before |

## How it works
- Each project you apply ship to gets a `.workflow/` folder (the **artifact
  trail**). `state.md` is the spine: it records the current phase, gates passed,
  and an index of artifacts — so any tool can resume by reading it.
- `core/_conventions.md` defines the phase contract, gate protocol, and
  `state.md` schema. Everything obeys it.
- **Information currency:** every phase verifies external facts (versions, APIs,
  pricing, policies) against current sources and records them in the artifact's
  `## Sources` section; unverifiable claims are flagged, never silently trusted.

## Using it

**Claude Code:** install `adapters/claude-code/` (skill + `/ship-*` commands),
then run `/ship-bootstrap`, `/ship-discover`, … in your project.

**Codex / Cursor / Copilot and other agent tools:** point them at
`adapters/agents/AGENTS.md`.

**Any chat tool (ChatGPT, Gemini, …):** follow `adapters/generic/USAGE.md` —
copy `templates/workflow/` into your project and paste the phase prompts.

## Verify the toolkit
```bash
./tests/check.sh
```

## Layout
- `core/` — canonical phase prompts (single source of truth)
- `adapters/` — thin per-tool entry points
- `templates/workflow/` — copied into a target project as `.workflow/`
- `tests/check.sh` — structural regression check
- `docs/superpowers/` — design spec and this plan
