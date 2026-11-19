from fastapi import APIRouter, Depends, HTTPException, BackgroundTasks
from sqlalchemy.orm import Session
from pydantic import BaseModel
from typing import Optional, List
from datetime import datetime
from database.db import get_db
from database.models import Partner, Event, Email
from services.ai_service import generate_email, chat_with_assistant, generate_marketing_content
from services.prediction_service import predict_attendance
from services.email_sender import send_email_background


# ── Email Router ──────────────────────────────────────────────────────────────
email_router = APIRouter()


class EmailRequest(BaseModel):
    recipient_name: str
    recipient_org:  str
    email_purpose:  str
    context:        Optional[str] = ""


class EmailSaveRequest(BaseModel):
    recipient_name:  str
    recipient_org:   Optional[str] = ""
    recipient_email: Optional[str] = ""
    subject:         str
    body:            str
    email_purpose:   Optional[str] = "general"
    status:          Optional[str] = "draft"
    partner_id:      Optional[int] = None


@email_router.post("/generate")
def create_email(req: EmailRequest):
    try:
        result = generate_email(
            req.recipient_name, req.recipient_org,
            req.email_purpose, req.context
        )
        return {"success": True, **result}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@email_router.post("/save")
def save_email(req: EmailSaveRequest, background_tasks: BackgroundTasks, db: Session = Depends(get_db)):
    try:
        email = Email(
            recipient_name=req.recipient_name,
            recipient_org=req.recipient_org or "",
            recipient_email=req.recipient_email or "",
            subject=req.subject,
            body=req.body,
            email_purpose=req.email_purpose or "general",
            status=req.status or "draft",
            partner_id=req.partner_id,
            is_ai_generated=True,
            sent_at=datetime.utcnow() if req.status == "sent" else None,
        )
        db.add(email)
        db.commit()
        db.refresh(email)
        if req.status == "sent" and req.recipient_email:
            background_tasks.add_task(
                send_email_background,
                to_email=req.recipient_email,
                to_name=req.recipient_name,
                subject=req.subject,
                body=req.body,
            )
        return {"success": True, "email_id": email.id}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@email_router.get("/all")
def get_all_emails(db: Session = Depends(get_db)):
    emails = db.query(Email).order_by(Email.created_at.desc()).all()
    return {
        "total": len(emails),
        "emails": [
            {
                "id":              e.id,
                "recipient_name":  e.recipient_name,
                "recipient_email": e.recipient_email,
                "subject":         e.subject,
                "body":            e.body,
                "email_purpose":   e.email_purpose,
                "status":          e.status,
                "is_ai_generated": e.is_ai_generated,
                "sent_at":         str(e.sent_at) if e.sent_at else None,
                "created_at":      str(e.created_at),
            }
            for e in emails
        ],
    }


@email_router.get("/{email_id}")
def get_email(email_id: int, db: Session = Depends(get_db)):
    e = db.query(Email).filter(Email.id == email_id).first()
    if not e:
        raise HTTPException(status_code=404, detail="Email not found")
    return {
        "id":              e.id,
        "recipient_name":  e.recipient_name,
        "recipient_email": e.recipient_email,
        "subject":         e.subject,
        "body":            e.body,
        "email_purpose":   e.email_purpose,
        "status":          e.status,
        "is_ai_generated": e.is_ai_generated,
        "sent_at":         str(e.sent_at) if e.sent_at else None,
        "created_at":      str(e.created_at),
    }


# ── Events Router ─────────────────────────────────────────────────────────────
events_router = APIRouter()


class EventCreateRequest(BaseModel):
    title:               str
    description:         Optional[str] = ""
    event_type:          Optional[str] = "seminar"
    status:              Optional[str] = "upcoming"
    start_date:          Optional[str] = None
    end_date:            Optional[str] = None
    venue:               Optional[str] = "TBD"
    expected_attendees:  Optional[int] = 0
    organizer:           Optional[str] = "BDO"
    is_virtual:          Optional[bool] = False
    meeting_link:        Optional[str] = None


class EventUpdateRequest(BaseModel):
    title:               Optional[str] = None
    description:         Optional[str] = None
    event_type:          Optional[str] = None
    status:              Optional[str] = None
    start_date:          Optional[str] = None
    end_date:            Optional[str] = None
    venue:               Optional[str] = None
    expected_attendees:  Optional[int] = None
    organizer:           Optional[str] = None
    is_virtual:          Optional[bool] = None
    meeting_link:        Optional[str] = None


class EventPredictRequest(BaseModel):
    title:               str
    event_type:          str
    department:          str
    day_of_week:         str
    time_slot:           str
    season:              str
    capacity:            int
    is_free:             bool = True
    has_food:            bool = False
    industry_guests:     bool = False
    weeks_promoted:      int  = 1
    past_avg_attendance: int  = 60


# ── GET /events/all ───────────────────────────────────────────────────────────
@events_router.get("/all")
def get_all_events(db: Session = Depends(get_db)):
    """Return all events with ALL fields so Flutter can display them correctly."""
    events = db.query(Event).order_by(Event.created_at.desc()).all()
    return {
        "total": len(events),
        "events": [
            {
                "id":                 e.id,
                "title":              e.title,
                "description":        getattr(e, "description", "") or "",
                "event_type":         getattr(e, "event_type", "seminar") or "seminar",
                "status":             getattr(e, "status", "upcoming") or "upcoming",
                # ✅ return actual start/end dates
                "start_date":         e.start_date.isoformat()
                                      if getattr(e, "start_date", None) else None,
                "end_date":           e.end_date.isoformat()
                                      if getattr(e, "end_date", None) else None,
                # ✅ return actual venue — not hardcoded TBD
                "venue":              getattr(e, "venue", "TBD") or "TBD",
                # ✅ return actual expected_attendees — not hardcoded 100
                "expected_attendees": getattr(e, "expected_attendees", 0) or 0,
                "organizer":          getattr(e, "organizer", "BDO") or "BDO",
                "is_virtual":         bool(getattr(e, "is_virtual", False)),
                "meeting_link":       getattr(e, "meeting_link", None),
                "prediction":         getattr(e, "predicted_attendance", None),
                "confidence":         getattr(e, "prediction_confidence", None),
                "created_at":         e.created_at.isoformat()
                                      if getattr(e, "created_at", None) else None,
            }
            for e in events
        ],
    }


# ── POST /events/create ───────────────────────────────────────────────────────
@events_router.post("/create")
def create_event(req: EventCreateRequest, db: Session = Depends(get_db)):
    """Save a new event with all fields. Returns 409 on venue/time clash."""

    start_dt = None
    end_dt   = None
    if req.start_date:
        try:
            start_dt = datetime.fromisoformat(req.start_date)
        except ValueError:
            pass
    if req.end_date:
        try:
            end_dt = datetime.fromisoformat(req.end_date)
        except ValueError:
            pass

    # ── Clash detection ───────────────────────────────────────────────────────
    if start_dt and end_dt and req.venue and req.venue.strip().lower() != "tbd":
        clash = (
            db.query(Event)
            .filter(
                Event.venue == req.venue,
                Event.status != "completed",
                Event.start_date < end_dt,
                Event.end_date   > start_dt,
            )
            .first()
        )
        if clash:
            raise HTTPException(
                status_code=409,
                detail={
                    "error":              "clash",
                    "message":            f"'{req.venue}' is already booked by "
                                          f"'{clash.title}' during this time.",
                    "clashing_event_id":  clash.id,
                    "clashing_event_title": clash.title,
                },
            )

    # ── Save to DB ────────────────────────────────────────────────────────────
    event = Event(
        title               = req.title,
        description         = req.description,
        event_type          = req.event_type,
        status              = req.status,
        start_date          = start_dt,
        end_date            = end_dt,
        venue               = req.venue,
        expected_attendees  = req.expected_attendees,
        organizer           = req.organizer,
        is_virtual          = req.is_virtual,
        meeting_link        = req.meeting_link,
        # ML fields default to None until /predict is called
        department          = "General",
        day_of_week         = start_dt.strftime("%A") if start_dt else None,
        time_slot           = _hour_to_slot(start_dt.hour) if start_dt else None,
        season              = _month_to_season(start_dt.month) if start_dt else None,
        capacity            = req.expected_attendees,
        is_free             = req.is_virtual,
        has_food            = not req.is_virtual,
        industry_guests     = False,
        weeks_promoted      = 2,
        past_avg_attendance = int((req.expected_attendees or 0) * 0.6),
    )
    db.add(event)
    db.commit()
    db.refresh(event)
    return {"id": event.id, "status": "created"}


# ── PUT /events/{event_id} ────────────────────────────────────────────────────
@events_router.put("/{event_id}")
def update_event(event_id: int, req: EventUpdateRequest, db: Session = Depends(get_db)):
    """Update only the provided fields on an existing event."""
    event = db.query(Event).filter(Event.id == event_id).first()
    if not event:
        raise HTTPException(status_code=404, detail="Event not found")

    if req.title               is not None: event.title               = req.title
    if req.description         is not None: event.description         = req.description
    if req.event_type          is not None: event.event_type          = req.event_type
    if req.status              is not None: event.status              = req.status
    if req.venue               is not None: event.venue               = req.venue
    if req.expected_attendees  is not None: event.expected_attendees  = req.expected_attendees
    if req.organizer           is not None: event.organizer           = req.organizer
    if req.is_virtual          is not None: event.is_virtual          = req.is_virtual
    if req.meeting_link        is not None: event.meeting_link        = req.meeting_link
    if req.start_date          is not None:
        try:
            event.start_date = datetime.fromisoformat(req.start_date)
        except ValueError:
            pass
    if req.end_date            is not None:
        try:
            event.end_date = datetime.fromisoformat(req.end_date)
        except ValueError:
            pass

    db.commit()
    return {"status": "updated"}


# ── DELETE /events/{event_id} ─────────────────────────────────────────────────
@events_router.delete("/{event_id}")
def delete_event(event_id: int, db: Session = Depends(get_db)):
    event = db.query(Event).filter(Event.id == event_id).first()
    if not event:
        raise HTTPException(status_code=404, detail="Event not found")
    db.delete(event)
    db.commit()
    return {"status": "deleted"}


# ── POST /events/predict ──────────────────────────────────────────────────────
@events_router.post("/predict")
def predict_event(req: EventPredictRequest, db: Session = Depends(get_db)):
    try:
        result = predict_attendance(
            req.event_type, req.department, req.day_of_week,
            req.time_slot, req.season, req.capacity,
            req.is_free, req.has_food, req.industry_guests,
            req.weeks_promoted, req.past_avg_attendance,
        )
        # Update prediction on existing event if title matches, else create record
        existing = db.query(Event).filter(Event.title == req.title).first()
        if existing:
            existing.predicted_attendance  = result["prediction"]
            existing.prediction_confidence = result["confidence"]
            db.commit()
        return {"success": True, "event": req.title, **result}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


# ── Helpers ───────────────────────────────────────────────────────────────────
def _hour_to_slot(hour: int) -> str:
    if hour < 12:  return "morning"
    if hour < 17:  return "afternoon"
    return "evening"

def _month_to_season(month: int) -> str:
    if 3  <= month <= 5:  return "spring"
    if 6  <= month <= 8:  return "summer"
    if 9  <= month <= 11: return "fall"
    return "winter"


# ── Partners Router ───────────────────────────────────────────────────────────
partners_router = APIRouter()


class PartnerCreate(BaseModel):
    name:           str
    type:           str
    contact_person: Optional[str] = ""
    email:          Optional[str] = ""
    phone:          Optional[str] = ""
    address:        Optional[str] = ""


@partners_router.post("/add")
def add_partner(req: PartnerCreate, db: Session = Depends(get_db)):
    existing = db.query(Partner).filter(Partner.name == req.name).first()
    if existing:
        raise HTTPException(status_code=400, detail="Partner already exists")
    p = Partner(**req.dict())
    db.add(p)
    db.commit()
    db.refresh(p)
    return {"success": True, "partner_id": p.id, "name": p.name}


@partners_router.get("/all")
def get_all_partners(db: Session = Depends(get_db)):
    partners = db.query(Partner).order_by(Partner.created_at.desc()).all()
    return {
        "total": len(partners),
        "partners": [
            {
                "id":     p.id,
                "name":   p.name,
                "type":   p.type,
                "email":  p.email,
                "phone":  p.phone,
                "status": p.status,
            }
            for p in partners
        ],
    }


@partners_router.get("/{partner_id}")
def get_partner(partner_id: int, db: Session = Depends(get_db)):
    p = db.query(Partner).filter(Partner.id == partner_id).first()
    if not p:
        raise HTTPException(status_code=404, detail="Not found")
    return p


@partners_router.delete("/{partner_id}")
def delete_partner(partner_id: int, db: Session = Depends(get_db)):
    p = db.query(Partner).filter(Partner.id == partner_id).first()
    if not p:
        raise HTTPException(status_code=404, detail="Not found")
    db.delete(p)
    db.commit()
    return {"success": True}


# ── AI Router ─────────────────────────────────────────────────────────────────
ai_router = APIRouter()


class ChatMessage(BaseModel):
    role:    str
    content: str


class ChatRequest(BaseModel):
    message: str
    history: Optional[List[ChatMessage]] = []


@ai_router.post("/chat")
def ask_assistant(req: ChatRequest):
    try:
        history = [{"role": m.role, "content": m.content} for m in req.history]
        reply = chat_with_assistant(req.message, history)
        return {"success": True, "reply": reply}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


class MarketingRequest(BaseModel):
    event_name: str
    event_type: str
    event_date: str
    platform:   str


@ai_router.post("/marketing")
def create_marketing(req: MarketingRequest):
    try:
        content = generate_marketing_content(
            req.event_name, req.event_type, req.event_date, req.platform
        )
        return {"success": True, "platform": req.platform, "content": content}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))