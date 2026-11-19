"""
PartnerPlus.AI — Calls Router
Now saves all calls, IVR responses, and transcripts to PostgreSQL.
"""
from fastapi import APIRouter, Request, Form, HTTPException, Depends
from fastapi.responses import Response
from pydantic import BaseModel
from typing import Optional, List
from datetime import datetime
from sqlalchemy.orm import Session
from database.db import get_db
from database.models import Call, CallIVRResponse, CallTranscript
from services.twilio_calling_service import (
    make_ivr_call, get_call_status, list_recent_calls,
)

router = APIRouter()


class SingleCallRequest(BaseModel):
    phone_number:  str
    contact_name:  str
    call_purpose:  Optional[str] = "general"
    organization:  Optional[str] = ""


class BulkContact(BaseModel):
    phone_number:  str
    contact_name:  str
    call_purpose:  Optional[str] = "general"


class BulkCallRequest(BaseModel):
    contacts: List[BulkContact]


# ─────────────────────────────────────────────────────────────
#  SINGLE CALL — saves to DB
# ─────────────────────────────────────────────────────────────

@router.post("/single")
def single_call(req: SingleCallRequest, db: Session = Depends(get_db)):
    try:
        result = make_ivr_call(
            to_number    = req.phone_number,
            contact_name = req.contact_name,
            call_purpose = req.call_purpose or "general",
        )

        # Save call to database
        call_record = Call(
            call_sid      = result.get("call_sid", ""),
            contact_name  = req.contact_name,
            contact_phone = req.phone_number,
            call_purpose  = req.call_purpose or "general",
            status        = result.get("status", "completed"),
            duration_secs = _parse_duration(result.get("duration", "0")),
            is_demo       = result.get("demo_mode", True),
        )
        db.add(call_record)
        db.commit()
        db.refresh(call_record)

        # Save transcript to database
        transcript = result.get("transcript")
        summary    = result.get("recipient_action") or result.get("message", "")
        if transcript:
            db.add(CallTranscript(
                call_id    = call_record.id,
                call_sid   = result.get("call_sid", ""),
                transcript = transcript,
                summary    = summary,
            ))
            db.commit()

        return result

    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


# ─────────────────────────────────────────────────────────────
#  BULK CALLS
# ─────────────────────────────────────────────────────────────

@router.post("/bulk")
def bulk_call(req: BulkCallRequest, db: Session = Depends(get_db)):
    results, errors = [], []
    for contact in req.contacts:
        try:
            r = make_ivr_call(
                to_number    = contact.phone_number,
                contact_name = contact.contact_name,
                call_purpose = contact.call_purpose or "general",
            )
            # Save each call to DB
            call_record = Call(
                call_sid      = r.get("call_sid", ""),
                contact_name  = contact.contact_name,
                contact_phone = contact.phone_number,
                call_purpose  = contact.call_purpose or "general",
                status        = r.get("status", "completed"),
                duration_secs = _parse_duration(r.get("duration", "0")),
                is_demo       = r.get("demo_mode", True),
            )
            db.add(call_record)
            db.commit()
            results.append(r)
        except Exception as e:
            errors.append({"number": contact.phone_number, "error": str(e)})

    return {
        "success":        len(results) > 0,
        "total_contacts": len(req.contacts),
        "called":         len(results),
        "failed":         len(errors),
        "results":        results,
        "errors":         errors,
    }


# ─────────────────────────────────────────────────────────────
#  TWIML — served to Twilio when call is answered
# ─────────────────────────────────────────────────────────────

@router.get("/twiml")
@router.post("/twiml")
def serve_twiml(request: Request, purpose: str = "general"):
    base_url    = str(request.base_url).rstrip("/")
    webhook_url = f"{base_url}/calls/webhook?purpose={purpose}"

    messages = {
        "attendance": (
            "Welcome to BDOMate A I, the Business Development System "
            "of the University of South Asia, Lahore. "
            "To confirm your attendance for the upcoming university event, press 1. "
            "To request a copy of the draft Memorandum of Understanding, press 2. "
            "To speak with our Business Development Officer, press 3."
        ),
        "mou": (
            "Welcome to BDOMate A I, the Business Development System "
            "of the University of South Asia, Lahore. "
            "To confirm receipt of the Memorandum of Understanding, press 1. "
            "To request changes or amendments to the MOU, press 2. "
            "To speak with our Business Development Officer, press 3."
        ),
        "general": (
            "Welcome to BDOMate A I, the Business Development System "
            "of the University of South Asia, Lahore. "
            "To confirm your interest in partnering with our university, press 1. "
            "To request more information about collaboration opportunities, press 2. "
            "To speak with our Business Development Officer, press 3."
        ),
    }
    msg  = messages.get(purpose, messages["general"])
    xml  = f"""<?xml version="1.0" encoding="UTF-8"?>
<Response>
    <Gather input="dtmf" timeout="10" numDigits="1" action="{webhook_url}" method="POST">
        <Say voice="Polly.Joanna" language="en-US">{msg}</Say>
    </Gather>
    <Say voice="Polly.Joanna">We did not receive your input. Please call back. Goodbye.</Say>
    <Hangup/>
</Response>"""
    return Response(content=xml, media_type="application/xml")


# ─────────────────────────────────────────────────────────────
#  WEBHOOK — saves digit pressed to DB
# ─────────────────────────────────────────────────────────────

@router.post("/webhook")
async def handle_digit(
    request:  Request,
    Digits:   str = Form(...),
    CallSid:  str = Form(default=""),
    purpose:  str = "general",
    db: Session = Depends(get_db),
):
    digit          = Digits.strip()
    action, text   = _get_action_and_text(purpose, digit)

    # Save IVR response to database
    call_record = db.query(Call).filter(Call.call_sid == CallSid).first()
    ivr = CallIVRResponse(
        call_id       = call_record.id if call_record else None,
        call_sid      = CallSid,
        digit_pressed = digit,
        action_taken  = action,
        call_purpose  = purpose,
        response_text = text,
    )
    db.add(ivr)
    db.commit()
    print(f"✅ IVR saved — SID: {CallSid} | Digit: {digit} | Action: {action}")

    xml = f"""<?xml version="1.0" encoding="UTF-8"?>
<Response>
    <Say voice="Polly.Joanna" language="en-US">{text}</Say>
    <Hangup/>
</Response>"""
    return Response(content=xml, media_type="application/xml")


# ─────────────────────────────────────────────────────────────
#  STATUS WEBHOOK
# ─────────────────────────────────────────────────────────────

@router.post("/status")
async def call_status(request: Request, db: Session = Depends(get_db)):
    form   = await request.form()
    sid    = form.get("CallSid", "")
    status = form.get("CallStatus", "")
    # Update call status in DB
    record = db.query(Call).filter(Call.call_sid == sid).first()
    if record:
        record.status = status
        db.commit()
    print(f"📞 Call Status — SID: {sid} | Status: {status}")
    return Response(content="OK")


# ─────────────────────────────────────────────────────────────
#  GET CALL HISTORY — from DB first, fallback to Twilio
# ─────────────────────────────────────────────────────────────

# Add the extra route mappings right here:
@router.get("")
@router.get("/")
@router.get("/history")
def call_history(limit: int = 10, db: Session = Depends(get_db)):
    try:
        # Try DB first
        # Try DB first
        db_calls = db.query(Call).order_by(Call.created_at.desc()).limit(limit).all()
        if db_calls:
            return {
                "success": True,
                "total":   len(db_calls),
                "calls": [
                    {
                        "call_sid":   c.call_sid,
                        "id":         c.id,
                        "to":         c.contact_phone,
                        "contact":    c.contact_name,
                        "purpose":    c.call_purpose,
                        "status":     c.status,
                        "duration":   c.duration_secs,
                        "is_demo":    c.is_demo,
                        "start_time": str(c.created_at),
                    }
                    for c in db_calls
                ],
            }
        # Fallback to Twilio/demo
        calls = list_recent_calls(limit=limit)
        return {"success": True, "total": len(calls), "calls": calls}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/ivr-responses")
def get_ivr_responses(db: Session = Depends(get_db)):
    """Returns all IVR digit responses from database."""
    responses = db.query(CallIVRResponse).order_by(
        CallIVRResponse.created_at.desc()).all()
    return {
        "success":   True,
        "total":     len(responses),
        "responses": [
            {
                "id":           r.id,
                "call_sid":     r.call_sid,
                "digit_pressed": r.digit_pressed,
                "action_taken": r.action_taken,
                "call_purpose": r.call_purpose,
                "response_text": r.response_text,
                "timestamp":    str(r.created_at),
            }
            for r in responses
        ],
    }


@router.get("/{call_id}")
def get_call(call_id: str, db: Session = Depends(get_db)):
    # Try DB first
    record = db.query(Call).filter(Call.call_sid == call_id).first()
    if record:
        transcript = db.query(CallTranscript).filter(
            CallTranscript.call_sid == call_id).first()
        return {
            "call_sid":   record.call_sid,
            "status":     record.status,
            "duration":   record.duration_secs,
            "contact":    record.contact_name,
            "purpose":    record.call_purpose,
            "transcript": transcript.transcript if transcript else None,
            "summary":    transcript.summary    if transcript else None,
        }
    # Fallback to Twilio
    try:
        return get_call_status(call_id)
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


# ─────────────────────────────────────────────────────────────
#  HELPERS
# ─────────────────────────────────────────────────────────────

def _parse_duration(val) -> int:
    if isinstance(val, int): return val
    s = str(val)
    import re
    m   = re.search(r'(\d+)m', s)
    sec = re.search(r'(\d+)s', s)
    return (int(m.group(1)) if m else 0) * 60 + (int(sec.group(1)) if sec else 0)


def _get_action_and_text(purpose: str, digit: str):
    data = {
        "attendance": {
            "1": ("attendance_confirmed",  "Thank you! Your attendance has been confirmed. We look forward to seeing you. Goodbye."),
            "2": ("mou_requested",         "Thank you! The MOU draft will be sent to your email within 24 hours. Goodbye."),
            "3": ("bdo_requested",         "Thank you! Our Business Development Officer will contact you shortly. Goodbye."),
        },
        "mou": {
            "1": ("mou_receipt_confirmed", "Thank you for confirming receipt. Our team will follow up shortly. Goodbye."),
            "2": ("amendments_requested",  "Thank you! Our team will contact you to discuss amendments. Goodbye."),
            "3": ("bdo_requested",         "Thank you! Our officer will contact you shortly. Goodbye."),
        },
        "general": {
            "1": ("interest_confirmed",    "Thank you for your interest! Our team will contact you soon. Goodbye."),
            "2": ("info_requested",        "Thank you! An information package will be sent to your email. Goodbye."),
            "3": ("bdo_requested",         "Thank you! Our Business Development Officer will contact you. Goodbye."),
        },
    }
    actions = data.get(purpose, data["general"])
    action, text = actions.get(digit, ("invalid", "Invalid selection. Please call back. Goodbye."))
    return action, text