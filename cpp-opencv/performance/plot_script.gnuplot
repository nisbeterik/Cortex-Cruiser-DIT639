# Output settings
set terminal png size 1200,600
if (!exists("output_png")) output_png = 'plot.png'
set output output_png

# Title and labels
set title "Steering Values Over Time"
set xlabel "Timestamp" offset 0,-1
set ylabel "Steering Value"

# Grid and border styling
set grid linecolor rgb "#dddddd" linewidth 0.5
set border linewidth 1.5

# Data format
set datafile separator ','

# X-axis configuration (raw microseconds)
unset xdata
unset timefmt
unset format x

# Rotate x-axis labels and adjust spacing
set xtics font ",6"  


# Margins and layout
set bmargin 6 
set lmargin 13
set rmargin 13
set tmargin 3

# Line styles
set style line 1 linewidth 2 linecolor rgb "#0060ad"  # Ground Truth
set style line 2 linewidth 2 linecolor rgb "#dd0000"  # Ground Steering
set style line 3 linewidth 2 linecolor rgb "#00aa00"  # Previous Ground Steering

# Plot command
plot 'comb.csv' using 1:2 with lines linestyle 1 title 'Ground Truth', \
     '' using 1:4 with lines linestyle 3 title 'Previous Ground Steering', \
     '' using 1:3 with lines linestyle 2 title 'Ground Steering'