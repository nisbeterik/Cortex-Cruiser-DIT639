RECORDING_DIR="src/automation"

# Verify directory exists
if [ ! -d "${RECORDING_DIR}" ]; then
  echo "Error: Directory not found at ${RECORDING_DIR}"
  exit 1
fi

# Get all .rec files
rec_files=("${RECORDING_DIR}"/*.rec)

# Check if any .rec files exist
if [ ${#rec_files[@]} -eq 0 ]; then
  echo "Error: No .rec files found in ${RECORDING_DIR}"
  exit 1
fi

# Process each file one by one
for rec_file in "${rec_files[@]}"; do
  filename=$(basename "${rec_file}")
  echo "Processing recording file: ${filename}"
  
  docker run \
    -v "$(pwd)/${RECORDING_DIR}:/data" \
    performance:latest \
    --rec="/data/${filename}" \
    --verbose
  
  # Check if the last command succeeded
  if [ $? -ne 0 ]; then
    echo "Error processing ${filename}"
    exit 1
  fi
  
  echo "Completed processing: ${filename}"
  echo "----------------------------------"
done

echo "All recordings processed successfully"