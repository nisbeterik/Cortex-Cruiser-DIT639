#!/bin/sh

RECORDING_DIR="src/automation"
OUTPUT_DIR="plots"
COMMIT_HASH="$1"
PREVIOUS_OUTPUT_DIR="previous_plots"

# Create directories if they don't exist
mkdir -p "${OUTPUT_DIR}"
mkdir -p "${PREVIOUS_OUTPUT_DIR}"

# Verify recording directory exists
if [ ! -d "${RECORDING_DIR}" ]; then
  echo "Error: Directory not found at ${RECORDING_DIR}"
  exit 1
fi

# Attempt to fetch previous jobs if CI is running
if [ -n "$CI" ]; then
  echo "Running in CI environment, attempting to fetch previous jobs..."
  echo "GitLab API URL: $CI_API_V4_URL"
  echo "GitLab Project ID: $CI_PROJECT_ID"

  response=$(curl -sS --header "PRIVATE-TOKEN: $CI_REGISTRY_PASSWORD" \
    "$CI_API_V4_URL/projects/$CI_PROJECT_ID/jobs")

  if [ $? -ne 0 ]; then
    echo "Failed to fetch previous jobs from GitLab API"
    exit 1
  fi

  echo "Response from GitLab API:"
  echo "$response"
  echo "----------------------------------"
fi

# Process each .rec file
for rec_file in "${RECORDING_DIR}"/*.rec; do
  [ -e "${rec_file}" ] || continue
  
  filename=$(basename "${rec_file}" .rec)
  output_png="${OUTPUT_DIR}/${filename}_${COMMIT_HASH}.png"
  
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