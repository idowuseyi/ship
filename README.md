# ship — Reusable Project Lifecycle Workflow

**A reusable, tool-agnostic workflow that carries a project from first idea to going to market** — usable with any coding agent or chat tool (Claude Code, Codex, Cursor, Copilot, ChatGPT, Gemini, …).

Optimized for software projects, adaptable to non-software ventures.

## Why

Most workflows are locked to one tool. `ship` keeps the workflow itself in plain
markdown — a single source of truth — with thin per-tool adapters that just point
back to it. The result:

- **One canonical set of phase prompts** that works in any tool.
- **Durable, resumable, git-friendly state** — switch tools mid-project without
  losing context.
- **No drift** — edit a phase once in `core/`, every tool reflects it.
- **Human-in-the-loop where it matters**, automatic flow elsewhere.

## The six phases

| # | Phase | Does | Output | Gate |
|---|---|---|---|---|
| 1 | **Discover** | Brainstorm + ideate: intent, requirements, success criteria, options | `01-brief.md` | **Stop & approve** |
| 2 | **Plan / Architect** | Decompose work; choose architecture & tech; sequence | `02-plan.md` | flow |
| 3 | **Design** | Component / interface / data / UX design; contracts | `03-design.md` | **Stop & approve** |
| 4 | **Implement** | Build per the design; log decisions & changes | `04-implementation.md` | flow |
| 5 | **Verify** | QA + bug-hunt the freshly built code; record issues & fixes | `05-verify.md` | flow (auto after Implement) |
| 6 | **Go-to-Market** | Positioning, messaging, launch & sales assets | `06-gtm.md` | **Stop & approve before starting** |

**Gates** are hard stops that present the artifact and wait for an explicit
"approved" before continuing: **after Discover**, **after Design**, and **before
Go-to-Market**. Implement → Verify flows automatically.

## Two layers

**Layer 1 — the toolkit (this repo):** canonical phase prompts in `core/`, thin
adapters in `adapters/`, and the files copied into a project in `templates/`.

**Layer 2 — the artifact trail (created fresh in each target project):** a
per-project `.workflow/` folder whose `state.md` is the single file an agent reads
to know *where we are*. That's what makes a project resumable and portable across
tools.

```
<target-project>/.workflow/
  state.md            # current phase + gate status + artifact index (the "spine")
  memory.md           # curated non-obvious learnings — verified-true facts only
  01-brief.md … 06-gtm.md
```

## How it works

- Each project you apply ship to gets a `.workflow/` folder (the **artifact
  trail**). `state.md` is the spine: it records the current phase, gates passed,
  and an index of artifacts — so any tool can resume by reading it.
- `core/_conventions.md` defines the phase contract, gate protocol, and
  `state.md` schema. Everything obeys it.
- **Information currency:** every phase verifies external facts (versions, APIs,
  pricing, policies) against current sources and records them in the artifact's
  `## Sources` section; unverifiable claims are flagged, never silently trusted.

## How it's used

1. In a target project, bootstrap the workflow (`/ship-bootstrap` in Claude Code,
   or copy `templates/workflow/` by hand) → creates `.workflow/` with `state.md`.
2. Run each phase in order. The agent reads `state.md` + prior artifacts, executes
   the phase, writes its artifact, and updates `state.md`.
3. At each gate, the agent stops and presents the artifact for approval.
4. Switch tools any time — the next agent reads `state.md` and continues.

## Quality is enforced, not hoped for

Gates don't pass on the model's say-so — they must clear checks the model can't
fake, so the workflow holds a quality floor even under a weak or stale model:

- **Machine gate** — `.workflow/check-gate.sh` (copied into each project, run in
  CI via `templates/ci/ship-gate.yml`) validates each artifact and runs the real
  build/test/lint; Verify is strict (tests must exist and pass); enforces a
  non-empty `## Security` (no open Critical/High findings) and secret-scans the
  working tree — including `.workflow/`.
- **Security + memory in the loop** — `core/_security-review.md` runs at the
  Design gate (trust boundaries, authn/authz, sensitive data) and as a full
  adversarial pass in Verify; `.workflow/memory.md` carries verified-true,
  non-obvious learnings across sessions — appended and pruned at every phase
  handoff.
- **Executable acceptance criteria** — Discover writes *measurable* criteria;
  Verify maps each to an automated test in a `## Acceptance` section.
- **Critic + human rubric** — every hard gate runs the adversarial review in
  `core/_gate-review.md` (ideally on a stronger model) and hands you a checklist.

Running a small/local model? See [`adapters/local/`](adapters/local/README.md) for
how to keep quality dependable regardless of which model drives.

## Using it

**Claude Code:** install `adapters/claude-code/` (the `ship` skill + `/ship-*`
commands), then run `/ship-bootstrap`, `/ship-discover`, … in your project.

**Continue (VS Code, incl. local models):** merge `adapters/continue/config.yaml`
into your Continue config — see [`adapters/continue/`](adapters/continue/README.md).

**Cline / OpenCode / Codex / Cursor and other agent tools:** point them at
`adapters/agents/AGENTS.md` (read natively by Cline and OpenCode).

**Any chat tool (ChatGPT, Gemini, …):** follow `adapters/generic/USAGE.md` —
copy `templates/workflow/` into your project and paste the phase prompts.

## Verify the toolkit

```bash
./tests/check.sh
```

## Layout

- `core/` — canonical phase prompts (single source of truth)
- `adapters/` — thin per-tool entry points (Claude Code, `AGENTS.md`, generic)
- `templates/workflow/` — copied into a target project as `.workflow/`
- `tests/check.sh` — structural regression check
- `docs/superpowers/` — design spec and implementation plan

## Documentation

- [Design spec](docs/superpowers/specs/2026-06-30-ship-lifecycle-workflow-design.md)
- [Implementation plan](docs/superpowers/plans/2026-06-30-ship-lifecycle-workflow.md)
