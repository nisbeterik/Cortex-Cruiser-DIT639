import pandas as pd
import matplotlib.pyplot as plt
from sklearn.metrics import mean_squared_error
import numpy as np

# Load both files
computed_df = pd.read_csv("computed_output.csv")
truth_df = pd.read_csv("comparison.csv")

# Inspect and rename columns if needed
if 'ground_truth_angle' not in truth_df.columns:
    truth_df.columns = ['timestamp', 'ground_truth_angle']

if 'computed_angle' not in computed_df.columns:
    computed_df.columns = ['timestamp', 'computed_angle']

# Merge on timestamp
merged = pd.merge(computed_df, truth_df, on="timestamp")

# Compute RMSE
rmse = np.sqrt(mean_squared_error(merged['ground_truth_angle'], merged['computed_angle']))
print(f" RMSE = {rmse:.4f}")

# Plot
plt.figure(figsize=(12, 6))
plt.plot(merged['timestamp'], merged['ground_truth_angle'], label='Ground Truth')
plt.plot(merged['timestamp'], merged['computed_angle'], label='Computed Steering', linestyle='--')

plt.xlabel("Timestamp (μs)")
plt.ylabel("Steering Angle")
plt.title(f"Group 06 Steering Comparison — RMSE = {rmse:.4f}")
plt.legend()
plt.grid(True)

# Add watermark text
plt.text(merged['timestamp'].iloc[len(merged)//2],
         max(merged['ground_truth_angle'].max(), merged['computed_angle'].max()) * 0.95,
         "group_06", fontsize=14, color='gray', alpha=0.4)

plt.tight_layout()
plt.savefig("steering_comparison.png")
plt.show()
