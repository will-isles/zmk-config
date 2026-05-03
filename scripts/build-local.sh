#!/usr/bin/env bash
# Local ZMK builds using the same container image and west flow as GitHub Actions
# (zmkfirmware/zmk/.github/workflows/build-user-config.yml @ main).
#
# Usage:
#   ./scripts/build-local.sh [--init] [TARGET]
#
# TARGET: dongle|left|right|reset-xiao|reset-nano|sofle-left|sofle-right|
#         corne-all|sofle-all|all
#
# Requires: Docker (or Podman with docker CLI compatibility)
set -euo pipefail

DOCKER_IMAGE="${ZMK_BUILD_IMAGE:-zmkfirmware/zmk-build-arm:stable}"
WEST_VOLUME="${ZMK_WEST_VOLUME:-zmk-aurora-corne-west}"
CONFIG_PATH="${ZMK_CONFIG_PATH:-config}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

usage() {
  echo "Usage: $0 [--init] [TARGET]" >&2
  echo "  --init  Run west update + west zephyr-export after syncing config (e.g. after west.yml revision change)" >&2
  echo "  TARGET (Corne + shared reset):" >&2
  echo "    dongle  left  right  reset-xiao  reset-nano  corne-all" >&2
  echo "  TARGET (Sofle halves):" >&2
  echo "    sofle-left  sofle-right  sofle-all" >&2
  echo "  TARGET (combined):" >&2
  echo "    all       corne-all + sofle-all (reset-nano built once inside corne-all)" >&2
  exit 1
}

INIT=0
TARGET="all"
while [[ $# -gt 0 ]]; do
  case "$1" in
    --init)
      INIT=1
      shift
      ;;
    -h|--help)
      usage
      ;;
    dongle|left|right|reset-xiao|reset-nano|sofle-left|sofle-right|corne-all|sofle-all|all)
      TARGET="$1"
      shift
      ;;
    *)
      echo "Unknown argument: $1" >&2
      usage
      ;;
  esac
done

if ! command -v docker >/dev/null 2>&1; then
  echo "error: docker not found on PATH" >&2
  exit 1
fi

if [[ ! -f "${REPO_ROOT}/zephyr/module.yml" ]]; then
  echo "error: expected ${REPO_ROOT}/zephyr/module.yml (ZMK module root)" >&2
  exit 1
fi

docker volume inspect "${WEST_VOLUME}" >/dev/null 2>&1 || docker volume create "${WEST_VOLUME}" >/dev/null

# Default artifact names match build-user-config.yml when artifact-name is omitted:
#   ${shield:+$shield-}${board_sanitized}-zmk   (board slashes -> _)
# If ARTIFACT_NAME is set by the caller, UF2 is firmware/${ARTIFACT_NAME}.uf2 (matches explicit build.yaml rows).
artifact_name_default() {
  local board="$1"
  local shield="$2"
  local board_sanitized="${board//\//_}"
  printf '%s%s-zmk' "${shield:+$shield-}" "${board_sanitized}"
}

run_in_work() {
  docker run --rm \
    -v "${REPO_ROOT}:/zmk-config" \
    -v "${WEST_VOLUME}:/work" \
    -w /work \
    "${DOCKER_IMAGE}" \
    bash -c "$1"
}

sync_config() {
  run_in_work "set -euo pipefail
# Replace config dir entirely so removed host files (e.g. deleted overlays) do not linger in the volume.
rm -rf /work/${CONFIG_PATH}
mkdir -p /work/${CONFIG_PATH}
cp -a /zmk-config/${CONFIG_PATH}/. /work/${CONFIG_PATH}/
"
}

west_init_update() {
  run_in_work "set -euo pipefail
rm -rf /work/${CONFIG_PATH}
mkdir -p /work/${CONFIG_PATH}
cp -a /zmk-config/${CONFIG_PATH}/. /work/${CONFIG_PATH}/
west init -l /work/${CONFIG_PATH}
west update --fetch-opt=--filter=tree:0
west zephyr-export
"
}

west_refresh() {
  run_in_work "set -euo pipefail
rm -rf /work/${CONFIG_PATH}
mkdir -p /work/${CONFIG_PATH}
cp -a /zmk-config/${CONFIG_PATH}/. /work/${CONFIG_PATH}/
west update --fetch-opt=--filter=tree:0
west zephyr-export
"
}

needs_init() {
  docker run --rm \
    -v "${WEST_VOLUME}:/work" \
    -w /work \
    "${DOCKER_IMAGE}" \
    bash -c 'test ! -d /work/.west'
}

if needs_init; then
  echo "==> Initializing west workspace in Docker volume ${WEST_VOLUME}"
  west_init_update
elif [[ "${INIT}" -eq 1 ]]; then
  echo "==> --init: syncing config and running west update"
  sync_config
  west_refresh
else
  sync_config
fi

# Run a west build inside the container; copies the resulting UF2 to REPO_ROOT/firmware/.
# Arguments: human_name board shield [snippet]
# Optional env: WEST_EXTRA_CMAKE, ARTIFACT_NAME (basename without .uf2; must match build.yaml when set)
run_west_build() {
  local human_name="$1"
  local board="$2"
  local shield="$3"
  local snippet="${4:-}"
  local artifact
  if [[ -n "${ARTIFACT_NAME:-}" ]]; then
    artifact="${ARTIFACT_NAME}"
  else
    artifact="$(artifact_name_default "${board}" "${shield}")"
  fi

  echo "==> Building ${human_name} (${board} / ${shield})"

  # -i required so bash -s reads the heredoc from stdin (without it, the script is empty and exits 0)
  docker run -i --rm \
    -v "${REPO_ROOT}:/zmk-config" \
    -v "${WEST_VOLUME}:/work" \
    -w /work \
    -e "CONFIG_PATH=${CONFIG_PATH}" \
    -e "BOARD=${board}" \
    -e "SHIELD=${shield}" \
    -e "SNIPPET=${snippet}" \
    -e "ARTIFACT=${artifact}" \
    -e "WEST_EXTRA_CMAKE=${WEST_EXTRA_CMAKE:-}" \
    "${DOCKER_IMAGE}" \
    bash -s <<'EOS'
set -euo pipefail
rm -rf "/work/${CONFIG_PATH}"
mkdir -p "/work/${CONFIG_PATH}"
cp -a "/zmk-config/${CONFIG_PATH}/." "/work/${CONFIG_PATH}/"
# Each docker run has a fresh $HOME; re-register Zephyr from the persisted /work tree.
west zephyr-export
build_dir="$(mktemp -d)"
if [[ -n "${SNIPPET}" ]]; then
  # shellcheck disable=SC2086
  west build -s zmk/app -d "${build_dir}" -b "${BOARD}" -S "${SNIPPET}" -- \
    -DZMK_CONFIG="/work/${CONFIG_PATH}" \
    -DSHIELD="${SHIELD}" \
    -DZMK_EXTRA_MODULES=/zmk-config \
    ${WEST_EXTRA_CMAKE-}
else
  # shellcheck disable=SC2086
  west build -s zmk/app -d "${build_dir}" -b "${BOARD}" -- \
    -DZMK_CONFIG="/work/${CONFIG_PATH}" \
    -DSHIELD="${SHIELD}" \
    -DZMK_EXTRA_MODULES=/zmk-config \
    ${WEST_EXTRA_CMAKE-}
fi
mkdir -p /zmk-config/firmware
out="/zmk-config/firmware/${ARTIFACT}.uf2"
if [[ -f "${build_dir}/zephyr/zmk.uf2" ]]; then
  cp "${build_dir}/zephyr/zmk.uf2" "${out}"
  echo "    -> ${out}"
else
  echo "error: zmk.uf2 not found after build" >&2
  exit 1
fi
EOS
}

build_dongle() {
  ARTIFACT_NAME=corne_dongle WEST_EXTRA_CMAKE="-DCONFIG_ZMK_SPLIT_ROLE_CENTRAL=y -DCONFIG_ZMK_SPLIT=y -DCONFIG_ZMK_STUDIO=y" \
    run_west_build dongle "xiao_ble//zmk" splitkb_aurora_corne_dongle studio-rpc-usb-uart
}

build_left() {
  ARTIFACT_NAME=corne_left WEST_EXTRA_CMAKE="-DCONFIG_ZMK_SPLIT=y -DCONFIG_ZMK_SPLIT_ROLE_CENTRAL=n" \
    run_west_build left "nice_nano//zmk" "splitkb_nice_view_spi splitkb_aurora_corne_left nice_view_adapter nice_view splitkb_aurora_i2c_off"
}

build_right() {
  ARTIFACT_NAME=corne_right WEST_EXTRA_CMAKE="-DCONFIG_ZMK_SPLIT=y -DCONFIG_ZMK_SPLIT_ROLE_CENTRAL=n" \
    run_west_build right "nice_nano//zmk" "splitkb_nice_view_spi splitkb_aurora_corne_right nice_view_adapter nice_view splitkb_aurora_i2c_off"
}

build_reset_xiao() {
  ARTIFACT_NAME=reset_xiao WEST_EXTRA_CMAKE="" \
    run_west_build reset-xiao "xiao_ble//zmk" settings_reset
}

build_reset_nano() {
  ARTIFACT_NAME=reset_nano WEST_EXTRA_CMAKE="" \
    run_west_build reset-nano "nice_nano//zmk" settings_reset
}

build_sofle_left() {
  # Sofle left is BLE central (dongle-less); Corne halves use CENTRAL=n because the dongle is central.
  ARTIFACT_NAME=sofle_left WEST_EXTRA_CMAKE="-DCONFIG_ZMK_SPLIT=y -DCONFIG_ZMK_SPLIT_ROLE_CENTRAL=y" \
    run_west_build sofle-left "nice_nano//zmk" splitkb_aurora_sofle_left
}

build_sofle_right() {
  ARTIFACT_NAME=sofle_right WEST_EXTRA_CMAKE="-DCONFIG_ZMK_SPLIT=y -DCONFIG_ZMK_SPLIT_ROLE_CENTRAL=n" \
    run_west_build sofle-right "nice_nano//zmk" splitkb_aurora_sofle_right
}

build_corne_all() {
  build_dongle
  build_left
  build_right
  build_reset_xiao
  build_reset_nano
}

build_sofle_all() {
  build_sofle_left
  build_sofle_right
}

case "${TARGET}" in
  dongle) build_dongle ;;
  left) build_left ;;
  right) build_right ;;
  reset-xiao) build_reset_xiao ;;
  reset-nano) build_reset_nano ;;
  sofle-left) build_sofle_left ;;
  sofle-right) build_sofle_right ;;
  corne-all) build_corne_all ;;
  sofle-all) build_sofle_all ;;
  all)
    build_corne_all
    build_sofle_all
    ;;
  *)
    usage
    ;;
esac

echo "Done."
