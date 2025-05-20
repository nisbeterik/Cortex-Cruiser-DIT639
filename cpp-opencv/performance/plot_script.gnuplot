#!/usr/bin/gnuplot -persist

# Set output to PNG
set terminal pngcairo size 1200,800 enhanced font 'Verdana,12'
set output 'plot.png'

# Data format: timestamp;y1;y2;accuracy
set datafile separator ';'

# Read piped data, filter valid lines, and extract last accuracy
valid_data = system("cat /dev/stdin | grep -E '^[0-9]+;-?[0-9.]+;-?[0-9.]+;[0-9.]+$'")
set print $dummy
print valid_data
set print

# Get last accuracy value
stats $dummy using 4 nooutput
last_accuracy = STATS_max

# Configure time on x-axis (convert microseconds to seconds)
set xdata time
set timefmt "%s"
set format x "%H:%M:%S"

# Labels and title
set title sprintf("Real-Time Plot (Accuracy: %.2f%%)", last_accuracy)
set xlabel "Time"
set ylabel "Value"
set grid

# Plot
plot $dummy using ($1/1e6):2 with lines lw 2 title "Y1", \
     $dummy using ($1/1e6):3 with lines lw 2 title "Y2", \
     $dummy using ($1/1e6):($3+0.1):(sprintf("A=%.2f", $4)) with labels offset 0,1 notitle

# Add accuracy box
set obj 1 rect at graph 0.95, graph 0.95 size char 20, char 3 fc rgb "white" fs solid 0.5 border
set label 1 sprintf("Final Accuracy: %.2f%%", last_accuracy) at graph 0.95, graph 0.95 right