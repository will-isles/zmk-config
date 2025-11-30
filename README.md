# ZMK Configuration for SplitKB Aurora Corne

This repository contains the ZMK firmware configuration for a SplitKB Aurora Corne split keyboard.

## Hardware Configuration

- **Keyboard**: SplitKB Aurora Corne (36-key split keyboard)
- **Microcontrollers**: 
  - Left/Right halves: Nice!Nano v2
  - Dongle: Seeed XIAO BLE
- **Displays**: Nice!View (128x64 OLED displays)
- **Connectivity**: Bluetooth Low Energy (BLE) with central dongle support

## Repository Structure

```
.
├── boards/
│   └── shields/
│       └── splitkb_aurora_corne/    # Shield definitions
├── config/
│   ├── splitkb_aurora_corne.conf    # Firmware configuration
│   └── splitkb_aurora_corne.keymap  # Keymap definition
├── build.yaml                       # GitHub Actions build matrix
└── README.md                        # This file
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

3. Build the firmware:
   ```bash
   # For left half
   west build -b nice_nano_v2 -- -DSHIELD=splitkb_aurora_corne_left

   # For right half
   west build -b nice_nano_v2 -- -DSHIELD=splitkb_aurora_corne_right

   # For dongle (central)
   west build -b seeeduino_xiao_ble -- -DSHIELD=splitkb_aurora_corne_dongle
   ```

4. Flash the firmware using ZMK Toolbox or your preferred flashing tool.

### Automated Builds

This repository is configured for automated builds via GitHub Actions. The `build.yaml` file defines the build matrix for:
- Left half (Nice!Nano v2)
- Right half (Nice!Nano v2)
- Central dongle (Seeed XIAO BLE)
- Settings reset firmware for both board types

Build artifacts are available in the GitHub Actions workflow runs.

## Bluetooth Configuration

### Power Settings
- **Transmit Power**: +8dBm (`CONFIG_BT_CTLR_TX_PWR_PLUS_8=y`)
  - Increased power for better range and connection stability, especially important for split keyboards
- **2M PHY**: Disabled (`CONFIG_BT_CTLR_PHY_2M=n`)
  - Disabled for better compatibility with older Bluetooth devices

### Pairing and Device Selection
- Use the Raise layer to access Bluetooth controls
- `BT_SEL 0-4`: Switch between up to 5 paired devices
- `BT_CLR`: Clear all Bluetooth pairing information

## ZMK Studio

This configuration includes support for ZMK Studio, a web-based keymap editor and configuration tool.

- **Configuration**: `CONFIG_ZMK_STUDIO=y` is enabled in the dongle build
- **Usage**: The `studio_unlock` behavior in the Raise layer unlocks the keyboard for ZMK Studio configuration
- **Documentation**: See [ZMK Studio documentation](https://zmk.dev/docs/features/studio) for more information

## Display Configuration

Nice!View displays are configured for both keyboard halves. The display shows:
- Current layer information
- Battery status
- Connection status

Configuration is handled via the `nice_view_adapter` and `nice_view_custom` shields in the build configuration.

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

