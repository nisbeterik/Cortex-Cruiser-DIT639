#!/bin/bash

# Debug: Show current directory and tree structure
echo "Current directory: $(pwd)"
echo "Directory contents:"
ls -laR cpp-opencv/performance/src/automation || echo "Automation directory not found"

# Define paths
RECORDING_DIR="cpp-opencv/performance/src/automation"
RECORDING_FILE="CID-140-recording-2020-03-18_150001-selection.rec"
FULL_PATH="$(pwd)/${RECORDING_DIR}/${RECORDING_FILE}"

echo "Looking for recording at: ${FULL_PATH}"

# Verify path exists
if [ ! -f "${FULL_PATH}" ]; then
  echo "ERROR: Recording file not found at ${FULL_PATH}"
  echo "Available files in ${RECORDING_DIR}:"
  ls -la "${RECORDING_DIR}" || true
  exit 1
fi

# Run the test
echo "Running performance test with recording: ${FULL_PATH}"
docker run \
  -v "$(pwd)/${RECORDING_DIR}:/data" \
  performance:latest \
  --rec="/data/${RECORDING_FILE}" \
  --verbose