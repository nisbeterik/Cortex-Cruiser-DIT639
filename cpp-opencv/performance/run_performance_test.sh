#!/bin/sh

RECORDING_DIR="src/recordings"
OUTPUT_DIR="plots"
CSV_OUTPUT_DIR="output"
CURRENT_CSV_DIR="current"
PREVIOUS_OUTPUT_DIR="previous_plots"
PREVIOUS_CSV_DIR="previous_output" 
COMMIT_HASH="$1"
COMBINED_CSV_DIR="combined_csv"

# Create directories if they don't exist
mkdir -p "${OUTPUT_DIR}"
mkdir -p "${CSV_OUTPUT_DIR}" 
mkdir -p "${PREVIOUS_OUTPUT_DIR}"
mkdir -p "${PREVIOUS_CSV_DIR}"
mkdir -p "${COMBINED_CSV_DIR}"
mkdir -p "${CURRENT_CSV_DIR}"

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

  response=$(curl -sS --header "PRIVATE-TOKEN: $CI_API_TOKEN" \
    "$CI_API_V4_URL/projects/$CI_PROJECT_ID/jobs")

  if [ $? -ne 0 ]; then
    echo "Failed to fetch previous jobs from GitLab API"
    exit 1
  fi

  # Extract the ID of the latest successful job in the "performance" stage
  previous_perf_job_id=$(echo "$response" | jq '[.[] | select(.stage == "performance" and .status == "success")] | first | .id')

  if [ "$previous_perf_job_id" = "null" ] || [ -z "$previous_perf_job_id" ]; then
    echo "No previous successful 'performance' job found."
  else
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
      
      # Move previous CSV files to previous_csv directory
      find "${PREVIOUS_OUTPUT_DIR}" -name "*.csv" -exec mv {} "${PREVIOUS_CSV_DIR}" \;
    else
      echo "Failed to download artifacts from previous job"
    fi
  fi
fi

# Process each .rec file
for rec_file in "${RECORDING_DIR}"/*.rec; do
  [ -e "${rec_file}" ] || continue
  
  filename=$(basename "${rec_file}" .rec)
  output_png="${OUTPUT_DIR}/${filename}_${COMMIT_HASH}.png"
  output_csv="${CSV_OUTPUT_DIR}/${filename}_${COMMIT_HASH}.csv"
  current_csv="${CURRENT_CSV_DIR}/${filename}_${COMMIT_HASH}_current.csv"
  combined_csv="${COMBINED_CSV_DIR}/${filename}_${COMMIT_HASH}_combined.csv"
  
  echo "Processing recording file: ${filename}.rec"
  echo "Plot will be saved to: ${output_png}"
  echo "CSV will be saved to: ${output_csv}"
  
  # Process the recording and generate CSVs
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
  
  # Find matching previous CSV file
  previous_csv=$(find "${PREVIOUS_CSV_DIR}" -name "${filename}_*.csv" | head -n 1)
  
  if [ -n "$previous_csv" ]; then
    echo "Found previous CSV file: ${previous_csv}"
    
    # Combine current and previous CSV files
    echo "Combining CSV files..."
    
    # Process current CSV to extract timestamp, groundTruth, groundSteering
    awk -F, 'NR>1 {print $1","$2","$3}' "${current_csv}" > "${current_csv}.tmp"
    
    # Process previous CSV to extract groundSteering (which becomes prevGroundSteering)
    awk -F, 'NR>1 {print $3}' "${previous_csv}" > "${previous_csv}.tmp"
    
    # Combine them line by line
    paste -d, "${current_csv}.tmp" "${previous_csv}.tmp" > "${combined_csv}"
    
    # Add header
    echo "timestamp,groundTruth,groundSteering,prevGroundSteering" > "${combined_csv}.tmp"
    cat "${combined_csv}" >> "${combined_csv}.tmp"
    mv "${combined_csv}.tmp" "${combined_csv}"
    
    # Clean up temp files
    rm "${current_csv}.tmp" "${previous_csv}.tmp"
    
    echo "Combined CSV created at: ${combined_csv}"
  else
    echo "No previous CSV file found for ${filename}"
    # Just use current CSV with empty prevGroundSteering column
    awk -F, 'NR==1 {print $1","$2","$3",prevGroundSteering"} NR>1 {print $1","$2","$3","}' "${current_csv}" > "${combined_csv}"
  fi
  
  # Generate plot from combined CSV
  cat "${combined_csv}" | grep -E '^[0-9]+,-?[0-9.]+,-?[0-9.]+,-?[0-9.]*$' \
    | gnuplot -e "output_png='${output_png}'" -c plot_script.gnuplot
  
  if [ $? -ne 0 ]; then
    echo "Error generating plot for ${filename}"
    exit 1
  fi
  
  echo "Successfully generated: ${output_png} and ${combined_csv}"
  echo "----------------------------------"
done

echo "All recordings processed successfully"