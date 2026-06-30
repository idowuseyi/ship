# Using ship in any chat tool (copy-paste)

No integration required — ship is plain markdown. Use it in ChatGPT, Gemini, or
any agent like this.

## One-time per project
1. Create a `.workflow/` folder in your project.
2. Copy the files from the ship repo's `templates/workflow/` into it.
3. In `state.md`, set the project name and date.

## Running a phase
1. Paste the contents of `core/_conventions.md` (once per session) so the tool
   knows the rules.
2. Paste the current `.workflow/state.md` and any artifacts it lists as done.
3. Paste the phase prompt for where you are:
   - Discover → `core/01-discover.md`
   - Plan → `core/02-plan.md`
   - Design → `core/03-design.md`
   - Implement → `core/04-implement.md`
   - Verify → `core/05-verify.md`
   - Go-to-Market → `core/06-gtm.md`
4. Do what the phase says, save its artifact into `.workflow/`, and update
   `state.md`.

## Gates
Stop for your own approval after Discover, after Design, and before
Go-to-Market. Implement flows straight into Verify.

## Switching tools mid-project
Because everything lives in `.workflow/`, you can switch tools any time: open the
new tool, paste `state.md` + the done artifacts + the current phase prompt, and
continue.
