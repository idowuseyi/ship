# ship in Continue (and Cline / OpenCode)

Drive the ship workflow from VS Code with the [Continue](https://continue.dev)
extension — including with a **local model** (Ollama, LM Studio, llama.cpp).

> Verified against `docs.continue.dev` and `docs.cline.bot`, July 2026. If the
> config format has since changed, check the current docs — per ship's own
> Information Currency rule, don't trust a remembered format.

## Continue

1. Open your Continue config (`~/.continue/config.yaml`, or a per-project
   `.continue/config.yaml`).
2. Merge in the `rules` and `prompts` blocks from [`config.yaml`](config.yaml).
3. Replace `/ABS/PATH/TO/ship` with the absolute path to your local ship repo.
4. In a project, invoke the phases as slash commands: `/ship-bootstrap`,
   `/ship-discover`, `/ship-plan`, `/ship-design`, `/ship-implement`,
   `/ship-verify`, `/ship-gtm`.

The `rules` block keeps ship's conventions always in context; the `prompts`
entries are thin — each just tells the model to read the matching `core/NN-*.md`
and execute it. Single source of truth is preserved.

Sources: [config.yaml reference](https://docs.continue.dev/reference),
[slash commands](https://docs.continue.dev/customize/slash-commands).

## Cline

Cline reads `AGENTS.md` natively as a cross-tool standard, so the existing
[`adapters/agents/AGENTS.md`](../agents/AGENTS.md) already works — copy it to your
project root (or symlink it). For invokable per-phase commands, add one workflow
file per phase under `.clinerules/workflows/` (e.g. `ship-discover.md`) whose body
is *"Read `core/01-discover.md` from the ship repo and execute it against
`.workflow/`."*

Source: [Cline rules](https://docs.cline.bot/customization/cline-rules).

## OpenCode and other AGENTS.md tools

Point them at [`adapters/agents/AGENTS.md`](../agents/AGENTS.md); no extra config
needed.

## Running a local model? Read this next

A local/weak model changes the quality math. See
[`adapters/local/README.md`](../local/README.md) for how ship still holds a
quality floor when the model is stale or small.
