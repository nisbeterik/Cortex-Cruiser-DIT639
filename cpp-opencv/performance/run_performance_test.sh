RECORDING_DIR="src/automation"

# Verify directory exists
if [ ! -d "${RECORDING_DIR}" ]; then
  echo "Error: Directory not found at ${RECORDING_DIR}"
  exit 1
fi

# Process each .rec file
for rec_file in "${RECORDING_DIR}"/*.rec; do
  [ -e "$rec_file" ] || continue  
  filename=$(basename "${rec_file}")
  echo "Processing recording file: ${filename}"
  
  docker run \
    -v "$(pwd)/${RECORDING_DIR}:/data" \
    performance:latest \
    --rec="/data/${filename}" \
  
  if [ $? -ne 0 ]; then
    echo "Error processing ${filename}"
    exit 1
  fi
  
  echo "Completed processing: ${filename}"
  echo "----------------------------------"
done

echo "All recordings processed successfully"