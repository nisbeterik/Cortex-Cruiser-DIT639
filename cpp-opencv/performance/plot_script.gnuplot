# Set output to PNG
set terminal pngcairo size 800,600 enhanced font 'Arial,10'
set output 'plot.png'

# Data format: timestamp;y1;y2;accuracy
set datafile separator ';'

# Extract the last 'accuracy' value from the data stream
stats '< tail -n 1 input.dat' using 4 nooutput
last_accuracy = STATS_max

# Set title with the last accuracy value
set title sprintf("Data Plot (Accuracy: %.4f)", last_accuracy)

# Configure time on x-axis
set xdata time
set timefmt "%s"  # Timestamp in microseconds (adjust if needed)
set format x "%H:%M:%S"

# Axis labels
set xlabel "Time"
set ylabel "Values"

# Plot the data
plot "input.dat" using ($1/1e6):2 with lines title "Column 2", \
     "" using ($1/1e6):3 with lines title "Column 3"

# Add accuracy label (positioned at graph's top-right)
set label sprintf("Accuracy: %.4f", last_accuracy) at graph 0.95, graph 0.95 right