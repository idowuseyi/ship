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
