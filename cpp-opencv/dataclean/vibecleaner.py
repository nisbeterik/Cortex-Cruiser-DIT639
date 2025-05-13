import csv

# Read GroundSteering data
steering_readings = []
with open("groundSteering.csv", "r") as f:
    reader = csv.DictReader(f, delimiter=';')  # Use semicolon delimiter
    for row in reader:
        timestamp = float(row['sent.seconds']) + float(row['sent.microseconds']) / 1_000_000
        steering_readings.append((timestamp, row['groundSteering']))

# Read ImageReading data (now including width & height)
image_readings = []
with open("imageReading.csv", "r") as f:
    reader = csv.DictReader(f, delimiter=';')
    for row in reader:
        timestamp = float(row['sent.seconds']) + float(row['sent.microseconds']) / 1_000_000
        img_data = row['data']
        width = row['width']
        height = row['height']
        image_readings.append((timestamp, img_data, width, height))

# Sort both lists
image_readings.sort()
steering_readings.sort()

# Match closest steering value to each image timestamp
matched_rows = []
steering_index = 0
for img_time, img_data, width, height in image_readings:
    closest_steering = None
    min_diff = float('inf')
    for i in range(steering_index, len(steering_readings)):
        steer_time, steer_value = steering_readings[i]
        diff = abs(steer_time - img_time)
        if diff < min_diff:
            min_diff = diff
            closest_steering = steer_value
            steering_index = i
        elif steer_time > img_time:
            break
    if min_diff <= 0.05:  # Only match if within 50 ms
        matched_rows.append((f"{img_time:.6f}", img_data, width, height, closest_steering))

# Write output CSV
with open("./cleaned-data/merged_output.csv", "w", newline='') as f:
    writer = csv.writer(f)
    writer.writerow(['timestamp', 'image_base64', 'width', 'height', 'groundTruth'])
    writer.writerows(matched_rows)

print("✅ Merged CSV created with width and height: ./cleaned-data/merged_output.csv")
