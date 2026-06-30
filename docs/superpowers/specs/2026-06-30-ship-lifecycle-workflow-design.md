# ship — Reusable Project Lifecycle Workflow

**Date:** 2026-06-30
**Status:** Approved design (pre-implementation)
**Location:** `/home/dokimazo-tech/dev247/ship` (own git repo)

## Purpose

A reusable, tool-agnostic workflow that carries a project through its entire
lifecycle — from first idea to going to market — usable with **any** coding
agent or chat tool (Claude Code, Codex, Cursor, Copilot, ChatGPT, Gemini, …).

Optimized for software projects but adaptable to non-software ventures.

## Goals

- One canonical set of phase prompts that works in any tool ("single source of truth").
- Durable, resumable, git-friendly per-project state — switch tools mid-project
  without losing context.
- Thin per-tool adapters so each tool can invoke phases natively, with **no drift**
  from the core.
- Human-in-the-loop control at the moments that matter, automatic flow elsewhere.

## Non-Goals (YAGNI)

- No build step / code generation for adapters (adapters are thin pointers).
- No Cursor `.mdc` adapter (explicitly out of scope for v1).
- No configurable-per-project gate engine (gates are fixed; see Gate Protocol).
- No tool-specific memory reliance — state is plain files.

## Key Decisions (from brainstorming)

| Decision | Choice |
|---|---|
| Form | Tool-agnostic markdown core + thin adapters |
| Target projects | Mostly software, occasionally other |
| State model | Artifact trail in a per-project `.workflow/` folder |
| Phases | 6: Discover → Plan/Architect → Design → Implement → Verify → Go-to-Market |
| Gates | Hard stops **after Discover**, **after Design**, **before Go-to-Market**; Implement→Verify flows automatically |
| Adapters | Claude Code (skill + commands), `AGENTS.md`, generic copy-paste guide |
| Sync model | Single source of truth — adapters reference `core/*.md` |
| Name | `ship` (commands `/ship-discover`, etc.) |

## Architecture — Two Layers

### Layer 1: The toolkit (this repo, built once)

```
ship/
  README.md                  # the playbook: what it is, the 6 phases, gate rules, how to use
  core/                      # ★ SINGLE SOURCE OF TRUTH — canonical phase prompts
    _conventions.md          #   shared: artifact format, gate protocol, resume rules, state.md schema
    00-bootstrap.md          #   scaffolds a target project's .workflow/ trail
    01-discover.md           #   brainstorm + ideate     → 01-brief.md           [GATE after]
    02-plan.md               #   plan / architect        → 02-plan.md
    03-design.md             #   design                  → 03-design.md          [GATE after]
    04-implement.md          #   implement               → 04-implementation.md
    05-verify.md             #   QA + bug-hunt           → 05-verify.md  (auto after implement)
    06-gtm.md                #   marketing / sales       → 06-gtm.md             [GATE before]
  adapters/
    claude-code/             # thin skill + /ship-* commands that READ core/*.md
    agents/AGENTS.md         # universal entries referencing core/*.md
    generic/USAGE.md         # copy-paste guide for any chat tool
  templates/workflow/        # the files copied into a target project's .workflow/
    state.md
    01-brief.md … 06-gtm.md  # empty templates with required section headers
  docs/superpowers/specs/    # this design + future specs
```

### Layer 2: The artifact trail (created fresh in each target project)

```
<target-project>/.workflow/
  state.md            # current phase + gate status + artifact index (the "spine")
  01-brief.md
  02-plan.md
  03-design.md
  04-implementation.md
  05-verify.md
  06-gtm.md
```

`state.md` is the single file an agent reads to know **where we are**. This is
what makes the workflow resumable and portable across tools.

## The Six Phases

| # | Phase | Does | Output | Gate |
|---|---|---|---|---|
| 1 | **Discover** | Brainstorm + ideate: explore intent, requirements, success criteria, options | `01-brief.md` | **Stop & approve** |
| 2 | **Plan / Architect** | Decompose into work; choose architecture & tech; sequence | `02-plan.md` | flow |
| 3 | **Design** | Component/interface/data/UX design; contracts | `03-design.md` | **Stop & approve** |
| 4 | **Implement** | Build per the design; log decisions & changes | `04-implementation.md` | flow |
| 5 | **Verify** | QA + bug-hunt on the freshly built code; record issues & fixes | `05-verify.md` | flow (auto after Implement) |
| 6 | **Go-to-Market** | Positioning, messaging, launch & sales assets | `06-gtm.md` | **Stop & approve before starting** |

## Phase-Prompt Contract

Every `core/NN-*.md` has the **same shape** so any agent or human can run it:

1. **Purpose** — one line.
2. **Inputs** — which prior artifacts to read first (e.g. Design reads `01-brief.md` + `02-plan.md`).
3. **Process** — the actual instructions/questions the agent executes.
4. **Output** — exact artifact path + required section headers.
5. **Gate** — whether it stops for approval and what to present.
6. **Handoff** — what the next phase needs; how to update `state.md`.

## Gate Protocol (defined once in `_conventions.md`)

- Hard stops present the artifact and wait for an explicit "approved" before
  continuing: **after Discover**, **after Design**, and **before Go-to-Market**.
- Implement → Verify flows automatically (Verify runs on the freshly-built code).
- On approval, the running agent updates `state.md` (current phase + gate passed)
  before starting the next phase.

## `state.md` Schema (sketch)

```markdown
# Workflow State
- project: <name>
- current_phase: 03-design
- last_gate_passed: discover (2026-06-30)
- next_gate: design

## Artifacts
- [x] 01-brief.md
- [x] 02-plan.md
- [ ] 03-design.md  (in progress)
- [ ] 04-implementation.md
- [ ] 05-verify.md
- [ ] 06-gtm.md
```

## Adapters (thin — single source of truth)

- **Claude Code** (`adapters/claude-code/`): a `ship` skill that explains the flow
  + slash commands `/ship-bootstrap`, `/ship-discover`, `/ship-plan`,
  `/ship-design`, `/ship-implement`, `/ship-verify`, `/ship-gtm`. Each command body
  is essentially *"Read `core/NN.md` and execute it against this project's
  `.workflow/`."*
- **AGENTS.md** (`adapters/agents/AGENTS.md`): a section describing the workflow
  and instructing any agent to read the relevant `core/NN.md`, plus trigger phrases.
- **Generic** (`adapters/generic/USAGE.md`): "paste `core/01-discover.md` into your
  tool, proceed to `02`…", including how to maintain `.workflow/` by hand.

Changing a phase once in `core/` is reflected by every tool.

## How It's Used (lifecycle)

1. In a target project, run bootstrap (`/ship-bootstrap` in Claude Code, or copy
   `templates/workflow/` by hand) → creates `.workflow/` with `state.md`.
2. Run each phase in order. The agent reads `state.md` + prior artifacts, executes
   the phase, writes its artifact, updates `state.md`.
3. At each gate, the agent stops and presents the artifact for approval.
4. Switch tools any time — the next agent reads `state.md` and continues.

## Success Criteria

- A new project can be taken from idea → GTM using only the markdown core in any tool.
- Editing one `core/NN.md` changes behavior across all adapters with no other edits.
- A project's `.workflow/` trail is enough for a fresh agent (any tool) to resume.
- Gates stop exactly after Discover, after Design, and before Go-to-Market.

## Open Questions

- None blocking. (Detailed wording of each phase prompt is implementation work.)
