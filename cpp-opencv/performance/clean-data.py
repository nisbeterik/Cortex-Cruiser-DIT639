import csv

input_file = "computed_output.csv"
output_file = "cleaned_data.csv"

with open(input_file, "r") as infile, open(output_file, "w", newline='') as outfile:
    reader = csv.DictReader(infile, delimiter=';')
    writer = csv.writer(outfile)
    
    # Write header
    writer.writerow(["timestamp", "groundSteering"])
    
    for row in reader:
        # Concatenate seconds and microseconds from sampleTimeStamp
        seconds = row["sampleTimeStamp.seconds"].strip()
        microseconds = row["sampleTimeStamp.microseconds"].strip().zfill(6)  # pad to 6 digits
        timestamp = f"{seconds}{microseconds}"
        
        # Ground steering angle (remove any dash sign if it's just -0)
        steering = row["groundSteering"].strip().replace("-0", "0")
        
        writer.writerow([timestamp, steering])