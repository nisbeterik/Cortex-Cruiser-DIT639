#!/usr/bin/gnuplot -persist

# Set output to PNG with dynamic filename
set terminal png size 1200,800 font ",10"
if (!exists("output_png")) output_png = 'plot.png'
set output output_png

# Default separator for piped data (semicolons)
set datafile separator ';'

# Read piped data (semicolon-separated)
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

# First plot piped data (always semicolon-separated)
plot $dummy using ($1/1e6):2 with lines lw 1 title "groundTruth", \
     $dummy using ($1/1e6):3 with lines lw 2 title "groundSteering (piped)", \
     csv_path using ($1/1e6):2 every ::1 with lines lw 2 title "groundSteering (file)" datafile separator ","