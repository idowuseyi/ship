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

```
S-NNN — <title> — <Critical|High|Medium|Low> — <file:line> — <exploit scenario> — <fix> — <fixed|open|deferred(<reason + flip condition>)>
```

Never wrap a finding line, even past 80 columns — the gate matches whole lines.

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
