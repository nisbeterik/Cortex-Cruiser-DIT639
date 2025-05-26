#!/bin/sh

RECORDING_DIR="src/recordings"
OUTPUT_DIR="plots"
CSV_OUTPUT_DIR="output"
PREVIOUS_OUTPUT_DIR="previous_plots"
PREVIOUS_CSV_DIR="previous_output"
COMMIT_HASH="$1"

# Validate commit hash parameter
if [ -z "$COMMIT_HASH" ]; then
    echo "Error: Commit hash parameter is required"
    echo "Usage: $0 <commit_hash>"
    exit 1
fi

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

echo "=== Step 1: Generating CSV files from recordings ==="

# Process each .rec file to generate CSVs
csv_count=0
for rec_file in "${RECORDING_DIR}"/*.rec; do
    [ -e "${rec_file}" ] || continue
    
    filename=$(basename "${rec_file}" .rec)
    output_csv="${CSV_OUTPUT_DIR}/${filename}_${COMMIT_HASH}.csv"
    
    echo "Processing recording file: ${filename}.rec"
    echo "CSV will be saved to: ${output_csv}"
    
    # Process the recording and generate CSV
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
    
    csv_count=$((csv_count + 1))
    echo "Successfully generated: ${output_csv}"
    echo "----------------------------------"
done

echo "Generated ${csv_count} CSV files from recordings"

echo "=== Step 2: Fetching previous commit CSV files ==="

# Fetch previous job artifacts in CI environment
previous_csv_count=0
if [ -n "$CI" ]; then
    echo "Running in CI environment, attempting to fetch previous jobs..."
    
    response=$(curl -sS --header "PRIVATE-TOKEN: $CI_API_TOKEN" \
        "$CI_API_V4_URL/projects/$CI_PROJECT_ID/jobs")
    
    if [ $? -ne 0 ]; then
        echo "Failed to fetch previous jobs from GitLab API"
        exit 1
    fi
    
    # Extract the ID of the latest successful job in the "performance" stage
    previous_perf_job_id=$(echo "$response" | jq -r '[.[] | select(.stage == "performance" and .status == "success")] | first | .id')
    
    if [ "$previous_perf_job_id" != "null" ] && [ -n "$previous_perf_job_id" ]; then
        echo "Previous successful 'performance' job ID: $previous_perf_job_id"
        
        # Fetch artifacts from the previous job
        echo "Fetching artifacts from previous job..."
        curl -sS --header "PRIVATE-TOKEN: $CI_API_TOKEN" \
            -o "${PREVIOUS_OUTPUT_DIR}/artifacts.zip" \
            "$CI_API_V4_URL/projects/$CI_PROJECT_ID/jobs/$previous_perf_job_id/artifacts"
        
        if [ $? -eq 0 ] && [ -f "${PREVIOUS_OUTPUT_DIR}/artifacts.zip" ]; then
            echo "Successfully downloaded artifacts"
            
            # Unzip the artifacts
            unzip -qo "${PREVIOUS_OUTPUT_DIR}/artifacts.zip" -d "${PREVIOUS_OUTPUT_DIR}"
            echo "Artifacts extracted to ${PREVIOUS_OUTPUT_DIR}"
            
            # Move previous CSV files to their own directory
            find "${PREVIOUS_OUTPUT_DIR}" -name "*.csv" -exec mv {} "${PREVIOUS_CSV_DIR}/" \;
            
            # Count previous CSV files
            previous_csv_count=$(find "${PREVIOUS_CSV_DIR}" -name "*.csv" | wc -l)
            echo "Found ${previous_csv_count} previous CSV files"
        else
            echo "Failed to download artifacts from previous job"
        fi
    else
        echo "No previous successful 'performance' job found"
    fi
else
    echo "Not running in CI environment, skipping artifact fetch"
fi

echo "=== Step 3: Generating comparison plots ==="

# Now generate plots comparing current and previous data
plot_count=0
for current_csv in "${CSV_OUTPUT_DIR}"/*.csv; do
    [ -e "${current_csv}" ] || continue
    
    # Extract filename without commit hash suffix
    filename=$(basename "${current_csv}" "_${COMMIT_HASH}.csv")
    output_png="${OUTPUT_DIR}/${filename}_comparison_${COMMIT_HASH}.png"
    
    # Find matching previous CSV (any commit hash)
    previous_csv=""
    if [ -d "${PREVIOUS_CSV_DIR}" ]; then
        previous_csv=$(find "${PREVIOUS_CSV_DIR}" -name "${filename}_*.csv" | head -n 1)
    fi
    
    echo "Generating plot for: ${filename}"
    echo "Current CSV: ${current_csv}"
    if [ -n "$previous_csv" ] && [ -f "$previous_csv" ]; then
        echo "Previous CSV: ${previous_csv}"
    else
        echo "Previous CSV: Not found (will plot only current + ground truth)"
        previous_csv=""
    fi
    echo "Output PNG: ${output_png}"
    
    # Generate plot using gnuplot
    # Pass variables to gnuplot script
    gnuplot -e "
        current_csv='${current_csv}'; 
        previous_csv='${previous_csv}'; 
        output_png='${output_png}';
        filename='${filename}';
        commit_hash='${COMMIT_HASH}'
    " -c plot_script.gnuplot
    
    if [ $? -ne 0 ]; then
        echo "Error generating plot for ${filename}"
        exit 1
    fi
    
    plot_count=$((plot_count + 1))
    echo "Successfully generated: ${output_png}"
    echo "----------------------------------"
done

echo "=== Summary ==="
echo "Generated ${csv_count} CSV files from recordings"
echo "Found ${previous_csv_count} previous CSV files"
echo "Generated ${plot_count} comparison plots"
echo "All recordings processed successfully"