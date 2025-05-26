# Gnuplot script for plotting steering data
# Usage: cat data.csv | gnuplot -e "output_png='output.png'" plot_script.gnuplot

# Set output to PNG with dynamic filename
set terminal png size 1200,800 
if (!exists("output_png")) output_png = 'plot.png'
set output output_png

# Data format: timestamp,groundTruth,groundSteering,prevGroundSteering
set datafile separator ','

# Labels and title
set title "Group 06 - Cortex Cruiser"
set xlabel "Time (seconds)" 
set ylabel "Steering Value"
set grid

# Add legend position
set key top left

# Plot from piped stdin data
# Convert microseconds to seconds by dividing by 1,000,000
# Handle the case where prevGroundSteering might be empty
plot '<cat' using ($1/1000000.0):2 with lines lw 2 title "Ground Truth", \
     '' using ($1/1000000.0):3 with lines lw 2 title "Current Steering", \
     '' using ($1/1000000.0):($4 eq "" ? 1/0 : $4) with lines lw 2 dashtype 2 title "Previous Steering"