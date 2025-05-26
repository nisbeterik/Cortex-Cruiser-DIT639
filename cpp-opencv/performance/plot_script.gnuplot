#!/usr/bin/gnuplot -persist

# Set output to PNG with dynamic filename
set terminal png size 1200,800 
if (!exists("output_png")) output_png = 'plot.png'
set output output_png

# Both piped data and CSV files now use semicolons
set datafile separator ';'

# Read piped data and separate into current and previous datasets
current_data = ""
previous_data = ""
set print $dummy
do for [line in system("cat /dev/stdin")] {
  if (strstrt(line, ";previous") > 0) {
    print substr(line, 1, strstrt(line, ";previous")-1)
    previous_data = previous_data.line."\n"
  } else {
    print line
    current_data = current_data.line."\n"
  }
}
set print

# Get last accuracy value from current data
stats $dummy using 4 nooutput
last_accuracy = STATS_max

# Set up plot
unset xdata
unset timefmt
unset format x
set title "Group 06 - Cortex Cruiser"
set xlabel "Timestamp" 
set ylabel "Value"
set grid

# Check if CSV file exists
csv_path = 'output/'.csv_file
if (system("[ -f '".csv_path."' ]") == 0) {
    file_exists = 1
} else {
    file_exists = 0
    print "CSV file not found: ".csv_path
}

# Plot using raw timestamp values
if (file_exists) {
    plot $dummy using ($1/1e6):2 with lines lw 1 title "groundTruth", \
         $dummy using ($1/1e6):3 with lines lw 2 title "groundSteering (piped)", \
         csv_path using ($1/1e6):2 with lines lw 2 title "groundSteering (file)"
} else {
    plot $dummy using ($1/1e6):2 with lines lw 1 title "groundTruth", \
         $dummy using ($1/1e6):3 with lines lw 2 title "groundSteering (piped)"
}