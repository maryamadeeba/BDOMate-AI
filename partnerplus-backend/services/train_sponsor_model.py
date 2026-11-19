"""
Sponsor Segmentation Model — Training Script
PartnerPlus.AI — Model 2 (Sponsor Segmentation)

Trains a K-Means clustering model that segments sponsors into
Bronze / Silver / Gold / Platinum / Diamond tiers based on their profile.
The resulting model is what services/sponsor_service.py loads at runtime.

Dataset: data/customer_segmentation_data.csv (1,000 records)
Columns are renamed below to match the sponsor domain used across the
backend (see services/sponsor_service.py for the feature names it expects).
"""

import os
import joblib
import pandas as pd
from sklearn.preprocessing import LabelEncoder, StandardScaler
from sklearn.cluster import KMeans

# ─────────────────────────────────────────────────────────────
# Paths — same convention as services/retrain_service.py
# ─────────────────────────────────────────────────────────────
BASE = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
MDIR = os.path.join(BASE, 'models')
DDIR = os.path.join(BASE, 'data')
os.makedirs(MDIR, exist_ok=True)

DATA_PATH = os.path.join(DDIR, 'customer_segmentation_data.csv')

N_CLUSTERS = 6
RANDOM_STATE = 42

TIER_NAMES_ASCENDING = [
    'Bronze Sponsor',
    'Silver Sponsor',
    'Gold Sponsor',
    'Platinum Sponsor',
    'Diamond Sponsor',
    'Diamond Sponsor',   # top 2 of 6 clusters both map to the top tier
]


# ─────────────────────────────────────────────────────────────
# STEP 1 — Train the sponsor segmentation model
# ─────────────────────────────────────────────────────────────
def train_sponsor_model() -> dict:
    """
    Loads the sponsor dataset, trains a K-Means segmentation model,
    and saves all artifacts to the models/ folder.
    """
    print(f"🔄 Loading sponsor dataset from {DATA_PATH} ...")
    df = pd.read_csv(DATA_PATH)

    # Rename generic columns to the sponsor domain
    df = df.rename(columns={
        'income':               'sponsor_budget',
        'spending_score':        'engagement_score',
        'membership_years':      'partnership_years',
        'purchase_frequency':    'interaction_frequency',
        'last_purchase_amount':  'last_contribution_amount',
        'age':                   'org_size_score',
        'preferred_category':    'industry_sector',
    })

    # Encode the categorical feature
    le_sector = LabelEncoder()
    df['industry_sector_enc'] = le_sector.fit_transform(df['industry_sector'])

    feature_cols = [
        'sponsor_budget',
        'engagement_score',
        'partnership_years',
        'interaction_frequency',
        'last_contribution_amount',
        'org_size_score',
        'industry_sector_enc',
    ]

    X = df[feature_cols].values

    # Scale features
    scaler = StandardScaler()
    X_scaled = scaler.fit_transform(X)

    # Train K-Means
    print(f"🔄 Training K-Means with {N_CLUSTERS} clusters on {len(df)} sponsor records...")
    kmeans = KMeans(n_clusters=N_CLUSTERS, random_state=RANDOM_STATE, n_init=10)
    df['cluster'] = kmeans.fit_predict(X_scaled)

    # Map clusters to tier names, ranked by avg sponsor_budget (ascending)
    cluster_rank = df.groupby('cluster')['sponsor_budget'].mean().sort_values()
    seg_labels = {
        cluster_id: TIER_NAMES_ASCENDING[i]
        for i, cluster_id in enumerate(cluster_rank.index)
    }

    print("✅ Cluster -> Tier mapping:")
    for cluster_id, tier in seg_labels.items():
        avg_budget = cluster_rank[cluster_id]
        print(f"   Cluster {cluster_id}: {tier}  (avg sponsor_budget ≈ {avg_budget:,.0f})")

    # Save model artifacts
    joblib.dump(kmeans,       os.path.join(MDIR, 'sponsor_model.pkl'))
    joblib.dump(scaler,       os.path.join(MDIR, 'sponsor_scaler.pkl'))
    joblib.dump(seg_labels,   os.path.join(MDIR, 'sponsor_segment_labels.pkl'))
    joblib.dump(le_sector,    os.path.join(MDIR, 'sponsor_sector_encoder.pkl'))
    joblib.dump(feature_cols, os.path.join(MDIR, 'sponsor_feature_cols.pkl'))

    print(f"\n✅ Sponsor segmentation model trained and saved to: {MDIR}")
    print(f"   Model: KMeans (n_clusters={N_CLUSTERS}, random_state={RANDOM_STATE})")
    print(f"   Trained on {len(df)} sponsor records")

    return {
        'status':       'success',
        'message':      'Sponsor segmentation model trained successfully!',
        'records_used': len(df),
        'n_clusters':   N_CLUSTERS,
        'model':        'KMeans',
    }


if __name__ == '__main__':
    train_sponsor_model()
