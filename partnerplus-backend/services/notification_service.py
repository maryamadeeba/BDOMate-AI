"""
PartnerPlus.AI — Smart Notification & Scheduling Service
Handles:
- Follow-up reminders for MOUs
- Event reminders
- Partner follow-up alerts
- Scheduled call notifications
Uses APScheduler to run background jobs automatically.
"""
import os
import json
from datetime import datetime, timedelta
from typing import Optional
from apscheduler.schedulers.background import BackgroundScheduler
from apscheduler.jobstores.memory import MemoryJobStore
from dotenv import load_dotenv

load_dotenv()

# ── Scheduler setup ───────────────────────────────────────────
scheduler = BackgroundScheduler(
    jobstores={"default": MemoryJobStore()},
    job_defaults={"coalesce": True, "max_instances": 1},
    timezone="Asia/Karachi"         # Pakistan timezone
)

# ── In-memory notification store (replace with DB in production)
_notifications: list = []
_notification_id_counter: int = 0


def _next_id() -> int:
    global _notification_id_counter
    _notification_id_counter += 1
    return _notification_id_counter


# ─────────────────────────────────────────────────────────────
#  START / STOP SCHEDULER
# ─────────────────────────────────────────────────────────────

def start_scheduler():
    """Call this once when FastAPI starts."""
    if not scheduler.running:
        scheduler.start()
        print("✅ Notification scheduler started (Asia/Karachi timezone)")


def stop_scheduler():
    """Call this when FastAPI shuts down."""
    if scheduler.running:
        scheduler.shutdown()
        print("🛑 Notification scheduler stopped")


# ─────────────────────────────────────────────────────────────
#  CREATE NOTIFICATION
# ─────────────────────────────────────────────────────────────

def create_notification(
    title:       str,
    message:     str,
    notify_type: str,           # mou_followup / event_reminder / call_reminder / partner_alert
    related_id:  Optional[int] = None,
    scheduled_at: Optional[datetime] = None
) -> dict:
    """
    Creates a notification.
    If scheduled_at is provided, it fires at that time.
    Otherwise it fires immediately.
    """
    notif = {
        "id":           _next_id(),
        "title":        title,
        "message":      message,
        "type":         notify_type,
        "related_id":   related_id,
        "is_read":      False,
        "scheduled_at": scheduled_at.isoformat() if scheduled_at else None,
        "created_at":   datetime.utcnow().isoformat(),
        "fired_at":     None,
    }
    _notifications.append(notif)

    # Schedule the job if future time given
    if scheduled_at and scheduled_at > datetime.utcnow():
        scheduler.add_job(
            func        = _fire_notification,
            trigger     = "date",
            run_date    = scheduled_at,
            args        = [notif["id"]],
            id          = f"notif_{notif['id']}",
            replace_existing = True,
        )

    return {"success": True, "notification": notif}


def _fire_notification(notification_id: int):
    """Called by scheduler when notification time arrives."""
    for n in _notifications:
        if n["id"] == notification_id:
            n["fired_at"] = datetime.utcnow().isoformat()
            print(f"🔔 Notification fired: [{n['type']}] {n['title']}")
            break


# ─────────────────────────────────────────────────────────────
#  MOU FOLLOW-UP REMINDER
# ─────────────────────────────────────────────────────────────

def schedule_mou_followup(
    mou_id:       int,
    partner_name: str,
    days_after:   int = 7
) -> dict:
    """
    Schedules a follow-up reminder X days after MOU creation.
    Default: 7 days.
    """
    fire_at = datetime.utcnow() + timedelta(days=days_after)
    return create_notification(
        title        = f"MOU Follow-up: {partner_name}",
        message      = (
            f"It has been {days_after} days since the MOU with {partner_name} was generated. "
            f"Please follow up to check on the signing status."
        ),
        notify_type  = "mou_followup",
        related_id   = mou_id,
        scheduled_at = fire_at,
    )


# ─────────────────────────────────────────────────────────────
#  EVENT REMINDER
# ─────────────────────────────────────────────────────────────

def schedule_event_reminder(
    event_id:    int,
    event_title: str,
    event_date:  datetime,
    remind_hours_before: int = 24
) -> dict:
    """
    Schedules an event reminder X hours before the event.
    Default: 24 hours before.
    """
    fire_at = event_date - timedelta(hours=remind_hours_before)

    if fire_at <= datetime.utcnow():
        # Event is too soon — notify immediately
        fire_at = datetime.utcnow() + timedelta(minutes=1)

    return create_notification(
        title        = f"Event Reminder: {event_title}",
        message      = (
            f"Your event '{event_title}' is in {remind_hours_before} hours. "
            f"Make sure everything is prepared!"
        ),
        notify_type  = "event_reminder",
        related_id   = event_id,
        scheduled_at = fire_at,
    )


# ─────────────────────────────────────────────────────────────
#  CALL REMINDER
# ─────────────────────────────────────────────────────────────

def schedule_call_reminder(
    partner_name: str,
    phone_number: str,
    call_purpose: str,
    scheduled_at: datetime
) -> dict:
    """
    Schedules a reminder to call a partner at a specific time.
    """
    return create_notification(
        title        = f"Scheduled Call: {partner_name}",
        message      = (
            f"Time to call {partner_name} at {phone_number}. "
            f"Purpose: {call_purpose}"
        ),
        notify_type  = "call_reminder",
        scheduled_at = scheduled_at,
    )


# ─────────────────────────────────────────────────────────────
#  PARTNER INACTIVITY ALERT
# ─────────────────────────────────────────────────────────────

def check_inactive_partners_job():
    """
    Background job — runs every Monday at 9 AM.
    Checks for partners with no activity in 30 days and alerts BDO.
    """
    alert_msg = (
        "Weekly Partner Activity Check: "
        "Review your partner list for any inactive partnerships "
        "that need follow-up this week."
    )
    create_notification(
        title       = "Weekly Partner Activity Alert",
        message     = alert_msg,
        notify_type = "partner_alert",
    )
    print("✅ Weekly partner alert created")


def schedule_weekly_partner_check():
    """Schedules the weekly partner activity check job."""
    scheduler.add_job(
        func             = check_inactive_partners_job,
        trigger          = "cron",
        day_of_week      = "mon",
        hour             = 9,
        minute           = 0,
        id               = "weekly_partner_check",
        replace_existing = True,
    )
    print("✅ Weekly partner check scheduled for every Monday 9:00 AM")


# ─────────────────────────────────────────────────────────────
#  GET NOTIFICATIONS
# ─────────────────────────────────────────────────────────────

def get_all_notifications(unread_only: bool = False) -> dict:
    """Returns all notifications, optionally filtered to unread only."""
    result = _notifications if not unread_only else [
        n for n in _notifications if not n["is_read"]
    ]
    # Sort newest first
    result = sorted(result, key=lambda x: x["created_at"], reverse=True)
    return {
        "success":       True,
        "total":         len(result),
        "unread_count":  sum(1 for n in _notifications if not n["is_read"]),
        "notifications": result
    }


def mark_as_read(notification_id: int) -> dict:
    """Marks a notification as read."""
    for n in _notifications:
        if n["id"] == notification_id:
            n["is_read"] = True
            return {"success": True, "message": "Marked as read"}
    return {"success": False, "message": "Notification not found"}


def mark_all_read() -> dict:
    """Marks all notifications as read."""
    for n in _notifications:
        n["is_read"] = True
    return {"success": True, "message": f"All {len(_notifications)} notifications marked as read"}


def delete_notification(notification_id: int) -> dict:
    """Deletes a notification."""
    global _notifications
    before = len(_notifications)
    _notifications = [n for n in _notifications if n["id"] != notification_id]
    if len(_notifications) < before:
        # Also remove scheduled job if exists
        try:
            scheduler.remove_job(f"notif_{notification_id}")
        except Exception:
            pass
        return {"success": True, "message": "Notification deleted"}
    return {"success": False, "message": "Notification not found"}
