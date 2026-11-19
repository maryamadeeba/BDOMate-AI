import os
from routers.admin_analytics import router as admin_router

# Fix Railway's postgres:// to postgresql:// for SQLAlchemy
db_url = os.getenv("DATABASE_URL", "")
if db_url.startswith("postgres://"):
    os.environ["DATABASE_URL"] = db_url.replace("postgres://", "postgresql://", 1)

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from database.db import create_tables
from routers.auth import router as auth_router
from routers.mou import router as mou_router
from routers.other_routers import (
    email_router,
    events_router as other_events_router,
    partners_router,
    ai_router,
)
from routers.sponsors  import router as sponsor_router
from routers.retrain   import router as retrain_router
from routers.calls     import router as calls_router
from routers.events    import router as events_router          # ML predict/recommend
# ✅ NEW — email inbox + notification routers (in routers/ folder, not routes/)
from routers.email_replies  import router as email_replies_router
from routers.notifications  import router as notifications_router
from services.notification_service import (
    start_scheduler, stop_scheduler, schedule_weekly_partner_check
)

app = FastAPI(
    title       = "BDOMate.AI API",
    description = "AI-Powered University Business Development System — University of South Asia",
    version     = "3.1.0",
    redirect_slashes = True,
)

app.add_middleware(
    CORSMiddleware,
    allow_origins     = ["*"],
    allow_credentials = True,
    allow_methods     = ["*"],
    allow_headers     = ["*"],
)

# ── Routers ───────────────────────────────────────────────────────────────────
app.include_router(auth_router,           prefix="/auth",          tags=["Authentication"])
app.include_router(mou_router,            prefix="/mou",           tags=["MOU Generator"])
app.include_router(email_router,          prefix="/email",         tags=["Email Generator"])
app.include_router(events_router,         prefix="/events",        tags=["Attendance Prediction"])
app.include_router(other_events_router,   prefix="/events",        tags=["Events & AI Scheduler"])
app.include_router(partners_router,       prefix="/partners",      tags=["Partner CRM"])
app.include_router(ai_router,             prefix="/ai",            tags=["AI Chat & Marketing"])
app.include_router(sponsor_router,        prefix="/sponsors",      tags=["Sponsor Segmentation"])
app.include_router(retrain_router,        prefix="/retrain",       tags=["Model Retraining"])
app.include_router(calls_router,          prefix="/calls",         tags=["Automated Calling"])
# ✅ NEW — replaces old notifications router; handles process-bdo-email + unread-count
app.include_router(notifications_router,  prefix="/notifications", tags=["Smart Notifications"])
# ✅ NEW — inbox endpoints: GET/PATCH/DELETE /emails/replies
app.include_router(email_replies_router,  prefix="/emails",        tags=["Email Inbox"])
app.include_router(admin_router,          prefix="/api/admin",     tags=["Admin Analytics"])


@app.on_event("startup")
def startup():
    create_tables()
    start_scheduler()
    schedule_weekly_partner_check()
    print("\n🚀 BDOMate.AI v3.1 is running!")
    print("🔐 Auth: POST /auth/signup  POST /auth/login  POST /auth/forgot-password")
    print("📊 Model 1: Attendance Predictor — 90% accuracy")
    print("📊 Model 2: Sponsor Segmentation — 6 tiers")
    print("📞 Calling: Twilio IVR — DEMO_MODE active")
    print("🔔 Notifications: Scheduler active (Asia/Karachi)")
    print("📥 Email Inbox: GET /emails/replies\n")


@app.on_event("shutdown")
def shutdown():
    stop_scheduler()


@app.get("/", tags=["Health"])
def home():
    return {
        "app":     "BDOMate.AI",
        "version": "3.1.0",
        "status":  "running",
        "auth_endpoints": {
            "Signup": "POST /auth/signup",
            "Login":  "POST /auth/login",
        },
    }


# ── Direct Gmail route ────────────────────────────────────────────────────────
from pydantic import BaseModel
from typing import Optional

class DirectGmailPayload(BaseModel):
    sender_email: str
    sender_name:  Optional[str] = ""
    subject:      str
    body:         str

@app.post("/direct-bdo-email/")
async def direct_bdo_email(payload: DirectGmailPayload):
    from services.notification_service import create_notification
    from services.email_sender import send_email_background

    print(f"[Direct Route] 📥 Request Received from {payload.sender_email}")

    bdo_keywords = [
        "mou", "partnership", "collaboration", "meeting", "proposal",
        "sponsor", "event", "industrial visit", "placement",
    ]
    content = f"{payload.subject} {payload.body}".lower()

    if not any(k in content for k in bdo_keywords):
        return {"status": "ignored"}

    create_notification(
        title=f"📧 New BDO Lead: {payload.subject}",
        message=f"From: {payload.sender_name} ({payload.sender_email})",
        notify_type="partner_alert",
        related_id=None,
        scheduled_at=None,
    )

    send_email_background(
        to_email=payload.sender_email,
        to_name=payload.sender_name or payload.sender_email,
        subject=f"Re: {payload.subject} — Business Development Office",
        body=(
            f"Hello,\n\nWe have received your email regarding '{payload.subject}' "
            f"and logged it into BDOMate.AI.\n\n"
            f"Best Regards,\nBusiness Development Team"
        ),
    )
    return {"status": "processed"}
