RECORDING_DIR="cpp-opencv/performance/src/automation"
RECORDING_FILE="CID-140-recording-2020-03-18_150001-selection.rec"

# Check if the recording file exists
if [ ! -f "${RECORDING_DIR}/${RECORDING_FILE}" ]; then
  echo "Error: Recording file not found at ${RECORDING_DIR}/${RECORDING_FILE}"
  exit 1
fi

# Run the performance test with the recording file
echo "Running performance test with recording: ${RECORDING_FILE}"
docker run \
  -v "$(pwd)/${RECORDING_DIR}:/data" \
  performance:latest \
  --rec="/data/${RECORDING_FILE}" \ 