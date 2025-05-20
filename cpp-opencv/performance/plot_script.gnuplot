#!/usr/bin/gnuplot -persist

# Set output to PNG
set terminal pngcairo size 800,600 enhanced font 'Arial,10'
set output 'plot.png'

# Data format: timestamp;y1;y2;accuracy
set datafile separator ';'

# Extract the last 'accuracy' value (from filtered data)
stats '< grep -E "^[0-9]+;-?[0-9.]+;-?[0-9.]+;[0-9.]+$" input.dat | tail -n 1' using 4 nooutput
last_accuracy = STATS_max

# Configure time on x-axis
set xdata time
set timefmt "%s"  # Timestamp in microseconds (divided by 1e6)
set format x "%H:%M:%S"

# Title and labels
set title sprintf("Data Plot (Accuracy: %.4f)", last_accuracy)
set xlabel "Time"
set ylabel "Values"

# Plot filtered data (only lines with ;-separated numbers)
plot '< grep -E "^[0-9]+;-?[0-9.]+;-?[0-9.]+;[0-9.]+$" input.dat' \
     using ($1/1e6):2 with lines title "Column 2", \
     '' using ($1/1e6):3 with lines title "Column 3"

# Add accuracy label
set label sprintf("Accuracy: %.4f", last_accuracy) at graph 0.95, graph 0.95 right