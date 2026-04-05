# AGENTS.md — zmk-config

Concise instructions for AI coding agents. ZMK behavior and APIs: use Context7 with library ID `/zmkfirmware/zmk` (see `.cursor/rules/zmk-firmware-docs.mdc`). Do not duplicate long docs here.

## Project snapshot

- **Purpose**: User configuration for ZMK firmware (SplitKB Aurora Corne: halves + optional central dongle, Nice!View).
- **Stack**: ZMK on Zephyr; `west` workspace; CI uses `zmkfirmware/zmk/.github/workflows/build-user-config.yml` (see `.github/workflows/build.yml`).

## Layout

- **Board/shield sources**: `boards/shields/splitkb_aurora_corne/`
- **Keymap and Kconfig**: `config/` (`*.keymap`, `*.conf`)
- **CI build matrix**: `build.yaml` (source of truth for board/shield/snippet/cmake-args per artifact)
- **Plans / notes**: `docs/` (see `docs/README.md`)

## Commands

Run from repo root after a `west` workspace exists (paths match `README.md`; confirm before relying):

- **Init / update**: `west init -l config` then `west update`
- **Build (examples)**: `west build -b <board> -- -DSHIELD=<shields...> [extra cmake-args]` — use `**build.yaml`** for the exact `board`, `shield`, `snippet`, and `cmake-args` for each target; `README.md` may simplify shield lists.
- **Validate in CI**: push or open a PR; workflow **Build ZMK firmware** runs the user-config build.

There is no repo-local unit test script; firmware validation is build/CI and hardware checks.

## Workflow expectations

- Prefer small, reviewable changes; match existing style in neighboring `*.keymap`, `*.conf`, and shield files.
- After substantive config or shield edits, run the **narrowest** `west build` that covers your change, or rely on CI if no local workspace.

## Agent affordances

- **Rules**: `.cursor/rules/` — keep **≤2** `alwaysApply: true` globals; scope other rules with `globs` (see `zmk-config-files.mdc`).
- **Skills**: `.cursor/skills/` — add focused workflows here if recurring multi-step tasks appear (none required at init).
- **Human docs**: `README.md` (hardware, layers, flashing); `docs/` for supplementary material.

## Out of scope / do not

- Do not commit secrets, tokens, or personal `.env` files.
- Do not run production deploys or flash hardware unless the user explicitly asks; prefer documenting flash steps.