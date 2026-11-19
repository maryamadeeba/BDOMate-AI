import os
from fastapi import APIRouter, HTTPException, Depends
from pydantic import BaseModel
from typing import Optional
from sqlalchemy.orm import Session
from database.db import get_db
from database.models import EmailReply
from services.email_sender import send_email_async
import asyncio
from services.ai_service import _call_gemini   # reuse chat AI function

router = APIRouter()

SENDER_EMAIL   = os.getenv("SMTP_USER", "nooriqbal504@gmail.com")
SENDER_NAME    = os.getenv("SMTP_FROM_NAME", "BDOMate.AI – University of South Asia")


# ── Helpers ───────────────────────────────────────────────────────────────────

def _serialize(r: EmailReply) -> dict:
    return {
        "id":           r.id,
        "sender_email": r.sender_email,
        "sender_name":  r.sender_name or "",
        "subject":      r.subject,
        "body":         r.body,
        "is_read":      r.is_read,
        "received_at":  r.created_at.isoformat() if r.created_at else None,
    }


# ── GET /emails/replies ───────────────────────────────────────────────────────

@router.get("/replies")
def list_replies(limit: int = 50, db: Session = Depends(get_db)):
    replies = (
        db.query(EmailReply)
        .order_by(EmailReply.created_at.desc())
        .limit(limit)
        .all()
    )
    return {
        "success": True,
        "total":   len(replies),
        "unread":  sum(1 for r in replies if not r.is_read),
        "replies": [_serialize(r) for r in replies],
    }


# ── GET /emails/replies/{id} ──────────────────────────────────────────────────

@router.get("/replies/{reply_id}")
def get_reply(reply_id: int, db: Session = Depends(get_db)):
    r = db.query(EmailReply).filter(EmailReply.id == reply_id).first()
    if not r:
        raise HTTPException(status_code=404, detail="Reply not found")
    if not r.is_read:
        r.is_read = True
        db.commit()
    return _serialize(r)


# ── PATCH /emails/replies/{id}/read ──────────────────────────────────────────

@router.patch("/replies/{reply_id}/read")
def mark_read(reply_id: int, db: Session = Depends(get_db)):
    r = db.query(EmailReply).filter(EmailReply.id == reply_id).first()
    if not r:
        raise HTTPException(status_code=404, detail="Reply not found")
    r.is_read = True
    db.commit()
    return {"success": True}


# ── PATCH /emails/replies/read-all ───────────────────────────────────────────

@router.patch("/replies/read-all")
def mark_all_read(db: Session = Depends(get_db)):
    db.query(EmailReply).filter(EmailReply.is_read == False).update({"is_read": True})
    db.commit()
    return {"success": True}


# ── DELETE /emails/replies/{id} ───────────────────────────────────────────────

@router.delete("/replies/{reply_id}")
def delete_reply(reply_id: int, db: Session = Depends(get_db)):
    r = db.query(EmailReply).filter(EmailReply.id == reply_id).first()
    if not r:
        raise HTTPException(status_code=404, detail="Reply not found")
    db.delete(r)
    db.commit()
    return {"success": True}


# ── POST /emails/replies/{id}/generate-reply — AI draft via OpenRouter ────────

@router.post("/replies/{reply_id}/generate-reply")
async def generate_reply(reply_id: int, db: Session = Depends(get_db)):
    """
    Uses _call_gemini() from ai_service — the exact same function that
    powers the chat AI.  If chat works, this will always work too.
    """
    r = db.query(EmailReply).filter(EmailReply.id == reply_id).first()
    if not r:
        raise HTTPException(status_code=404, detail="Reply not found")

    prompt = f"""You are a professional Business Development Officer at the University of South Asia, Lahore.
Draft a polite, professional email reply to the following incoming email.

The reply should:
- Address the sender by name
- Acknowledge their specific request or message
- Respond appropriately (accept, decline, request more info, or express interest — based on the content)
- Be concise (3-5 short paragraphs)
- End with "Warm regards, BDO Team, University of South Asia"
- NOT include a subject line — just the body text

Incoming email:
From: {r.sender_name} <{r.sender_email}>
Subject: {r.subject}
Message:
{r.body}

Write only the reply body. Do not add any commentary or explanation."""

    # Use the same _call_gemini() that powers the working chat AI
    import asyncio as _asyncio
    loop = _asyncio.get_event_loop()
    reply_text = await loop.run_in_executor(None, _call_gemini, prompt)

    if not reply_text or reply_text.startswith("I'm having trouble"):
        raise HTTPException(status_code=502, detail="AI could not generate a reply. Please try again.")

    original_subject = r.subject
    reply_subject = (
        original_subject
        if original_subject.lower().startswith("re:")
        else f"Re: {original_subject}"
    )

    return {
        "success":        True,
        "generated_body": reply_text,
        "reply_subject":  reply_subject,
        "reply_to_email": r.sender_email,
        "reply_to_name":  r.sender_name or r.sender_email,
    }




# ── POST /emails/replies/{id}/send-reply — send via SMTP ─────────────────────

class SendReplyRequest(BaseModel):
    to_email: str
    to_name:  str
    subject:  str
    body:     str


@router.post("/replies/{reply_id}/send-reply")
async def send_reply(reply_id: int, req: SendReplyRequest, db: Session = Depends(get_db)):
    """
    Sends a reply email using the existing SMTP email_sender service.
    """
    r = db.query(EmailReply).filter(EmailReply.id == reply_id).first()
    if not r:
        raise HTTPException(status_code=404, detail="Reply not found")

    result = await send_email_async(
        to_email=req.to_email,
        to_name=req.to_name,
        subject=req.subject,
        body=req.body,
    )

    if not result.get("sent"):
        raise HTTPException(
            status_code=502,
            detail=f"SMTP error: {result.get('error', 'Unknown')}",
        )

    return {"success": True, "message": f"Reply sent to {req.to_email}"}