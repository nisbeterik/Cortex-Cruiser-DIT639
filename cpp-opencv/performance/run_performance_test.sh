#!/bin/bash

RECORDING_DIR="src/automation"
OUTPUT_DIR="plots"  # Directory to store output PNGs

# Create output directory if it doesn't exist
mkdir -p "${OUTPUT_DIR}"

# Verify recording directory exists
if [ ! -d "${RECORDING_DIR}" ]; then
  echo "Error: Directory not found at ${RECORDING_DIR}"
  exit 1
fi

# Process each .rec file
for rec_file in "${RECORDING_DIR}"/*.rec; do
  [ -e "$rec_file" ] || continue
  
  filename=$(basename "${rec_file}" .rec)
  output_png="${OUTPUT_DIR}/${filename}.png"
  
  echo "Processing recording file: ${filename}.rec"
  echo "Output will be saved to: ${output_png}"
  
  # Process the recording and generate plot
  docker run \
    -v "$(pwd)/${RECORDING_DIR}:/data" \
    performance:latest \
    --rec="/data/${filename}.rec" \
    | grep -E '^[0-9]+;-?[0-9.]+;-?[0-9.]+;[0-9.]+$' \
    | gnuplot -e "output_png='${output_png}'" -c plot_script.gnuplot
  
  if [ $? -ne 0 ]; then
    echo "Error processing ${filename}.rec"
    exit 1
  fi
  
  echo "Successfully generated: ${output_png}"
  echo "----------------------------------"
done

echo "All recordings processed successfully"