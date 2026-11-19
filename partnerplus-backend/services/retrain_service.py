import os
import json
import joblib
import numpy as np
import pandas as pd
from datetime import datetime
from sklearn.ensemble import RandomForestClassifier
from sklearn.preprocessing import LabelEncoder
from sklearn.model_selection import train_test_split
from sklearn.metrics import accuracy_score

BASE  = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
MDIR  = os.path.join(BASE, 'models')
DDIR  = os.path.join(BASE, 'data')
os.makedirs(DDIR, exist_ok=True)

RETRAIN_LOG = os.path.join(DDIR, 'retrain_log.json')
MIN_ROWS_TO_RETRAIN = 50   


def save_real_event(
    event_type: str,
    department: str,
    day_of_week: str,
    time_slot: str,
    season: str,
    capacity: int,
    is_free: bool,
    has_food: bool,
    industry_guests: bool,
    weeks_promoted: int,
    past_avg_attendance: int,
    actual_attendance: int       
):
      
    will_be_high = 1 if (actual_attendance / max(capacity, 1)) > 0.6 else 0

    row = {
        'event_type':          event_type,
        'department':          department,
        'day_of_week':         day_of_week,
        'time_slot':           time_slot,
        'season':              season,
        'capacity':            capacity,
        'is_free':             int(is_free),
        'has_food':            int(has_food),
        'industry_guests':     int(industry_guests),
        'weeks_promoted':      weeks_promoted,
        'past_avg_attendance': past_avg_attendance,
        'is_weekend':          int(day_of_week in ['Saturday','Sunday']),
        'is_weekday_peak':     int(day_of_week in ['Tuesday','Wednesday','Thursday']),
        'will_be_high_attendance': will_be_high,
        'recorded_at':         datetime.utcnow().isoformat()
    }

    real_data_path = os.path.join(DDIR, 'real_events.csv')
    new_row = pd.DataFrame([row])

    if os.path.exists(real_data_path):
        new_row.to_csv(real_data_path, mode='a', header=False, index=False)
    else:
        new_row.to_csv(real_data_path, index=False)

    total_rows = sum(1 for _ in open(real_data_path)) - 1
    print(f"✅ Real event saved. Total real records: {total_rows}")

    if total_rows >= MIN_ROWS_TO_RETRAIN and total_rows % MIN_ROWS_TO_RETRAIN == 0:
        print(f"🔄 Threshold reached ({total_rows} records) — retraining model...")
        retrain_attendance_model()

    return {"saved": True, "total_real_records": total_rows}

def retrain_attendance_model() -> dict:
    real_data_path = os.path.join(DDIR, 'real_events.csv')

    if not os.path.exists(real_data_path):
        return {"success": False, "message": "No real data yet. Collect more events first."}

    df = pd.read_csv(real_data_path)
    total = len(df)

    if total < MIN_ROWS_TO_RETRAIN:
        return {
            "success": False,
            "message": f"Only {total} real events collected. Need {MIN_ROWS_TO_RETRAIN} to retrain.",
            "records_collected": total,
            "records_needed": MIN_ROWS_TO_RETRAIN
        }

    print(f"🔄 Retraining on {total} real events...")

    label_encoders = {}
    cat_cols = ['event_type', 'department', 'day_of_week', 'time_slot', 'season']
    for col in cat_cols:
        le = LabelEncoder()
        df[col + '_enc'] = le.fit_transform(df[col].astype(str))
        label_encoders[col] = le

    feature_cols = [c + '_enc' for c in cat_cols] + [
        'capacity', 'is_free', 'has_food', 'industry_guests',
        'weeks_promoted', 'past_avg_attendance',
        'is_weekend', 'is_weekday_peak'
    ]

    X = df[feature_cols]
    y = df['will_be_high_attendance']
    X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2, random_state=42)

    model = RandomForestClassifier(n_estimators=200, random_state=42)
    model.fit(X_train, y_train)
    accuracy = accuracy_score(y_test, model.predict(X_test))

    joblib.dump(model,          os.path.join(MDIR, 'attendance_model.pkl'))
    joblib.dump(label_encoders, os.path.join(MDIR, 'label_encoders.pkl'))
    joblib.dump(feature_cols,   os.path.join(MDIR, 'feature_cols.pkl'))

    log = {
        'retrained_at':   datetime.utcnow().isoformat(),
        'records_used':   total,
        'new_accuracy':   round(accuracy * 100, 1),
        'model':          'RandomForestClassifier'
    }
    with open(RETRAIN_LOG, 'w') as f:
        json.dump(log, f, indent=2)

    print(f"✅ Model retrained! New accuracy: {accuracy*100:.1f}%")
    return {
        "success":      True,
        "message":      "Model retrained with real university event data!",
        "records_used": total,
        "new_accuracy": f"{accuracy*100:.1f}%",
        "retrained_at": log['retrained_at']
    }

def get_model_status() -> dict:
    real_data_path = os.path.join(DDIR, 'real_events.csv')
    records = 0
    if os.path.exists(real_data_path):
        records = sum(1 for _ in open(real_data_path)) - 1

    last_retrain = None
    if os.path.exists(RETRAIN_LOG):
        with open(RETRAIN_LOG) as f:
            last_retrain = json.load(f)

    return {
        'real_records_collected': records,
        'records_needed_to_retrain': MIN_ROWS_TO_RETRAIN,
        'progress_percent': round(min(records / MIN_ROWS_TO_RETRAIN * 100, 100), 1),
        'can_retrain_now': records >= MIN_ROWS_TO_RETRAIN,
        'last_retrain':   last_retrain,
        'tip': (
            f"Keep using the app! {MIN_ROWS_TO_RETRAIN - records} more real events needed to auto-retrain."
            if records < MIN_ROWS_TO_RETRAIN
            else "✅ Enough data collected! You can retrain now via POST /retrain/trigger"
        )
    }
