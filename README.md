# BDOMate.AI
 
> An AI-powered Business Development Officer (BDO) Assistant, built as a Final Year Project at the University of South Asia (2026).
 
Final Year Project, BSc Computer Science, University of South Asia, Lahore (2022–2026)
Team: Maryam Adeeba · Noor Fatima · Syeda Minahil Noor
*(Earlier name: PartnerPlus.AI. Some identifiers in the code still use that name.)*
 
---
 
## What It Does
 
| Module | What it does |
|---|---|
| 🤝 **Partner CRM** | Add, view, and manage university partners and contacts in one place |
| 📄 **MOU Generator** | AI drafts a full Memorandum of Understanding from a short brief, using an LLM through the OpenRouter API |
| 📧 **Email Generator** | AI writes professional outreach and follow-up emails instantly |
| 📥 **Email Inbox** | BDOs receive and read partner replies pulled from Gmail, and send AI-drafted responses in-app |
| 📅 **Event Management** | Create and manage events with venue/time clash checks; ML model predicts whether attendance will be high or low |
| 🏆 **Sponsor Segmentation** | ML model classifies sponsors into tiers (Bronze → Diamond) with recommended next actions |
| 📞 **Automated Calling** | Twilio-based outbound calling with IVR flows, call logs, transcripts and summaries; currently runs in demo mode (simulated calls, template transcripts) |
| 📣 **Marketing Campaigns** | Create and track outreach campaigns with AI-generated content (campaigns are kept in the app session, not yet saved to the backend) |
| 📊 **Analytics Dashboard** | Visual dashboards tracking contacts, events, emails, and partnership activity |
| 🔔 **Smart Notifications** | Auto-alerts for new BDO leads, MOU follow-ups, upcoming events and calls, and weekly partner health checks |
| 🤖 **AI Chat Assistant** | In-app AI assistant for quick help, content generation, and recommendations |
| 👤 **Admin Panel** | Role-restricted analytics (Admin, SuperAdmin, BDO Manager) across all BDO activity, with CSV export |
 
## What is in this repository
 
```
BDOMate.AI/
├── partnerplus-backend/              ← Python FastAPI backend (the server)
│   ├── main.py                       ← Starts the server, registers routers, starts the scheduler
│   ├── Procfile, nixpacks.toml       ← Railway deployment config
│   ├── requirements.txt              ← Python packages (see §8 for the missing ones)
│   ├── test_partnerplus.py           ← 25 backend tests (unit, integration, workflow)
│   ├── locustfile.py                 ← Load-test script (covers / and /docs only)
│   ├── evaluate_ai.py                ← Metrics template with hard-coded labels (not a model evaluation)
│   ├── migrate_*.py                  ← One-time database migrations (events, email replies, notifications)
│   │
│   ├── database/
│   │   ├── db.py                     ← PostgreSQL connection
│   │   ├── models.py                 ← 13 core tables (users, partners, MOUs, events, calls, emails, ...)
│   │   ├── models_email_reply.py     ← email_replies table
│   │   └── models_notifications.py   ← app_notifications table
│   │
│   ├── models/                       ← Trained ML artifacts (scikit-learn 1.8.0)
│   │   ├── attendance_model.pkl      ← Random Forest, 200 trees, 14 features, fit on 160 rows
│   │   ├── label_encoders.pkl        ← Category encoders for the attendance model
│   │   ├── feature_cols.pkl          ← Feature list for the attendance model
│   │   ├── sponsor_model.pkl         ← K-Means, K=6 (Bronze to Diamond tiers)
│   │   ├── sponsor_scaler.pkl        ← StandardScaler for the sponsor model
│   │   ├── sponsor_segment_labels.pkl← Cluster-to-tier names
│   │   ├── sponsor_sector_encoder.pkl← Sector encoder
│   │   └── sponsor_feature_cols.pkl  ← Sponsor feature list
│   │
│   ├── data/
│   │   ├── customer_segmentation_data.csv ← 1,000-row proxy dataset for the sponsor model
│   │   ├── event_attendance.csv      ← 200,000 attendee records (names/contacts; not model training data)
│   │   └── real_events.csv           ← Real event outcomes collected for retraining (1 row so far)
│   │
│   ├── services/
│   │   ├── ai_service.py             ← LLM client (OpenRouter): MOU, email, chat, marketing
│   │   ├── mou_templates.py          ← Reference MOU templates used in prompts
│   │   ├── prediction_service.py     ← Loads and runs the attendance model
│   │   ├── sponsor_service.py        ← Loads and runs the sponsor model, adds tier actions
│   │   ├── train_sponsor_model.py    ← Reproducible K-Means training script
│   │   ├── retrain_service.py        ← Stores real outcomes, retrains every 50 records
│   │   ├── calling_service.py        ← Outbound calls (DEMO_MODE: template transcripts)
│   │   ├── twilio_calling_service.py ← Twilio Voice / IVR integration
│   │   ├── gmail_scanner.py          ← Reads partner replies via the Gmail API
│   │   ├── email_sender.py           ← SMTP sending
│   │   └── notification_service.py   ← APScheduler jobs and notifications
│   │
│   └── routers/                      ← API endpoints (58 handlers, see §6)
│       ├── auth.py                   ← /auth/*  sign up, log in, password reset
│       ├── mou.py                    ← /mou/*  MOU generation and status
│       ├── other_routers.py          ← /email, /events, /partners, /ai endpoints
│       ├── events.py                 ← /events/*  event CRUD and slot recommender
│       ├── email_replies.py          ← /emails/replies/*  inbox and AI replies
│       ├── sponsors.py               ← /sponsors/segment
│       ├── retrain.py                ← /retrain/*
│       ├── calls.py                  ← /calls/*
│       ├── notifications.py          ← /notifications/*
│       └── admin_analytics.py        ← /api/admin/analytics (role-gated)
│
└── app/                              ← Flutter client (Android, iOS, Web, Desktop)
    ├── pubspec.yaml                  ← Flutter dependencies
    ├── lib/
    │   ├── main.dart, app_router.dart← App entry point and navigation
    │   ├── services/                 ← API clients (api_constants.dart holds the backend URL)
    │   ├── models/                   ← Data models (partner, event, MOU, email, call, ...)
    │   ├── screens/                  ← 13 feature areas: auth, dashboard, crm, mou, email,
    │   │                                events, calling, marketing, ai_assistant, analytics,
    │   │                                notifications, admin, settings
    │   ├── widgets/, theme/          ← Shared UI components and theme
    └── test/                         ← 25 Flutter tests (unit, integration, widget workflow)
```
 
## 1. Problem
 
University Business Development Offices manage a constant stream of tasks: drafting MOUs, emailing potential partners, predicting event turnout, classifying sponsors, handling inbound enquiries, and making outreach calls. All of this is done manually, scattered across emails, spreadsheets and notebooks, with no central system, no intelligence, and a lot of repetitive work.
 
BDOMate.AI gives BDOs a single mobile platform that automates the repetitive work, surfaces insights from data, and puts AI-generated drafts at their fingertips, so they can focus on building real partnerships instead of writing the same email for the 50th time. It combines:
 
- a partner CRM, with document generation through an LLM (MOUs, emails, marketing copy, replies);
- two machine learning components: event attendance classification and sponsor segmentation;
- an automated outreach layer: an outbound calling workflow, Gmail reply ingestion and scheduled notifications;
- role-gated analytics for office managers.
 
## 2. System architecture
 
```
 Flutter client (Android / Web / Desktop)
        │  HTTP + JWT
        ▼
 FastAPI backend ──► PostgreSQL (SQLAlchemy ORM, 15 tables)
   ├─ routers/       58 endpoints in 10 router modules
   ├─ services/      LLM client, ML inference, retraining, calling, Gmail, SMTP, scheduler
   ├─ models/        serialized scikit-learn artifacts (.pkl)
   └─ data/          training and feedback datasets
        │
        ├──► LLM provider (OpenRouter chat-completions API)
        ├──► Gmail API (OAuth2): ingests partner replies
        ├──► SMTP: outbound email, password reset
        └──► Twilio Voice / IVR (demo mode by default)
```
 
| Layer | Technology |
|---|---|
| Backend | Python 3.11, FastAPI, Uvicorn, SQLAlchemy 2, Pydantic 2 |
| Database | PostgreSQL (SQLite in memory for tests) |
| ML | scikit-learn (RandomForestClassifier, KMeans, StandardScaler), pandas, NumPy, joblib |
| LLM | OpenRouter chat-completions API (`openrouter/free`, temperature 0.4, max 2048 tokens) |
| Auth | bcrypt (passlib), JWT (python-jose) |
| Scheduling | APScheduler (timezone Asia/Karachi) |
| Client | Flutter (Dart SDK ^3.11), provider, go_router, fl_chart, http |
| Deployment | Railway (Procfile / nixpacks) |
 
## 3. Functional modules
 
| Module | What it does | Implementation |
|---|---|---|
| Authentication | Sign up, log in, forgot and reset password | bcrypt hashing, JWT access tokens, single-use reset tokens sent by SMTP |
| Partner CRM | Create, list, view and delete partners | `/partners/*`, duplicate checks |
| MOU generation | Draft an MOU from partner name, type and terms | LLM prompt with a reference template (`mou_templates.py`); status workflow |
| Email generation | Draft professional outreach emails | LLM, saved to `emails` table |
| AI assistant | Chat about BDO tasks | LLM with the last 10 turns of conversation as context |
| Marketing content | Copy for each platform about an event | LLM, tone chosen by platform |
| Email inbox | Read partner replies from Gmail and draft answers | Gmail API (OAuth2), LLM-drafted reply, sent by SMTP |
| Events | Create, update and delete events; checks for venue/time clashes (HTTP 409) | `/events/*` |
| Slot recommender | Suggests the top 3 dates in the next 14 days | **Rule-based scoring** (weekday and hour weights), not ML |
| Attendance prediction | Classifies an event as high or low attendance | Random Forest, §4.1 |
| Sponsor segmentation | Gives a sponsor a tier and suggested actions | K-Means, §4.2 |
| Feedback and retraining | Stores actual attendance and retrains the model | §4.3 |
| Outbound calling | Single and bulk calls, IVR keypress capture, transcripts, summaries | Twilio TwiML and webhooks; `DEMO_MODE` returns simulated results |
| Notifications | In-app notifications plus a weekly partner check | APScheduler jobs |
| Admin analytics | Aggregate metrics and CSV export | Limited to the `Admin`, `SuperAdmin` and `BDO Manager` roles |
 
## 4. Machine learning components
 
### 4.1 Event attendance classifier
 
| Property | Value (read from `models/attendance_model.pkl`) |
|---|---|
| Algorithm | `RandomForestClassifier(n_estimators=200, random_state=42)` |
| Target | `will_be_high_attendance`: 1 if actual attendance / capacity > 0.6 |
| Features (14) | `event_type`, `department`, `day_of_week`, `time_slot`, `season` (label-encoded); `capacity`, `is_free`, `has_food`, `industry_guests`, `weeks_promoted`, `past_avg_attendance`, `is_weekend`, `is_morning`, `is_weekday_peak` |
| Training set size | **160 rows** (the root-node weighted sample count of the fitted trees). With the 80/20 split in the code, that is about 200 events in total and about 40 held out |
| Category vocabulary | event_type {Conference, Seminar, Webinar, Workshop}; department {Architecture, Arts, Business, CS, Engineering, Medical}; time_slot {morning, afternoon, evening}; season {spring, summer, autumn, winter} |
| Top feature importances | past_avg_attendance 0.182 · event_type 0.131 · capacity 0.106 · weeks_promoted 0.084 · industry_guests 0.072 |
 
**Evaluation status: not verified.** The training dataset and training script for the shipped model are not in this repository, so its held-out accuracy cannot be reproduced. Earlier versions of this README and of the code said "90% accuracy, trained on 200K real records". That claim is withdrawn, for two reasons:
 
- `data/event_attendance.csv` (200,000 rows) is a list of attendees (names, emails, phone numbers). It contains none of the model's features and was not its training data.
- `evaluate_ai.py` computes metrics on two hard-coded lists of labels. It is a template and does not evaluate the model.
 
### 4.2 Sponsor segmentation
 
| Property | Value |
|---|---|
| Algorithm | `KMeans(n_clusters=6, n_init=10, random_state=42)` on `StandardScaler` features |
| Data | `data/customer_segmentation_data.csv`, 1,000 rows. This is a **proxy dataset**: a public retail customer segmentation set whose columns were renamed to sponsor terms (income → `sponsor_budget`, spending_score → `engagement_score`, preferred_category → `industry_sector`, and so on). The "sectors" are retail categories (Clothing, Electronics, Groceries, Home & Garden, Sports) |
| Features (7) | budget, engagement, partnership years, interaction frequency, last contribution, org size score, sector (encoded) |
| Tier mapping | Clusters are ranked by mean budget and named Bronze, Silver, Gold, Platinum, Diamond, Diamond (the top two clusters share Diamond) |
| Training script | `services/train_sponsor_model.py` (reproducible) |
 
**Measured cluster quality** (shipped model, applied to its own training data):
 
| Metric | Value |
|---|---|
| Silhouette score | **0.111** |
| Davies–Bouldin index | 1.909 |
| Silhouette for K = 2 … 8 | 0.111, 0.101, 0.108, 0.110, 0.111, 0.114, 0.117 |
 
Cluster sizes, from Bronze to the top Diamond cluster: 154, 167, 170, 186, 179, 144. Mean budgets per cluster: 66.2K, 66.3K, 83.7K, 87.1K, 106.8K, 122.8K.
 
**Interpretation.** The separation is weak (silhouette is near 0), and no value of K is clearly better than the others, so K = 6 is a design choice rather than something the data shows. Bronze and Silver have almost the same mean budget and differ mainly in engagement. Treat the tiers as a demonstration of the pipeline, not as validated sponsor categories.
 
### 4.3 Feedback loop
 
`POST /retrain/record-actual` saves an event's real outcome to `data/real_events.csv`. When the number of saved rows reaches a multiple of 50, `retrain_attendance_model()` refits the Random Forest (80/20 split, `random_state=42`), replaces the model artifacts, and writes the held-out accuracy to `data/retrain_log.json`. `GET /retrain/status` reports progress. **Current state: 1 real record saved, so no retraining has run.**
 
## 5. Verification and results
 
| Item | Result |
|---|---|
| Backend test suite (`test_partnerplus.py`) | **25 / 25 pass** (8 unit, 10 integration, 7 workflow; SQLite in memory; LLM and model calls mocked) |
| Flutter test suite (`app/test/`) | **25 / 25 pass** (10 unit, 8 integration, 7 widget workflow) |
| API surface | 58 endpoint handlers covering 57 distinct routes (65 route registrations, because some paths are registered with and without a trailing `/`) |
| Data model | 15 SQLAlchemy tables |
| LLM document generation | 10 MOU and email documents generated during end-to-end testing; 2 generated live at the project evaluation |
| Outbound calling | Full workflow shown in `DEMO_MODE` (template transcripts and summaries); no real calls were placed, because Twilio is a paid service |
| Load test | `locustfile.py` covers only `/` and `/docs`; no load results recorded |
 
Backend test coverage includes password hashing and verification, JWT claims, schema validation (blank name, short password, bad email), sign-up conflict (409), login failure (401), partner CRUD, and end-to-end BDO workflows (sign up → partner → event prediction → MOU → email → chat).
 
## 6. API endpoints
 
Interactive docs are at `/docs` once the server is running.
 
| Method | URL | Feature |
|--------|-----|---------|
| POST | `/auth/signup` | Register a user (bcrypt-hashed password, role defaults to `bdo`); returns JWT |
| POST | `/auth/login` | Log in; returns JWT access token |
| POST | `/auth/forgot-password` | Email a single-use password-reset link via SMTP |
| POST | `/auth/reset-password` | Set a new password using the reset token |
| POST | `/mou/generate` | Generate an MOU draft with the LLM from partner, type and terms |
| GET | `/mou/all` | List all saved MOUs |
| PUT | `/mou/{id}/status` | Update MOU status (e.g. draft → sent → signed) |
| DELETE | `/mou/{id}` | Delete an MOU |
| POST | `/email/generate` | Generate a professional outreach email with the LLM |
| POST | `/email/save` | Save an email to the database |
| GET | `/email/all` | List all saved emails |
| GET | `/email/{id}` | Get one email |
| GET | `/emails/replies` | List partner replies ingested from Gmail |
| GET | `/emails/replies/{id}` | Get one reply |
| PATCH | `/emails/replies/{id}/read` | Mark a reply as read |
| PATCH | `/emails/replies/read-all` | Mark all replies as read |
| DELETE | `/emails/replies/{id}` | Delete a reply |
| POST | `/emails/replies/{id}/generate-reply` | Draft a response to a partner reply with the LLM |
| POST | `/emails/replies/{id}/send-reply` | Send the drafted response via SMTP |
| POST | `/events/` | Save a new event from the Flutter client |
| GET | `/events/` | List all events |
| GET | `/events/{id}` | Get one event |
| DELETE | `/events/{id}` | Delete an event |
| GET | `/events/all` | List events with all fields *(currently unreachable, returns 422; see §8)* |
| POST | `/events/create` | Create an event; returns 409 on venue/time clash |
| PUT | `/events/{id}` | Update selected fields of an event |
| POST | `/events/recommend` | Recommend the top 3 dates in the next 14 days (rule-based scoring) |
| POST | `/events/predict` | Predict high/low attendance (Random Forest) |
| POST | `/partners/add` | Add a new partner |
| GET | `/partners/all` | List all partners |
| GET | `/partners/{id}` | Get one partner |
| DELETE | `/partners/{id}` | Delete a partner |
| POST | `/ai/chat` | AI assistant chat (LLM, last 10 turns as context) |
| POST | `/ai/marketing` | Generate platform-specific marketing content for an event (LLM) |
| POST | `/sponsors/segment` | Assign a sponsor tier (K-Means) with description and recommended actions |
| POST | `/retrain/record-actual` | Record an event's actual attendance for retraining |
| GET | `/retrain/status` | Real records collected and last retraining result |
| POST | `/retrain/trigger` | Manually retrain the attendance model |
| POST | `/calls/single` | Place one outbound call (simulated in `DEMO_MODE`) |
| POST | `/calls/bulk` | Place calls to multiple contacts (simulated in `DEMO_MODE`) |
| POST | `/calls/twiml` | Return the TwiML script for a Twilio call |
| POST | `/calls/webhook` | Receive IVR keypress responses from Twilio |
| POST | `/calls/status` | Receive call status updates from Twilio |
| GET | `/calls/history` | List call history |
| GET | `/calls/ivr-responses` | List recorded IVR responses |
| GET | `/calls/{id}` | Get one call with transcript and summary |
| POST | `/notifications/process-bdo-email` | Create notifications from an incoming BDO email |
| GET | `/notifications/unread-count` | Count unread notifications |
| GET | `/notifications/all` | List all notifications |
| PATCH | `/notifications/{id}/read` | Mark a notification as read |
| PATCH | `/notifications/read-all` | Mark all notifications as read |
| POST | `/notifications/test` | Seed test notifications (development) |
| DELETE | `/notifications/clear-demo` | Remove demo/test notifications |
| GET | `/api/admin/analytics` | Aggregate analytics (Admin, SuperAdmin, BDO Manager only) |
| GET | `/api/admin/analytics/export` | Download the analytics summary as CSV |
| GET | `/` | Service info and health check |
| POST | `/direct-bdo-email/` | Receive a direct email payload addressed to the BDO |
 
58 endpoint handlers serve 57 distinct method and URL pairs, because `DELETE /events/{id}` is defined in both `events.py` and `other_routers.py`.
 
## 7. Setup
 
### Backend
 
```bash
cd partnerplus-backend
python -m venv venv
venv\Scripts\activate            # Windows   (Linux/macOS: source venv/bin/activate)
pip install -r requirements.txt
pip install apscheduler requests google-api-python-client google-auth-oauthlib   # imported but not yet in requirements.txt
```
 
Create a `.env` file. Variables the code reads:
 
```
DATABASE_URL=postgresql://user:password@localhost:5432/partnerplus_db
OPENAI_API_KEY=            # OpenRouter key; the LLM client reads this variable name
SECRET_KEY=                # long random string
ALGORITHM=HS256
ACCESS_TOKEN_EXPIRE_MINUTES=60
SMTP_HOST=  SMTP_PORT=  SMTP_USER=  SMTP_PASSWORD=  SMTP_FROM_NAME=
APP_BASE_URL=              # used in password-reset links
TWILIO_ACCOUNT_SID=  TWILIO_AUTH_TOKEN=  TWILIO_PHONE_NUMBER=
PUBLIC_URL=                # public base URL for Twilio webhooks
DEMO_MODE=true             # simulated calls; set false only with a funded Twilio account
```
 
Gmail ingestion also needs `credentials.json` (an OAuth client from Google Cloud). The first OAuth run creates `token.json`.
 
```bash
python migrate_events_table_v2.py      # run once on an existing database
uvicorn main:app --reload              # http://localhost:8000/docs
```
 
### Tests
 
```bash
python -m pytest test_partnerplus.py -q    # backend; needs no PostgreSQL or API keys
cd ../app && flutter test                  # client
```
 
### Retrain the sponsor model
 
```bash
python services/train_sponsor_model.py
```
 
### Flutter client
 
```bash
cd app
flutter pub get
flutter run
```
 
The backend base URL is set in `lib/services/api_constants.dart`.
 
## 8. Known issues and limitations
 
1. **Route shadowing:** `GET /events/{event_id}` (in `routers/events.py`) is registered before `GET /events/all` (in `other_routers.py`), so `GET /events/all` returns HTTP 422. `DELETE /events/{event_id}` is also defined in both routers, and only the first one is reached. Fix: register the static paths first, or merge the two routers.
2. **Mismatched encoder inputs:** the attendance encoders expect `CS` and lowercase time slots, while the retraining path and the client may send `Computer Science` or `Morning`. `safe_encode` maps unknown values to 0 without any warning. The `is_morning` feature is always sent as 0 at inference time.
3. **The attendance model's training data is missing**, so its accuracy cannot be reproduced (§4.1).
4. **Sponsor segmentation uses proxy data** and the clusters separate weakly (§4.2).
5. **LLM provider:** requests go to OpenRouter with the `openrouter/free` model router, so the underlying model can change from request to request. `_call_gemini()` keeps its old name; the direct Gemini REST code after its `return` never runs and refers to an undefined `MODELS_TO_TRY`. LLM outputs were not evaluated with any metric.
6. **Call transcripts in `DEMO_MODE` are fixed templates**, not generated text or recordings of real calls.
7. **Dependencies:** `requirements.txt` is missing `apscheduler`, `requests`, `google-api-python-client` and `google-auth-oauthlib`. The model artifacts were saved with scikit-learn 1.8.0; loading them with other versions raises `InconsistentVersionWarning`.
8. **Secrets:** `.gitignore` excludes `.env` but not `credentials.json` or `token.json`. Add both before pushing, and rotate any key that has already been shared.
 
## 9. Future work
 
- Collect real event outcomes through the feedback endpoint, then retrain and report accuracy, precision, recall and F1 on a held-out set, plus a baseline (majority class, logistic regression).
- Replace the proxy sponsor data with real partner records, and choose K with silhouette and gap statistics.
- Evaluate generated MOUs and emails with a rubric (completeness, factual consistency with the inputs, reviewer edits needed).
- Fix the issues in §8 and add tests for the ML endpoints without mocks.
 
## 10. Team
 
**Maryam Adeeba**: Lead Developer (Flutter, FastAPI, ML)
**Noor Fatima**: Co-developer
**Syeda Minahil Noor**: Co-developer
 
Supervised by **Ms. Nabeela Yaqoob**
University of South Asia, Department of Computer Science, FYP 2022–2026
 
---
 
## ⚠️ Note on API keys
 
Never commit API keys. Keep `.env`, `credentials.json` and `token.json` out of version control (§8, item 8), and create your own `.env` from the variable list in §7.
 
