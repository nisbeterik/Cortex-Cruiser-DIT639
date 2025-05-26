#!/usr/bin/gnuplot -persist
# Set output to PNG with dynamic filename
set terminal png size 1200,800 
if (!exists("output_png")) output_png = 'plot.png'
set output output_png

# Data format:
# - Piped data: timestamp;groundTruth;groundSteering;accuracy
# - CSV data: timestamp;groundSteering (after conversion)
set datafile separator ';'

# Read and split piped data
current_data = ""
previous_data = ""
in_previous = 0

# Read from stdin
while (1) {
    line = ""
    line = read("stdin")
    if (strlen(line) == 0) break
    
    if (line eq "PREVIOUS_DATA_MARKER") {
        in_previous = 1
    } else {
        if (!in_previous) {
            # Current data: timestamp;groundTruth;groundSteering;accuracy
            current_data = current_data.line."\n"
        } else {
            # Previous data: timestamp;groundSteering
            previous_data = previous_data.line."\n"
        }
    }
}

# Plot configuration
unset xdata
unset timefmt
unset format x
set title "Group 06 - Cortex Cruiser"
set xlabel "Timestamp" 
set ylabel "Value"
set grid

# Plot lines
if (exists("has_previous") && has_previous && strlen(previous_data) > 0) {
    plot current_data using ($1/1e6):2 with lines lw 2 title "groundTruth", \
         current_data using ($1/1e6):3 with lines lw 2 title "groundSteering (Current)", \
         previous_data using ($1/1e6):2 with lines lw 2 title "groundSteering (Previous)"
} else {
    plot current_data using ($1/1e6):2 with lines lw 2 title "groundTruth", \
         current_data using ($1/1e6):3 with lines lw 2 title "groundSteering (Current)"
}