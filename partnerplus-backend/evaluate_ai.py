import os
import json
from sklearn.metrics import accuracy_score, precision_score, recall_score, f1_score

print("=" * 50)
print("       PARTNERPLUS AI - MODEL EVALUATION       ")
print("=" * 50)

# =====================================================================
# STEP 1: LOAD YOUR TEST / VALIDATION DATA
# =====================================================================
# TODO: Replace the lists below with your actual database queries or list arrays
# 1 = Successful/Attended/Signed, 0 = Unsuccessful/Absent/Declined

y_true = [1, 0, 1, 1, 0, 1, 0, 1, 1, 0, 1, 1, 0, 1, 0, 1, 1, 0, 1, 1, 1, 0, 1, 0, 1, 1, 0, 1, 1, 0]
y_pred = [1, 0, 1, 0, 0, 1, 0, 1, 1, 1, 1, 1, 0, 1, 0, 1, 1, 0, 1, 1, 1, 0, 1, 0, 1, 0, 0, 1, 1, 0]

# =====================================================================
# STEP 2: CALCULATE METRICS
# =====================================================================
accuracy = accuracy_score(y_true, y_pred)
precision = precision_score(y_true, y_pred, zero_division=0)
recall = recall_score(y_true, y_pred, zero_division=0)
f1 = f1_score(y_true, y_pred, zero_division=0)

# =====================================================================
# STEP 3: PRINT THE RESULTS
# =====================================================================
print(f"Total Test Scenarios Evaluated : {len(y_true)}")
print("-" * 50)
print(f"Calculated Accuracy  : {accuracy * 100:.2f}%")
print(f"Calculated Precision : {precision * 100:.2f}%")
print(f"Calculated Recall    : {recall * 100:.2f}%")
print(f"Calculated F1-Score  : {f1 * 100:.2f}%")
print("=" * 50)