# PartnerPlus.AI — Complete Project
**University of South Asia | FYP 2022–2026 | Maryam Adeeba · Noor Fatima · Syeda Minahil Noor**

---

## What Is In This Zip

```
partnerplus-backend/         ← Python FastAPI backend (your server)
├── main.py                  ← Starts the server
├── Procfile                 ← Railway deployment config
├── nixpacks.toml            ← Railway build config
├── requirements.txt         ← Python packages to install
├── .env.example             ← Copy this to .env and fill in keys
├── .gitignore               ← Protects your .env from GitHub
│
├── database/
│   ├── db.py                ← PostgreSQL connection
│   └── models.py            ← All 6 database tables
│
├── models/                  ← TRAINED ML MODELS (ready to use)
│   ├── attendance_model.pkl       ← Random Forest, 90% accuracy
│   ├── label_encoders.pkl         ← Encoders for attendance model
│   ├── feature_cols.pkl           ← Feature list for attendance model
│   ├── sponsor_model.pkl          ← K-Means, 6 sponsor tiers
│   ├── sponsor_scaler.pkl         ← Scaler for sponsor model
│   ├── sponsor_segment_labels.pkl ← Tier names (Bronze to Diamond)
│   ├── sponsor_sector_encoder.pkl ← Industry encoder
│   └── sponsor_feature_cols.pkl   ← Sponsor feature list
│
├── services/
│   ├── ai_service.py        ← GPT-4o for MOU, Email, Chat, Marketing
│   ├── mou_templates.py     ← Real USA university MOU examples
│   ├── prediction_service.py← Uses trained attendance model
│   ├── sponsor_service.py   ← Uses trained sponsor model
│   └── retrain_service.py   ← Auto-retraining as real data collects
│
├── routers/
│   ├── mou.py               ← /mou/* endpoints
│   ├── other_routers.py     ← /email, /events, /partners, /ai endpoints
│   ├── sponsors.py          ← /sponsors/* endpoints
│   └── retrain.py           ← /retrain/* endpoints
│
├── flutter_helper/          ← FILES TO COPY INTO YOUR FLUTTER APP
│   └── api_constants.dart   ← All API URLs in one place
│
└── flutter_frontend/        ← YOUR FLUTTER APP (already connected)
    └── lib/
        ├── main.dart
        ├── login_page.dart
        ├── dashboard_page.dart
        ├── new_mou_page.dart    ← Connected to real backend
        ├── ai_email_page.dart   ← Connected to real backend
        ├── partners_page.dart
        ├── auto_call_page.dart
        ├── docs_page.dart
        └── ...
```

---

## SETUP — LOCAL TESTING

### Step 1 — Install PostgreSQL
- Download: https://www.postgresql.org/download/windows
- Password: `1234` | Port: `5432`
- Open pgAdmin → Create database: `partnerplus_db`

### Step 2 — Setup Backend
```
cd partnerplus-backend
python -m venv venv
venv\Scripts\activate
pip install -r requirements.txt
```

### Step 3 — Setup .env File
```
copy .env.example .env
```
Open `.env` and paste your OpenAI key:
```
OPENAI_API_KEY=sk-your-key-here
```
Get free key at: https://platform.openai.com

### Step 4 — Run Backend
```
uvicorn main:app --reload
```
Open: **http://localhost:8000/docs** — all APIs listed here!

### Step 5 — Run Flutter App
```
cd flutter_frontend
flutter pub get
flutter run
```

---

## DEPLOY LIVE (Railway)

### Step 1 — Push to GitHub
```
git init
git add .
git commit -m "PartnerPlus.AI backend"
git remote add origin https://github.com/YOURUSERNAME/partnerplus-backend.git
git push -u origin main
```
Note: `.env` is in `.gitignore` — your API key stays safe!

### Step 2 — Deploy on Railway
1. Go to https://railway.app → Sign up with GitHub
2. Click "New Project" → "Deploy from GitHub repo"
3. Select your repo

### Step 3 — Add Database on Railway
Click "New" → "Database" → "PostgreSQL"
Railway sets DATABASE_URL automatically!

### Step 4 — Add Environment Variables
In Railway → "Variables" tab, add:
- `OPENAI_API_KEY` = your sk-... key
- `SECRET_KEY` = any long random string

### Step 5 — Get Your Live URL
Railway gives you: `https://partnerplus-backend.up.railway.app`

### Step 6 — Update Flutter App
In `flutter_frontend/lib/new_mou_page.dart` and `ai_email_page.dart`:
```dart
static const bool isLive = true;  // change false → true
static const String railway = "https://your-real-railway-url.up.railway.app";
```

---

## ALL API ENDPOINTS

| Method | URL | Feature |
|--------|-----|---------|
| POST | /mou/generate | Generate MOU with GPT-4o |
| GET  | /mou/all | List all saved MOUs |
| GET  | /mou/{id} | Get one MOU |
| POST | /email/generate | Generate professional email |
| POST | /events/predict | Predict event attendance (ML) |
| GET  | /events/all | All events with predictions |
| POST | /partners/add | Add new partner |
| GET  | /partners/all | All partners |
| POST | /ai/chat | AI chat assistant |
| POST | /ai/marketing | Marketing content for events |
| POST | /sponsors/segment | Classify sponsor tier |
| POST | /retrain/record-actual | Record real event attendance |
| GET  | /retrain/status | Model status + data collected |
| POST | /retrain/trigger | Manually retrain model |

---

## ML MODELS

**Model 1 — Event Attendance Predictor**
- Algorithm: Random Forest Classifier
- Accuracy: 90%
- Trained on: 200,000 real event attendee records
- Predicts: High Attendance vs Low Attendance
- Auto-retrains: When BDOs record 50+ real events in the app

**Model 2 — Sponsor Segmentation**
- Algorithm: K-Means Clustering
- Trained on: 1,000 real sponsor/customer records
- Segments: Bronze → Silver → Gold → Platinum → Diamond
- Returns: Tier + description + recommended BDO actions

---

*PartnerPlus.AI | University of South Asia | Dept of Computer Science*
