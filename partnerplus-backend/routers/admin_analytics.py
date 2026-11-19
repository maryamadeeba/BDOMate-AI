# ============================================================
# FILE: backend/routers/admin_analytics.py
# ============================================================

from fastapi import APIRouter, Depends, HTTPException, Query, status
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from sqlalchemy.orm import Session
from sqlalchemy import func, and_, cast, Date
from datetime import datetime, date, timedelta
from typing import Optional
from jose import JWTError, jwt
import os

# ── Router ───────────────────────────────────────────────────
router = APIRouter()
security = HTTPBearer()

# ── JWT Config ───────────────────────────────────────────────
# TODO: Move these to environment variables / .env file
SECRET_KEY = os.getenv("SECRET_KEY", "your-super-secret-key-change-this")
ALGORITHM = "HS256"

# ── DB Dependency ─────────────────────────────────────────────
# Replace with your actual DB session dependency
def get_db():
    """
    Replace this with your actual SQLAlchemy session.
    Example with SQLAlchemy:
        from database import SessionLocal
        db = SessionLocal()
        try:
            yield db
        finally:
            db.close()
    """
    raise NotImplementedError("Replace get_db() with your actual DB session")

# ── Auth Dependency ───────────────────────────────────────────
async def require_admin(
    credentials: HTTPAuthorizationCredentials = Depends(security),
    db: Session = Depends(get_db),
):
    """
    Validates JWT token and ensures the user has Admin role.
    Only admins can access these endpoints.
    """
    token = credentials.credentials
    credentials_exception = HTTPException(
        status_code=status.HTTP_403_FORBIDDEN,
        detail="Access denied. Admin privileges required.",
        headers={"WWW-Authenticate": "Bearer"},
    )
    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        user_id: str = payload.get("sub")
        user_role: str = payload.get("role", "")
        if user_id is None:
            raise credentials_exception
        # ── Role check ─────────────────────────────────────────
        # Allowed admin roles – update to match your role system
        allowed_roles = {"Admin", "SuperAdmin", "BDO Manager"}
        if user_role not in allowed_roles:
            raise credentials_exception
        return {"user_id": user_id, "role": user_role}
    except JWTError:
        raise credentials_exception


# ── Helper: Date Range Clamp ─────────────────────────────────
def _parse_dates(start_date: str, end_date: str):
    """Parse ISO date strings, defaulting to last 30 days on error."""
    try:
        start = datetime.fromisoformat(start_date).replace(tzinfo=None)
        end = datetime.fromisoformat(end_date).replace(tzinfo=None)
    except Exception:
        end = datetime.utcnow()
        start = end - timedelta(days=30)
    # Safety clamp – no future end dates
    if end > datetime.utcnow():
        end = datetime.utcnow()
    return start, end


# ── Helper: Time-Series Labels ────────────────────────────────
def _build_series_labels(start: datetime, end: datetime, mode: str):
    """
    Returns a list of (label_str, period_start, period_end) tuples
    for grouping time-series data.
    """
    labels = []
    delta = (end - start).days + 1
    if mode == "weekly" or delta <= 14:
        current = start.date()
        while current <= end.date():
            labels.append((
                current.strftime("%a"),
                datetime.combine(current, datetime.min.time()),
                datetime.combine(current, datetime.max.time()),
            ))
            current += timedelta(days=1)
    elif mode == "monthly" or delta <= 92:
        # Group by week
        week_start = start.date()
        i = 1
        while week_start <= end.date():
            week_end = min(week_start + timedelta(days=6), end.date())
            labels.append((
                f"W{i}",
                datetime.combine(week_start, datetime.min.time()),
                datetime.combine(week_end, datetime.max.time()),
            ))
            week_start = week_end + timedelta(days=1)
            i += 1
    else:
        # Group by month
        from dateutil.relativedelta import relativedelta
        cur = start.replace(day=1, hour=0, minute=0, second=0)
        months = ["Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec"]
        while cur <= end:
            m_end = cur + relativedelta(months=1) - timedelta(seconds=1)
            labels.append((months[cur.month - 1], cur, min(m_end, end)))
            cur += relativedelta(months=1)
    return labels


# ════════════════════════════════════════════════════════════
# MAIN ANALYTICS ENDPOINT
# GET /api/admin/analytics
# ════════════════════════════════════════════════════════════
@router.get("/analytics")
async def get_admin_analytics(
    start_date: str = Query(..., description="ISO 8601 start datetime"),
    end_date: str   = Query(..., description="ISO 8601 end datetime"),
    mode: str       = Query("monthly", description="weekly | monthly | yearly | custom"),
    admin: dict     = Depends(require_admin),
    db: Session     = Depends(get_db),
):
    """
    Master admin analytics endpoint.
    Returns all aggregated KPIs and time-series data for the dashboard.

    Replace the placeholder queries below with your actual ORM models.
    Each section is clearly labeled with TODO comments.
    """
    start, end = _parse_dates(start_date, end_date)
    series_labels = _build_series_labels(start, end, mode)

    # ════════════════════════════════════════════════════════
    # SECTION 1: SUMMARY KPIs
    # ════════════════════════════════════════════════════════
    # TODO: Import your ORM models at the top of this file:
    # from models import Partner, Email, Call, MOU, Event, Campaign, User, AILog
    #
    # Then replace each placeholder below with real DB queries.

    # ── Partners ─────────────────────────────────────────────
    # total_partners = db.query(func.count(Partner.id)).scalar()
    # new_partners = db.query(func.count(Partner.id)).filter(
    #     Partner.created_at.between(start, end)
    # ).scalar()
    # active_partners = db.query(func.count(Partner.id)).filter(
    #     Partner.status == 'active'
    # ).scalar()

    # ── Emails ───────────────────────────────────────────────
    # total_emails = db.query(func.count(Email.id)).filter(
    #     Email.sent_at.between(start, end),
    #     Email.status == 'sent'
    # ).scalar()
    # ai_emails = db.query(func.count(Email.id)).filter(
    #     Email.sent_at.between(start, end),
    #     Email.is_ai_generated == True
    # ).scalar()

    # ── Calls ────────────────────────────────────────────────
    # total_calls = db.query(func.count(Call.id)).filter(
    #     Call.call_time.between(start, end)
    # ).scalar()
    # avg_duration = db.query(func.avg(Call.duration_seconds)).filter(
    #     Call.call_time.between(start, end)
    # ).scalar() or 0

    # ── MOUs ─────────────────────────────────────────────────
    # total_mous = db.query(func.count(MOU.id)).scalar()
    # mous_signed = db.query(func.count(MOU.id)).filter(
    #     MOU.status == 'signed', MOU.signed_at.between(start, end)
    # ).scalar()
    # active_mous = db.query(func.count(MOU.id)).filter(MOU.status == 'active').scalar()
    # expiring = db.query(func.count(MOU.id)).filter(
    #     MOU.status == 'active',
    #     MOU.expiry_date.between(datetime.utcnow(), datetime.utcnow() + timedelta(days=30))
    # ).scalar()

    # ── Campaigns ────────────────────────────────────────────
    # campaign_reach = db.query(func.sum(Campaign.total_reach)).filter(
    #     Campaign.created_at.between(start, end)
    # ).scalar() or 0
    # avg_open_rate = db.query(func.avg(
    #     cast(Campaign.opened, Float) / func.nullif(Campaign.total_reach, 0) * 100
    # )).filter(Campaign.created_at.between(start, end)).scalar() or 0

    # ── AI Usage ─────────────────────────────────────────────
    # ai_total = db.query(func.count(AILog.id)).filter(
    #     AILog.created_at.between(start, end)
    # ).scalar()

    # ── Events ───────────────────────────────────────────────
    # total_events = db.query(func.count(Event.id)).filter(
    #     Event.start_date.between(start, end)
    # ).scalar()

    # ── Avg Engagement Score ─────────────────────────────────
    # avg_engagement = db.query(func.avg(Partner.engagement_score)).scalar() or 0

    # ── BDO Count ────────────────────────────────────────────
    # total_bdos = db.query(func.count(User.id)).filter(User.role.in_(['BDO', 'BDO Manager'])).scalar()

    # PLACEHOLDER VALUES (remove when real DB is connected):
    summary = {
        "total_partners": 42,
        "new_partners": 7,
        "active_partners": 36,
        "total_emails": 187,
        "ai_emails": 124,
        "total_calls": 67,
        "call_duration_avg": 8.4,
        "total_mous": 12,
        "mous_signed": 8,
        "active_mous": 6,
        "expiring_soon": 2,
        "total_events": 6,
        "campaign_reach": 4850,
        "campaign_open_rate": 67.4,
        "ai_actions_total": 381,
        "avg_engagement_score": 74.2,
        "total_bdos": 5,
    }

    # ════════════════════════════════════════════════════════
    # SECTION 2: TIME-SERIES DATA
    # ════════════════════════════════════════════════════════

    partner_growth = []
    email_stats = []
    call_stats = []
    ai_usage_stats = []
    campaign_stats = []
    event_stats = []

    for label, p_start, p_end in series_labels:
        # ── Partner Growth ────────────────────────────────────
        # new_in_period = db.query(func.count(Partner.id)).filter(
        #     Partner.created_at.between(p_start, p_end)
        # ).scalar()
        # cumulative = db.query(func.count(Partner.id)).filter(
        #     Partner.created_at <= p_end
        # ).scalar()
        partner_growth.append({
            "label": label,
            "new": 2,           # replace: new_in_period
            "total": 14,        # replace: cumulative
        })

        # ── Email Stats ───────────────────────────────────────
        # sent = db.query(func.count(Email.id)).filter(
        #     Email.sent_at.between(p_start, p_end),
        #     Email.status == 'sent'
        # ).scalar()
        # ai_gen = db.query(func.count(Email.id)).filter(
        #     Email.sent_at.between(p_start, p_end),
        #     Email.is_ai_generated == True
        # ).scalar()
        # opened = db.query(func.count(Email.id)).filter(
        #     Email.sent_at.between(p_start, p_end),
        #     Email.is_read == True
        # ).scalar()
        email_stats.append({
            "label": label,
            "sent": 8,          # replace: sent
            "ai_generated": 5,  # replace: ai_gen
            "opened": 6,        # replace: opened
        })

        # ── Call Stats ────────────────────────────────────────
        # total_c = db.query(func.count(Call.id)).filter(
        #     Call.call_time.between(p_start, p_end)
        # ).scalar()
        # missed_c = db.query(func.count(Call.id)).filter(
        #     Call.call_time.between(p_start, p_end),
        #     Call.status == 'missed'
        # ).scalar()
        # avg_dur = db.query(func.avg(Call.duration_seconds / 60)).filter(
        #     Call.call_time.between(p_start, p_end)
        # ).scalar() or 0
        call_stats.append({
            "label": label,
            "total": 4,         # replace: total_c
            "missed": 1,        # replace: missed_c
            "avg_duration": 8.4, # replace: float(avg_dur)
        })

        # ── AI Usage ─────────────────────────────────────────
        # email_ai = db.query(func.count(AILog.id)).filter(
        #     AILog.created_at.between(p_start, p_end),
        #     AILog.action_type == 'email'
        # ).scalar()
        # mou_ai = ...  (same pattern for mou, summary, campaign)
        ai_usage_stats.append({
            "label": label,
            "emails": 5,        # replace: email_ai
            "mous": 1,          # replace: mou_ai
            "summaries": 2,     # replace: summary_ai
            "campaigns": 1,     # replace: campaign_ai
        })

        # ── Campaign Stats ────────────────────────────────────
        # reach = db.query(func.sum(Campaign.total_reach)).filter(
        #     Campaign.created_at.between(p_start, p_end)
        # ).scalar() or 0
        campaign_stats.append({
            "label": label,
            "reach": 820,           # replace: reach
            "open_rate": 67.4,      # replace: computed avg
            "click_rate": 44.2,     # replace: computed avg
        })

        # ── Event Stats ───────────────────────────────────────
        # ev_count = db.query(func.count(Event.id)).filter(
        #     Event.start_date.between(p_start, p_end)
        # ).scalar()
        # attendees = db.query(func.sum(Event.actual_attendees)).filter(
        #     Event.start_date.between(p_start, p_end)
        # ).scalar() or 0
        event_stats.append({
            "label": label,
            "events": 1,        # replace: ev_count
            "attendees": 80,    # replace: attendees
        })

    # ════════════════════════════════════════════════════════
    # SECTION 3: MOU STATUS BREAKDOWN (pie chart)
    # ════════════════════════════════════════════════════════
    # mou_status_rows = db.query(MOU.status, func.count(MOU.id)).group_by(MOU.status).all()
    # mou_stats = [{"status": row[0].capitalize(), "count": row[1], "color": _mou_color(row[0])}
    #              for row in mou_status_rows]
    mou_stats = [
        {"status": "Active",  "count": 6, "color": 0xFF2DC653},
        {"status": "Draft",   "count": 3, "color": 0xFF2E86AB},
        {"status": "Pending", "count": 2, "color": 0xFFF4A261},
        {"status": "Expired", "count": 1, "color": 0xFFE63946},
    ]

    # ════════════════════════════════════════════════════════
    # SECTION 4: TOP BDOs LEADERBOARD
    # ════════════════════════════════════════════════════════
    # bdo_rows = db.query(
    #     User.id, User.name, User.role,
    #     func.count(Email.id).label('emails'),
    #     func.count(Call.id).label('calls'),
    #     func.count(Partner.id).label('partners'),
    #     func.avg(Partner.engagement_score).label('avg_score'),
    # ).outerjoin(Email, Email.created_by == User.id
    # ).outerjoin(Call, Call.created_by == User.id
    # ).outerjoin(Partner, Partner.created_by == User.id
    # ).filter(User.role.in_(['BDO', 'BDO Manager'])
    # ).group_by(User.id
    # ).order_by(func.count(Partner.id).desc()
    # ).limit(10).all()
    #
    # top_bdos = [{
    #     "name": r.name, "role": r.role,
    #     "emails": r.emails, "calls": r.calls,
    #     "partners": r.partners,
    #     "score": float(r.avg_score or 0)
    # } for r in bdo_rows]

    top_bdos = [
        {"name": "Maryam Adeeba", "role": "BDO Manager", "emails": 48, "calls": 22, "partners": 14, "score": 94.0},
        {"name": "Hassan Malik",  "role": "BDO",         "emails": 31, "calls": 17, "partners": 9,  "score": 81.0},
        {"name": "Sana Tariq",    "role": "BDO",         "emails": 27, "calls": 12, "partners": 8,  "score": 73.0},
        {"name": "Usman Ghani",   "role": "BDO",         "emails": 19, "calls": 8,  "partners": 6,  "score": 62.0},
        {"name": "Nida Farooq",   "role": "BDO",         "emails": 14, "calls": 6,  "partners": 5,  "score": 54.0},
    ]

    # ── Final Response ────────────────────────────────────────
    return {
        "summary":        summary,
        "partner_growth": partner_growth,
        "email_stats":    email_stats,
        "call_stats":     call_stats,
        "mou_stats":      mou_stats,
        "campaign_stats": campaign_stats,
        "event_stats":    event_stats,
        "ai_usage_stats": ai_usage_stats,
        "top_bdos":       top_bdos,
        "fetched_at":     datetime.utcnow().isoformat(),
        "period": {
            "start": start.isoformat(),
            "end":   end.isoformat(),
            "mode":  mode,
        },
    }


# ════════════════════════════════════════════════════════════
# BONUS ENDPOINT: Export CSV
# GET /api/admin/analytics/export
# ════════════════════════════════════════════════════════════
@router.get("/analytics/export")
async def export_analytics_csv(
    start_date: str = Query(...),
    end_date:   str = Query(...),
    admin: dict     = Depends(require_admin),
    db: Session     = Depends(get_db),
):
    """
    Returns a CSV download of the analytics summary.
    The Flutter app can open this via url_launcher.
    """
    import csv
    import io
    from fastapi.responses import StreamingResponse

    start, end = _parse_dates(start_date, end_date)

    output = io.StringIO()
    writer = csv.writer(output)
    writer.writerow(["Metric", "Value", "Period"])
    # TODO: Replace hardcoded values with real DB queries (same as above)
    rows = [
        ["Total Partners",    42,    f"{start.date()} – {end.date()}"],
        ["New Partners",       7,    f"{start.date()} – {end.date()}"],
        ["Emails Sent",       187,   f"{start.date()} – {end.date()}"],
        ["AI Emails",         124,   f"{start.date()} – {end.date()}"],
        ["Total Calls",        67,   f"{start.date()} – {end.date()}"],
        ["Active MOUs",         6,   f"{start.date()} – {end.date()}"],
        ["Campaign Reach",   4850,   f"{start.date()} – {end.date()}"],
        ["AI Actions",        381,   f"{start.date()} – {end.date()}"],
    ]
    writer.writerows(rows)
    output.seek(0)

    return StreamingResponse(
        iter([output.getvalue()]),
        media_type="text/csv",
        headers={"Content-Disposition": f"attachment; filename=analytics_{start.date()}_{end.date()}.csv"},
    )
