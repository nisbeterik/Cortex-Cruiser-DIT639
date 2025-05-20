#!/usr/bin/gnuplot -persist

# Set output to PNG
set terminal pngcairo size 800,600 enhanced font 'Arial,10'
set output 'plot.png'

# Data format: timestamp;y1;y2;accuracy
set datafile separator ';'

# Read from stdin and extract the last 'accuracy' value
stats '-' using 4 nooutput name "accuracy_stats"
last_accuracy = accuracy_stats_max

# Configure time on x-axis
set xdata time
set timefmt "%s"  # Timestamp in microseconds (divided by 1e6)
set format x "%H:%M:%S"

# Title and labels
set title sprintf("Data Plot (Accuracy: %.4f)", last_accuracy)
set xlabel "Time"
set ylabel "Values"

# Plot from stdin (piped data)
plot '-' using ($1/1e6):2 with lines title "Column 2", \
     '-' using ($1/1e6):3 with lines title "Column 3"

# Add accuracy label
set label sprintf("Accuracy: %.4f", last_accuracy) at graph 0.95, graph 0.95 right