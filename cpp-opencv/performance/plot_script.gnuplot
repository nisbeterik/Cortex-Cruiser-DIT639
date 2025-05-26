# plot_script.gnuplot
# Variables passed from shell script:
# current_csv - path to current commit CSV
# previous_csv - path to previous commit CSV (may be empty)
# output_png - output PNG file path
# filename - base filename for title
# commit_hash - current commit hash

# Set terminal and output
set terminal png size 1200,800 font "Arial,12"
set output output_png

# Set plot styling
set grid
set key outside right top
set xlabel "Timestamp"
set ylabel "Steering Value"
set title sprintf("Steering Comparison: %s", filename)

# Set time format for x-axis if timestamps are in recognizable format
# Adjust this based on your timestamp format
set xdata time
set timefmt "%Y-%m-%d %H:%M:%S"
set format x "%H:%M:%S"
set xtics rotate by -45

# Define line styles
set style line 1 lc rgb '#e74c3c' lw 2 pt 7 ps 0.5  # Red for current
set style line 2 lc rgb '#3498db' lw 2 pt 5 ps 0.5  # Blue for previous  
set style line 3 lc rgb '#2ecc71' lw 2 pt 9 ps 0.5  # Green for ground truth

# Check if previous CSV exists and plot accordingly
if (strlen(previous_csv) > 0) {
    # Plot all three lines: current, previous, and ground truth
    plot current_csv using 1:2 with linespoints ls 1 title sprintf("Current (%s)", commit_hash[1:8]), \
         current_csv using 1:3 with linespoints ls 3 title "Ground Truth", \
         previous_csv using 1:2 with linespoints ls 2 title "Previous Commit"
} else {
    # Plot only current and ground truth (no previous data available)
    plot current_csv using 1:2 with linespoints ls 1 title sprintf("Current (%s)", commit_hash[1:8]), \
         current_csv using 1:3 with linespoints ls 3 title "Ground Truth"
}

# Add some annotations
set label sprintf("Generated: %s", strftime("%Y-%m-%d %H:%M:%S", time(0))) at graph 0.02, 0.98 font "Arial,10"

print sprintf("Plot saved to: %s", output_png)