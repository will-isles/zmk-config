# ZMK Configuration for SplitKB Aurora Corne

This repository contains the ZMK firmware configuration for a SplitKB Aurora Corne split keyboard.

## Hardware

Physical setup, MCUs, displays, BLE options, and **Corne-specific build notes** (shield merge order, Nice!View): **[`docs/keyboards/splitkb_aurora_corne.md`](docs/keyboards/splitkb_aurora_corne.md)** (slug = `splitkb_aurora_corne`). Index of keyboards: [`docs/keyboards/README.md`](docs/keyboards/README.md).

This repo follows [ZMK’s documented layout](https://zmk.dev/docs/config/): root [`build.yaml`](build.yaml), [`config/`](config/) for user keymaps/Kconfig + [`config/west.yml`](config/west.yml), repo-root [`boards/shields/`](boards/shields/) for out-of-tree shields (not under `config/boards/shields/`). [`zephyr/module.yml`](zephyr/module.yml) sets `board_root: .` so CI and local Docker builds discover `boards/` via `ZMK_EXTRA_MODULES`.

## Repository Structure

```
.
├── boards/
│   └── shields/
│       ├── splitkb_aurora_corne/       # Aurora Corne shield (dongle overlay, Kconfig)
│       ├── splitkb_nice_view_spi/      # Helper: nice_view_spi for halves matrix
│       └── splitkb_aurora_i2c_off/     # Helper: I2C off (must be last in shield list)
├── config/
│   ├── west.yml
│   ├── splitkb_aurora_corne_{left,right}.conf
│   └── splitkb_aurora_corne.keymap
├── docs/
│   └── keyboards/                    # Per-keyboard inventory (see README there)
├── zephyr/
│   └── module.yml                  # board_root: . ; ZMK_EXTRA_MODULES in CI/local
├── Makefile
├── build.yaml
├── scripts/
│   └── build-local.sh
└── README.md
```

## Keymap Layers

The keymap consists of three layers:

### Base Layer (Layer 0)
Default QWERTY layout. The left and right thumb keys activate the Lower and Raise layers respectively when held.

- **Left thumb key**: Activates Lower layer (`&mo 1`)
- **Right thumb key**: Activates Raise layer (`&mo 2`)

### Lower Layer (Layer 1)
Numbers, symbols, and navigation keys. Activated by holding the left thumb key.

- **Top row**: Numbers 0-9, grave accent
- **Middle rows**: Symbols (parentheses, brackets, operators), navigation keys (Home, End, Page Up/Down, arrow keys)
- **Bottom row**: Additional modifiers and symbols

### Raise Layer (Layer 2)
Function keys and Bluetooth controls. Activated by holding the right thumb key.

- **Top row**: Function keys F1-F12
- **Bottom row**: 
  - `studio_unlock`: ZMK Studio unlock behavior (requires `CONFIG_ZMK_STUDIO=y`)
  - Bluetooth selection keys (`BT_SEL 0-4`): Switch between up to 5 paired devices
  - `BT_CLR`: Clear Bluetooth pairing information

## Build and Flash Instructions

### Prerequisites

- [ZMK Toolbox](https://github.com/zmkfirmware/zmk-toolbox) or
- [West](https://docs.zephyrproject.org/latest/develop/west/index.html) build system

### Building Locally

1. Clone this repository:
   ```bash
   git clone <repository-url>
   cd zmk-config
   ```

2. Initialize the ZMK workspace:
   ```bash
   west init -l config
   west update
   ```

3. Build the firmware (Zephyr 4.1 / ZMK `main` use HWMv2 board qualifiers; quote `-b` so the shell does not treat `//` as a comment):
   ```bash
   # For left half
   west build -b "nice_nano//zmk" -- -DSHIELD=splitkb_aurora_corne_left

   # For right half
   west build -b "nice_nano//zmk" -- -DSHIELD=splitkb_aurora_corne_right

   # For dongle (central)
   west build -b "xiao_ble//zmk" -- -DSHIELD=splitkb_aurora_corne_dongle
   ```

4. Flash the firmware using ZMK Toolbox or your preferred flashing tool.

### Local container build (matches GitHub Actions)

This mirrors CI: image `zmkfirmware/zmk-build-arm:stable` (override with `ZMK_BUILD_IMAGE` if it lags the ZMK revision you need), `west init` / `west update --fetch-opt=--filter=tree:0`, and the same `west build` flags as [`build.yaml`](build.yaml) (including `-DZMK_EXTRA_MODULES` because this repo ships [`zephyr/module.yml`](zephyr/module.yml)). CI uses [`build-user-config.yml` on ZMK `main`](https://github.com/zmkfirmware/zmk/blob/main/.github/workflows/build-user-config.yml) until a **`v0.4.x`** tag exists; then pin both [`config/west.yml`](config/west.yml) and [`.github/workflows/build.yml`](.github/workflows/build.yml) to that tag.

**Prerequisites:** [Docker](https://docs.docker.com/get-docker/) (or Podman with a `docker`-compatible CLI on `PATH`).

**One-time image pull (recommended):**

```bash
docker pull zmkfirmware/zmk-build-arm:stable
```

**Build from the repo root:**

```bash
make build                            # all targets from build.yaml (same as script below)
./scripts/build-local.sh              # all targets from build.yaml
./scripts/build-local.sh left         # left half only
make build TARGET=left                # equivalent to the line above
./scripts/build-local.sh dongle       # central dongle only
./scripts/build-local.sh --init all   # re-sync west modules, then build all
make build INIT=1                     # equivalent: west refresh, then all targets
```

UF2s are written to `firmware/` (gitignored) using stable names from [`build.yaml`](build.yaml) (`corne_dongle.uf2`, `corne_left.uf2`, `corne_right.uf2`, `reset_xiao.uf2`, `reset_nano.uf2`). The west workspace is cached in the Docker volume `zmk-aurora-corne-west` (override with `ZMK_WEST_VOLUME`).

After changing the ZMK revision in [`config/west.yml`](config/west.yml), run with **`--init`** so `west update` runs again. For a clean Zephyr tree after a major bump, remove the volume once: `docker volume rm zmk-aurora-corne-west`, then `./scripts/build-local.sh --init all`.

**Rollback:** If a migration fails after merge, `git revert` the migration commit, remove the Docker west volume as above, and `./scripts/build-local.sh --init all` to rebuild against the reverted manifest.

### Automated Builds

This repository is configured for automated builds via GitHub Actions. The `build.yaml` file defines the build matrix for:
- Left half (Nice!Nano v2)
- Right half (Nice!Nano v2)
- Central dongle (Seeed XIAO BLE)
- Settings reset firmware for both board types

Build artifacts are available in the GitHub Actions workflow runs.

## Bluetooth (halves)

Power, PHY, and pairing behavior are documented in **[`docs/keyboards/splitkb_aurora_corne.md`](docs/keyboards/splitkb_aurora_corne.md)**. In the keymap, use the **Raise** layer for `BT_SEL 0-4` and `BT_CLR`.

## ZMK Studio

This configuration includes support for ZMK Studio, a web-based keymap editor and configuration tool.

- **Configuration**: `CONFIG_ZMK_STUDIO=y` is enabled in the dongle build
- **Usage**: The `studio_unlock` behavior in the Raise layer unlocks the keyboard for ZMK Studio configuration
- **Documentation**: See [ZMK Studio documentation](https://zmk.dev/docs/features/studio) for more information

## Display (halves)

Nice!View on each half — widgets, built-in vs custom status screen, and build matrix fragments: **[`docs/keyboards/splitkb_aurora_corne.md`](docs/keyboards/splitkb_aurora_corne.md)**.

## Troubleshooting

### Build Issues
- Ensure all ZMK submodules are properly initialized with `west update`
- Check that your ZMK version is compatible with this configuration

### Bluetooth Connection Issues
- Try clearing Bluetooth pairings using `BT_CLR` in the Raise layer
- Ensure both halves are powered and within range
- Check that the central dongle is properly flashed and connected

### Layer Activation Not Working
- Verify that the layer activation keys (`&mo 1` and `&mo 2`) are correctly bound in the Base layer
- Check that layer names match between definitions and references

### Display Not Working
- Verify that `CONFIG_ZMK_DISPLAY=y` is set in your configuration
- Check display connections and power

## Additional Resources

- [ZMK Documentation](https://zmk.dev/docs)
- [ZMK Discord](https://zmk.dev/community/discord)
- [SplitKB Documentation](https://docs.splitkb.com)

## License

This configuration is based on ZMK Firmware, which is licensed under the MIT License.

