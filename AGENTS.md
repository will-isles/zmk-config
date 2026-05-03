# AGENTS.md — zmk-config

Concise instructions for AI coding agents. ZMK behavior and APIs: use Context7 with library ID `/zmkfirmware/zmk` (see `.cursor/rules/zmk-firmware-docs.mdc`). Do not duplicate long docs here.

## Project snapshot

- **Purpose**: User configuration for ZMK firmware (SplitKB Aurora Corne: halves + optional central dongle, Nice!View).
- **Stack**: ZMK on Zephyr; `west` workspace; CI uses `zmkfirmware/zmk/.github/workflows/build-user-config.yml@main` (see `.github/workflows/build.yml`) until a **`v0.4.x`** release tag is published—then pin the same tag in `config/west.yml` and the workflow `uses:` ref.

## Layout

Monorepo matches [ZMK config — file locations](https://zmk.dev/docs/config/): root [`build.yaml`](build.yaml), [`config/`](config/) for user keymaps/Kconfig + [`config/west.yml`](config/west.yml), repo-root [`boards/shields/`](boards/shields/) for out-of-tree shields (not `config/boards/shields/` — deprecated upstream). [`zephyr/module.yml`](zephyr/module.yml) sets `board_root: .` so Zephyr discovers `boards/shields/` when built with `ZMK_EXTRA_MODULES` (CI and [`scripts/build-local.sh`](scripts/build-local.sh)).

- **Board/shield sources (in-repo)**:
  - `boards/shields/splitkb_aurora_corne/` — Aurora Corne dongle + shared DTS/Kconfig
  - `boards/shields/splitkb_nice_view_spi/` — defines `nice_view_spi` before `nice_view` (halves matrix)
  - `boards/shields/splitkb_aurora_i2c_off/` — disables `&i2c0` / `&pro_micro_i2c`; must be **last** in the halves shield list in `build.yaml`
- **Keymap and Kconfig**: `config/` (`*.keymap`, `*.conf`)
- **Per-keyboard inventory**: `docs/keyboards/` (see [`docs/keyboards/README.md`](docs/keyboards/README.md)); use skill `.cursor/skills/keyboards/` before keyboard-specific build assumptions.
- **CI build matrix**: `build.yaml` (source of truth for board/shield/snippet/cmake-args per artifact)
- **Plans / notes**: `docs/` (see `docs/README.md`)

## Commands

Run from repo root after a `west` workspace exists (paths match `README.md`; confirm before relying):

- **Init / update**: `west init -l config` then `west update`
- **Build (examples)**: `west build -b <board> -- -DSHIELD=<shields...> [extra cmake-args]` — use `**build.yaml`** for the exact `board`, `shield`, `snippet`, and `cmake-args` for each target; `README.md` may simplify shield lists.
- **Validate in CI**: push or open a PR; workflow **Build ZMK firmware** runs the user-config build.
- **Local container build (CI parity)**: `make build` or `./scripts/build-local.sh` — same image and `west` flow as `build-user-config.yml`; optional `TARGET=left`, `INIT=1`; see `README.md`, [`Makefile`](Makefile), and skill `.cursor/skills/local-build/`.

There is no repo-local unit test script; firmware validation is build/CI and hardware checks.

## Workflow expectations

- Prefer small, reviewable changes; match existing style in neighboring `*.keymap`, `*.conf`, and shield files.
- After substantive config or shield edits, run the **narrowest** `west build` that covers your change, or rely on CI if no local workspace.

## Agent affordances

- **Rules**: `.cursor/rules/` — keep **≤2** `alwaysApply: true` globals; scope other rules with `globs` (see `zmk-config-files.mdc`).
- **Skills**: `.cursor/skills/` — `keyboards` (inventory + hardware truth); `local-build` for Docker-based CI-parity builds.
- **Human docs**: `README.md` (layers, flashing, container build); hardware detail in `docs/keyboards/<slug>.md`.

## Out of scope / do not

- Do not commit secrets, tokens, or personal `.env` files.
- Do not run production deploys or flash hardware unless the user explicitly asks; prefer documenting flash steps.