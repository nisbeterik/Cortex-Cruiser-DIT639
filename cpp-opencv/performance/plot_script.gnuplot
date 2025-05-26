# Variables passed from shell script:
# current_csv - path to current commit CSV
# previous_csv - path to previous commit CSV (may be empty)
# output_png - output PNG file path
# filename - base filename for title
# commit_hash - current commit hash

# Set terminal and output
set terminal pngcairo size 1200,800 enhanced font "Arial,12"
set output output_png

# Set plot styling
set grid
set key outside right top
set xlabel "Timestamp (μs)"
set ylabel "Steering Value"
set title sprintf("Steering Comparison: %s", filename)

# Treat timestamps as numeric values (microseconds)
unset xdata
unset timefmt

# Auto-scale the x-axis to show microseconds properly
set autoscale x

# Define line styles
set style line 1 lc rgb '#e74c3c' lw 2 pt 7 ps 0.5  # Red for current
set style line 2 lc rgb '#3498db' lw 2 pt 5 ps 0.5  # Blue for previous  
set style line 3 lc rgb '#2ecc71' lw 2 pt 9 ps 0.5  # Green for ground truth

# Function to format large numbers (microseconds) for x-axis
set xtics format "%.1s%cμs"

# Check if previous CSV exists and plot accordingly
if (strlen(previous_csv) > 0) {
    # First check if we can read the data
    stats current_csv using 1:2 nooutput
    if (STATS_records > 0) {
        stats previous_csv using 1:2 nooutput
        if (STATS_records > 0) {
            # Plot all three lines: current, previous, and ground truth
            plot current_csv using 1:2 with linespoints ls 1 title sprintf("Current (%s)", commit_hash[1:8]), \
                 current_csv using 1:3 with linespoints ls 3 title "Ground Truth", \
                 previous_csv using 1:2 with linespoints ls 2 title "Previous Commit"
        } else {
            # Fallback if previous CSV is empty
            plot current_csv using 1:2 with linespoints ls 1 title sprintf("Current (%s)", commit_hash[1:8]), \
                 current_csv using 1:3 with linespoints ls 3 title "Ground Truth"
        }
    } else {
        print "Error: Current CSV contains no valid data"
        exit 1
    }
} else {
    # Plot only current and ground truth (no previous data available)
    stats current_csv using 1:2 nooutput
    if (STATS_records > 0) {
        plot current_csv using 1:2 with linespoints ls 1 title sprintf("Current (%s)", commit_hash[1:8]), \
             current_csv using 1:3 with linespoints ls 3 title "Ground Truth"
    } else {
        print "Error: Current CSV contains no valid data"
        exit 1
    }
}

# Add some annotations
set label sprintf("Generated: %s", strftime("%Y-%m-%d %H:%M:%S", time(0))) at graph 0.02, 0.98 font "Arial,10"

print sprintf("Plot saved to: %s", output_png)