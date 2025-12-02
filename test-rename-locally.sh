#!/bin/bash
# Local test script for the rename-artifacts workflow step
# This simulates what happens in the GitHub Actions workflow

set -euo pipefail

# Create a test artifacts directory
TEST_DIR="test-artifacts"
mkdir -p "$TEST_DIR"

# Create mock .uf2 files (simulating what download-artifact extracts)
# download-artifact extracts ZIP files by default, so we simulate the extracted contents
echo "Mock firmware content - dongle" > "$TEST_DIR/splitkb_aurora_corne_dongle-seeeduino_xiao_ble-zmk.uf2"
echo "Mock firmware content - left" > "$TEST_DIR/splitkb_aurora_corne_left-nice_nano_v2-zmk.uf2"
echo "Mock firmware content - right" > "$TEST_DIR/splitkb_aurora_corne_right-nice_nano_v2-zmk.uf2"

echo "Testing rename logic..."
echo "Artifacts directory contents:"
ls -la "$TEST_DIR/"

# Generate timestamp (same as workflow)
TIMESTAMP=$(date -u +'%Y-%m-%d-%H-%M-%S')
echo "Generated timestamp: $TIMESTAMP"

# Check for .uf2 files (same logic as workflow)
if [ ! -d "$TEST_DIR" ] || [ -z "$(ls -A "$TEST_DIR"/*.uf2 2>/dev/null)" ]; then
  echo "Error: No firmware files (.uf2) found in artifacts directory"
  echo "Contents of artifacts directory:"
  ls -la "$TEST_DIR/" || true
  exit 1
fi

# Create a new ZIP file containing all firmware files (same logic as workflow)
NEW_NAME="aurora-corne-${TIMESTAMP}.zip"
cd "$TEST_DIR"
zip -r "../${NEW_NAME}" *.uf2
cd ..

# Verify the file was created successfully
if [ ! -f "$NEW_NAME" ]; then
  echo "Error: Failed to create zip file: $NEW_NAME"
  exit 1
fi

echo "✓ Successfully created: $NEW_NAME"
echo "Test file size: $(du -h "$NEW_NAME" | cut -f1)"

# Cleanup
rm -rf "$TEST_DIR"
rm -f "$NEW_NAME"

echo "✓ Test passed!"

