"""
routers/notifications.py
"""
from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel
from typing import Optional
from sqlalchemy.orm import Session
from database.db import get_db
from database.models import EmailReply, AppNotification

router = APIRouter()


# ── Schemas ───────────────────────────────────────────────────────────────────

class InboundEmailPayload(BaseModel):
    sender_email: str
    sender_name:  Optional[str] = ""
    subject:      str
    body:         str


# ── Helper — create an AppNotification from anywhere ─────────────────────────

def create_app_notification(
    db: Session,
    title: str,
    body: str,
    notif_type: str = "general",
    reference_id: Optional[str] = None,
):
    """
    Call this from any router to add a notification to the Alerts screen.
    Example:
        from routers.notifications import create_app_notification
        create_app_notification(db, "MOU Signed", "Partner XYZ signed the MOU", "mou", str(mou.id))
    """
    notif = AppNotification(
        title=title,
        body=body,
        type=notif_type,
        reference_id=reference_id,
        is_read=False,
    )
    db.add(notif)
    # Don't commit here — caller commits in their own transaction


# ── POST /notifications/process-bdo-email ────────────────────────────────────

@router.post("/process-bdo-email")
def process_bdo_email(payload: InboundEmailPayload, db: Session = Depends(get_db)):
    from datetime import datetime, timedelta
    cutoff = datetime.utcnow() - timedelta(hours=24)
    existing = (
        db.query(EmailReply)
        .filter(
            EmailReply.sender_email == payload.sender_email,
            EmailReply.subject      == payload.subject,
            EmailReply.created_at   >= cutoff,
        )
        .first()
    )
    if existing:
        return {"success": True, "id": existing.id, "message": "Duplicate skipped."}

    try:
        reply = EmailReply(
            sender_email = payload.sender_email,
            sender_name  = payload.sender_name or "",
            subject      = payload.subject,
            body         = payload.body,
            is_read      = False,
        )
        db.add(reply)
        db.flush()

        # ✅ Create notification for the Alerts screen
        create_app_notification(
            db,
            title        = f"📧 New Email: {payload.subject[:60]}",
            body         = f"From: {payload.sender_name or payload.sender_email}",
            notif_type   = "email_reply",
            reference_id = str(reply.id),
        )

        db.commit()
        db.refresh(reply)

        return {
            "success": True,
            "id":      reply.id,
            "message": f"Email from {payload.sender_email} stored.",
        }
    except Exception as e:
        db.rollback()
        raise HTTPException(status_code=500, detail=str(e))


# ── GET /notifications/unread-count ──────────────────────────────────────────

@router.get("/unread-count")
def unread_count(db: Session = Depends(get_db)):
    email_unread = db.query(EmailReply).filter(EmailReply.is_read == False).count()
    notif_unread = db.query(AppNotification).filter(AppNotification.is_read == False).count()
    return {"unread": email_unread, "notif_unread": notif_unread}


# ── GET /notifications/all ────────────────────────────────────────────────────

@router.get("/all")
def list_notifications(limit: int = 50, db: Session = Depends(get_db)):
    notifs = (
        db.query(AppNotification)
        .order_by(AppNotification.created_at.desc())
        .limit(limit)
        .all()
    )
    return {
        "success": True,
        "total":   len(notifs),
        "unread":  sum(1 for n in notifs if not n.is_read),
        "notifications": [
            {
                "id":           n.id,
                "title":        n.title,
                "body":         n.body,
                "type":         n.type,
                "reference_id": n.reference_id,
                "is_read":      n.is_read,
                "created_at":   n.created_at.isoformat() if n.created_at else None,
            }
            for n in notifs
        ],
    }


# ── PATCH /notifications/{id}/read ───────────────────────────────────────────

@router.patch("/{notif_id}/read")
def mark_notif_read(notif_id: int, db: Session = Depends(get_db)):
    n = db.query(AppNotification).filter(AppNotification.id == notif_id).first()
    if not n:
        raise HTTPException(status_code=404, detail="Not found")
    n.is_read = True
    db.commit()
    return {"success": True}


# ── PATCH /notifications/read-all ────────────────────────────────────────────

@router.patch("/read-all")
def mark_all_notifs_read(db: Session = Depends(get_db)):
    db.query(AppNotification).filter(
        AppNotification.is_read == False
    ).update({"is_read": True})
    db.commit()
    return {"success": True}


# ── POST /notifications/test ──────────────────────────────────────────────────
# Call this once to seed test notifications so the screen shows data

@router.post("/test")
def seed_test_notifications(db: Session = Depends(get_db)):
    """Seed some test notifications. Call once from Swagger or terminal."""
    test_data = [
        ("📧 New Email: IEEE FMLDS 2026 Call for Papers",
         "From: IEEE eNotice (enotice@enotice.ieee.org)", "email_reply"),
        ("📅 Event Reminder: Cloud Computing Workshop",
         "Starts in 2 hours at Gulberg Campus", "event"),
        ("📞 Call Summary: Partner Follow-up",
         "Call with Unilever Corporate lasted 4 minutes", "call"),
        ("🤝 MOU Follow-up Due",
         "Follow-up with National Foods Ltd is overdue by 2 days", "mou"),
        ("📧 New Email: Foodpanda Partnership Inquiry",
         "From: Foodpanda (contact@info.foodpanda.pk)", "email_reply"),
    ]
    for title, body, notif_type in test_data:
        db.add(AppNotification(
            title=title, body=body, type=notif_type,
            is_read=False, reference_id=None,
        ))
    db.commit()
    return {"success": True, "message": f"Seeded {len(test_data)} test notifications."}


# ── DELETE /notifications/clear-demo ─────────────────────────────────────────

@router.delete("/clear-demo")
def clear_demo_data(db: Session = Depends(get_db)):
    dummy_names = ["john smith", "john doe", "test user", "demo user", "jane doe"]
    deleted = 0
    for name in dummy_names:
        rows = db.query(EmailReply).filter(
            EmailReply.sender_name.ilike(f"%{name}%")
        ).all()
        for r in rows:
            db.delete(r)
            deleted += 1
    db.commit()
    return {"success": True, "deleted": deleted, "message": f"Purged {deleted} demo rows."}