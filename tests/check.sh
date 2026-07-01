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
grep -q 'current_phase: 02-plan'      core/01-discover.md  || note "Discover handoff: wrong next phase"
grep -q 'last_gate_passed: discover'  core/01-discover.md  || note "Discover handoff: wrong gate label"
grep -q 'current_phase: 03-design'    core/02-plan.md      || note "Plan handoff: wrong next phase"
grep -q 'current_phase: 04-implement' core/03-design.md    || note "Design handoff: wrong next phase"
grep -q 'last_gate_passed: design'    core/03-design.md    || note "Design handoff: wrong gate label"
grep -q 'current_phase: 05-verify'    core/04-implement.md || note "Implement handoff: wrong next phase"
grep -q 'current_phase: 06-gtm'       core/05-verify.md    || note "Verify handoff: wrong next phase"
grep -q 'current_phase: done'         core/06-gtm.md       || note "GTM handoff: wrong terminal state"

# Information currency rule + Sources sections
grep -qF '## Information Currency' core/_conventions.md || note "_conventions.md missing Information Currency rule"
for f in 01-brief 02-plan 03-design 04-implementation 05-verify 06-gtm; do
  grep -qF '## Sources' "templates/workflow/$f.md" || note "templates/workflow/$f.md missing ## Sources"
done
for f in core/01-discover.md core/02-plan.md core/03-design.md core/04-implement.md core/05-verify.md core/06-gtm.md; do
  grep -q 'Information currency' "$f" || note "$f missing Information currency note"
  grep -qF '## Sources' "$f"          || note "$f Output missing ## Sources"
done

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

# Quality hardening — machine gate, acceptance, critic/rubric
test -f templates/workflow/check-gate.sh || note "missing templates/workflow/check-gate.sh"
test -x templates/workflow/check-gate.sh || note "check-gate.sh is not executable"
bash -n templates/workflow/check-gate.sh 2>/dev/null || note "check-gate.sh has a syntax error"
test -f templates/ci/ship-gate.yml || note "missing templates/ci/ship-gate.yml"
test -f core/_gate-review.md || note "missing core/_gate-review.md"
grep -qF '## Quality Enforcement' core/_conventions.md || note "_conventions.md missing Quality Enforcement"
grep -qF '## Executable Acceptance Criteria' core/_conventions.md || note "_conventions.md missing Acceptance Criteria rule"
grep -q 'check-gate.sh' core/_conventions.md || note "_conventions.md does not reference check-gate.sh"
grep -qF '## Acceptance' templates/workflow/05-verify.md || note "verify template missing ## Acceptance"
grep -qF '## Acceptance' core/05-verify.md || note "core/05-verify.md missing ## Acceptance in Output"
grep -qi 'measurable' core/01-discover.md || note "Discover does not require measurable criteria"
# Every gated phase references the enforcement (check-gate + critic)
for f in core/01-discover.md core/03-design.md core/06-gtm.md; do
  grep -q 'check-gate.sh' "$f"     || note "$f gate does not run check-gate.sh"
  grep -q '_gate-review.md' "$f"   || note "$f gate does not run the critic"
done

if [ $fail -eq 0 ]; then echo "ALL CHECKS PASS"; else echo "CHECKS FAILED"; exit 1; fi
