# Set the output format
set terminal pngcairo size 1024,768 enhanced font 'Arial,14'
set output 'output_plot.png'

# Set titles and labels
set title "Steering vs. Ground Truth Over Time"
set xlabel "Timestamp (microseconds)"
set ylabel "Values"

# Set grid and key
set grid
set key outside

# Specify the separator and skip the header row
set datafile separator ","
set datafile missing "NaN" # Handle any missing data gracefully
set key autotitle columnhead # Use column headers as legend titles

# Skip the header row by starting plotting from the second line
plot 'computed_output.csv' every ::1 using 1:2 with lines title "Ground Steering" lc rgb "red", \
     'computed_output.csv' every ::1 using 1:3 with lines title "Ground Truth" lc rgb "blue"














