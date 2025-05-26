#!/usr/bin/gnuplot -persist
# Set output to PNG with dynamic filename
set terminal png size 1200,800 
if (!exists("output_png")) output_png = 'plot.png'
set output output_png

# Data format: timestamp;groundTruth;groundSteering;accuracy
set datafile separator ';'

# Read piped data, filter valid lines
valid_data = system("cat /dev/stdin | grep -E '^[0-9]+;-?[0-9.]+;-?[0-9.]+;[0-9.]+$'")
set print $current_data
print valid_data
set print

# Read previous commit data if directory exists
if (exists("previous_dir")) {
    # Get all CSV files from previous directory and concatenate them
    csv_files = system("find " . previous_dir . " -name '*.csv' -type f")
    if (strlen(csv_files) > 0) {
        set print $previous_data
        print system("find " . previous_dir . " -name '*.csv' -type f -exec cat {} \\; | grep -E '^[0-9]+;-?[0-9.]+;-?[0-9.]+;[0-9.]+

# Remove time formatting and use raw timestamp values
unset xdata
unset timefmt
unset format x

# Labels and title
set title "Group 06 - Cortex Cruiser"
set xlabel "Timestamp" 
set ylabel "Value"
set grid

# Plot three lines: groundTruth (current), groundSteering (current), groundSteering (previous)
if (has_previous_data) {
    plot $current_data using ($1/1e6):2 with lines lw 2 title "groundTruth", \
         $current_data using ($1/1e6):3 with lines lw 2 title "groundSteering (Current)", \
         $previous_data using ($1/1e6):3 with lines lw 2 title "groundSteering (Previous)"
} else {
    plot $current_data using ($1/1e6):2 with lines lw 2 title "groundTruth", \
         $current_data using ($1/1e6):3 with lines lw 2 title "groundSteering (Current)"
}")
        set print
        has_previous_data = 1
    } else {
        has_previous_data = 0
    }
} else {
    has_previous_data = 0
}

# Remove time formatting and use raw timestamp values
unset xdata
unset timefmt
unset format x

# Labels and title
set title "Group 06 - Cortex Cruiser"
set xlabel "Timestamp" 
set ylabel "Value"
set grid

# Plot three lines: groundTruth (current), groundSteering (current), groundSteering (previous)
if (has_previous_data) {
    plot $current_data using ($1/1e6):2 with lines lw 2 title "groundTruth", \
         $current_data using ($1/1e6):3 with lines lw 2 title "groundSteering (Current)", \
         $previous_data using ($1/1e6):3 with lines lw 2 title "groundSteering (Previous)"
} else {
    plot $current_data using ($1/1e6):2 with lines lw 2 title "groundTruth", \
         $current_data using ($1/1e6):3 with lines lw 2 title "groundSteering (Current)"
}