#!/bin/sh

RECORDING_DIR="src/recordings"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
OUTPUT_DIR="plots"
CSV_OUTPUT_DIR="output"
PREVIOUS_OUTPUT_DIR="previous_plots"
COMMIT_HASH="$1"

# Create directories if they don't exist
mkdir -p "${OUTPUT_DIR}"
mkdir -p "${CSV_OUTPUT_DIR}" 
mkdir -p "${PREVIOUS_OUTPUT_DIR}"
chmod +x combine.sh

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
  fi

  echo "----------------------------------"
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
      ls "${PREVIOUS_OUTPUT_DIR}/cpp-opencv/performance/output" 
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
  output_csv="${CSV_OUTPUT_DIR}/${filename}_${COMMIT_HASH}_current.csv" 
  combined_csv="comb.csv"
  
  echo "Processing recording file: ${filename}.rec"
  echo "Plot will be saved to: ${output_png}"
  echo "Current CSV will be saved to: ${output_csv}"

  # First run the docker image to generate the current CSV
  docker run \
    -v "$(pwd)/${RECORDING_DIR}:/data" \
    -v "$(pwd)/${CSV_OUTPUT_DIR}:/output" \
    performance:latest \
    --rec="/data/${filename}.rec" \
    --output="/output/${filename}_${COMMIT_HASH}_current.csv"
  
  if [ $? -ne 0 ]; then
    echo "Error processing ${filename}.rec"
    exit 1
  fi

  # Find the most recent matching previous CSV file (excluding _current)
  if [ -d "${PREVIOUS_OUTPUT_DIR}/cpp-opencv/performance/output" ]; then
    echo "Looking for most recent previous CSV file matching: ${filename}*.csv (excluding _current files)"
    previous_csv_file=$(find "${PREVIOUS_OUTPUT_DIR}/cpp-opencv/performance/output" -name "${filename}*.csv" ! -name "*_current.csv")
    
    if [ -n "$previous_csv_file" ]; then
      echo "Found previous CSV file: ${previous_csv_file}"
      
      # Run combine.sh with current and previous CSV files
      echo "Combining current and previous CSV files..."

      ${SCRIPT_DIR}/combine.sh "${output_csv}" "${previous_csv_file}" "${combined_csv}"
      
      if [ $? -ne 0 ]; then
        echo "Error combining CSV files"
        exit 1
      fi
      
      # Use the combined CSV for plotting
      plotting_csv="${combined_csv}"
    else
      echo "No previous CSV file found for ${filename} (excluding _current files), using current CSV only"
      plotting_csv="${output_csv}"
    fi
  else
    echo "Previous output directory not found, using current CSV only"
    plotting_csv="${output_csv}"
  fi

  # Generate plot using the selected CSV file
  echo "Generating plot from: ${plotting_csv}"
  gnuplot -e "output_png='${output_png}'" plot_script.gnuplot
  
  if [ $? -ne 0 ]; then
    echo "Error generating plot"
    exit 1
  fi
  
  echo "Successfully generated: ${output_png}"
  echo "----------------------------------"
done

echo "All recordings processed successfully"