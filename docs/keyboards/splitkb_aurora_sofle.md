# Inventory: SplitKB Aurora Sofle (v2 kit)

**Slug:** `splitkb_aurora_sofle` (ZMK shield prefix — use for `rg` across `config/`, `boards/shields/`, and this doc).

## Summary

- **Kit:** [SplitKB Aurora Sofle v2](https://splitkb.com/products/aurora-sofle-v2-pcb-kit) — 58-key split with number row; ZMK uses the upstream **Aurora Sofle** shields (no separate `*_v2` shield name).
- **Roles:** BLE halves on **Nice!Nano** (`nice_nano//zmk`). Committed `*.conf` enables **per-key RGB** (white at boot) and **EC11**; **OLED** stays off unless you add `CONFIG_ZMK_DISPLAY=y` (see below).
- **ZMK:** Shared keymap [`config/splitkb_aurora_sofle.keymap`](../../config/splitkb_aurora_sofle.keymap); half-specific Kconfig [`config/splitkb_aurora_sofle_left.conf`](../../config/splitkb_aurora_sofle_left.conf), [`config/splitkb_aurora_sofle_right.conf`](../../config/splitkb_aurora_sofle_right.conf).

## Components

| Unit       | MCU / part                     | Notes                                                                                                    |
| ---------- | ------------------------------ | -------------------------------------------------------------------------------------------------------- |
| Left half  | Nice!Nano v2                   | `splitkb_aurora_sofle_left`                                                                              |
| Right half | Nice!Nano v2                   | `splitkb_aurora_sofle_right`                                                                             |
| Displays   | 128×32 I2C OLED (optional)     | Upstream DTS uses SSD1306 on `&pro_micro_i2c`; enable `CONFIG_ZMK_DISPLAY=y` in `*.conf` when using OLED |
| Encoders   | EC11 (one per half)            | Upstream half overlays enable the encoder node; stock keymap uses `sensor-bindings`                      |
| RGB        | Per-key SK6812 (optional bottom strip) | `CONFIG_ZMK_RGB_UNDERGLOW` + `&led_strip` `chain-length` in [`splitkb_aurora_sofle.keymap`](../../config/splitkb_aurora_sofle.keymap) (`29` per-key, `35` if bottom WS2812s per half are populated) |

## Bluetooth (halves)

Committed defaults mirror Aurora Corne halves for RF policy:

- `CONFIG_BT_CTLR_TX_PWR_PLUS_8=y`
- `CONFIG_BT_CTLR_PHY_2M=n`

Adjust in `splitkb_aurora_sofle_{left,right}.conf` if your host or environment needs different settings.

## Optional features (OLED)

Upstream shield [`splitkb_aurora_sofle.conf`](https://raw.githubusercontent.com/zmkfirmware/zmk/main/app/boards/shields/splitkb_aurora_sofle/splitkb_aurora_sofle.conf) documents additional snippets:

- **OLED:** `CONFIG_ZMK_DISPLAY=y` in `splitkb_aurora_sofle_{left,right}.conf` — compare with upstream shield docs for status screen / blank-on-idle.

## Firmware mapping (`build.yaml`)

| `artifact-name` | Board            | Shield(s)                    |
| --------------- | ---------------- | ---------------------------- |
| `sofle_left`    | `nice_nano//zmk` | `splitkb_aurora_sofle_left`  |
| `sofle_right`   | `nice_nano//zmk` | `splitkb_aurora_sofle_right` |

**Nice!Nano erase firmware** is **not** duplicated for Sofle: use the shared CI artifact **`reset_nano`** (same `settings_reset` build as Aurora Corne). Flash `firmware/reset_nano.uf2` when clearing storage on any Nice!Nano in this repo.

Full matrix: [`build.yaml`](../../build.yaml).

## Config pointers

- Keymap: [`config/splitkb_aurora_sofle.keymap`](../../config/splitkb_aurora_sofle.keymap)
- Kconfig: [`config/splitkb_aurora_sofle_left.conf`](../../config/splitkb_aurora_sofle_left.conf), [`config/splitkb_aurora_sofle_right.conf`](../../config/splitkb_aurora_sofle_right.conf)
- West manifest: [`config/west.yml`](../../config/west.yml)

## Zephyr module (repo root)

[`zephyr/module.yml`](../../zephyr/module.yml) sets **`board_root: .`** when this repo is passed as `ZMK_EXTRA_MODULES` (CI and [`scripts/build-local.sh`](../../scripts/build-local.sh)). Sofle shields ship **in ZMK upstream**; this repo does not add out-of-tree Sofle shields.

## Shield paths

- **Upstream only:** `splitkb_aurora_sofle_left` / `splitkb_aurora_sofle_right` — single shield name each (no Nice!View stack, no `splitkb_aurora_i2c_off`).

## Local Docker targets

[`scripts/build-local.sh`](../../scripts/build-local.sh) / [`Makefile`](../../Makefile):

| Target                       | Builds                                                                       |
| ---------------------------- | ---------------------------------------------------------------------------- |
| `sofle-left` / `sofle-right` | One Sofle half UF2                                                           |
| `sofle-all`                  | Left then right (`reset_nano` **not** included)                              |
| `corne-all`                  | Corne dongle, halves, `reset_xiao`, **`reset_nano` once**                    |
| `all`                        | `corne-all` then `sofle-all` (Nice!Nano reset built only inside `corne-all`) |

## Build gotchas

1. **No in-tree Sofle dongle** — unlike Corne, there is no upstream `splitkb_aurora_sofle_dongle`; central USB + ZMK Studio would be a custom shield project.
2. **Stock keymap** — based on upstream `splitkb_aurora_sofle.keymap`; lower layer uses `&ext_power` behaviors (harmless when not used; trim if you drop ext power from your board).
3. **Optional OLED** — enabling display may require additional ZMK display Kconfig (status screen, blank-on-idle); compare with upstream shield docs when turning on `CONFIG_ZMK_DISPLAY`.
4. **Per-key RGB** — [`config/splitkb_aurora_sofle.keymap`](../../config/splitkb_aurora_sofle.keymap) sets `&led_strip` `chain-length = <29>` per half (per-key only, matches upstream stock comments). If you soldered **both** per-key SK6812 and the **6** bottom WS2812 underglow LEDs per half, use `<35>` instead. [`splitkb_aurora_sofle_{left,right}.conf`](../../config/splitkb_aurora_sofle_left.conf) enables `CONFIG_ZMK_RGB_UNDERGLOW` with **saturation 0** for white at boot. Nice!Nano **SPI MOSI is P0.06**; **pro_micro pin 6** is **P1.00** (matrix column) — they are not the same net.
   6666```
