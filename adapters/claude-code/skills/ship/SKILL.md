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
