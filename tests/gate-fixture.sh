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

# 8. open Low finding whose text merely contains "highlighted"/"highly" must
# not be mistaken for an open Critical/High finding (substring-match trap).
r=$(make_fixture 05-verify)
write_verify "$r" 'criterion A — tests/a — pass' \
  'S-002 — leaked config highlighted in logs — Low — src/y:5 — logs are highly visible — redact — open'
"$r/.workflow/check-gate.sh" >/dev/null 2>&1 || note "open Low finding mentioning highlighted/highly should not block"
rm -rf "$r"

# 9. passing acceptance line whose criterion text mentions blocked/failing
# must not be mistaken for an actual blocked/failing verdict (substring-match trap).
r=$(make_fixture 05-verify)
write_verify "$r" 'criterion A (previously blocked, failing before) — tests/a — pass' \
  'S-001 — sample — Low — src/x:1 — n/a — n/a — fixed'
"$r/.workflow/check-gate.sh" >/dev/null 2>&1 || note "passing criterion mentioning blocked/failing in prose should not block"
rm -rf "$r"

# 10. GTM pre-flight (no 06-gtm.md yet): hyphen-delimited open High security
# finding in 05-verify.md must still block — proves check_security is wired
# into the pre-flight else-branch, and exercises the hyphen-delimiter fix
# (Fix 1) from that branch too.
r=$(make_fixture 06-gtm)
write_verify "$r" 'criterion A — tests/a — pass' \
  'S-001 - auth bypass - High - src/x:1 - scenario - fix - open'
"$r/.workflow/check-gate.sh" >/dev/null 2>&1 && note "GTM pre-flight with hyphen-delimited open High finding should block"
rm -rf "$r"

# 11. hyphen-delimited open High finding blocks at 05-verify (locks Fix 1:
# the severity pre-filter must accept single "-" as a field delimiter, not
# just em-dash / double-hyphen).
r=$(make_fixture 05-verify)
write_verify "$r" 'criterion A — tests/a — pass' \
  'S-001 - auth bypass - High - src/x:1 - scenario - fix - open'
"$r/.workflow/check-gate.sh" >/dev/null 2>&1 && note "hyphen-delimited open High finding should block"
rm -rf "$r"

# 12. blocked acceptance line whose reason itself contains nested parens
# blocks (locks Fix 3: the blocked regex must not stop at the first ")").
# A separate passing line is included so the only thing that can trigger a
# block is correct detection of the (parenthesized) blocked line itself.
r=$(make_fixture 05-verify)
write_verify "$r" "$(printf 'criterion A — tests/a — pass\ncriterion B — tests/b — blocked(env down (staging))')" \
  'S-001 — sample — Low — src/x:1 — n/a — n/a — fixed'
"$r/.workflow/check-gate.sh" >/dev/null 2>&1 && note "blocked acceptance with nested parens in reason should block"
rm -rf "$r"

if [ "$fail" -eq 0 ]; then echo "GATE FIXTURE TESTS PASS"; else echo "GATE FIXTURE TESTS FAILED"; exit 1; fi
