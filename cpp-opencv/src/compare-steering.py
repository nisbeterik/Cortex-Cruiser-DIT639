import pandas as pd
import matplotlib.pyplot as plt
from sklearn.metrics import mean_squared_error
import numpy as np

# Load both CSV files
computed_df = pd.read_csv("computed_output.csv")
truth_df = pd.read_csv("comparison.csv")

# Rename columns if needed
if 'ground_truth_angle' not in truth_df.columns:
    truth_df.columns = ['timestamp', 'ground_truth_angle']

if 'computed_angle' not in computed_df.columns:
    computed_df.columns = ['timestamp', 'computed_angle']

# Merge on timestamp
merged = pd.merge(computed_df, truth_df, on="timestamp")

# Compute RMSE
rmse = np.sqrt(mean_squared_error(merged['ground_truth_angle'], merged['computed_angle']))

# Estimate max possible steering angle (adjust if you know the real limit)
max_steering_angle = max(abs(merged['ground_truth_angle'].max()), abs(merged['ground_truth_angle'].min()))

# Compute relative accuracy as a percentage
accuracy_percent = 100 * (1 - (rmse / max_steering_angle))
accuracy_percent = max(0, min(accuracy_percent, 100))  # Clamp between 0 and 100

print(f"RMSE = {rmse:.4f}")
print(f"Accuracy ≈ {accuracy_percent:.2f}%")

# Plot
plt.figure(figsize=(12, 6))
plt.plot(merged['timestamp'], merged['ground_truth_angle'], label='Ground Truth', linewidth=2)
plt.plot(merged['timestamp'], merged['computed_angle'], label='Computed Steering', linestyle='--')

plt.xlabel("Timestamp (μs)")
plt.ylabel("Steering Angle")
plt.title(f"Group 06 Steering Comparison\nRMSE = {rmse:.4f} | Accuracy ≈ {accuracy_percent:.2f}%")
plt.legend()
plt.grid(True)

# Watermark with group name
plt.text(merged['timestamp'].iloc[len(merged)//2],
         max(merged['ground_truth_angle'].max(), merged['computed_angle'].max()) * 0.95,
         "group_06", fontsize=14, color='gray', alpha=0.4)

plt.tight_layout()
plt.savefig("steering_comparison.png")
plt.show()
