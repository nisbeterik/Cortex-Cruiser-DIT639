#!/bin/sh

RECORDING_DIR="src/recordings"
OUTPUT_DIR="plots"
CSV_OUTPUT_DIR="output"
PREVIOUS_OUTPUT_DIR="previous_plots"
PREVIOUS_CSV_DIR="previous_output" 
COMMIT_HASH="$1"

# Create directories if they don't exist
mkdir -p "${OUTPUT_DIR}"
mkdir -p "${CSV_OUTPUT_DIR}" 
mkdir -p "${PREVIOUS_OUTPUT_DIR}"
mkdir -p "${PREVIOUS_CSV_DIR}"

# Verify recording directory exists
if [ ! -d "${RECORDING_DIR}" ]; then
  echo "Error: Directory not found at ${RECORDING_DIR}"
  exit 1
fi

# Fetch previous job artifacts in CI environment
if [ -n "$CI" ]; then
  echo "Running in CI environment, attempting to fetch previous jobs..."
  
  response=$(curl -sS --header "PRIVATE-TOKEN: $CI_API_TOKEN" \
    "$CI_API_V4_URL/projects/$CI_PROJECT_ID/jobs")

  if [ $? -ne 0 ]; then
    echo "Failed to fetch previous jobs from GitLab API"
    exit 1
  fi

  # Extract the ID of the latest successful job in the "performance" stage
  previous_perf_job_id=$(echo "$response" | jq '[.[] | select(.stage == "performance" and .status == "success")] | first | .id')

  if [ "$previous_perf_job_id" != "null" ] && [ -n "$previous_perf_job_id" ]; then
    echo "Previous successful 'performance' job ID: $previous_perf_job_id"
    
    # Fetch artifacts from the previous job
    echo "Fetching artifacts from previous job..."
    curl -sS --header "PRIVATE-TOKEN: $CI_API_TOKEN" \
      -o "${PREVIOUS_OUTPUT_DIR}/artifacts.zip" \
      "$CI_API_V4_URL/projects/$CI_PROJECT_ID/jobs/$previous_perf_job_id/artifacts"
    
    if [ $? -eq 0 ]; then
      echo "Successfully downloaded artifacts"
      # Unzip the artifacts
      unzip -qo "${PREVIOUS_OUTPUT_DIR}/artifacts.zip" -d "${PREVIOUS_OUTPUT_DIR}"
      echo "Artifacts extracted to ${PREVIOUS_OUTPUT_DIR}"
      
      # Move previous CSV files to their own directory
      mkdir -p "${PREVIOUS_CSV_DIR}"
      find "${PREVIOUS_OUTPUT_DIR}" -name "*.csv" -exec mv {} "${PREVIOUS_CSV_DIR}" \;
    else
      echo "Failed to download artifacts from previous job"
    fi
  fi
fi

# Process each .rec file to generate CSVs
for rec_file in "${RECORDING_DIR}"/*.rec; do
  [ -e "${rec_file}" ] || continue
  
  filename=$(basename "${rec_file}" .rec)
  output_csv="${CSV_OUTPUT_DIR}/${filename}_${COMMIT_HASH}.csv" 
  
  echo "Processing recording file: ${filename}.rec"
  echo "CSV will be saved to: ${output_csv}"
  
  # Process the recording and generate CSV only
  docker run \
    -v "$(pwd)/${RECORDING_DIR}:/data" \
    -v "$(pwd)/${CSV_OUTPUT_DIR}:/output" \
    performance:latest \
    --rec="/data/${filename}.rec" \
    --output="/output/${filename}_${COMMIT_HASH}.csv"
  
  if [ $? -ne 0 ]; then
    echo "Error processing ${filename}.rec"
    exit 1
  fi
  
  echo "Successfully generated: ${output_csv}"
  echo "----------------------------------"
done

# Now generate plots comparing current and previous data
for current_csv in "${CSV_OUTPUT_DIR}"/*.csv; do
  [ -e "${current_csv}" ] || continue
  
  filename=$(basename "${current_csv}" "_${COMMIT_HASH}.csv")
  output_png="${OUTPUT_DIR}/${filename}_${COMMIT_HASH}.png"
  
  # Find matching previous CSV
  previous_csv=""
  if [ -d "${PREVIOUS_CSV_DIR}" ]; then
    previous_csv=$(find "${PREVIOUS_CSV_DIR}" -name "${filename}_*.csv" | head -n 1)
  fi
  
  echo "Generating plot for: ${filename}"
  echo "Current CSV: ${current_csv}"
  echo "Previous CSV: ${previous_csv}"
  echo "Output PNG: ${output_png}"
  
  # Generate plot using gnuplot
  gnuplot -e "current_csv='${current_csv}'; previous_csv='${previous_csv}'; output_png='${output_png}'" -c plot_script.gnuplot
  
  if [ $? -ne 0 ]; then
    echo "Error generating plot for ${filename}"
    exit 1
  fi
  
  echo "Successfully generated: ${output_png}"
  echo "----------------------------------"
done

echo "All recordings processed successfully"