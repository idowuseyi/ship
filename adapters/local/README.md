# ship with a local or weak model

You can run ship end-to-end on a local model (Ollama, LM Studio, llama.cpp) driving
VS Code via Continue/Cline. But be honest about the ceiling.

## What a workflow can and cannot do

**No process can guarantee a masterpiece from a weak model.** A workflow reduces
variance and raises the *floor*; it cannot manufacture capability the model lacks.
A model with a 2023 training cutoff will confidently invent APIs, package names,
and versions — its dominant failure mode is *stale certainty*.

The way ship stays robust anyway is a single principle:

> **Make correctness checkable by something other than the model.**

The model can *assert* "no bugs, ship it." It cannot make a failing test pass, a
broken build compile, or a linter go quiet by asserting. Those are the guarantees
that survive a weak model. ship leans on them deliberately.

## The five levers (in priority order)

1. **Give the model tools, and trust the result, not the memory.**
   Point the model's environment at web search / docs / package registries so the
   Information Currency rule can actually run. Then verify by *execution*: the
   build must compile, dependencies must really install, tests must run. Pin
   versions and generate a lockfile. Never let a recalled import ship unverified.

2. **Let `check-gate.sh` and CI be the real gate.**
   The machine gate (`.workflow/check-gate.sh`, plus `templates/ci/ship-gate.yml`)
   validates artifacts and runs your build/test/lint. A weak model cannot skip a
   hook or a red CI job. Treat a non-zero exit exactly like a failing test: stop.

3. **Route the three gate reviews to a stronger model.**
   This is the highest-leverage move: let the cheap local model do the bulk work
   (Discover→Implement), and send only the three gate critiques
   (`core/_gate-review.md`) to a stronger model — even an occasional API call.
   You get most of a strong model's judgment at a fraction of the cost, and only
   where it matters most. If you truly have only the weak model, run it again in a
   **fresh context** with *"find what is wrong with this — assume a serious flaw
   exists."* Adversarial framing in a clean context catches errors self-review
   misses.

4. **You are the backstop — use the rubric.**
   At each gate, ship hands you the checklist in `core/_gate-review.md`. A weak
   model makes the human reviewer *more* important, not less. Don't rubber-stamp:
   walk the rubric.

5. **Smaller steps, shown work.**
   Weak models do markedly better with small sub-tasks and explicit reasoning.
   In Implement, build one design unit at a time, commit, and run its test before
   the next — rather than one big generation.

## When there is no tool access at all

If the local model has no web/registry access, Information Currency degrades to:
every external fact is flagged `[unverified — from training data]` and handed to
**you** to confirm. That is by design — an honest "I could not verify this" beats a
confident fabrication. In that mode, levers 2–4 (machine gate, stronger-model
critic, your rubric) are what hold quality. Consider running at least the gate
critiques on a current, tool-enabled model.

## Bottom line

ship does not promise a masterpiece from a 2023 Llama. It promises that the parts
that *can* be checked mechanically **are** checked, that a stronger reviewer sees
the decisions that matter, and that nothing reaches "done" on the model's word
alone. That is how you get a dependable result regardless of which model is driving.
