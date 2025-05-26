#!/usr/bin/gnuplot -persist

# Set output to PNG with dynamic filename
set terminal png size 1200,800 
if (!exists("output_png")) output_png = 'plot.png'
set output output_png

# Data format: timestamp,groundTruth,groundSteering,prevGroundSteering
set datafile separator ','

# Read piped data, filter valid lines
valid_data = system("cat /dev/stdin | grep -E '^[0-9]+,-?[0-9.]+,-?[0-9.]+,-?[0-9.]+$'")
set print $dummy
print valid_data
set print

# Remove time formatting and use raw timestamp values
unset xdata
unset timefmt
unset format x

# Labels and title
set title "Group 06 - Cortex Cruiser"
set xlabel "Timestamp (seconds)" 
set ylabel "Steering Value"
set grid

# Plot using raw timestamp values (converted to seconds)
plot $dummy using ($1/1e6):2 with lines lw 2 title "Ground Truth", \
     $dummy using ($1/1e6):3 with lines lw 2 title "Current Steering", \
     $dummy using ($1/1e6):4 with lines lw 2 dashtype 2 title "Previous Steering"

# Add legend
set key top left