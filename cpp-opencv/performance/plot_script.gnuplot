#!/usr/bin/gnuplot -persist

# Set output to PNG with dynamic filename
set terminal pngcairo size 1200,800 enhanced font 'Verdana,12'
if (!exists("output_png")) output_png = 'plot.png'
set output output_png

# Data format: timestamp;groundTruth;groundSteering;accuracy
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

# Plot using raw timestamp values
plot $dummy using ($1/1e6):2 with lines lw 2 title "groundTruth", \
     $dummy using ($1/1e6):3 with lines lw 2 title "groundSteering"

# Add accuracy box (only the final value)
set obj 1 rect at graph 0.95, graph 0.95 size char 20, char 3 fc rgb "white" fs solid 0.5 border
set label 1 sprintf("Final Accuracy: %.2f%%", last_accuracy) at graph 0.95, graph 0.95 right