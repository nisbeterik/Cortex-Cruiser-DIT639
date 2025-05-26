#!/bin/bash

# Check if input files are provided
if [ "$#" -ne 3 ]; then
    echo "Usage: $0 <input_file1.csv> <input_file2.csv> <output_file.csv>"
    echo "  input_file1.csv should have: timestamp,groundTruth,groundSteering"
    echo "  input_file2.csv should have: prevGroundSteering"
    exit 1
fi

input1="$1"
input2="$2"
output="$3"

# Check if files exist
if [ ! -f "$input1" ]; then
    echo "Error: $input1 does not exist"
    exit 1
fi

if [ ! -f "$input2" ]; then
    echo "Error: $input2 does not exist"
    exit 1
fi

# Get number of lines in each file (excluding headers)
lines1=$(tail -n +2 "$input1" | wc -l)
lines2=$(tail -n +2 "$input2" | wc -l)

# Verify files have same number of data rows
if [ "$lines1" -ne "$lines2" ]; then
    echo "Error: Files have different number of data rows ($lines1 vs $lines2)"
    exit 1
fi

# Combine the files
{
    # Combine headers (assumes first line is header in both files)
    head -n 1 "$input1" | tr -d '\n'
    echo -n ","
    head -n 1 "$input2"
    
    # Combine data rows
    paste -d ',' \
        <(tail -n +2 "$input1") \
        <(tail -n +2 "$input2")
} > "$output"

echo "Combined CSV file created: $output"