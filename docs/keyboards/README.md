# Keyboards (inventory index)

One markdown file per physical keyboard. **Slug = ZMK shield prefix** (grep-friendly with `config/` and `boards/shields/`).

| Slug | Name | Inventory | `build.yaml` artifact names |
| --- | --- | --- | --- |
| `splitkb_aurora_corne` | SplitKB Aurora Corne (+ dongle / reset UF2s) | [splitkb_aurora_corne.md](splitkb_aurora_corne.md) | `corne_dongle`, `corne_left`, `corne_right`, `reset_xiao`, `reset_nano` |
| `splitkb_aurora_sofle` | SplitKB Aurora Sofle v2 (halves; Nice!Nano reset shared) | [splitkb_aurora_sofle.md](splitkb_aurora_sofle.md) | `sofle_left`, `sofle_right` (use shared `reset_nano` for erase) |

When adding an upstream-only keyboard (Phase B), add a row here and `docs/keyboards/<shield_prefix>.md`.
