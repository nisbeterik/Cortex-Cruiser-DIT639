# Set the output format
set terminal png size 1200,800 
if (!exists("output_png")) output_png = 'plot.png'
set output output_png

# Set the title and labels
set title "Steering Values Over Time"
set xlabel "Timestamp (μs)" offset 0,-1
set ylabel "Steering Value"

# Set grid
set grid

# Set data separator (comma for CSV)
set datafile separator ','

# Disable time formatting and use raw microseconds
unset xdata
unset timefmt
unset format x

# Rotate x-axis labels and adjust spacing
set xtics rotate by -30 offset -1,-0.2
set xtics font ",8"  # Smaller font for timestamps

# Adjust margins to make room for rotated labels
set bmargin 5

# Make sure we're using numeric formatting for x-axis
set format x "%.0f"

# Define the plot using raw microseconds
plot 'comb.csv' using 1:2 with lines title 'Ground Truth', \
     '' using 1:3 with lines title 'Ground Steering', \
     '' using 1:4 with lines title 'Previous Ground Steering'