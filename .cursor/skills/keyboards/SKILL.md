---
name: keyboards
description: >-
  Resolve which physical keyboard a task targets and read its inventory file in
  docs/keyboards/<slug>.md (slug == shield prefix) before changing keymaps,
  build matrix, scripts, or shield-specific config.
---

# Keyboards inventory (this repo)

## When to use

- User or task names a **specific keyboard** (Corne, dongle, a future upstream board).
- You need **MCU list, shield names, BLE/display settings, or build ordering** (not only `build.yaml`).
- Before editing [`build.yaml`](build.yaml), [`scripts/build-local.sh`](scripts/build-local.sh), or Corne helper shields under [`boards/shields/`](boards/shields/).

## Steps

1. Open [`docs/keyboards/README.md`](docs/keyboards/README.md) — index of slugs and artifact names.
2. Open **`docs/keyboards/<slug>.md`** for that keyboard. **Slug = shield prefix** (e.g. Corne → `splitkb_aurora_corne` → `splitkb_aurora_corne.md`).
3. Treat that file as **source of truth** for hardware, Kconfig rationale, and **keyboard-specific build gotchas** (shield merge order, display flags).
4. Use [`build.yaml`](build.yaml) for exact `board` / `shield` / `snippet` / `cmake-args` / `artifact-name` per CI artifact.

## Slugs

| Keyboard | Slug | Inventory |
| --- | --- | --- |
| SplitKB Aurora Corne | `splitkb_aurora_corne` | [`docs/keyboards/splitkb_aurora_corne.md`](docs/keyboards/splitkb_aurora_corne.md) |

Future upstream-only keyboards: use their primary shield prefix as slug and add a row to the index README.

## Rules guardrail

Do **not** add a new `alwaysApply: true` Cursor rule for keyboards — [`AGENTS.md`](AGENTS.md) caps always-on rules at **≤ 2**. Use this skill + `docs/keyboards/` for discoverability.
