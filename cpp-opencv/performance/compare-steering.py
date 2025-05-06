import pandas as pd
import matplotlib.pyplot as plt
from sklearn.metrics import mean_squared_error
import numpy as np

# Load both CSV files
computed_df = pd.read_csv("/Users/martinlidgren/Desktop/dit639/2025-group-06/cpp-opencv/performance/computed_output.csv")
truth_df = pd.read_csv("/Users/martinlidgren/Desktop/dit639/2025-group-06/cpp-opencv/performance/cleaned_data.csv")

# Rename columns if necessary (assuming both files have 'timestamp' and 'groundSteering')
computed_df.columns = ['timestamp', 'groundSteering']  # Rename in computed data
truth_df.columns = ['timestamp', 'groundSteering']  # Rename in truth data

# Merge on timestamp
merged = pd.merge(computed_df, truth_df, on="timestamp", suffixes=('_computed', '_truth'))

# Compute RMSE
rmse = np.sqrt(mean_squared_error(merged['groundSteering_truth'], merged['groundSteering_computed']))

# Estimate max possible steering angle (adjust if you know the real limit)
max_steering_angle = max(abs(merged['groundSteering_truth'].max()), abs(merged['groundSteering_truth'].min()))

# Compute relative accuracy as a percentage
accuracy_percent = 100 * (1 - (rmse / max_steering_angle))
accuracy_percent = max(0, min(accuracy_percent, 100))  # Clamp between 0 and 100

print(f"RMSE = {rmse:.4f}")
print(f"Accuracy ≈ {accuracy_percent:.2f}%")

# Plot
plt.figure(figsize=(12, 6))
plt.plot(merged['timestamp'], merged['groundSteering_truth'], label='Ground Truth', linewidth=2)
plt.plot(merged['timestamp'], merged['groundSteering_computed'], label='Computed Steering', linestyle='--')

plt.xlabel("Timestamp (μs)")
plt.ylabel("Steering Angle")
plt.title(f"Group 06 Steering Comparison\nRMSE = {rmse:.4f} | Accuracy ≈ {accuracy_percent:.2f}%")
plt.legend()
plt.grid(True)

# Watermark with group name
plt.text(merged['timestamp'].iloc[len(merged)//2],
         max(merged['groundSteering_truth'].max(), merged['groundSteering_computed'].max()) * 0.95,
         "group_06", fontsize=14, color='gray', alpha=0.4)

plt.tight_layout()
plt.savefig("steering_comparison.png")
plt.show()
