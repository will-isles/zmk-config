# Local ZMK builds (Docker, CI parity). Matrix: build.yaml — script: scripts/build-local.sh
.DEFAULT_GOAL := build

.PHONY: build help init

# dongle | left | right | reset-xiao | reset-nano | all
TARGET ?= all

# Set INIT=1 (or true/yes) to pass --init (west update after west.yml / module changes)
build:
	"$(CURDIR)/scripts/build-local.sh" $(if $(filter 1 true yes,$(INIT)),--init) $(TARGET)

init:
	"$(CURDIR)/scripts/build-local.sh" --init $(TARGET)

help:
	@echo "ZMK local build (same image/flow as GitHub build-user-config):"
	@echo "  make build                  # all matrix targets (default)"
	@echo "  make build TARGET=left      # one target: dongle|left|right|reset-xiao|reset-nano|all"
	@echo "  make build INIT=1           # west refresh, then all targets"
	@echo "  make init                     # same as: make build INIT=1"
	@echo "  make init TARGET=right       # west refresh, then right half only"
