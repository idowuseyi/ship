# ship — Lifecycle Workflow Toolkit Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a reusable, tool-agnostic project-lifecycle workflow (`ship`) whose canonical markdown phase prompts drive a project from idea → go-to-market in any coding agent, with thin per-tool adapters and a durable per-project artifact trail.

**Architecture:** A single-source-of-truth `core/` of six markdown phase prompts plus a shared `_conventions.md`. Thin adapters (Claude Code skill+commands, `AGENTS.md`, generic guide) reference `core/` rather than restating it. A `templates/workflow/` folder is copied into each target project as `.workflow/`, where `state.md` is the resumable spine. Verification is structural: shell assertions consolidated into `tests/check.sh`.

**Tech Stack:** Markdown (content), Bash (verification harness), git (versioning). No language runtime or package manager.

## Global Constraints

- Toolkit repo root: `/home/dokimazo-tech/dev247/ship` (already `git init`-ed; spec committed).
- Name is `ship`; Claude Code commands are `/ship-<phase>` (`bootstrap`, `discover`, `plan`, `design`, `implement`, `verify`, `gtm`).
- Six phases, fixed order: `01-discover` → `02-plan` → `03-design` → `04-implement` → `05-verify` → `06-gtm`.
- Gates (hard stop, present artifact, wait for explicit "approved"): **after Discover**, **after Design**, **before Go-to-Market**. Implement → Verify flows automatically.
- Per-project artifacts live in the **target project's** `.workflow/`, never in this toolkit repo.
- Single source of truth: adapters must reference `core/NN-*.md` paths, never duplicate phase instructions.
- Every `core/NN-*.md` phase prompt MUST contain these six section headers verbatim: `## Purpose`, `## Inputs`, `## Process`, `## Output`, `## Gate`, `## Handoff`.
- Artifact filenames in `.workflow/`: `state.md`, `01-brief.md`, `02-plan.md`, `03-design.md`, `04-implementation.md`, `05-verify.md`, `06-gtm.md`.
- Commit after every task. Co-author trailer: `Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>`.

---

## File Structure

```
ship/
  README.md                              # Task 8 — the playbook
  core/
    _conventions.md                      # Task 1 — shared contract, gate protocol, state schema
    00-bootstrap.md                      # Task 2 — scaffolds target .workflow/
    01-discover.md                       # Task 3
    02-plan.md                           # Task 3
    03-design.md                         # Task 4
    04-implement.md                      # Task 4
    05-verify.md                         # Task 5
    06-gtm.md                            # Task 5
  adapters/
    claude-code/
      skills/ship/SKILL.md               # Task 6
      commands/ship-bootstrap.md         # Task 6
      commands/ship-discover.md          # Task 6
      commands/ship-plan.md              # Task 6
      commands/ship-design.md            # Task 6
      commands/ship-implement.md         # Task 6
      commands/ship-verify.md            # Task 6
      commands/ship-gtm.md               # Task 6
    agents/AGENTS.md                     # Task 7
    generic/USAGE.md                     # Task 7
  templates/workflow/
    state.md                             # Task 2
    01-brief.md 02-plan.md 03-design.md  # Task 2
    04-implementation.md 05-verify.md 06-gtm.md   # Task 2
  tests/check.sh                         # Task 8 — consolidated regression assertions
```

Each `core/NN-*.md` has one responsibility (one phase). Adapters are thin pointers. Templates are content-free scaffolds. This keeps every file focused and individually editable.

---

### Task 1: Conventions — the shared contract

**Files:**
- Create: `core/_conventions.md`

**Interfaces:**
- Produces: the canonical definitions every other file references — the six-section phase-prompt contract, the gate protocol, the `state.md` schema, artifact filenames, and resume rules. Later tasks cite this file by path.

- [ ] **Step 1: Write the failing verification**

Run:
```bash
cd /home/dokimazo-tech/dev247/ship
test -f core/_conventions.md && grep -q '## Phase-Prompt Contract' core/_conventions.md \
  && grep -q '## Gate Protocol' core/_conventions.md \
  && grep -q '## state.md Schema' core/_conventions.md \
  && echo PASS || echo FAIL
```
Expected: `FAIL` (file does not exist yet).

- [ ] **Step 2: Create `core/_conventions.md`**

````markdown
# ship — Conventions

Shared rules every phase prompt and adapter relies on. This file is the single
source of truth for the workflow's mechanics.

## Phase-Prompt Contract

Every phase prompt in `core/NN-<phase>.md` has exactly these six sections, in order:

1. `## Purpose` — one line: what this phase achieves.
2. `## Inputs` — which prior `.workflow/` artifacts to read before starting.
3. `## Process` — the concrete steps/questions the agent runs.
4. `## Output` — exact artifact path written, plus its required section headers.
5. `## Gate` — whether the phase stops for human approval, and what to present.
6. `## Handoff` — what the next phase needs, and the `state.md` update to make.

## The Artifact Trail

A project under the workflow has a `.workflow/` directory containing:

| File | Written by | Purpose |
|---|---|---|
| `state.md` | every phase | current phase + gate status + artifact index (the spine) |
| `01-brief.md` | Discover | problem, users, requirements, success criteria, chosen direction |
| `02-plan.md` | Plan/Architect | work breakdown, architecture, tech choices, sequence |
| `03-design.md` | Design | components, interfaces, data, UX, contracts |
| `04-implementation.md` | Implement | build log: decisions, files changed, deviations |
| `05-verify.md` | Verify | QA results, bugs found, fixes, residual risks |
| `06-gtm.md` | Go-to-Market | positioning, messaging, launch & sales assets |

Artifacts are append-friendly markdown. An agent in any tool reconstructs full
context by reading `state.md` then the listed artifacts.

## Gate Protocol

Three hard gates. At a hard gate the agent MUST: write the artifact, present a
short summary, and stop with the line:

> **GATE — reply `approved` to continue, or tell me what to change.**

- **After Discover** (gate on `01-brief.md`).
- **After Design** (gate on `03-design.md`).
- **Before Go-to-Market** (gate before starting `06-gtm.md`; present the plan to proceed).

All other transitions flow automatically. In particular **Implement → Verify**
runs without stopping: after `04-implementation.md` is written, proceed directly
to Verify.

On `approved`, update `state.md` (`last_gate_passed`, advance `current_phase`)
before starting the next phase.

## state.md Schema

```markdown
# Workflow State
- project: <name>
- current_phase: <NN-phase>        # e.g. 03-design
- last_gate_passed: <phase|none>   # e.g. discover
- next_gate: <phase|none>          # e.g. design

## Artifacts
- [ ] 01-brief.md
- [ ] 02-plan.md
- [ ] 03-design.md
- [ ] 04-implementation.md
- [ ] 05-verify.md
- [ ] 06-gtm.md

## Log
- <date> — <one-line note of what happened>
```

Check a box when its artifact is written. Append one `## Log` line per phase.

## Resume Rules

To resume in any tool: read `.workflow/state.md`, then read every checked
artifact, then open `core/<current_phase>.md` and continue its `## Process`.
If `current_phase` sits at a passed gate awaiting approval, re-present the gate.

## Adaptation

Optimized for software. For a non-software venture, treat "Implement" as
"build the real-world thing" and keep the same artifacts; skip sections that
don't apply rather than inventing software structure.
````

- [ ] **Step 3: Run the verification to confirm it passes**

Run:
```bash
cd /home/dokimazo-tech/dev247/ship
test -f core/_conventions.md && grep -q '## Phase-Prompt Contract' core/_conventions.md \
  && grep -q '## Gate Protocol' core/_conventions.md \
  && grep -q '## state.md Schema' core/_conventions.md \
  && echo PASS || echo FAIL
```
Expected: `PASS`.

- [ ] **Step 4: Commit**

```bash
cd /home/dokimazo-tech/dev247/ship
git add core/_conventions.md
git commit -m "feat: add shared conventions (contract, gates, state schema)

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

### Task 2: Bootstrap prompt + project templates

**Files:**
- Create: `core/00-bootstrap.md`
- Create: `templates/workflow/state.md`
- Create: `templates/workflow/01-brief.md`
- Create: `templates/workflow/02-plan.md`
- Create: `templates/workflow/03-design.md`
- Create: `templates/workflow/04-implementation.md`
- Create: `templates/workflow/05-verify.md`
- Create: `templates/workflow/06-gtm.md`

**Interfaces:**
- Consumes: `core/_conventions.md` (state schema, artifact filenames).
- Produces: `templates/workflow/` (copied into a target project as `.workflow/`) and `core/00-bootstrap.md` (the prompt that performs the copy + fills `state.md`).

- [ ] **Step 1: Write the failing verification**

Run:
```bash
cd /home/dokimazo-tech/dev247/ship
ok=1
test -f core/00-bootstrap.md || ok=0
for f in state 01-brief 02-plan 03-design 04-implementation 05-verify 06-gtm; do
  test -f "templates/workflow/$f.md" || ok=0
done
grep -q '# Workflow State' templates/workflow/state.md 2>/dev/null || ok=0
[ $ok -eq 1 ] && echo PASS || echo FAIL
```
Expected: `FAIL`.

- [ ] **Step 2: Create `templates/workflow/state.md`**

```markdown
# Workflow State
- project: <PROJECT_NAME>
- current_phase: 01-discover
- last_gate_passed: none
- next_gate: discover

## Artifacts
- [ ] 01-brief.md
- [ ] 02-plan.md
- [ ] 03-design.md
- [ ] 04-implementation.md
- [ ] 05-verify.md
- [ ] 06-gtm.md

## Log
- <date> — workflow bootstrapped
```

- [ ] **Step 3: Create the six artifact templates**

Each is an empty scaffold with the required section headers. Create exactly these files:

`templates/workflow/01-brief.md`:
```markdown
# 01 — Discovery Brief
## Problem
## Users & Context
## Requirements
## Success Criteria
## Options Considered
## Chosen Direction
```

`templates/workflow/02-plan.md`:
```markdown
# 02 — Plan / Architecture
## Work Breakdown
## Architecture
## Tech Choices
## Sequence & Milestones
## Risks
```

`templates/workflow/03-design.md`:
```markdown
# 03 — Design
## Components
## Interfaces & Contracts
## Data
## UX / Flows
## Error Handling
```

`templates/workflow/04-implementation.md`:
```markdown
# 04 — Implementation Log
## Files Changed
## Key Decisions
## Deviations from Design
## How to Run
```

`templates/workflow/05-verify.md`:
```markdown
# 05 — Verify (QA + Bug Hunt)
## Test Coverage
## Bugs Found
## Fixes Applied
## Residual Risks
```

`templates/workflow/06-gtm.md`:
```markdown
# 06 — Go-to-Market
## Positioning
## Audience & Channels
## Messaging
## Launch Assets
## Sales / Next Steps
```

- [ ] **Step 4: Create `core/00-bootstrap.md`**

````markdown
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
3. Copy every file from `ship/templates/workflow/` into `<target>/.workflow/`.
4. In `<target>/.workflow/state.md`, replace `<PROJECT_NAME>` with the project's
   name and `<date>` with today's date.
5. Report the created files and tell the user the next step is the Discover phase.

## Output
- Directory `<target>/.workflow/` containing `state.md` and the six artifact
  templates from `_conventions.md`'s artifact table.

## Gate
None. Bootstrap is setup only; proceed when done.

## Handoff
Next phase is `01-discover`. `state.md` already points `current_phase` at
`01-discover` with `next_gate: discover`.
````

- [ ] **Step 5: Run the verification to confirm it passes**

Run:
```bash
cd /home/dokimazo-tech/dev247/ship
ok=1
test -f core/00-bootstrap.md || ok=0
for f in state 01-brief 02-plan 03-design 04-implementation 05-verify 06-gtm; do
  test -f "templates/workflow/$f.md" || ok=0
done
grep -q '# Workflow State' templates/workflow/state.md || ok=0
[ $ok -eq 1 ] && echo PASS || echo FAIL
```
Expected: `PASS`.

- [ ] **Step 6: Commit**

```bash
cd /home/dokimazo-tech/dev247/ship
git add core/00-bootstrap.md templates/workflow/
git commit -m "feat: add bootstrap prompt and project artifact templates

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

### Task 3: Discover + Plan phase prompts

**Files:**
- Create: `core/01-discover.md`
- Create: `core/02-plan.md`

**Interfaces:**
- Consumes: `core/_conventions.md` (contract, gate protocol).
- Produces: `01-brief.md` (Discover, gated) and `02-plan.md` (Plan, flows) prompts. Both carry the six contract headers.

- [ ] **Step 1: Write the failing verification**

Run:
```bash
cd /home/dokimazo-tech/dev247/ship
check_contract() {  # $1 = file
  for h in '## Purpose' '## Inputs' '## Process' '## Output' '## Gate' '## Handoff'; do
    grep -qF "$h" "$1" || return 1
  done
}
ok=1
for f in core/01-discover.md core/02-plan.md; do test -f "$f" && check_contract "$f" || ok=0; done
grep -qi 'reply `approved`' core/01-discover.md 2>/dev/null || ok=0   # Discover is gated
[ $ok -eq 1 ] && echo PASS || echo FAIL
```
Expected: `FAIL`.

- [ ] **Step 2: Create `core/01-discover.md`**

````markdown
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

## Output
`.workflow/01-brief.md` with: `## Problem`, `## Users & Context`,
`## Requirements`, `## Success Criteria`, `## Options Considered`,
`## Chosen Direction`.

## Gate
HARD GATE. Present a 3–5 line summary of the brief, then stop:
> **GATE — reply `approved` to continue, or tell me what to change.**

## Handoff
On `approved`: in `state.md` set `last_gate_passed: discover`,
`current_phase: 02-plan`, `next_gate: design`, check `01-brief.md`, add a Log
line. Next phase is `02-plan`.
````

- [ ] **Step 3: Create `core/02-plan.md`**

````markdown
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
````

- [ ] **Step 4: Run the verification to confirm it passes**

Run the Step 1 command. Expected: `PASS`.

- [ ] **Step 5: Commit**

```bash
cd /home/dokimazo-tech/dev247/ship
git add core/01-discover.md core/02-plan.md
git commit -m "feat: add Discover and Plan phase prompts

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

### Task 4: Design + Implement phase prompts

**Files:**
- Create: `core/03-design.md`
- Create: `core/04-implement.md`

**Interfaces:**
- Consumes: `core/_conventions.md`, `02-plan.md` artifact.
- Produces: `03-design.md` (Design, gated) and `04-implementation.md` (Implement, flows to Verify) prompts.

- [ ] **Step 1: Write the failing verification**

Run:
```bash
cd /home/dokimazo-tech/dev247/ship
check_contract() { for h in '## Purpose' '## Inputs' '## Process' '## Output' '## Gate' '## Handoff'; do grep -qF "$h" "$1" || return 1; done; }
ok=1
for f in core/03-design.md core/04-implement.md; do test -f "$f" && check_contract "$f" || ok=0; done
grep -qi 'reply `approved`' core/03-design.md 2>/dev/null || ok=0           # Design is gated
grep -qi 'proceed directly to.*verify' core/04-implement.md 2>/dev/null || ok=0  # Implement auto-flows
[ $ok -eq 1 ] && echo PASS || echo FAIL
```
Expected: `FAIL`.

- [ ] **Step 2: Create `core/03-design.md`**

````markdown
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
````

- [ ] **Step 3: Create `core/04-implement.md`**

````markdown
# Phase 04 — Implement

## Purpose
Build the project per the approved design, logging decisions and changes.

## Inputs
- `.workflow/03-design.md` (the contract to build to).
- `.workflow/02-plan.md` (sequence).
- `.workflow/state.md`.

## Process
1. Implement in the sequence from the plan, following the design's interfaces.
2. Prefer test-driven steps where a runtime exists; keep changes small and committed.
3. Record files changed, key decisions, and any deviation from the design (with why).
4. Write `.workflow/04-implementation.md` using its template sections.

## Output
`.workflow/04-implementation.md` with: `## Files Changed`, `## Key Decisions`,
`## Deviations from Design`, `## How to Run`.

## Gate
None. When implementation is complete, **proceed directly to Verify**
(`05-verify`) without stopping.

## Handoff
In `state.md` set `current_phase: 05-verify`, check `04-implementation.md`, add a
Log line. Next phase is `05-verify`.
````

- [ ] **Step 4: Run the verification to confirm it passes**

Run the Step 1 command. Expected: `PASS`.

- [ ] **Step 5: Commit**

```bash
cd /home/dokimazo-tech/dev247/ship
git add core/03-design.md core/04-implement.md
git commit -m "feat: add Design and Implement phase prompts

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

### Task 5: Verify + Go-to-Market phase prompts

**Files:**
- Create: `core/05-verify.md`
- Create: `core/06-gtm.md`

**Interfaces:**
- Consumes: `core/_conventions.md`, `04-implementation.md` artifact.
- Produces: `05-verify.md` (Verify, flows) and `06-gtm.md` (GTM, gated *before* starting) prompts.

- [ ] **Step 1: Write the failing verification**

Run:
```bash
cd /home/dokimazo-tech/dev247/ship
check_contract() { for h in '## Purpose' '## Inputs' '## Process' '## Output' '## Gate' '## Handoff'; do grep -qF "$h" "$1" || return 1; done; }
ok=1
for f in core/05-verify.md core/06-gtm.md; do test -f "$f" && check_contract "$f" || ok=0; done
grep -qi 'reply `approved`' core/06-gtm.md 2>/dev/null || ok=0   # GTM gated before
[ $ok -eq 1 ] && echo PASS || echo FAIL
```
Expected: `FAIL`.

- [ ] **Step 2: Create `core/05-verify.md`**

````markdown
# Phase 05 — Verify (QA + Bug Hunt)

## Purpose
Exercise the built project, hunt for bugs, and record results and fixes.

## Inputs
- `.workflow/04-implementation.md` (what was built, how to run).
- `.workflow/03-design.md` (intended behavior to check against).
- `.workflow/state.md`.

## Process
1. Derive test cases from the brief's success criteria and the design's contracts.
2. Run the project; cover happy paths, edge cases, and the listed error modes.
3. Hunt for bugs: boundary inputs, race conditions, silent failures, wrong
   error handling. For each bug, note repro, severity, and fix.
4. Apply fixes (re-entering Implement conventions as needed); re-test.
5. Write `.workflow/05-verify.md` using its template sections.

## Output
`.workflow/05-verify.md` with: `## Test Coverage`, `## Bugs Found`,
`## Fixes Applied`, `## Residual Risks`.

## Gate
None during Verify. But the **next** phase (Go-to-Market) is gated: do not start
it automatically.

## Handoff
In `state.md` set `current_phase: 06-gtm`, check `05-verify.md`, add a Log line.
Then present the Go-to-Market gate (see `06-gtm`).
````

- [ ] **Step 3: Create `core/06-gtm.md`**

````markdown
# Phase 06 — Go-to-Market

## Purpose
Position the finished project and produce launch and sales assets.

## Inputs
- `.workflow/01-brief.md` (problem, users, success criteria).
- `.workflow/05-verify.md` (what's proven to work).
- `.workflow/state.md`.

## Gate
HARD GATE — this gate fires **before** starting. Present a short plan of the GTM
assets you intend to create and stop:
> **GATE — reply `approved` to continue, or tell me what to change.**

## Process
(After approval.)
1. Define positioning: the one-line value proposition and target audience.
2. Choose channels and craft messaging tailored to each.
3. Draft launch assets (e.g. landing copy, announcement, demo script).
4. Outline sales next steps (outreach, pricing notes, objections/answers).
5. Write `.workflow/06-gtm.md` using its template sections.

## Output
`.workflow/06-gtm.md` with: `## Positioning`, `## Audience & Channels`,
`## Messaging`, `## Launch Assets`, `## Sales / Next Steps`.

## Handoff
In `state.md` set `last_gate_passed: gtm`, `current_phase: done`,
`next_gate: none`, check `06-gtm.md`, add a Log line. The workflow is complete.
````

- [ ] **Step 4: Run the verification to confirm it passes**

Run the Step 1 command. Expected: `PASS`.

- [ ] **Step 5: Commit**

```bash
cd /home/dokimazo-tech/dev247/ship
git add core/05-verify.md core/06-gtm.md
git commit -m "feat: add Verify and Go-to-Market phase prompts

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

### Task 6: Claude Code adapter (skill + slash commands)

**Files:**
- Create: `adapters/claude-code/skills/ship/SKILL.md`
- Create: `adapters/claude-code/commands/ship-bootstrap.md`
- Create: `adapters/claude-code/commands/ship-discover.md`
- Create: `adapters/claude-code/commands/ship-plan.md`
- Create: `adapters/claude-code/commands/ship-design.md`
- Create: `adapters/claude-code/commands/ship-implement.md`
- Create: `adapters/claude-code/commands/ship-verify.md`
- Create: `adapters/claude-code/commands/ship-gtm.md`

**Interfaces:**
- Consumes: all `core/*.md`.
- Produces: thin Claude Code entry points. Each command instructs the agent to read the matching `core/NN-*.md` (resolved relative to the `ship` repo) and execute it against the target project's `.workflow/`. No phase instructions are duplicated.

- [ ] **Step 1: Write the failing verification**

Run:
```bash
cd /home/dokimazo-tech/dev247/ship
ok=1
test -f adapters/claude-code/skills/ship/SKILL.md || ok=0
grep -q '^name:' adapters/claude-code/skills/ship/SKILL.md 2>/dev/null || ok=0
grep -q '^description:' adapters/claude-code/skills/ship/SKILL.md 2>/dev/null || ok=0
declare -A map=( [bootstrap]=00-bootstrap [discover]=01-discover [plan]=02-plan [design]=03-design [implement]=04-implement [verify]=05-verify [gtm]=06-gtm )
for k in "${!map[@]}"; do
  f="adapters/claude-code/commands/ship-$k.md"
  test -f "$f" || ok=0
  grep -q "core/${map[$k]}.md" "$f" 2>/dev/null || ok=0   # references the core file
done
[ $ok -eq 1 ] && echo PASS || echo FAIL
```
Expected: `FAIL`.

- [ ] **Step 2: Create `adapters/claude-code/skills/ship/SKILL.md`**

```markdown
---
name: ship
description: Use to run the ship project-lifecycle workflow — taking a project from idea through go-to-market in six gated phases (Discover, Plan, Design, Implement, Verify, Go-to-Market). Use when the user wants to start, resume, or advance a project using ship, or mentions /ship-* commands.
---

# ship — Project Lifecycle Workflow

`ship` drives a project from idea to market through six phases backed by a
durable `.workflow/` artifact trail. The canonical prompts live in this repo's
`core/` directory; this skill and the `/ship-*` commands are thin entry points.

## How to use
1. **Resume awareness:** if the target project has `.workflow/state.md`, read it
   first and continue from `current_phase`. Otherwise start with bootstrap.
2. Run phases in order via the slash commands:
   `/ship-bootstrap` → `/ship-discover` → `/ship-plan` → `/ship-design` →
   `/ship-implement` → `/ship-verify` → `/ship-gtm`.
3. Always obey `core/_conventions.md` — especially the Gate Protocol (hard stops
   after Discover, after Design, and before Go-to-Market).

## Mechanics
Each command reads the matching `core/NN-<phase>.md` and executes it against the
target project's `.workflow/`. Never duplicate phase instructions here; the
`core/` files are the single source of truth.
```

- [ ] **Step 3: Create the seven command files**

Each command file follows the same thin pattern. Create them with this content (substitute the phase file per the table in Step 1):

`adapters/claude-code/commands/ship-bootstrap.md`:
```markdown
---
description: ship — Bootstrap the .workflow/ trail in the current project
---

Read `core/00-bootstrap.md` from the ship toolkit repo and execute it against
the current target project. Follow `core/_conventions.md`. If you cannot locate
the ship repo, ask the user for its path.
```

`adapters/claude-code/commands/ship-discover.md`:
```markdown
---
description: ship — Run the Discover phase (brainstorm + ideate)
---

Read `core/01-discover.md` from the ship toolkit repo and execute it against the
current project's `.workflow/`. First read `.workflow/state.md`. Obey the Gate
Protocol in `core/_conventions.md`.
```

`adapters/claude-code/commands/ship-plan.md`:
```markdown
---
description: ship — Run the Plan / Architect phase
---

Read `core/02-plan.md` from the ship toolkit repo and execute it against the
current project's `.workflow/`. First read `.workflow/state.md`. Obey the Gate
Protocol in `core/_conventions.md`.
```

`adapters/claude-code/commands/ship-design.md`:
```markdown
---
description: ship — Run the Design phase
---

Read `core/03-design.md` from the ship toolkit repo and execute it against the
current project's `.workflow/`. First read `.workflow/state.md`. Obey the Gate
Protocol in `core/_conventions.md`.
```

`adapters/claude-code/commands/ship-implement.md`:
```markdown
---
description: ship — Run the Implement phase
---

Read `core/04-implement.md` from the ship toolkit repo and execute it against the
current project's `.workflow/`. First read `.workflow/state.md`. Obey the Gate
Protocol in `core/_conventions.md`.
```

`adapters/claude-code/commands/ship-verify.md`:
```markdown
---
description: ship — Run the Verify phase (QA + bug hunt)
---

Read `core/05-verify.md` from the ship toolkit repo and execute it against the
current project's `.workflow/`. First read `.workflow/state.md`. Obey the Gate
Protocol in `core/_conventions.md`.
```

`adapters/claude-code/commands/ship-gtm.md`:
```markdown
---
description: ship — Run the Go-to-Market phase
---

Read `core/06-gtm.md` from the ship toolkit repo and execute it against the
current project's `.workflow/`. First read `.workflow/state.md`. Obey the Gate
Protocol in `core/_conventions.md`.
```

- [ ] **Step 4: Run the verification to confirm it passes**

Run the Step 1 command. Expected: `PASS`.

- [ ] **Step 5: Commit**

```bash
cd /home/dokimazo-tech/dev247/ship
git add adapters/claude-code/
git commit -m "feat: add Claude Code adapter (ship skill + slash commands)

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

### Task 7: AGENTS.md + generic copy-paste adapters

**Files:**
- Create: `adapters/agents/AGENTS.md`
- Create: `adapters/generic/USAGE.md`

**Interfaces:**
- Consumes: all `core/*.md`.
- Produces: a universal `AGENTS.md` entry and a generic guide, both referencing `core/` by path.

- [ ] **Step 1: Write the failing verification**

Run:
```bash
cd /home/dokimazo-tech/dev247/ship
ok=1
for f in adapters/agents/AGENTS.md adapters/generic/USAGE.md; do
  test -f "$f" || ok=0
  grep -q 'core/01-discover.md' "$f" 2>/dev/null || ok=0
  grep -q '_conventions.md' "$f" 2>/dev/null || ok=0
done
[ $ok -eq 1 ] && echo PASS || echo FAIL
```
Expected: `FAIL`.

- [ ] **Step 2: Create `adapters/agents/AGENTS.md`**

```markdown
# ship — Lifecycle Workflow (for any agent)

This project may use the `ship` workflow. If a `.workflow/` directory exists,
follow it; if the user asks to start/resume/advance with ship, follow it.

## Rules
- The single source of truth is the ship repo's `core/` directory. Read
  `core/_conventions.md` for the phase contract, gate protocol, and `state.md`
  schema. Never duplicate or improvise phase logic.
- Always read `.workflow/state.md` first to learn the current phase, then read
  the checked artifacts, then execute the current phase's `core/NN-*.md`.

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
```

- [ ] **Step 3: Create `adapters/generic/USAGE.md`**

```markdown
# Using ship in any chat tool (copy-paste)

No integration required — ship is plain markdown. Use it in ChatGPT, Gemini, or
any agent like this.

## One-time per project
1. Create a `.workflow/` folder in your project.
2. Copy the files from the ship repo's `templates/workflow/` into it.
3. In `state.md`, set the project name and date.

## Running a phase
1. Paste the contents of `core/_conventions.md` (once per session) so the tool
   knows the rules.
2. Paste the current `.workflow/state.md` and any artifacts it lists as done.
3. Paste the phase prompt for where you are:
   - Discover → `core/01-discover.md`
   - Plan → `core/02-plan.md`
   - Design → `core/03-design.md`
   - Implement → `core/04-implement.md`
   - Verify → `core/05-verify.md`
   - Go-to-Market → `core/06-gtm.md`
4. Do what the phase says, save its artifact into `.workflow/`, and update
   `state.md`.

## Gates
Stop for your own approval after Discover, after Design, and before
Go-to-Market. Implement flows straight into Verify.

## Switching tools mid-project
Because everything lives in `.workflow/`, you can switch tools any time: open the
new tool, paste `state.md` + the done artifacts + the current phase prompt, and
continue.
```

- [ ] **Step 4: Run the verification to confirm it passes**

Run the Step 1 command. Expected: `PASS`.

- [ ] **Step 5: Commit**

```bash
cd /home/dokimazo-tech/dev247/ship
git add adapters/agents/ adapters/generic/
git commit -m "feat: add AGENTS.md and generic copy-paste adapters

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

### Task 8: README playbook + consolidated regression check

**Files:**
- Create: `README.md`
- Create: `tests/check.sh`

**Interfaces:**
- Consumes: the whole repo.
- Produces: the human-facing playbook and a single `tests/check.sh` that re-runs every structural assertion from Tasks 1–7 (the regression suite).

- [ ] **Step 1: Create `tests/check.sh`**

```bash
#!/usr/bin/env bash
# Structural regression check for the ship toolkit. Run from repo root.
set -u
cd "$(dirname "$0")/.." || exit 1
fail=0
note() { echo "FAIL: $1"; fail=1; }

# Task 1 — conventions
for h in '## Phase-Prompt Contract' '## Gate Protocol' '## state.md Schema'; do
  grep -qF "$h" core/_conventions.md || note "_conventions.md missing '$h'"
done

# Task 2 — bootstrap + templates
test -f core/00-bootstrap.md || note "missing core/00-bootstrap.md"
for f in state 01-brief 02-plan 03-design 04-implementation 05-verify 06-gtm; do
  test -f "templates/workflow/$f.md" || note "missing templates/workflow/$f.md"
done
grep -q '# Workflow State' templates/workflow/state.md || note "state.md template malformed"

# Tasks 3-5 — phase prompts carry the six-section contract
for f in core/01-discover.md core/02-plan.md core/03-design.md core/04-implement.md core/05-verify.md core/06-gtm.md; do
  test -f "$f" || { note "missing $f"; continue; }
  for h in '## Purpose' '## Inputs' '## Process' '## Output' '## Gate' '## Handoff'; do
    grep -qF "$h" "$f" || note "$f missing '$h'"
  done
done
grep -qi 'reply `approved`' core/01-discover.md || note "Discover not gated"
grep -qi 'reply `approved`' core/03-design.md   || note "Design not gated"
grep -qi 'reply `approved`' core/06-gtm.md      || note "GTM not gated"
grep -qi 'proceed directly to.*verify' core/04-implement.md || note "Implement should auto-flow to Verify"

# Task 6 — Claude Code adapter references core files
test -f adapters/claude-code/skills/ship/SKILL.md || note "missing ship SKILL.md"
declare -A map=( [bootstrap]=00-bootstrap [discover]=01-discover [plan]=02-plan [design]=03-design [implement]=04-implement [verify]=05-verify [gtm]=06-gtm )
for k in "${!map[@]}"; do
  f="adapters/claude-code/commands/ship-$k.md"
  test -f "$f" || { note "missing $f"; continue; }
  grep -q "core/${map[$k]}.md" "$f" || note "$f does not reference core/${map[$k]}.md"
done

# Task 7 — universal adapters reference core
for f in adapters/agents/AGENTS.md adapters/generic/USAGE.md; do
  grep -q 'core/01-discover.md' "$f" || note "$f missing core reference"
  grep -q '_conventions.md' "$f"     || note "$f missing _conventions reference"
done

if [ $fail -eq 0 ]; then echo "ALL CHECKS PASS"; else echo "CHECKS FAILED"; exit 1; fi
```

- [ ] **Step 2: Make it executable and run it (expect failure until README exists is NOT required — README is not checked, so it should already pass)**

Run:
```bash
cd /home/dokimazo-tech/dev247/ship
chmod +x tests/check.sh
./tests/check.sh
```
Expected: `ALL CHECKS PASS` (Tasks 1–7 are complete by now).

- [ ] **Step 3: Create `README.md`**

````markdown
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
````

- [ ] **Step 4: Run the check again and commit**

Run:
```bash
cd /home/dokimazo-tech/dev247/ship
./tests/check.sh
```
Expected: `ALL CHECKS PASS`.

```bash
git add README.md tests/check.sh
git commit -m "feat: add README playbook and consolidated structural check

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

## Self-Review

**Spec coverage:**
- Two-layer architecture → Tasks 1–8 build the toolkit; `.workflow/` trail produced by Task 2 templates + bootstrap. ✅
- Six phases with correct outputs/gates → Tasks 2–5; gate wording verified in checks. ✅
- Phase-prompt contract (6 sections) → enforced by `check_contract` in Tasks 3–5 and `tests/check.sh`. ✅
- `state.md` spine + resume rules → defined Task 1, templated Task 2, referenced by all phases. ✅
- Gate protocol (after Discover, after Design, before GTM; Implement→Verify auto) → encoded in phase `## Gate`/`## Handoff` and asserted in checks. ✅
- Single source of truth → adapters reference `core/NN-*.md`; asserted in Tasks 6–7 and `check.sh`. ✅
- Adapters: Claude Code, AGENTS.md, generic → Tasks 6–7. ✅ (Cursor intentionally excluded — matches non-goals.)
- Name `ship` / `/ship-*` → Task 6 commands. ✅

**Placeholder scan:** No TBD/TODO; all file contents given verbatim; `<PROJECT_NAME>`/`<date>` are intentional template tokens replaced by bootstrap, not plan placeholders. ✅

**Type/name consistency:** Artifact filenames, phase filenames (`04-implement.md` prompt → `04-implementation.md` artifact, consistent throughout), gate phrase ``reply `approved` ``, and the `proceed directly to ... Verify` string all match between the phase files and the assertions in `check.sh`. ✅

No gaps found.
