import csv

# Define the threshold
THRESHOLD = 0.09

# Initialize counters
total_valid = 0
within_range = 0

# Read CSV data 
with open("computed_output.csv", "r") as csvfile:
    reader = csv.DictReader(csvfile)
    
    for row in reader:
        ground_truth = float(row["groundTruth"])
        ground_steering = float(row["groundSteering"])
        
        if ground_truth != 0:
            total_valid += 1
            if abs(ground_steering - ground_truth) <= THRESHOLD:
                within_range += 1

# Calculate percentage
if total_valid > 0:
    percentage = (within_range / total_valid) * 100
    print(f"Percentage within ±{THRESHOLD}: {percentage:.2f}%")
else:
    print("No valid groundTruth values to evaluate.")