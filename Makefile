# Local ZMK builds (Docker, CI parity). Matrix: build.yaml — script: scripts/build-local.sh
.DEFAULT_GOAL := build

.PHONY: build help init

# dongle | left | right | reset-xiao | reset-nano | sofle-left | sofle-right | corne-all | sofle-all | all
TARGET ?= all

# Set INIT=1 (or true/yes) to pass --init (west update after west.yml / module changes)
build:
	"$(CURDIR)/scripts/build-local.sh" $(if $(filter 1 true yes,$(INIT)),--init) $(TARGET)

init:
	"$(CURDIR)/scripts/build-local.sh" --init $(TARGET)

help:
	@echo "ZMK local build (same image/flow as GitHub build-user-config):"
	@echo "  make build                    # TARGET=all (default): corne-all + sofle-all"
	@echo "  make build TARGET=corne-all   # Corne dongle, halves, XIAO reset, nano reset (once)"
	@echo "  make build TARGET=sofle-all   # Sofle left + right only"
	@echo "  make build TARGET=left        # single Corne / Sofle / reset: see scripts/build-local.sh --help"
	@echo "  make build INIT=1             # west refresh, then chosen TARGET"
	@echo "  make init                     # same as: make build INIT=1"
	@echo "  make init TARGET=sofle-right"
