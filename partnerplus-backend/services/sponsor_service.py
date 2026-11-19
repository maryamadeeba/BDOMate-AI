"""
Sponsor Segmentation Service
Uses real K-Means model trained on 1,000 sponsor records.
Classifies any sponsor into: Bronze / Silver / Gold / Platinum / Diamond
"""
import joblib
import numpy as np
import os

BASE  = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
MDIR  = os.path.join(BASE, 'models')

model        = joblib.load(os.path.join(MDIR, 'sponsor_model.pkl'))
scaler       = joblib.load(os.path.join(MDIR, 'sponsor_scaler.pkl'))
seg_labels   = joblib.load(os.path.join(MDIR, 'sponsor_segment_labels.pkl'))
le_sector    = joblib.load(os.path.join(MDIR, 'sponsor_sector_encoder.pkl'))
feature_cols = joblib.load(os.path.join(MDIR, 'sponsor_feature_cols.pkl'))

print("✅ Sponsor segmentation model loaded!")

SEGMENT_DESCRIPTIONS = {
    'Bronze Sponsor':   'New or low-engagement sponsor. Needs nurturing. Send introductory event invitations.',
    'Silver Sponsor':   'Mid-tier sponsor with moderate budget. Good potential. Invite to workshops and seminars.',
    'Gold Sponsor':     'Reliable sponsor with consistent engagement. Offer co-branding on events.',
    'Platinum Sponsor': 'High-value long-term sponsor. Offer MOU renewal and exclusive event partnerships.',
    'Diamond Sponsor':  'Top-tier sponsor. Maximum budget and engagement. Offer premium collaboration and named events.',
}

RECOMMENDED_ACTIONS = {
    'Bronze Sponsor':   ['Send welcome email', 'Invite to free events', 'Share university newsletter'],
    'Silver Sponsor':   ['Invite to workshops', 'Propose internship MOU', 'Offer logo on event banners'],
    'Gold Sponsor':     ['Propose annual MOU', 'Co-host seminar', 'Feature in university magazine'],
    'Platinum Sponsor': ['Offer MOU renewal meeting', 'Named scholarship opportunity', 'VIP event invitation'],
    'Diamond Sponsor':  ['Strategic partnership MOU', 'Named auditorium/lab offer', 'Board advisory invitation'],
}


def segment_sponsor(
    sponsor_budget: float,
    engagement_score: float,
    partnership_years: float,
    interaction_frequency: float,
    last_contribution_amount: float,
    org_size_score: float,
    industry_sector: str = 'Technology'
) -> dict:
    """
    Classifies a sponsor into a tier based on their profile.
    Returns segment name + description + recommended BDO actions.
    """
    # Encode industry sector safely
    if industry_sector in le_sector.classes_:
        sector_enc = le_sector.transform([industry_sector])[0]
    else:
        sector_enc = 0

    features = np.array([[
        sponsor_budget,
        engagement_score,
        partnership_years,
        interaction_frequency,
        last_contribution_amount,
        org_size_score,
        sector_enc
    ]])

    features_scaled = scaler.transform(features)
    cluster         = int(model.predict(features_scaled)[0])
    segment_name    = seg_labels.get(cluster, 'Silver Sponsor')

    return {
        'segment':     segment_name,
        'cluster_id':  cluster,
        'description': SEGMENT_DESCRIPTIONS.get(segment_name, ''),
        'recommended_actions': RECOMMENDED_ACTIONS.get(segment_name, []),
    }
