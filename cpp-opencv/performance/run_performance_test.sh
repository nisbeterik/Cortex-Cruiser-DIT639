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

# Attempt to fetch previous artifacts if CI is running
if [ -n "$CI" ]; then
  echo "Running in CI environment, attempting to fetch previous artifacts..."
  
  # Get the previous commit hash (HEAD~1)
  PREVIOUS_COMMIT=$(git rev-parse HEAD~1 2>/dev/null)
  
  if [ -n "$PREVIOUS_COMMIT" ]; then
    echo "Attempting to fetch artifacts from commit: $PREVIOUS_COMMIT"
    
    # Using CI_JOB_TOKEN for authentication (automatically available in CI jobs)
    curl --header "PRIVATE-TOKEN: $CI_JOB_TOKEN" \
      "$CI_API_V4_URL/projects/$CI_PROJECT_ID/jobs/artifacts/$PREVIOUS_COMMIT/download?job=performance" \
      -o previous_artifacts.zip
    
    if [ $? -eq 0 ] && [ -f previous_artifacts.zip ]; then
      echo "Successfully downloaded previous artifacts"
      unzip -q previous_artifacts.zip -d "${PREVIOUS_OUTPUT_DIR}"
      echo "Previous plots extracted to: ${PREVIOUS_OUTPUT_DIR}"
      rm previous_artifacts.zip
    else
      echo "Warning: Could not retrieve previous artifacts (might be first run or artifacts expired)"
    fi
  else
    echo "Warning: Could not determine previous commit hash"
  fi
else
  echo "Not running in CI, skipping artifact retrieval"
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