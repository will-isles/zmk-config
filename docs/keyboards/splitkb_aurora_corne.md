# Inventory: SplitKB Aurora Corne

**Slug:** `splitkb_aurora_corne` (same string as the ZMK shield prefix — use for `rg` across `config/`, `boards/shields/`, and this doc).

## Summary

- **Kit:** SplitKB Aurora Corne — 36-key column-staggered split.
- **Roles:** BLE halves (Nice!Nano v2) + optional USB **central dongle** (Seeed XIAO BLE) + Nice!View on each half.
- **ZMK:** Shared keymap [`config/splitkb_aurora_corne.keymap`](../../config/splitkb_aurora_corne.keymap); half-specific Kconfig [`config/splitkb_aurora_corne_left.conf`](../../config/splitkb_aurora_corne_left.conf), [`config/splitkb_aurora_corne_right.conf`](../../config/splitkb_aurora_corne_right.conf).

## Components

| Unit | MCU / part | Notes |
| --- | --- | --- |
| Left half | Nice!Nano v2 | Peripheral; Nice!View |
| Right half | Nice!Nano v2 | Peripheral; Nice!View |
| Central (optional) | Seeed XIAO BLE | Dongle build: `CONFIG_ZMK_SPLIT_ROLE_CENTRAL=y`, ZMK Studio |
| Displays | Nice!View 128×64 | Via `nice_view_adapter` + `nice_view` in matrix |

## Bluetooth (halves)

From [`config/splitkb_aurora_corne_{left,right}.conf`](../../config/splitkb_aurora_corne_left.conf):

- **Transmit power:** +8 dBm (`CONFIG_BT_CTLR_TX_PWR_PLUS_8=y`) — range / stability for splits.
- **2M PHY:** off (`CONFIG_BT_CTLR_PHY_2M=n`) — compatibility with older hosts.

## Display (halves)

Halves use **built-in** status screen (not custom) so the nice!view path does not pull widgets that do not link cleanly on split peripherals:

- `CONFIG_ZMK_DISPLAY_STATUS_SCREEN_BUILT_IN=y`
- `CONFIG_ZMK_DISPLAY_STATUS_SCREEN_CUSTOM=n`
- `CONFIG_ZMK_WIDGET_PERIPHERAL_STATUS=n`

If display regressions appear, compare against upstream Nice!View + split behavior before re-enabling custom status.

## Firmware mapping (`build.yaml`)

| `artifact-name` | Board | Role |
| --- | --- | --- |
| `corne_dongle` | `xiao_ble//zmk` | Central + Studio (`studio-rpc-usb-uart` snippet) |
| `corne_left` | `nice_nano//zmk` | Left half firmware |
| `corne_right` | `nice_nano//zmk` | Right half firmware |
| `reset_xiao` | `xiao_ble//zmk` | `settings_reset` for XIAO |
| `reset_nano` | `nice_nano//zmk` | `settings_reset` for Nice!Nano |

Full matrix: [`build.yaml`](../../build.yaml).

## Config pointers

- Keymap: [`config/splitkb_aurora_corne.keymap`](../../config/splitkb_aurora_corne.keymap)
- Kconfig: [`config/splitkb_aurora_corne_left.conf`](../../config/splitkb_aurora_corne_left.conf), [`config/splitkb_aurora_corne_right.conf`](../../config/splitkb_aurora_corne_right.conf)
- West manifest: [`config/west.yml`](../../config/west.yml)

## Zephyr module (repo root)

[`zephyr/module.yml`](../../zephyr/module.yml) sets **`board_root: .`** so the checkout root is the board root: Zephyr finds **`boards/shields/…`** when the build passes **`ZMK_EXTRA_MODULES`** pointing at this repo (GitHub Actions `build-user-config.yml` and [`scripts/build-local.sh`](../../scripts/build-local.sh)).

## Shield paths (in-repo)

- **Primary:** [`boards/shields/splitkb_aurora_corne/`](../../boards/shields/splitkb_aurora_corne/) — `Kconfig.shield`, `Kconfig.defconfig`, `splitkb_aurora_corne_dongle.{conf,overlay}`.
- **Helper — `splitkb_nice_view_spi`:** [`boards/shields/splitkb_nice_view_spi/`](../../boards/shields/splitkb_nice_view_spi/) — defines **`nice_view_spi`** before `nice_view.overlay` (module `nice_nano` path does not pick up ZMK’s `nice_view_adapter/boards/…` fragment). **Include before** `nice_view_adapter` / `nice_view` in the shield list (see `build.yaml` left/right rows).
- **Helper — `splitkb_aurora_i2c_off`:** [`boards/shields/splitkb_aurora_i2c_off/`](../../boards/shields/splitkb_aurora_i2c_off/) — merged **last**; disables **`&i2c0` / `&pro_micro_i2c`** so **`splitkb_aurora_corne.dtsi`** does not leave TWI0 enabled alongside SPIM0 (nRF52840 instance conflict).

## Build gotchas (Corne-specific)

1. **Shield order (left/right in `build.yaml` and `scripts/build-local.sh`):**  
   `splitkb_nice_view_spi` … `splitkb_aurora_corne_{left,right}` … `nice_view_adapter` `nice_view` **`splitkb_aurora_i2c_off` last**.

2. **Halves Kconfig:** `CONFIG_ZMK_DISPLAY_STATUS_SCREEN_BUILT_IN=y`, `CONFIG_ZMK_DISPLAY_STATUS_SCREEN_CUSTOM=n` — avoids linker issues from **`peripheral_status.c`** on split peripheral with current ZMK. Re-enabling custom status may require upstream ZMK / extra Kconfig (entropy, battery reporting) to match.

3. **Troubleshooting:** If **`nice_view_spi` undefined** — ensure halves matrix still includes **`splitkb_nice_view_spi`** (and ordering). If **SPI0 / TWI0 static assert** — ensure **`splitkb_aurora_i2c_off`** remains **last** in the shield list for halves. If **linker errors from `peripheral_status.c`** on halves — confirm built-in status screen settings above.
