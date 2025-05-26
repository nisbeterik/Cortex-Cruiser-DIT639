#!/usr/bin/gnuplot -persist

# Set output to PNG with dynamic filename
set terminal png size 1200,800 font ",10"
if (!exists("output_png")) output_png = 'plot.png'
set output output_png

# Data format configuration
set datafile separator ','

# Labels and title
set title "Group 06 - Cortex Cruiser"
set xlabel "Timestamp (ms)" 
set ylabel "Value"
set grid

# Plot configuration
plot_cmd = "plot "
plot_title = ""

# Plot current data if exists
if (strlen(current_csv) > 0 && system("[ -f '".current_csv."' ]") == 0) {
  plot_cmd = plot_cmd."'".current_csv."' using ($1/1e6):2 with lines lw 2 title 'Ground Truth (current)', "
  plot_cmd = plot_cmd."'".current_csv."' using ($1/1e6):3 with lines lw 2 title 'Ground Steering (current)', "
}

# Plot previous data if exists
if (strlen(previous_csv) > 0 && system("[ -f '".previous_csv."' ]") == 0) {
  previous_label = system("basename ".previous_csv." | cut -d'_' -f2 | cut -d'.' -f1")
  plot_cmd = plot_cmd."'".previous_csv."' using ($1/1e6):3 with lines lw 2 dt 2 title 'Ground Steering (".previous_label.")', "
}

# Remove trailing comma and space
if (strlen(plot_cmd) > 5) {
  plot_cmd = plot_cmd[1:strlen(plot_cmd)-2]
} else {
  print "Error: No valid data to plot"
  exit 1
}

# Execute the plot command
eval(plot_cmd)