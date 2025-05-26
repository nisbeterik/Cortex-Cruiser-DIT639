#!/bin/sh
RECORDING_DIR="src/recordings"
OUTPUT_DIR="plots"
CSV_OUTPUT_DIR="output"
PREVIOUS_OUTPUT_DIR="previous_plots"
COMMIT_HASH="$1"

# Create directories if they don't exist
mkdir -p "${OUTPUT_DIR}"
mkdir -p "${CSV_OUTPUT_DIR}"
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
            echo "Previous output directory contents"
            ls $PREVIOUS_OUTPUT_DIR/cpp-opencv/performance/$CSV_OUTPUT_DIR
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
    
    echo "Processing recording file: ${filename}.rec"
    echo "Plot will be saved to: ${output_png}"
    echo "CSV will be saved to: ${output_csv}"
    
    # Check if corresponding previous CSV exists for this specific recording
    previous_csv_dir="${PREVIOUS_OUTPUT_DIR}/cpp-opencv/performance/${CSV_OUTPUT_DIR}"
    previous_csv_file=""
    
    # Look for previous CSV file matching this recording (filename_*.csv pattern)
    if [ -d "$previous_csv_dir" ]; then
        for prev_file in "$previous_csv_dir"/${filename}_*.csv; do
            if [ -f "$prev_file" ]; then
                previous_csv_file="$prev_file"
                break
            fi
        done
    fi
    
    # Process the recording and generate plot
    if [ -n "$previous_csv_file" ] && [ -f "$previous_csv_file" ]; then
        echo "Using previous CSV for ${filename}: $previous_csv_file"
        # Create a combined input by concatenating current piped data with previous data
        {
            docker run \
                -v "$(pwd)/${RECORDING_DIR}:/data" \
                -v "$(pwd)/${CSV_OUTPUT_DIR}:/output" \
                performance:latest \
                --rec="/data/${filename}.rec" \
                --output="/output/${filename}_${COMMIT_HASH}.csv" \
            | grep -E '^[0-9]+;-?[0-9.]+;-?[0-9.]+;[0-9.]+'
    
    if [ $? -ne 0 ]; then
        echo "Error processing ${filename}.rec"
        exit 1
    fi
    
    echo "Successfully generated: ${output_png} and ${output_csv}"
    echo "----------------------------------"
done

echo "All recordings processed successfully"
            echo "PREVIOUS_DATA_MARKER"
            cat "$previous_csv_file" | grep -E '^[0-9]+;-?[0-9.]+;-?[0-9.]+;[0-9.]+'
    
    if [ $? -ne 0 ]; then
        echo "Error processing ${filename}.rec"
        exit 1
    fi
    
    echo "Successfully generated: ${output_png} and ${output_csv}"
    echo "----------------------------------"
done

echo "All recordings processed successfully"
        } | gnuplot -e "output_png='${output_png}'; has_previous=1" -c plot_script.gnuplot
    else
        echo "No previous CSV found for ${filename}, plotting current data only"
        docker run \
            -v "$(pwd)/${RECORDING_DIR}:/data" \
            -v "$(pwd)/${CSV_OUTPUT_DIR}:/output" \
            performance:latest \
            --rec="/data/${filename}.rec" \
            --output="/output/${filename}_${COMMIT_HASH}.csv" \
        | grep -E '^[0-9]+;-?[0-9.]+;-?[0-9.]+;[0-9.]+'
    
    if [ $? -ne 0 ]; then
        echo "Error processing ${filename}.rec"
        exit 1
    fi
    
    echo "Successfully generated: ${output_png} and ${output_csv}"
    echo "----------------------------------"
done

echo "All recordings processed successfully" \
        | gnuplot -e "output_png='${output_png}'; has_previous=0" -c plot_script.gnuplot
    fi
    
    if [ $? -ne 0 ]; then
        echo "Error processing ${filename}.rec"
        exit 1
    fi
    
    echo "Successfully generated: ${output_png} and ${output_csv}"
    echo "----------------------------------"
done

echo "All recordings processed successfully"