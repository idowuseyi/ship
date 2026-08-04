# ship — Security Review + Memory Layer Design

**Date:** 2026-08-04
**Branch:** main
**Status:** Approved by user

## Context

A comparison against the workflow system in `~/dev247/lms` (a four-agent
orchestrated delivery workflow with per-agent memory, an adversarial security
audit practice, and a layered CI/hooks enforcement stack) identified two real
gaps in ship plus four small high-leverage practices worth adopting. Everything
else in lms is either already covered by ship's stronger enforcement spine
(machine gate, critic pass, human rubric, Information Currency) or is an
anti-pattern ship deliberately avoids (duplicated instruction files that drift,
tool-native memory that breaks portability, machine-specific paths).

## Decisions (confirmed with user)

1. **Security review: machine-enforced** — not prose-only. New canonical
   security pass, required `## Security` artifact section, `check-gate.sh`
   assertions, and a secret scan.
2. **Memory: a `.workflow/memory.md` artifact** — tool-agnostic, read at the
   start of every phase, appended at every phase Handoff. Not tool-native
   memory, not an extension of `state.md`.
3. **Adopt all four extras** — result-staleness rule, BLOCKED verdict +
   `## Not Covered` reporting, anti-test-gaming rule, documented flip
   conditions for any non-blocking result.

## Design principle

Follow ship's own philosophy rather than copying lms literally: lms enforces
security/memory through agent prose (skippable by a weak model); ship enforces
quality by things the model cannot fake. Each adopted practice therefore gets
up to three layers: a phase-prompt instruction (prose), a required artifact
section (structure), and a `check-gate.sh` assertion (machine).

## 1. Security review (machine-enforced)

### New file `core/_security-review.md`

A tool-agnostic distillation of lms's red-team security prompt
(`lms/docs/security-prompt.md`) with two entry points:

**Design-time subset** — run at the Design gate as part of the
`_gate-review.md` critic:
- Are trust boundaries defined (who talks to what, with which privileges)?
- Are attacker profiles considered (anonymous, authenticated, insider, API
  consumer)?
- Is sensitive data identified, and its storage/transport/logging handling
  specified?
- Are authn/authz boundaries explicit for every interface in the design?

**Full adversarial pass** — run inside Verify, before `05-verify.md` is
finalized:
1. Threat model: attacker profiles, entry points, trust boundaries, sensitive
   assets.
2. Checklist areas: authn/authz; input handling (injection, XSS, path
   traversal, deserialization); data security (secrets in code/logs, crypto,
   PII exposure); API & business logic (IDOR/BOLA, mass assignment, race
   conditions, missing rate limits); infrastructure & config (headers, CORS,
   debug endpoints, default credentials); dependencies & supply chain (known
   CVEs against current advisories, per Information Currency).
3. Beyond checklists: logic flaws, chained multi-step attack paths, and any
   behavior that "shouldn't be possible" but is.

Mindset rules (kept from lms in spirit):
- Assume deployment in a hostile environment with motivated attackers.
- Do not skip analysis due to missing context — infer risks and flag them.
- Re-verify every finding against actual source (`file:line`) before
  reporting; drop or downgrade what cannot be confirmed.
- Never fabricate a verdict; if an area could not be assessed, list it in
  `## Not Covered` with the reason instead of guessing.

### Output contract — `## Security` section in `05-verify.md`

- One finding per line:
  `S-NNN — <title> — <severity> — <location file:line> — <exploit scenario> — <fix> — <status>`
- Severity rubric: **Critical** (exploitable data breach or silent data
  loss), **High** (serious risk), **Medium** (real but bounded),
  **Low** (hardening/hygiene).
- Status ∈ `fixed | open | deferred(<reason + flip condition>)`.
- A "reviewed and found solid" list of areas checked with no findings (guards
  against false negatives — an empty findings list must mean "checked and
  clean", not "didn't look").
- Non-code follow-ups (ops actions the codebase cannot perform, e.g. rotate a
  credential on a server) flagged explicitly as such.

### Machine enforcement — `templates/workflow/check-gate.sh`

- `Security` joins the required headers for `05-verify` and the GTM
  pre-flight path; a missing or empty section is a FAIL.
- New `check_security()`: FAIL if any `Critical` or `High` finding has status
  `open`. `deferred(...)` passes — deferral is a human decision made at the
  gate and must carry its reason + flip condition inline.
- New `run_secret_scan()`, run on every invocation (all gates + Verify):
  - If `gitleaks` is installed: `gitleaks detect --no-git --source "$ROOT"
    --redact` (working-tree scan, not history, so pre-existing historical
    leaks don't permanently block adoption — the lms rationale).
  - Fallback: portable grep for high-signal patterns only, to keep false
    positives near zero: `sk_live_`, `AKIA[0-9A-Z]{16}`,
    `-----BEGIN .*PRIVATE KEY`, `ghp_[A-Za-z0-9]{36}`. Skips `.git/`,
    `node_modules/`, and other vendored/build directories.
  - The scan covers the working tree **including `.workflow/` itself** —
    agent-written artifacts leak secrets too (lms learned this from a real
    incident in its agent-memory directory).
  - Any hit is a FAIL.
- CI inherits everything via the existing `templates/ci/ship-gate.yml`
  (it just runs `check-gate.sh`) — no CI template change needed.

### Phase-prompt changes

- `core/03-design.md` Process: new step — specify trust boundaries,
  authn/authz per interface, and sensitive-data handling as part of the
  design (the design-time subset's input).
- `core/_gate-review.md` Design checks: add the design-time security
  questions. GTM section + human rubric: add a line confirming no unresolved
  Critical/High security findings (deferred ones surfaced with their reasons).
- `core/05-verify.md` Process: new step — run the full pass per
  `core/_security-review.md`; record results in `## Security`. Output section
  list gains `## Security` and `## Not Covered`.

## 2. Memory layer (`.workflow/memory.md`)

### New file `templates/workflow/memory.md`

Copied at bootstrap alongside the other templates. Header comments explain the
protocol; body is a **curated** list of entries — it holds only what is
currently verified true, not a historical journal:

```
- <date> — <phase> — <the learning>.
  Why: <why it matters / what breaks without it>
  How to apply: <the concrete behavior next time>
```

### New `## Memory Protocol` section in `core/_conventions.md`

1. **Read at phase start** — every phase reads `memory.md` after `state.md`
   (Resume Rules updated to: `state.md` → `memory.md` → checked artifacts →
   current phase prompt).
2. **Update at every Handoff — append AND prune.** Recording non-obvious
   learnings is part of the loop, not an afterthought; so is curation.
3. **Verified-true only.** Memory holds only facts that are currently
   verified true — it is a curated set, never a historical journal. At every
   Handoff: remove entries proven false or dismissed; remove entries whose
   concern has been attended to (follow-up done, issue resolved), or rewrite
   them down to whatever fact still holds; re-verify or drop anything that
   can no longer be confirmed. History belongs in git and the phase
   artifacts, not in memory.
4. **Exclusion list** — never record what is derivable from the repo, the
   artifacts, or git history; those sources are authoritative and memory
   copies of them rot. If something derivable seems worth saving, capture
   only what was *surprising or non-obvious* about it.
5. **Staleness protocol** — a memory naming a file/function/flag is a claim
   it existed *when the memory was written*; verify it still exists before
   acting on it, and prune it once it no longer holds (per rule 3).
6. **Record confirmations, not just corrections** — only saving mistakes
   drifts the workflow away from approaches the user has already validated.
7. An empty memory is legitimate (nothing surprising happened, or everything
   was attended to). No machine gate on content; `check-gate.sh` warns (not
   fails) if the file is missing.

### Phase-prompt changes

Every phase file (`00`–`06`) gains one `## Handoff` line: "Update
`.workflow/memory.md` per the Memory Protocol in `_conventions.md`: append
any non-obvious learnings from this phase, and prune entries now proven
false, dismissed, or attended to." `00-bootstrap.md` additionally copies the new
template (already covered by "copy every file from templates/workflow/").
`_conventions.md`'s artifact table gains a `memory.md` row. `state.md`'s
checkbox list is unchanged — memory is cross-phase, not a phase artifact.

## 3. The four adopted extras

1. **Result staleness** (`_conventions.md`, Quality Enforcement): any prior
   PASS — acceptance line, security finding status, gate verdict — is stale
   the moment the underlying behavior changes. Re-run and overwrite the
   artifact section; never accumulate stale greens.
2. **BLOCKED verdict + Not Covered**: acceptance lines become
   `pass | fail | blocked(<reason>)`; `check_acceptance()` treats `blocked`
   as gate-blocking exactly like `fail` — a result can never be fabricated
   past the gate, and environment failures are named as such instead of
   masquerading as passes or product defects. New required `## Not Covered`
   section in `05-verify.md`: what was not tested/reviewed, and why.
3. **Anti-gaming rule** (`core/05-verify.md` + `_conventions.md`): fix the
   underlying defect — never edit a test or weaken a success criterion to
   make it pass. If the test itself is wrong (bad selector, race, stale
   assertion), say so explicitly and justify the change in the artifact.
4. **Flip conditions** (`_conventions.md`): any warn/deferred/non-blocking
   result must record the condition under which it becomes blocking (e.g.
   "deferred until upstream fix X lands — then blocking"). Deferred rigor
   has an expiry; silent permanent leniency is not allowed.

## 4. Files touched

| File | Change |
|---|---|
| `core/_security-review.md` | **new** — canonical security pass (both entry points, severity rubric, output contract) |
| `templates/workflow/memory.md` | **new** — memory artifact template |
| `core/_conventions.md` | Memory Protocol; staleness, anti-gaming, flip-condition rules; artifact table + Resume Rules; Quality Enforcement mentions security checks |
| `core/_gate-review.md` | Design-gate security checks; GTM critic + human-rubric lines for unresolved findings |
| `core/00-bootstrap.md` | Output list mentions `memory.md`; Handoff memory line |
| `core/01-discover.md`, `core/02-plan.md`, `core/06-gtm.md` | Handoff memory line |
| `core/03-design.md` | security-in-design Process step; Handoff memory line |
| `core/04-implement.md` | Handoff memory line; "no secrets in code/artifacts" reminder |
| `core/05-verify.md` | security-pass Process step; anti-gaming rule; `## Security` + `## Not Covered` outputs; blocked verdict; Handoff memory line |
| `templates/workflow/05-verify.md` | `## Security`, `## Not Covered` sections with format comments; `blocked(<reason>)` in Acceptance comment |
| `templates/workflow/check-gate.sh` | required headers; `check_security()`; `run_secret_scan()`; `blocked` handling in `check_acceptance()`; warn on missing `memory.md` |
| `adapters/agents/AGENTS.md` | two thin rule bullets (security pass at Verify/gates; memory read/append) — pointers only, no logic duplication |
| `adapters/claude-code/skills/ship/SKILL.md`, `adapters/claude-code/commands/ship-verify.md` (and other commands if they enumerate rules) | same two thin pointers |
| `adapters/continue/config.yaml` | same two thin pointers if it enumerates rules |
| `tests/check.sh` | structural assertions for the new files/sections/script functions |
| `README.md` | artifact-trail table + "Quality is enforced" section updated for security + memory |

## Explicitly not adopted from lms (with reasons)

- **Duplicated instruction files** (CLAUDE.md vs AGENTS.md, observed drifted)
  — ship's `core/` + thin adapters already prevents this.
- **Tool-native agent memory** — breaks ship's switch-tools-anytime promise.
- **Husky hooks / 8-job CI / scheduled dependency audits** — valuable in an
  app repo, but ship is a tool-agnostic toolkit; `ship-gate.yml` running
  `check-gate.sh` stays the single CI entry point. Projects can layer their
  own CI on top.
- **Multi-agent orchestration roles** — ship is deliberately single-agent
  sequential with human gates; the decoupled-validator benefit is already
  provided by the hard gates.

## Success criteria

- `tests/check.sh` passes with new structural assertions.
- `check-gate.sh` on a fixture: fails Verify when `## Security` is
  empty/missing, when a Critical/High finding is `open`, when an acceptance
  line reads `blocked`, or when the secret scan hits a planted
  `sk_live_`-style string; passes when findings are `fixed`/`deferred(...)`
  and acceptance lines all read `pass`.
- Bootstrap copies `memory.md`; every phase prompt's Handoff mentions the
  memory append; Resume Rules include `memory.md`.
- No adapter duplicates phase logic (bullets are pointers into `core/`).
