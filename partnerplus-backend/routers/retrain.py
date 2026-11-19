from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
from services.retrain_service import (
    save_real_event,
    retrain_attendance_model,
    get_model_status
)

router = APIRouter()


class RealEventData(BaseModel):
    event_type:           str
    department:           str
    day_of_week:          str
    time_slot:            str
    season:               str
    capacity:             int
    is_free:              bool
    has_food:             bool
    industry_guests:      bool
    weeks_promoted:       int
    past_avg_attendance:  int
    actual_attendance:    int   # ← BDO fills this AFTER the event happens


@router.post("/record-actual")
def record_actual_attendance(req: RealEventData):
    """
    BDO calls this after an event to record how many people actually came.
    This data trains the model over time — the more events recorded, the smarter it gets.
    """
    try:
        result = save_real_event(
            event_type          = req.event_type,
            department          = req.department,
            day_of_week         = req.day_of_week,
            time_slot           = req.time_slot,
            season              = req.season,
            capacity            = req.capacity,
            is_free             = req.is_free,
            has_food            = req.has_food,
            industry_guests     = req.industry_guests,
            weeks_promoted      = req.weeks_promoted,
            past_avg_attendance = req.past_avg_attendance,
            actual_attendance   = req.actual_attendance,
        )
        return {"success": True, **result}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/status")
def model_status():
    """
    Shows how much real data has been collected and when the model last retrained.
    Use this in the admin dashboard to show BDOs their progress.
    """
    return get_model_status()


@router.post("/trigger")
def trigger_retraining():
    """
    Admin manually triggers model retraining.
    Usually happens automatically, but can be forced from the app.
    """
    result = retrain_attendance_model()
    if not result['success']:
        raise HTTPException(status_code=400, detail=result['message'])
    return result
