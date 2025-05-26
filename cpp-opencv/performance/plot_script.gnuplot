#!/usr/bin/gnuplot -persist

# Set output to PNG with dynamic filename
set terminal png size 1200,800 font ",10"
if (!exists("output_png")) output_png = 'plot.png'
set output output_png

# Read piped data (semicolon-separated)
set datafile separator ';'
valid_data = system("cat /dev/stdin | grep -E '^[0-9]+;-?[0-9.]+;-?[0-9.]+;[0-9.]+$'")
set print $dummy
print valid_data
set print

# Get last accuracy value
stats $dummy using 4 nooutput
last_accuracy = STATS_max

# Remove time formatting
unset xdata
unset timefmt
unset format x

# Labels and title
set title "Group 06 - Cortex Cruiser"
set xlabel "Timestamp" 
set ylabel "Value"
set grid

# Plot configuration
csv_path = 'output/'.csv_file

# First check if CSV exists
if (system("[ -f '".csv_path."' ]") == 0) {
    # Set comma separator just for CSV file
    set table $csv_data
    set datafile separator ','
    plot csv_path every ::1 using 1:2 with table
    unset table
    set datafile separator ';'  # Reset to semicolon for piped data
    
    plot $dummy using ($1/1e6):2 with lines lw 1 title "groundTruth", \
         $dummy using ($1/1e6):3 with lines lw 2 title "groundSteering (piped)", \
         $csv_data using ($1/1e6):2 with lines lw 2 title "groundSteering (file)"
} else {
    plot $dummy using ($1/1e6):2 with lines lw 1 title "groundTruth", \
         $dummy using ($1/1e6):3 with lines lw 2 title "groundSteering (piped)"
}