#!/bin/bash
# Local test script for the rename-artifacts workflow step
# This simulates what happens in the GitHub Actions workflow

set -euo pipefail

# Create a test artifacts directory
TEST_DIR="test-artifacts"
mkdir -p "$TEST_DIR"

# Create a mock firmware.zip file (simulating what download-artifact creates)
echo "Mock firmware content" > "$TEST_DIR/firmware.zip"

echo "Testing rename logic..."
echo "Artifacts directory contents:"
ls -la "$TEST_DIR/"

# Generate timestamp (same as workflow)
TIMESTAMP=$(date -u +'%Y-%m-%d-%H-%M-%S')
echo "Generated timestamp: $TIMESTAMP"

# Find the firmware zip file (same logic as workflow)
FIRMWARE=$(find "$TEST_DIR" -name "firmware.zip" -type f | head -1)
if [ -z "$FIRMWARE" ]; then
  echo "Error: firmware.zip not found in artifacts directory"
  echo "Contents of artifacts directory:"
  ls -la "$TEST_DIR/" || true
  exit 1
fi

echo "Found firmware file: $FIRMWARE"

# Copy firmware to new timestamped name
NEW_NAME="aurora-corne-${TIMESTAMP}.zip"
cp "$FIRMWARE" "$NEW_NAME"

# Verify the file was created successfully
if [ ! -f "$NEW_NAME" ]; then
  echo "Error: Failed to copy zip file: $NEW_NAME"
  exit 1
fi

echo "✓ Successfully created: $NEW_NAME"
echo "Test file size: $(stat -c%s "$NEW_NAME") bytes"

# Cleanup
rm -rf "$TEST_DIR"
rm -f "$NEW_NAME"

echo "✓ Test passed!"

