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

Exception: a phase whose gate fires before any work begins (currently only
`06-gtm.md`) places `## Gate` immediately after `## Inputs`, before `## Process`,
so the section order reflects the runtime order.

## Information Currency

The connected model may have stale or outdated training data. Treat its built-in
knowledge as a starting hypothesis, never as ground truth for any fact about the
outside world.

Before asserting any external fact — library/package names and versions, API
signatures, language/framework features, pricing, market or competitor claims,
platform or store policies, security advisories, or "current best practice" —
verify it against an authoritative, current source using whatever tools are
available: web search, official documentation, package registries,
`--version`/CLI checks, or the project's own files. Prefer primary sources and
note the date.

Record what you checked in the artifact's `## Sources` section: one line per
claim as `claim — source (URL/command) — date checked`.

If no fact-checking tool is available in the current environment, do not silently
rely on memory. Label each unverifiable external claim inline as
`[unverified — from training data, as of <date>]` and ask the user to confirm it
or supply current information before the claim is treated as settled.

This rule binds every phase below.

## The Artifact Trail

A project under the workflow has a `.workflow/` directory containing:

| File | Written by | Purpose |
|---|---|---|
| `state.md` | every phase | current phase + gate status + artifact index (the spine) |
| `memory.md` | every phase | curated non-obvious learnings — verified-true facts only (see Memory Protocol) |
| `01-brief.md` | Discover | problem, users, requirements, success criteria, chosen direction |
| `02-plan.md` | Plan/Architect | work breakdown, architecture, tech choices, sequence |
| `03-design.md` | Design | components, interfaces, data, UX, contracts |
| `04-implementation.md` | Implement | build log: decisions, files changed, deviations |
| `05-verify.md` | Verify | QA results, bugs found, fixes, residual risks |
| `06-gtm.md` | Go-to-Market | positioning, messaging, launch & sales assets |

Artifacts are append-friendly markdown. An agent in any tool reconstructs full
context by reading `state.md` then the listed artifacts.

## Gate Protocol

Three hard gates: **after Discover**, **after Design**, and **before
Go-to-Market**. A gate is **not** passable on the model's say-so — it must clear
mechanical and adversarial checks first. This is what makes the workflow robust to
a weak or stale model: quality is enforced by things the model cannot fake.

At a hard gate the agent MUST, in this order:

1. Write the artifact.
2. **Run the machine check** `.workflow/check-gate.sh` (see Quality Enforcement).
   If it exits non-zero, fix every reported problem and re-run — do not present
   the gate until it exits 0.
3. **Run the critic review** in `core/_gate-review.md` against the artifact and
   record its verdict in the artifact's `## Sources`/notes. Resolve every
   `BLOCK` finding before proceeding.
4. Present a short summary **and the gate rubric** from `core/_gate-review.md`,
   then stop with the line:

> **GATE — reply `approved` to continue, or tell me what to change.**

The three gates are: **after Discover** (on `01-brief.md`), **after Design** (on
`03-design.md`), and **before Go-to-Market** (before starting `06-gtm.md`;
present the plan to proceed).

All other transitions flow automatically. In particular **Implement → Verify**
runs without stopping: after `04-implementation.md` is written, proceed directly
to Verify.

On `approved`, update `state.md` (`last_gate_passed`, advance `current_phase`)
before starting the next phase.

## Quality Enforcement

Prose instructions are not enough — a weak model will skip them. Two mechanical
backstops make correctness checkable by something other than the model:

- **`.workflow/check-gate.sh`** (copied in at bootstrap) is the machine gate. For
  the current phase it asserts: the artifact exists, carries all its required
  section headers, and has a **non-empty `## Sources`** (not just the template
  comment). It then auto-detects the project's stack and runs the real
  build/test/lint (`npm`/`pnpm`/`yarn`, `pytest`, `cargo`, `go`, `make`). For the
  **Verify** phase it is strict: automated tests MUST exist and pass, the
  `## Security` section must be non-empty with no `open` Critical/High
  finding, and no acceptance line may read `fail` or `blocked`. Every run
  also secret-scans the working tree — including `.workflow/` itself.
  A red check blocks the gate.
- **`templates/ci/ship-gate.yml`** runs the same script in CI so the check cannot
  be bypassed by a forgetful agent.

Run `check-gate.sh` before every hard gate, and after Verify. Treat a non-zero
exit as a hard stop, exactly like a failing test.

## Executable Acceptance Criteria

Success is defined by tests, not by the model's opinion.

- **Discover** MUST write each success criterion as a *measurable, checkable*
  statement (a number, a threshold, an observable behavior) — never a vague
  adjective like "fast" or "user-friendly".
- **Verify** MUST convert each success criterion into a concrete automated test
  and record the mapping in its `## Acceptance` section as
  `criterion — test (path/id) — pass|fail|blocked(<reason>)`. A criterion
  with no passing test is an open item, and `check-gate.sh` treats missing/failing
  acceptance tests as a gate failure.

## Memory Protocol

`.workflow/memory.md` is the project's cross-session memory: a **curated** set
of non-obvious learnings that holds **only verified-true facts** — it is not a
journal. History lives in git and the phase artifacts.

- **Read it at the start of every phase**, right after `state.md`.
- **Update it at every Handoff — append AND prune.** Append new non-obvious
  learnings. Prune: remove entries proven false or dismissed; remove or
  rewrite entries whose concern has been attended to (follow-up done, issue
  resolved) down to whatever fact still holds; re-verify or drop anything no
  longer confirmable.
- **Exclusions:** never record what is derivable from the repo, the
  artifacts, or git history — those sources are authoritative and copies rot.
  If something derivable seems worth saving, keep only what was *surprising
  or non-obvious* about it. Never store secrets or credentials (the secret
  scan covers `.workflow/` too).
- **Entry format:** `- <date> — <phase> — <learning>.` followed by `Why:`
  (what breaks without it) and `How to apply:` (the concrete behavior next
  time). Knowing *why* lets a future agent judge edge cases instead of
  blindly following the rule.
- **Staleness:** an entry naming a file/function/flag is a claim it existed
  *when written* — verify it still holds before acting on it, and prune it
  when it stops holding.
- **Record confirmations, not just corrections** — only saving mistakes
  drifts the workflow away from approaches the user has already validated.
- An **empty memory is legitimate** (nothing surprising, or everything
  attended to). `check-gate.sh` warns if the file is missing, but never
  blocks on content.

## Result Integrity

- **Staleness:** any prior PASS — an acceptance line, a security finding's
  status, a gate verdict — is stale the moment the underlying behavior
  changes. Re-run the affected checks and overwrite the artifact section;
  never accumulate stale greens.
- **BLOCKED is a verdict, not a failure to report:** when a criterion cannot
  be verified, record `blocked(<reason>)` — never fabricate a pass or guess
  a fail. `check-gate.sh` treats `blocked` like `fail`: the gate does not
  pass until the blocker is resolved or the criterion re-scoped with the
  user.
- **No gaming:** fix the underlying defect — never edit a test or weaken a
  success criterion to make it pass. If the test itself is wrong (bad
  selector, race, stale assertion), say so explicitly in the artifact and
  justify the change.
- **Flip conditions:** any warn/deferred/non-blocking result must record the
  condition under which it becomes blocking (e.g. "deferred until upstream
  fix lands — then blocking"). Deferred rigor has an expiry; silent
  permanent leniency is not allowed.

## Gate Review (critic + rubric)

At each hard gate the agent runs the adversarial checklist in
`core/_gate-review.md` — ideally routed to a **stronger model** than the one doing
the bulk work (a "mixture of models": cheap local model builds, strong model
reviews the three gates). If no stronger model is available, run the same model in
a fresh, explicitly adversarial "try to break this" pass. The same file holds the
**human rubric** presented to the user at the gate, so the human backstop has a
concrete checklist instead of a blank "approved?".

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

To resume in any tool: read `.workflow/state.md`, then `.workflow/memory.md`
(the Memory Protocol above), then read every checked artifact, then open
`core/<current_phase>.md` and continue its `## Process`.
If `current_phase` sits at a passed gate awaiting approval, re-present the gate.

## Adaptation

Optimized for software. For a non-software venture, treat "Implement" as
"build the real-world thing" and keep the same artifacts; skip sections that
don't apply rather than inventing software structure.
