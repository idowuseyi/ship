# ship — Gate Review (critic + human rubric)

Run this at every hard gate (after Discover, after Design, before Go-to-Market).
It has two parts: an **adversarial critic pass** the model runs on itself, and a
**human rubric** presented to the user. Neither replaces the machine check
(`.workflow/check-gate.sh`) — they catch the class of defects a script cannot:
weak reasoning, unstated assumptions, and confident-but-wrong claims.

## Who should run the critic

Route the critic to the **strongest model available** — not necessarily the one
doing the build. A capable pattern for local/weak models: a cheap local model
does Discover→Implement, and a stronger model (even an occasional API call) runs
only these three gate reviews. If only one weak model is available, run it again
in a **fresh context** with the explicit instruction *"Your job is to find what is
wrong with this artifact. Assume it contains at least one serious flaw."*
Adversarial framing in a clean context catches errors self-review misses.

## Critic pass (model)

For the artifact at this gate, produce a verdict for each check:
`PASS`, `WARN` (note it), or `BLOCK` (must fix before the gate). Record the
results in the artifact. **Every `BLOCK` must be resolved before presenting the
gate to the human.**

### Universal checks (all gates)
- **Grounding:** Is every external fact (version, API, price, policy, competitor
  claim) backed by a dated entry in `## Sources`? Any claim from memory that is
  not flagged `[unverified]` is a `BLOCK`.
- **Internal consistency:** Do later sections contradict earlier ones, or the
  prior artifacts (`state.md`, earlier phases)?
- **Unstated assumptions:** What is being taken for granted that, if false, breaks
  the artifact? List them.
- **Completeness:** Are all required section headers present *and substantive*
  (not empty, not restating the heading)?

### Discover (`01-brief.md`)
- Are success criteria **measurable** (numbers/thresholds/observable behavior),
  not adjectives? Vague criteria are a `BLOCK`.
- Is the problem validated against current reality (already solved? real users?),
  with sources?
- Is scope explicit — both in and out?

### Design (`03-design.md`)
- Does every component have one clear responsibility and a defined interface?
- Are the primary failure modes and their handling specified?
- Does the design actually satisfy each requirement in `01-brief.md`? Map them.
- Is it the *simplest* design that meets the brief, or is it over-engineered?
- Run the **design-time security subset** in `core/_security-review.md`:
  trust boundaries, attacker profiles, sensitive-data handling, and
  authn/authz per interface. Verdict each `PASS`/`WARN`/`BLOCK` like the
  checks above.

### Go-to-Market (`06-gtm.md`, reviewed before starting)
- Does the positioning follow from the brief's problem/users, not generic hype?
- Are channel, pricing, and policy claims verified against current sources?
- Is every claim about the product something Verify actually proved?
- Does `05-verify.md`'s `## Security` carry any unresolved `open`
  Critical/High finding? That is a `BLOCK`. Deferred findings must show
  their reason + flip condition.

## Human rubric (present at the gate)

Show the user this checklist alongside the summary, so approval is informed:

```
Gate rubric — confirm before you reply `approved`:
[ ] The machine check (.workflow/check-gate.sh) passed.
[ ] Success criteria are measurable, and (at Verify onward) backed by passing tests.
[ ] Every external fact has a dated source; unverifiable ones are flagged.
[ ] No BLOCK findings remain from the critic pass.
[ ] No open Critical/High security findings; deferrals carry a reason + flip condition.
[ ] memory.md was updated: learnings appended, stale/attended entries pruned.
[ ] The artifact actually solves the problem in 01-brief.md — not an adjacent one.
[ ] You understand the trade-offs and are comfortable proceeding.
```

Approval is the human's; the rubric only makes it an informed one.
