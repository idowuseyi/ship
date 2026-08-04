# Security Review + Memory Layer Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a machine-enforced security review and a curated verified-true memory layer to the ship workflow loops, plus four result-integrity rules (staleness, blocked verdict + not-covered reporting, anti-gaming, flip conditions).

**Architecture:** ship is a markdown+bash toolkit: canonical phase prompts in `core/`, per-project files in `templates/workflow/` (copied to `.workflow/` at bootstrap), thin adapters, and two test layers — `tests/check.sh` (structural greps over the repo) and a new `tests/gate-fixture.sh` (behavioral tests that run `check-gate.sh` against disposable fixture projects). Every adopted practice gets up to three layers: phase-prompt prose, a required artifact section, and a `check-gate.sh` assertion.

**Tech Stack:** Markdown, bash (`set -u`, functions with `local`, grep/awk/sed only — no new dependencies; `gitleaks` optional at runtime with a grep fallback).

**Spec:** `docs/superpowers/specs/2026-08-04-security-memory-workflow-design.md` — read it first.

## Global Constraints

- `core/` is the single source of truth. Adapters may only *point* at core files, never restate phase logic.
- Every phase prompt keeps the six-section contract from `core/_conventions.md` (`## Purpose`, `## Inputs`, `## Process`, `## Output`, `## Gate`, `## Handoff`).
- Markdown wraps near 80 columns, matching the existing files.
- `check-gate.sh` stays dependency-free: plain bash + grep/awk/sed. `gitleaks` is used only if already installed; otherwise a grep fallback with high-signal patterns only (`sk_live_`, `AKIA[0-9A-Z]{16}`, `-----BEGIN .*PRIVATE KEY`, `ghp_[A-Za-z0-9]{36}`).
- Security finding line format (status is ALWAYS the last field): `S-NNN — <title> — <Critical|High|Medium|Low> — <file:line> — <exploit scenario> — <fix> — <fixed|open|deferred(<reason + flip condition>)>`
- Acceptance line format: `criterion — test (path/id) — pass|fail|blocked(<reason>)`
- Memory holds ONLY currently-verified-true facts: append AND prune at every Handoff; no secrets; nothing derivable from repo/artifacts/git.
- Run `bash tests/check.sh` after every task; it must print `ALL CHECKS PASS` before each commit.

---

### Task 1: Canonical security-review file (`core/_security-review.md`)

**Files:**
- Create: `core/_security-review.md`
- Modify: `tests/check.sh` (append assertions before the final `if [ $fail -eq 0 ]` line)

**Interfaces:**
- Produces: `core/_security-review.md` with headers `## Mindset (both passes)`, `## Design-time subset (run at the Design gate)`, `## Full adversarial pass (run during Verify)`, `## Severity rubric`, `## Output contract (`## Security` in 05-verify.md)`. Tasks 3–5 reference this file by name and its finding-line format.

- [ ] **Step 1: Add failing structural assertions**

In `tests/check.sh`, insert immediately before the final `if [ $fail -eq 0 ]; then …` line:

```bash
# Security review + memory layer (2026-08-04 spec)
test -f core/_security-review.md || note "missing core/_security-review.md"
for h in '## Mindset' '## Design-time subset' '## Full adversarial pass' '## Severity rubric' '## Output contract'; do
  grep -qF "$h" core/_security-review.md 2>/dev/null || note "_security-review.md missing '$h'"
done
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `bash tests/check.sh`
Expected: `FAIL: missing core/_security-review.md` (+ the five header FAILs), exit 1.

- [ ] **Step 3: Create `core/_security-review.md`**

```markdown
# ship — Security Review (design-time + adversarial verify pass)

Two entry points, one file. The **design-time subset** runs at the Design gate
as part of `core/_gate-review.md`. The **full adversarial pass** runs inside
Verify (`core/05-verify.md`) before `05-verify.md` is finalized. Neither
replaces the machine checks in `.workflow/check-gate.sh` (which also
secret-scans the working tree); this file catches what a script cannot: logic
flaws, chained attacks, and missing boundaries.

## Mindset (both passes)

- Assume the system will be deployed in a hostile environment with motivated
  attackers.
- Do not skip analysis due to missing context — infer risks and flag them.
- Re-verify every finding against the actual source (`file:line`) before
  reporting it; drop or downgrade what cannot be confirmed.
- Never fabricate a verdict. If an area could not be assessed, list it in
  `## Not Covered` with the reason instead of guessing.
- *Information currency (see `_conventions.md`):* check dependencies against
  currently-published advisories/CVEs, not remembered ones. Record what you
  checked in `## Sources`.

## Design-time subset (run at the Design gate)

Verdict each check `PASS`/`WARN`/`BLOCK`, like the other critic checks in
`core/_gate-review.md`:

- **Trust boundaries:** is it defined who talks to what, with which
  privileges?
- **Attacker profiles:** anonymous user, authenticated user, insider, API
  consumer — has each been considered against the design?
- **Sensitive data:** identified, with storage/transport/logging handling
  specified?
- **Authn/authz:** explicit for every interface in
  `## Interfaces & Contracts`?

## Full adversarial pass (run during Verify)

1. **Threat model:** attacker profiles, entry points, trust boundaries,
   sensitive assets (data, tokens, permissions, secrets).
2. **Checklist areas:**
   - Authn/authz — session handling, privilege escalation, missing checks.
   - Input handling — injection (SQL/command), XSS, path traversal, unsafe
     deserialization.
   - Data security — secrets in code/logs/artifacts, weak crypto, PII
     exposure.
   - API & business logic — IDOR/BOLA, mass assignment, race conditions,
     missing rate limits.
   - Infrastructure & config — security headers, CORS, debug endpoints,
     default credentials.
   - Dependencies & supply chain — known CVEs against current advisories.
3. **Beyond checklists:** logic flaws, chained multi-step attack paths, and
   any behavior that "shouldn't be possible" but is.

## Severity rubric

- **Critical** — exploitable data breach or silent data loss.
- **High** — serious risk: auth bypass, privilege escalation, injection.
- **Medium** — real but bounded.
- **Low** — hardening / hygiene.

## Output contract (`## Security` in 05-verify.md)

One finding per line, **status last**:

`S-NNN — <title> — <Critical|High|Medium|Low> — <file:line> — <exploit
scenario> — <fix> — <fixed|open|deferred(<reason + flip condition>)>`

Then:
- **Reviewed and found solid:** the areas checked with no findings — an empty
  findings list must mean "checked and clean", never "didn't look".
- **Non-code follow-ups:** ops actions the codebase cannot perform (rotate a
  leaked credential, close a port), flagged explicitly.

Gate rules (enforced by `check-gate.sh`):
- `## Security` may not be empty at Verify or the GTM pre-flight.
- A `Critical` or `High` finding with status `open` blocks the gate.
  Deferral is a human decision made at a gate and must carry its reason and
  flip condition inline.
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `bash tests/check.sh`
Expected: `ALL CHECKS PASS`, exit 0.

- [ ] **Step 5: Commit**

```bash
git add core/_security-review.md tests/check.sh
git commit -m "feat: canonical security-review pass (design-time + adversarial verify)"
```

---

### Task 2: Memory template + conventions (Memory Protocol, Result Integrity)

**Files:**
- Create: `templates/workflow/memory.md`
- Modify: `core/_conventions.md` (artifact table ~line 49; new sections after `## Executable Acceptance Criteria`; Resume Rules ~line 160; Quality Enforcement ~line 99)
- Modify: `tests/check.sh`

**Interfaces:**
- Produces: `templates/workflow/memory.md`; `## Memory Protocol` and `## Result Integrity` sections in `core/_conventions.md`. Task 4's Handoff lines and Task 3's `blocked` handling reference these by name.

- [ ] **Step 1: Add failing assertions**

In `tests/check.sh`, extend the block added in Task 1 (before the final verdict `if`):

```bash
test -f templates/workflow/memory.md || note "missing templates/workflow/memory.md"
grep -qF '## Memory Protocol' core/_conventions.md || note "_conventions.md missing Memory Protocol"
grep -qF '## Result Integrity' core/_conventions.md || note "_conventions.md missing Result Integrity"
grep -q 'memory.md' core/_conventions.md || note "_conventions.md does not reference memory.md"
grep -qi 'verified true\|verified-true' core/_conventions.md || note "Memory Protocol missing verified-true rule"
grep -qi 'prune' core/_conventions.md || note "Memory Protocol missing prune rule"
grep -qi 'blocked' core/_conventions.md || note "_conventions.md missing blocked verdict"
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `bash tests/check.sh`
Expected: FAIL lines for memory.md, Memory Protocol, Result Integrity, verified-true, prune, blocked. (`memory.md`/`blocked` greps may already pass if words appear incidentally — that's fine; the section greps must fail.)

- [ ] **Step 3: Create `templates/workflow/memory.md`**

```markdown
# Workflow Memory — verified, non-obvious learnings
<!-- Read this file at the start of every phase (right after state.md). -->
<!-- Update at every phase Handoff: APPEND new non-obvious learnings AND
     PRUNE — remove entries proven false or dismissed; remove or rewrite
     entries whose concern has been attended to; re-verify or drop anything
     no longer confirmable. This file holds ONLY what is CURRENTLY VERIFIED
     TRUE — a curated set, not a journal. History lives in git and the phase
     artifacts. -->
<!-- Never record what is derivable from the repo, the artifacts, or git
     history. If something derivable seems worth saving, keep only what was
     surprising or non-obvious about it. Record confirmations as well as
     corrections. NEVER store secrets or credentials here — the secret scan
     covers this directory too. -->
<!-- Entry format:
- <date> — <phase> — <the learning>.
  Why: <why it matters / what breaks without it>
  How to apply: <the concrete behavior next time>
-->
```

- [ ] **Step 4: Add the `memory.md` row to the artifact table in `core/_conventions.md`**

In `## The Artifact Trail`, after the `state.md` row, add:

```markdown
| `memory.md` | every phase | curated non-obvious learnings — verified-true facts only (see Memory Protocol) |
```

- [ ] **Step 5: Add `## Memory Protocol` and `## Result Integrity` sections**

Insert after the `## Executable Acceptance Criteria` section (before `## Gate Review (critic + rubric)`):

```markdown
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
```

- [ ] **Step 6: Update Quality Enforcement, Acceptance format, and Resume Rules in `core/_conventions.md`**

In `## Quality Enforcement`, extend the `check-gate.sh` bullet's sentence "For the **Verify** phase it is strict: automated tests MUST exist and pass." to:

```markdown
  **Verify** phase it is strict: automated tests MUST exist and pass, the
  `## Security` section must be non-empty with no `open` Critical/High
  finding, and no acceptance line may read `fail` or `blocked`. Every run
  also secret-scans the working tree — including `.workflow/` itself.
```

In `## Executable Acceptance Criteria`, change the mapping format line from `criterion — test (path/id) — pass|fail` to:

```markdown
  `criterion — test (path/id) — pass|fail|blocked(<reason>)`. A criterion
```

In `## Resume Rules`, change the first sentence to:

```markdown
To resume in any tool: read `.workflow/state.md`, then `.workflow/memory.md`
(the Memory Protocol above), then read every checked artifact, then open
`core/<current_phase>.md` and continue its `## Process`.
```

- [ ] **Step 7: Run tests to verify they pass**

Run: `bash tests/check.sh`
Expected: `ALL CHECKS PASS`.

- [ ] **Step 8: Commit**

```bash
git add templates/workflow/memory.md core/_conventions.md tests/check.sh
git commit -m "feat: memory layer (curated verified-true) + result-integrity rules in conventions"
```

---

### Task 3: Machine gate — `check-gate.sh` security/memory/blocked + fixture tests

**Files:**
- Create: `tests/gate-fixture.sh`
- Modify: `templates/workflow/check-gate.sh`
- Modify: `tests/check.sh`

**Interfaces:**
- Consumes: finding/acceptance line formats from Global Constraints.
- Produces: `check_security()`, `run_secret_scan()`, `blocked` handling in `check_acceptance()`, memory-missing warn. Required headers for `05-verify` become `Test Coverage|Bugs Found|Fixes Applied|Residual Risks|Acceptance|Security|Not Covered|Sources` (same in the GTM pre-flight else-branch).

- [ ] **Step 1: Write the behavioral fixture tests**

Create `tests/gate-fixture.sh`:

```bash
#!/usr/bin/env bash
# Behavioral tests for templates/workflow/check-gate.sh using disposable
# fixture projects. Each fixture is a temp dir with a Makefile test target
# (so run_code_checks passes) and a .workflow/ trail.
set -u
cd "$(dirname "$0")/.." || exit 1
GATE="$PWD/templates/workflow/check-gate.sh"
fail=0
note() { echo "FAIL: $1"; fail=1; }
command -v make >/dev/null 2>&1 || { echo "skip: make not installed"; exit 0; }

make_fixture() { # $1=phase; echoes fixture root
  local root
  root=$(mktemp -d)
  mkdir -p "$root/.workflow"
  printf 'test:\n\t@true\n' > "$root/Makefile"
  cat > "$root/.workflow/state.md" <<EOF
# Workflow State
- project: fixture
- current_phase: $1
- last_gate_passed: design
- next_gate: gtm
EOF
  cp "$GATE" "$root/.workflow/check-gate.sh"
  chmod +x "$root/.workflow/check-gate.sh"
  : > "$root/.workflow/memory.md"
  echo "$root"
}

write_verify() { # $1=root $2=acceptance-line $3=security-line
  cat > "$1/.workflow/05-verify.md" <<EOF
# 05 — Verify
## Test Coverage
covered
## Bugs Found
none
## Fixes Applied
none
## Residual Risks
none
## Acceptance
$2
## Security
$3
## Not Covered
nothing — full coverage
## Sources
claim — command — 2026-08-04
EOF
}

# 1. green path passes
r=$(make_fixture 05-verify)
write_verify "$r" 'criterion A — tests/a — pass' \
  'S-001 — sample — Low — src/x:1 — n/a — n/a — fixed'
"$r/.workflow/check-gate.sh" >/dev/null 2>&1 || note "green fixture should pass"
rm -rf "$r"

# 2. empty ## Security blocks
r=$(make_fixture 05-verify)
write_verify "$r" 'criterion A — tests/a — pass' ''
"$r/.workflow/check-gate.sh" >/dev/null 2>&1 && note "empty ## Security should block"
rm -rf "$r"

# 3. open High finding blocks
r=$(make_fixture 05-verify)
write_verify "$r" 'criterion A — tests/a — pass' \
  'S-001 — auth bypass — High — src/x:1 — scenario — fix — open'
"$r/.workflow/check-gate.sh" >/dev/null 2>&1 && note "open High finding should block"
rm -rf "$r"

# 4. deferred High finding passes (human decision, reason + flip condition inline)
r=$(make_fixture 05-verify)
write_verify "$r" 'criterion A — tests/a — pass' \
  'S-001 — auth bypass — High — src/x:1 — scenario — fix — deferred(user accepted 2026-08-04; blocking once upstream patch lands)'
"$r/.workflow/check-gate.sh" >/dev/null 2>&1 || note "deferred High finding should pass"
rm -rf "$r"

# 5. blocked acceptance line blocks
r=$(make_fixture 05-verify)
write_verify "$r" 'criterion A — tests/a — blocked(env down)' \
  'S-001 — sample — Low — src/x:1 — n/a — n/a — fixed'
"$r/.workflow/check-gate.sh" >/dev/null 2>&1 && note "blocked acceptance should block"
rm -rf "$r"

# 6. planted secret blocks (24-char key so gitleaks' stripe rule also matches)
r=$(make_fixture 05-verify)
write_verify "$r" 'criterion A — tests/a — pass' \
  'S-001 — sample — Low — src/x:1 — n/a — n/a — fixed'
# Build the secret via %s so this test file never contains the literal
# pattern itself (it would otherwise trip the scan when run on the ship repo).
printf 'key = "sk_live_%s"\n' 'abcdefghijklmnopqrstuvwx' > "$r/leak.txt"
"$r/.workflow/check-gate.sh" >/dev/null 2>&1 && note "planted sk_live_ secret should block"
rm -rf "$r"

# 7. missing memory.md warns but does not block
r=$(make_fixture 05-verify)
write_verify "$r" 'criterion A — tests/a — pass' \
  'S-001 — sample — Low — src/x:1 — n/a — n/a — fixed'
rm -f "$r/.workflow/memory.md"
out=$("$r/.workflow/check-gate.sh" 2>&1) || note "missing memory.md must not block"
echo "$out" | grep -qi 'memory' || note "missing memory.md should print a warning"
rm -rf "$r"

if [ "$fail" -eq 0 ]; then echo "GATE FIXTURE TESTS PASS"; else echo "GATE FIXTURE TESTS FAILED"; exit 1; fi
```

Then `chmod +x tests/gate-fixture.sh`, and in `tests/check.sh` extend the new block:

```bash
grep -q 'check_security' templates/workflow/check-gate.sh || note "check-gate.sh missing check_security"
grep -q 'run_secret_scan' templates/workflow/check-gate.sh || note "check-gate.sh missing run_secret_scan"
if [ -f tests/gate-fixture.sh ]; then
  bash tests/gate-fixture.sh || note "gate fixture tests failed"
else
  note "missing tests/gate-fixture.sh"
fi
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `bash tests/check.sh`
Expected: `FAIL: check-gate.sh missing check_security`, `... run_secret_scan`, and `GATE FIXTURE TESTS FAILED` → `FAIL: gate fixture tests failed`. Specifically fixture tests 2, 3, 6, and 7 fail against the current gate (nothing blocks on security/secrets yet, and no memory warning exists); tests 1, 4, and 5 already pass (5 passes because a `blocked` acceptance line has no `pass`, which the existing check already rejects).

- [ ] **Step 3: Implement the gate changes in `templates/workflow/check-gate.sh`**

3a. After the `phase=` read/echo block (line ~25), add:

```bash
[ -f "$WF/memory.md" ] || warn "no .workflow/memory.md — copy templates/workflow/memory.md (Memory Protocol)"
```

3b. In `check_acceptance()`, after the `fails=` handling, add:

```bash
  local blocked
  blocked=$(printf '%s\n' "$body" | grep -ci 'blocked' || true)
  [ "${blocked:-0}" -ge 1 ] && err "05-verify.md ## Acceptance has blocked criteria ($blocked) — resolve the blocker or re-scope with the user"
```

(and declare `blocked` alongside `passes fails` if preferred — keep the existing style).

3c. After `check_acceptance()`, add two new functions:

```bash
# ## Security must be non-empty and carry no open Critical/High finding.
# Finding format (status LAST): S-NNN — title — severity — file:line — scenario — fix — status
check_security() {
  local body content open_high
  body=$(section_body "$WF/05-verify.md" "Security" | grep -v '<!--')
  content=$(printf '%s\n' "$body" | grep -v '^[[:space:]]*$')
  [ -n "$content" ] || { err "05-verify.md has an empty ## Security — run core/_security-review.md and record results"; return; }
  open_high=$(printf '%s\n' "$body" | grep -Ei 'critical|high' | grep -Eci -- '(—|--|-)[[:space:]]*open[[:space:]]*$' || true)
  [ "${open_high:-0}" -ge 1 ] && err "05-verify.md ## Security has open Critical/High findings ($open_high) — fix them or record a user-approved deferred(reason + flip condition)"
}

# Secret scan of the working tree — including .workflow/ itself (agent-written
# artifacts leak secrets too). Working-tree scan, not git history, so
# pre-existing historical leaks don't permanently block adoption.
run_secret_scan() {
  cd "$ROOT" || return 0
  if command -v gitleaks >/dev/null 2>&1; then
    gitleaks detect --no-git --source . --redact >/dev/null 2>&1 || \
      err "secret scan (gitleaks) found leaks — run: gitleaks detect --no-git --source . --redact --verbose"
  else
    # Fallback: high-signal patterns only, to keep false positives near zero.
    local hits
    hits=$(grep -RInE \
      --exclude-dir=.git --exclude-dir=node_modules --exclude-dir=vendor \
      --exclude-dir=dist --exclude-dir=build --exclude-dir=target \
      'sk_live_[0-9A-Za-z]{10,}|AKIA[0-9A-Z]{16}|-----BEGIN [A-Z ]*PRIVATE KEY|ghp_[A-Za-z0-9]{36}' \
      . 2>/dev/null | head -5)
    [ -n "$hits" ] && { printf '%s\n' "$hits"; err "secret scan (grep fallback) found potential secrets above — remove/rotate them; install gitleaks for a fuller scan"; }
  fi
  cd "$WF" || true
}
```

3d. Update the two required-header lists for `05-verify.md` (the `05-verify)` case AND the GTM pre-flight else-branch) from
`headers="Test Coverage|Bugs Found|Fixes Applied|Residual Risks|Acceptance|Sources"` to:

```bash
headers="Test Coverage|Bugs Found|Fixes Applied|Residual Risks|Acceptance|Security|Not Covered|Sources"
```

3e. Add `check_security` next to each `check_acceptance` call (the `05-verify)` case and the GTM pre-flight else-branch).

3f. After the `case … esac` block and before the final verdict `if`, add:

```bash
run_secret_scan
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `bash tests/check.sh`
Expected: `GATE FIXTURE TESTS PASS` then `ALL CHECKS PASS`. Also sanity-check syntax directly: `bash -n templates/workflow/check-gate.sh` (no output).

- [ ] **Step 5: Commit**

```bash
git add templates/workflow/check-gate.sh tests/gate-fixture.sh tests/check.sh
git commit -m "feat: machine gate enforces security section, open-finding block, secret scan, blocked verdict"
```

---

### Task 4: Phase prompts + verify template — wire security and memory into the loop

**Files:**
- Modify: `core/00-bootstrap.md`, `core/01-discover.md`, `core/02-plan.md`, `core/03-design.md`, `core/04-implement.md`, `core/05-verify.md`, `core/06-gtm.md`
- Modify: `templates/workflow/05-verify.md`
- Modify: `tests/check.sh`

**Interfaces:**
- Consumes: `core/_security-review.md` (Task 1), Memory Protocol / Result Integrity (Task 2), gate behavior (Task 3).
- Produces: every phase Handoff carries the memory-update line; `core/05-verify.md` Output lists `## Security` and `## Not Covered`.

The memory Handoff line (identical wording in every phase, appended to the existing `## Handoff` paragraph):

```markdown
Update `.workflow/memory.md` per the Memory Protocol in `_conventions.md`:
append any non-obvious learnings from this phase; prune entries now proven
false, dismissed, or attended to.
```

- [ ] **Step 1: Add failing assertions**

In `tests/check.sh`, extend the new block:

```bash
for f in core/00-bootstrap.md core/01-discover.md core/02-plan.md core/03-design.md core/04-implement.md core/05-verify.md core/06-gtm.md; do
  grep -qi 'memory.md' "$f" || note "$f missing memory.md update in Handoff"
done
grep -q '_security-review.md' core/05-verify.md || note "core/05-verify.md does not run the security pass"
grep -q '_security-review.md' core/03-design.md || note "core/03-design.md missing design-time security step"
grep -qF '## Security' core/05-verify.md || note "core/05-verify.md Output missing ## Security"
grep -qF '## Not Covered' core/05-verify.md || note "core/05-verify.md Output missing ## Not Covered"
grep -qF '## Security' templates/workflow/05-verify.md || note "verify template missing ## Security"
grep -qF '## Not Covered' templates/workflow/05-verify.md || note "verify template missing ## Not Covered"
grep -qi 'never edit a test' core/05-verify.md || note "core/05-verify.md missing anti-gaming rule"
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `bash tests/check.sh`
Expected: FAIL lines for all seven phase files + the security/template assertions.

- [ ] **Step 3: Rewrite `core/05-verify.md`** (full replacement — this is the phase that changes most):

```markdown
# Phase 05 — Verify (QA + Bug Hunt + Security)

## Purpose
Exercise the built project, hunt for bugs, run the adversarial security
review, and record results and fixes.

## Inputs
- `.workflow/04-implementation.md` (what was built, how to run).
- `.workflow/03-design.md` (intended behavior to check against).
- `.workflow/memory.md` and `.workflow/state.md`.

## Process
1. Turn each **measurable success criterion** in `01-brief.md` into a concrete
   **automated test** in the project's real test suite (not prose). Record the
   mapping in `## Acceptance` as
   `criterion — test (path/id) — pass|fail|blocked(<reason>)`. If a criterion
   cannot be verified, record `blocked(<reason>)` — never fabricate a result
   (see Result Integrity in `_conventions.md`).
2. Run the project; cover happy paths, edge cases, and the listed error modes.
3. Hunt for bugs: boundary inputs, race conditions, silent failures, wrong
   error handling. For each bug, note repro, severity, and fix.
4. Run the **full adversarial security pass** in `core/_security-review.md`.
   Record results in `## Security` per its output contract (finding lines
   with severity and status, "reviewed and found solid" list, non-code
   follow-ups). Fix every `Critical`/`High` finding, or obtain the user's
   explicit deferral at the gate — recorded inline as
   `deferred(<reason + flip condition>)`.
5. Apply fixes (re-entering Implement conventions as needed); re-test until
   every acceptance line reads `pass`. Fix the underlying defect — **never
   edit a test or weaken a criterion to make it pass**; if a test itself is
   wrong, say so explicitly here and justify the change. A prior `pass` is
   stale the moment the behavior it covered changes — re-run and overwrite.
6. Record in `## Not Covered` whatever was not tested or security-reviewed,
   and why. Never leave gaps implicit.
7. Write `.workflow/05-verify.md` using its template sections, then run
   `.workflow/check-gate.sh` — it fails Verify if tests are missing/red, any
   acceptance line reads `fail`/`blocked`, `## Security` is empty or has an
   open Critical/High finding, or the secret scan hits. Do not advance until
   it exits 0.

*Information currency (see `_conventions.md`):* check the build against
currently-known vulnerabilities/CVEs and current tooling behavior, not
remembered ones. Record sources in `## Sources`.

## Output
`.workflow/05-verify.md` with: `## Test Coverage`, `## Bugs Found`,
`## Fixes Applied`, `## Residual Risks`, `## Acceptance`, `## Security`,
`## Not Covered`, `## Sources`.

## Gate
None during Verify. But the **next** phase (Go-to-Market) is gated: do not
start it automatically.

## Handoff
In `state.md` set `current_phase: 06-gtm`, check `05-verify.md`, add a Log
line. Update `.workflow/memory.md` per the Memory Protocol in
`_conventions.md`: append any non-obvious learnings from this phase; prune
entries now proven false, dismissed, or attended to. Do not start
Go-to-Market automatically — it has a pre-flight gate. Wait for the user to
invoke the Go-to-Market phase.
```

- [ ] **Step 4: Edit `core/03-design.md`** — insert a new Process step 5 (renumber "Write" to 6):

```markdown
5. Specify the design's security posture: trust boundaries (who talks to
   what, with which privileges), authn/authz per interface, and how sensitive
   data is stored, transported, and logged. Record it inside
   `## Interfaces & Contracts` and `## Data`. The Design gate runs the
   design-time checks in `core/_security-review.md` against exactly this.
```

Append the memory Handoff line (wording above) to its `## Handoff`.

- [ ] **Step 5: Edit the remaining phase files**

- `core/00-bootstrap.md`: in `## Output`, change "containing `state.md`, the six artifact templates" to "containing `state.md`, `memory.md`, the six artifact templates"; append to `## Handoff`: "`memory.md` starts empty — the Memory Protocol in `_conventions.md` governs it from here."
- `core/01-discover.md`, `core/02-plan.md`, `core/06-gtm.md`: append the memory Handoff line to each `## Handoff`.
- `core/04-implement.md`: append the memory Handoff line; additionally add to `## Process` step 3: "Never hard-code secrets into code or artifacts — `check-gate.sh` secret-scans the working tree, including `.workflow/`."

- [ ] **Step 6: Edit `templates/workflow/05-verify.md`** — full replacement:

```markdown
# 05 — Verify (QA + Bug Hunt + Security)
## Test Coverage
## Bugs Found
## Fixes Applied
## Residual Risks

## Acceptance
<!-- One line per success criterion from 01-brief.md, mapped to an automated test. -->
<!-- Format: criterion — test (path or id) — pass | fail | blocked(<reason>) -->
<!-- check-gate.sh requires at least one passing line and zero fail/blocked lines. -->

## Security
<!-- Run core/_security-review.md (full adversarial pass) and record results here. -->
<!-- One finding per line, status LAST: -->
<!-- S-NNN — title — Critical|High|Medium|Low — file:line — exploit scenario — fix — fixed|open|deferred(reason + flip condition) -->
<!-- Then: "Reviewed and found solid:" areas checked clean, and non-code follow-ups flagged. -->
<!-- check-gate.sh blocks on an empty section or any open Critical/High finding. -->

## Not Covered
<!-- What was NOT tested or security-reviewed, and why. Never leave gaps implicit. -->

## Sources
<!-- One line per external fact: claim — source (URL/command) — date checked. -->
<!-- Flag anything you could not verify as [unverified — from training data, as of <date>]. -->
```

- [ ] **Step 7: Run tests to verify they pass**

Run: `bash tests/check.sh`
Expected: `ALL CHECKS PASS` (the pre-existing six-section-contract and handoff greps must still pass — the rewrites above preserve them).

- [ ] **Step 8: Commit**

```bash
git add core/0*.md templates/workflow/05-verify.md tests/check.sh
git commit -m "feat: wire security pass and memory update into every phase loop"
```

---

### Task 5: Gate review, adapters, README

**Files:**
- Modify: `core/_gate-review.md`, `adapters/agents/AGENTS.md`, `adapters/claude-code/skills/ship/SKILL.md`, `adapters/claude-code/commands/ship-verify.md`, `adapters/continue/config.yaml`, `README.md`
- Modify: `tests/check.sh`

**Interfaces:**
- Consumes: `core/_security-review.md` design-time subset (Task 1).

- [ ] **Step 1: Add failing assertions**

```bash
grep -q '_security-review.md' core/_gate-review.md || note "gate-review missing design-time security checks"
grep -qi 'security' adapters/agents/AGENTS.md || note "AGENTS.md missing security rule"
grep -qi 'memory.md' adapters/agents/AGENTS.md || note "AGENTS.md missing memory rule"
grep -q '_security-review.md' adapters/claude-code/commands/ship-verify.md || note "ship-verify command missing security pass"
grep -qi 'memory.md' README.md || note "README missing memory.md in artifact trail"
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `bash tests/check.sh` — expect those five FAIL lines.

- [ ] **Step 3: Edit `core/_gate-review.md`**

In the `### Design (03-design.md)` checklist, append:

```markdown
- Run the **design-time security subset** in `core/_security-review.md`:
  trust boundaries, attacker profiles, sensitive-data handling, and
  authn/authz per interface. Verdict each `PASS`/`WARN`/`BLOCK` like the
  checks above.
```

In the `### Go-to-Market` checklist, append:

```markdown
- Does `05-verify.md`'s `## Security` carry any unresolved `open`
  Critical/High finding? That is a `BLOCK`. Deferred findings must show
  their reason + flip condition.
```

In the human rubric code block, after the "No BLOCK findings remain" line, add:

```
[ ] No open Critical/High security findings; deferrals carry a reason + flip condition.
[ ] memory.md was updated: learnings appended, stale/attended entries pruned.
```

- [ ] **Step 4: Edit the adapters (pointers only — no logic duplication)**

`adapters/agents/AGENTS.md`, append two bullets to `## Rules`:

```markdown
- **Security is part of the loop.** The Design gate runs the design-time
  checks and Verify runs the full adversarial pass in
  `core/_security-review.md`; `check-gate.sh` blocks on an empty
  `## Security`, an open Critical/High finding, or a secret-scan hit.
- **Memory:** read `.workflow/memory.md` at the start of every phase and
  update it at every Handoff per the Memory Protocol in
  `core/_conventions.md` — append non-obvious learnings; prune anything
  false, dismissed, or attended to. It holds only verified-true facts.
```

`adapters/claude-code/skills/ship/SKILL.md`, append to `## How to use` as point 4:

```markdown
4. Read `.workflow/memory.md` at the start of every phase and update it at
   every Handoff (Memory Protocol in `core/_conventions.md`). Security is in
   the loop: `core/_security-review.md` runs at the Design gate and in Verify.
```

`adapters/claude-code/commands/ship-verify.md`, replace the body with:

```markdown
Read `core/05-verify.md` from the ship toolkit repo and execute it against the
current project's `.workflow/`. First read `.workflow/state.md` and
`.workflow/memory.md`. Run the full security pass in
`core/_security-review.md` and record it in `## Security`. Obey the Gate
Protocol in `core/_conventions.md`.
```

`adapters/continue/config.yaml`: in the first `rules` entry, after "Information Currency (verify external facts, cite them in ## Sources).", insert before "Never improvise phase logic.":

```
Read .workflow/memory.md at every phase start and update it at every Handoff
(Memory Protocol). Run core/_security-review.md at the Design gate and during
Verify.
```

And in the `ship-verify` prompt, after "Map each success criterion to an automated test,", insert "run the security pass in core/_security-review.md,".

- [ ] **Step 5: Edit `README.md`**

In the Layer-2 tree block, after `state.md`, add:

```
  memory.md           # curated non-obvious learnings — verified-true facts only
```

In "Quality is enforced, not hoped for", extend the machine-gate bullet with "; enforces a non-empty `## Security` (no open Critical/High findings) and secret-scans the working tree — including `.workflow/`", and append one new bullet:

```markdown
- **Security + memory in the loop** — `core/_security-review.md` runs at the
  Design gate (trust boundaries, authn/authz, sensitive data) and as a full
  adversarial pass in Verify; `.workflow/memory.md` carries verified-true,
  non-obvious learnings across sessions — appended and pruned at every phase
  handoff.
```

- [ ] **Step 6: Run tests to verify they pass**

Run: `bash tests/check.sh`
Expected: `ALL CHECKS PASS`.

- [ ] **Step 7: Commit**

```bash
git add core/_gate-review.md adapters/ README.md tests/check.sh
git commit -m "feat: security + memory rules in gate review, adapters, and README"
```

---

### Task 6: Final verification sweep

**Files:**
- None new — verification only.

- [ ] **Step 1: Full test run**

Run: `bash tests/check.sh`
Expected: `GATE FIXTURE TESTS PASS` + `ALL CHECKS PASS`, exit 0.

- [ ] **Step 2: Spec-coverage spot check**

Confirm each spec promise has landed (grep, don't trust memory):

```bash
grep -c '_security-review.md' core/*.md adapters/agents/AGENTS.md   # design + verify + gate-review + AGENTS
grep -l 'memory.md' core/0*.md | wc -l                              # expect 7
bash -n templates/workflow/check-gate.sh && echo syntax-ok
```

- [ ] **Step 3: Verify clean tree and log**

Run: `git status --short` (expect empty) and `git log --oneline -8` (expect the five feat commits from Tasks 1–5 on top, above the earlier docs commits for the spec and this plan).
