---
name: local-build
description: >-
  Test ZMK firmware locally via scripts/build-local.sh in Docker using the same
  image and west flow as GitHub Actions (build-user-config.yml @ main). Use
  before push, to reproduce CI failures, or when the user asks for a local
  container build.
---

# Local ZMK container build (this repo)

## When to use

- For **keyboard-specific** shield lists, merge order, or hardware (MCU, displays, BLE): use the **`keyboards`** skill ([`../keyboards/SKILL.md`](../keyboards/SKILL.md)) or read `docs/keyboards/<slug>.md` first (`slug` = shield prefix, e.g. `splitkb_aurora_corne`).
- Before pushing: confirm every row in [`build.yaml`](build.yaml) compiles.
- After CI failures: same image (`zmkfirmware/zmk-build-arm:stable`), `west init` / `west update --fetch-opt=--filter=tree:0`, and `west build` flags as CI ([`.github/workflows/build.yml`](.github/workflows/build.yml) → `build-user-config.yml` @ `main`).
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
- **Each firmware build:** a **new** `docker run` with **`docker run -i`** so `bash -s` reads the heredoc from stdin. Without `-i`, the heredoc is empty, **`west build` never runs**, and the script can still exit 0 — always keep **`-i`** on that invocation.
- Inside each build container, runs **`west zephyr-export`** before **`west build`** (fresh `$HOME`; Zephyr’s CMake package registry is not preserved across runs).
- Uses a fresh **`mktemp -d`** build dir per target (CI-style), then copies **`zephyr/zmk.uf2`** to **`firmware/<artifact>.uf2`**. Explicit **`ARTIFACT_NAME`** values match **`artifact-name`** in [`build.yaml`](build.yaml) (`corne_dongle`, `corne_left`, …).

## Matrix alignment (ZMK `main`, Zephyr 4.1)

[`build.yaml`](build.yaml) is the source of truth. Notable details for this tree:

| Target arg   | Board            | Notes |
| ------------ | ---------------- | ----- |
| `dongle`     | `xiao_ble//zmk`  | Seeed XIAO BLE; quote `-b` in shell (`//` starts a comment if unquoted). |
| `left`/`right` | `nice_nano//zmk` | Nice!Nano v2 default variant; not `nice_nano_v2`. |
| `reset-*`    | `xiao_ble//zmk` / `nice_nano//zmk` | `settings_reset` shield. |

Corne-specific shield strings, display Kconfig, and troubleshooting (**`nice_view_spi`**, **`splitkb_aurora_i2c_off`**, **`peripheral_status`**) live in [`docs/keyboards/splitkb_aurora_corne.md`](docs/keyboards/splitkb_aurora_corne.md).

## Success criteria

- Script exits **0**.
- Log lines **`-> /zmk-config/firmware/<artifact>.uf2`** per built target (host path: **`firmware/<artifact>.uf2`**).
- **`ls -la firmware/*.uf2`** shows non-zero sizes. Artifact basenames match **`build.yaml`** (`corne_dongle.uf2`, `corne_left.uf2`, …).

## Environment overrides

| Variable | Default | Purpose |
| --- | --- | --- |
| `ZMK_BUILD_IMAGE` | `zmkfirmware/zmk-build-arm:stable` | Pin or swap CI image |
| `ZMK_WEST_VOLUME` | `zmk-aurora-corne-west` | Named volume for west workspace |
| `ZMK_CONFIG_PATH` | `config` | Config directory under repo root |

## Troubleshooting

- **`docker: command not found`** — install Docker or Podman docker shim; do not assume a host `west` toolchain.
- **First run / `--init` is slow** — `west update` fills the named volume; later incremental builds are faster.
- **Stale ZMK / Zephyr after `west.yml` change** — **`./scripts/build-local.sh --init all`**; for a major bump, **`docker volume rm zmk-aurora-corne-west`** then **`--init all`**.

## Canonical references

- Matrix: [`build.yaml`](build.yaml)
- Corne inventory (shields, merge order, display/BLE): [`docs/keyboards/splitkb_aurora_corne.md`](docs/keyboards/splitkb_aurora_corne.md)
- Human steps: [`README.md`](README.md) (*Local container build*)
- Script: [`scripts/build-local.sh`](scripts/build-local.sh)
