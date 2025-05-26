#!/usr/bin/gnuplot -persist

# Set output to PNG with dynamic filename
set terminal png size 1200,800 
if (!exists("output_png")) output_png = 'plot.png'
set output output_png

# Both piped data and CSV files now use semicolons
set datafile separator ';'

# Read piped data, filter valid lines, and extract last accuracy
valid_data = system("cat /dev/stdin | grep -E '^[0-9]+;-?[0-9.]+;-?[0-9.]+;[0-9.]+$'")
set print $dummy
print valid_data
set print

# Get last accuracy value
stats $dummy using 4 nooutput
last_accuracy = STATS_max

# Remove time formatting and use raw timestamp values
unset xdata
unset timefmt
unset format x

# Labels and title
set title "Group 06 - Cortex Cruiser"
set xlabel "Timestamp" 
set ylabel "Value"
set grid

# Check if CSV file exists
csv_path = 'output/'.csv_file
if (system("[ -f '".csv_path."' ]") == 0) {
    file_exists = 1
} else {
    file_exists = 0
    print "CSV file not found: ".csv_path
}

# Plot using raw timestamp values
if (file_exists) {
    plot $dummy using ($1/1e6):2 with lines lw 1 title "groundTruth", \
         $dummy using ($1/1e6):3 with lines lw 2 title "groundSteering (piped)", \
         csv_path using ($1/1e6):2 with lines lw 2 title "groundSteering (file)"
} else {
    plot $dummy using ($1/1e6):2 with lines lw 1 title "groundTruth", \
         $dummy using ($1/1e6):3 with lines lw 2 title "groundSteering (piped)"
}