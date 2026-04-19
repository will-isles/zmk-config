---
name: local-build
description: >-
  Test ZMK firmware locally via scripts/build-local.sh in Docker using the same
  image and west flow as GitHub Actions (build-user-config.yml @ v0.3). Use
  before push, to reproduce CI failures, or when the user asks for a local
  container build.
---

# Local ZMK container build (this repo)

## When to use

- Before pushing: confirm every row in [`build.yaml`](build.yaml) compiles.
- After CI failures: same image (`zmkfirmware/zmk-build-arm:stable`), `west init` / `west update --fetch-opt=--filter=tree:0`, and `west build` flags as CI ([`.github/workflows/build.yml`](.github/workflows/build.yml) → `build-user-config.yml` @ v0.3).
- When the user wants UF2s without opening GitHub Actions.

## How to run

From the **repository root** (Docker or Podman with a `docker`-compatible CLI on `PATH`):

```bash
docker pull zmkfirmware/zmk-build-arm:stable   # optional; first run pulls anyway
./scripts/build-local.sh                       # all matrix targets
./scripts/build-local.sh left                  # dongle | left | right | reset-xiao | reset-nano
./scripts/build-local.sh --init all            # after config/west.yml revision change
```

Outputs go to **`firmware/`** (gitignored). The west tree is cached in Docker volume **`zmk-aurora-corne-west`** (override with `ZMK_WEST_VOLUME`).

## What the script does (agent-relevant)

- Binds this repo at **`/zmk-config`** and passes **`-DZMK_EXTRA_MODULES=/zmk-config`** when `zephyr/module.yml` exists (same idea as CI).
- Syncs **`config/`** into the volume before init/builds.
- **First run (empty volume):** `west init -l …/config`, `west update --fetch-opt=--filter=tree:0`, `west zephyr-export`.
- **Each firmware build:** a **new** `docker run` with **`docker run -i`** so `bash -s` reads the heredoc script from stdin. Without `-i`, the heredoc is empty, **`west build` never runs**, and the script can still exit 0 — always keep **`-i`** on that invocation.
- Inside each build container, runs **`west zephyr-export`** before **`west build`** (fresh `$HOME`; Zephyr’s CMake package registry is not preserved across runs).
- Uses a fresh **`mktemp -d`** build dir per target (CI-style), then copies **`zephyr/zmk.uf2`** to **`firmware/<artifact>.uf2`**.

## Matrix alignment (current ZMK `main`)

[`build.yaml`](build.yaml) is the source of truth. Notable details for this tree:

| Target arg   | Board      | Notes |
| ------------ | ---------- | ----- |
| `dongle`     | `xiao_ble` | Seeed XIAO BLE in Zephyr 4.1 / current ZMK (`xiao_ble`, not `seeeduino_xiao_ble`). |
| `left`/`right` | `nice_nano` | Unified HWMv2 board (`nice_nano`, not `nice_nano_v2`). |
| `reset-*`    | `xiao_ble` / `nice_nano` | `settings_reset` shield. |

Left/right shield strings include repo-local helpers under **`boards/shields/`**:

- **`splitkb_nice_view_spi`** — defines **`nice_view_spi`** before `nice_view.overlay` (module `nice_nano` path does not pick up ZMK’s `nice_view_adapter/boards/…` fragment).
- **`splitkb_aurora_i2c_off`** — merged **last**; disables **`&i2c0` / `&pro_micro_i2c`** so **`splitkb_aurora_corne.dtsi`** does not leave TWI0 enabled alongside SPIM0 (nRF52840 instance conflict).

Halves use **`config/splitkb_aurora_corne_{left,right}.conf`**: **`CONFIG_ZMK_DISPLAY_STATUS_SCREEN_BUILT_IN=y`** and **`CONFIG_ZMK_DISPLAY_STATUS_SCREEN_CUSTOM=n`** so the nice!view custom path does not link **`peripheral_status.c`** on split peripheral with current ZMK. If display regressions appear, compare against upstream nice!view + split behavior before re-enabling custom status.

## Success criteria

- Script exits **0**.
- Log lines **`-> /zmk-config/firmware/<artifact>.uf2`** per built target (host path: **`firmware/<artifact>.uf2`**).
- **`ls -la firmware/*.uf2`** shows non-zero sizes. Default artifact names mirror CI (`shield-board-zmk.uf2`); long **`shield`** strings yield long filenames (often **spaces** in the name).

## Environment overrides

| Variable | Default | Purpose |
| --- | --- | --- |
| `ZMK_BUILD_IMAGE` | `zmkfirmware/zmk-build-arm:stable` | Pin or swap CI image |
| `ZMK_WEST_VOLUME` | `zmk-aurora-corne-west` | Named volume for west workspace |
| `ZMK_CONFIG_PATH` | `config` | Config directory under repo root |

## Troubleshooting

- **`docker: command not found`** — install Docker or Podman docker shim; do not assume a host `west` toolchain.
- **First run / `--init` is slow** — `west update` fills the named volume; later incremental builds are faster.
- **`nice_view_spi` undefined** — ensure left/right matrix still includes **`splitkb_nice_view_spi`** (and ordering) in `build.yaml` and [`scripts/build-local.sh`](scripts/build-local.sh).
- **SPI0 / TWI0 static assert** — ensure **`splitkb_aurora_i2c_off`** remains **last** in the shield list for halves.
- **Linker errors from `peripheral_status.c`** on halves — halves conf uses built-in display status screen; re-enabling custom status may require upstream ZMK / extra Kconfig (entropy, battery reporting) to match.
- **Stale ZMK / Zephyr after `west.yml` change** — **`./scripts/build-local.sh --init all`**.

## Canonical references

- Matrix: [`build.yaml`](build.yaml)
- Human steps: [`README.md`](README.md) (*Local container build*)
- Script: [`scripts/build-local.sh`](scripts/build-local.sh)
- Helper shields: [`boards/shields/splitkb_nice_view_spi/`](boards/shields/splitkb_nice_view_spi/), [`boards/shields/splitkb_aurora_i2c_off/`](boards/shields/splitkb_aurora_i2c_off/)
