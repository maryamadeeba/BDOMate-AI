
from fastapi import APIRouter, HTTPException, Depends
from fastapi.responses import JSONResponse
from pydantic import BaseModel
from typing import Optional, List
from datetime import datetime, timedelta
from sqlalchemy.orm import Session
from database.db import get_db
from database.models import Event          # your ORM model

router = APIRouter()


# ── Pydantic schemas ──────────────────────────────────────────────────────────

class EventCreateRequest(BaseModel):
    title:               str
    description:         Optional[str]  = ""
    type:                Optional[str]  = "seminar"
    status:              Optional[str]  = "upcoming"
    start_date:          Optional[str]  = None   # ISO 8601
    end_date:            Optional[str]  = None   # ISO 8601
    venue:               Optional[str]  = "TBD"
    expected_attendees:  Optional[int]  = 0
    organizer:           Optional[str]  = "BDO"
    is_virtual:          Optional[bool] = False
    meeting_link:        Optional[str]  = None


class EventRecommendPayload(BaseModel):
    event_type:          str   = "seminar"
    expected_attendees:  int   = 100
    is_virtual:          bool  = False
    reference_date:      Optional[str] = None


# ── POST /events — save a new event ──────────────────────────────────────────

@router.post("")
@router.post("/")
def create_event(req: EventCreateRequest, db: Session = Depends(get_db)):
    """
    Called by Flutter's persistEventToBackend() after the user saves a new event.
    Stores ALL fields so GET /events can return them intact on the next app launch.
    """
    try:
        start_dt = datetime.fromisoformat(req.start_date) if req.start_date else datetime.now()
        end_dt   = datetime.fromisoformat(req.end_date)   if req.end_date   else start_dt + timedelta(hours=2)
    except (ValueError, TypeError):
        start_dt = datetime.now()
        end_dt   = start_dt + timedelta(hours=2)

    event = Event(
        title               = req.title,
        description         = req.description or "",
        type                = req.type or "seminar",
        status              = req.status or "upcoming",
        start_date          = start_dt,
        end_date            = end_dt,
        venue               = req.venue or "TBD",
        expected_attendees  = req.expected_attendees or 0,
        organizer           = req.organizer or "BDO",
        is_virtual          = req.is_virtual or False,
        meeting_link        = req.meeting_link,
    )
    db.add(event)
    db.commit()
    db.refresh(event)

    return {
        "success": True,
        "id":      event.id,
        "message": "Event created.",
    }


# ── GET /events — return all events with full fields ─────────────────────────

@router.get("")
@router.get("/")
def list_events(limit: int = 50, db: Session = Depends(get_db)):
    """
    Returns all events from the database.
    Every field is included so Flutter can rebuild the EventModel exactly.

    FIX: Previously this endpoint returned `created_at` as the date and
    hardcoded venue/description — causing every event to look identical
    after sign-out.  Now it returns start_date, end_date, and all columns.
    """
    try:
        events = db.query(Event).order_by(Event.start_date.desc()).limit(limit).all()
        return {
            "success": True,
            "total":   len(events),
            "events": [
                {
                    "id":                  str(e.id),
                    "title":               e.title,
                    "description":         e.description or "",
                    "type":                e.type or "seminar",
                    "status":              e.status or "upcoming",
                    # ← KEY FIX: use start_date / end_date, NOT created_at
                    "start_date":          e.start_date.isoformat() if e.start_date else None,
                    "end_date":            e.end_date.isoformat()   if e.end_date   else None,
                    "venue":               e.venue or "TBD",
                    "expected_attendees":  e.expected_attendees or 0,
                    "organizer":           e.organizer or "BDO",
                    "is_virtual":          e.is_virtual or False,
                    "meeting_link":        e.meeting_link,
                    "prediction":          e.predicted_attendees if hasattr(e, 'predicted_attendees') else None,
                    # Keep created_at for audit purposes only — NOT used as start date
                    "created_at":          e.created_at.isoformat() if e.created_at else None,
                }
                for e in events
            ],
        }
    except Exception as ex:
        raise HTTPException(status_code=500, detail=str(ex))


# ── GET /events/{id} — single event ──────────────────────────────────────────

@router.get("/{event_id}")
def get_event(event_id: int, db: Session = Depends(get_db)):
    event = db.query(Event).filter(Event.id == event_id).first()
    if not event:
        raise HTTPException(status_code=404, detail="Event not found")
    return {
        "id":                 str(event.id),
        "title":              event.title,
        "description":        event.description or "",
        "type":               event.type or "seminar",
        "status":             event.status or "upcoming",
        "start_date":         event.start_date.isoformat() if event.start_date else None,
        "end_date":           event.end_date.isoformat()   if event.end_date   else None,
        "venue":              event.venue or "TBD",
        "expected_attendees": event.expected_attendees or 0,
        "organizer":          event.organizer or "BDO",
        "is_virtual":         event.is_virtual or False,
        "meeting_link":       event.meeting_link,
        "prediction":         event.predicted_attendees if hasattr(event, 'predicted_attendees') else None,
    }


# ── DELETE /events/{id} ───────────────────────────────────────────────────────

@router.delete("/{event_id}")
def delete_event(event_id: int, db: Session = Depends(get_db)):
    event = db.query(Event).filter(Event.id == event_id).first()
    if not event:
        raise HTTPException(status_code=404, detail="Event not found")
    db.delete(event)
    db.commit()
    return {"success": True, "message": "Event deleted."}


# ── POST /events/recommend — AI scheduling (unchanged) ───────────────────────

@router.post("/recommend")
async def recommend_schedule(payload: EventRecommendPayload):
    try:
        ref_date = datetime.fromisoformat(payload.reference_date) \
            if payload.reference_date else datetime.now()
    except (ValueError, TypeError):
        ref_date = datetime.now()

    if ref_date < datetime.now():
        ref_date = datetime.now()

    candidates   = []
    pref_hours   = [10, 12, 14, 16]

    for offset in range(1, 15):
        candidate = ref_date + timedelta(days=offset)
        wd        = candidate.weekday()

        for hour in pref_hours:
            score = _score_slot(wd, hour, payload.event_type)
            if payload.is_virtual and 0 <= wd <= 4 and 9 <= hour <= 11:
                score = min(100, score + 5)

            slot_dt = candidate.replace(hour=hour, minute=0, second=0, microsecond=0)
            candidates.append({
                "date":   slot_dt.isoformat(),
                "reason": _reason_for_slot(wd, hour),
                "score":  score,
            })

    seen, unique = set(), []
    for c in sorted(candidates, key=lambda x: -x["score"]):
        key = c["date"][:10]
        if key not in seen:
            seen.add(key)
            unique.append(c)
        if len(unique) == 3:
            break

    return {"recommendations": unique}


# ── Helpers ───────────────────────────────────────────────────────────────────

def _score_slot(weekday: int, hour: int, event_type: str) -> int:
    if weekday >= 5:
        return 40 if event_type == "social" else 20
    if 10 <= hour <= 14:
        return 95 if event_type in ["seminar", "workshop", "ceremony"] else 80
    elif 15 <= hour <= 17:
        return 85
    return 50


def _reason_for_slot(weekday: int, hour: int) -> str:
    days     = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]
    day_name = days[weekday]
    h        = hour % 12 or 12
    ampm     = "AM" if hour < 12 else "PM"
    if weekday < 5 and 10 <= hour <= 14:
        return f"High attendance probability for {day_name} at {h}:00 {ampm} due to core academic hours."
    return f"Standard slot available on {day_name} at {h}:00 {ampm}."
