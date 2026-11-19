"""
PartnerPlus.AI — Twilio IVR Calling Service
DEMO_MODE=true  → Simulates full IVR call — no real call made
DEMO_MODE=false → Real Twilio call (paid account required for +92 numbers)
"""
import os
import random
from datetime import datetime
from urllib.parse import quote
from dotenv import load_dotenv

load_dotenv()

ACCOUNT_SID   = os.getenv("TWILIO_ACCOUNT_SID")
AUTH_TOKEN    = os.getenv("TWILIO_AUTH_TOKEN")
TWILIO_NUMBER = os.getenv("TWILIO_PHONE_NUMBER")
PUBLIC_URL    = os.getenv("PUBLIC_URL", "").rstrip("/")
DEMO_MODE     = os.getenv("DEMO_MODE", "true").lower() == "true"

print(f"📞 Calling Service — DEMO_MODE: {DEMO_MODE}")


def make_ivr_call(
    to_number:    str,
    contact_name: str = "Partner",
    call_purpose: str = "general",
) -> dict:
    """
    Makes an IVR call.
    DEMO_MODE=true  → returns realistic simulated response immediately
    DEMO_MODE=false → makes real Twilio call (needs paid account for +92)
    """

    # ── DEMO MODE — no real call ──────────────────────────────
    if DEMO_MODE:
        return _simulate_call(to_number, contact_name, call_purpose)

    # ── REAL TWILIO CALL ──────────────────────────────────────
    if not PUBLIC_URL:
        raise Exception(
            "PUBLIC_URL not set in .env. "
            "Add your ngrok or Railway URL."
        )

    from twilio.rest import Client
    client    = Client(ACCOUNT_SID, AUTH_TOKEN)
    twiml_url = f"{PUBLIC_URL}/calls/twiml?purpose={quote(call_purpose)}"

    call = client.calls.create(
        to=to_number,
        from_=TWILIO_NUMBER,
        url=twiml_url,
        status_callback=f"{PUBLIC_URL}/calls/status",
        status_callback_method="POST",
    )

    return {
        "success":      True,
        "call_sid":     call.sid,
        "status":       call.status,
        "to_number":    to_number,
        "from_number":  TWILIO_NUMBER,
        "contact_name": contact_name,
        "purpose":      call_purpose,
        "demo_mode":    False,
        "message":      f"Real IVR call initiated to {contact_name} at {to_number}.",
    }


def _simulate_call(to_number: str, contact_name: str, call_purpose: str) -> dict:
    """Simulates a complete IVR call with realistic data."""
    call_sid = f"DEMO-{random.randint(100000, 999999)}"
    digit    = random.choice(["1", "2", "3"])
    duration = random.randint(60, 240)

    menus = {
        "attendance": {
            "menu": (
                "Welcome to PartnerPlus AI, the Business Development System "
                "of the University of South Asia, Lahore. "
                "To confirm your attendance for the upcoming university event, press 1. "
                "To request a copy of the draft MOU, press 2. "
                "To speak with our Business Development Officer, press 3."
            ),
            "responses": {
                "1": "Attendance confirmed successfully. We look forward to seeing you.",
                "2": "MOU draft will be sent to your email within 24 hours.",
                "3": "Connecting to Business Development Officer.",
            }
        },
        "mou": {
            "menu": (
                "Welcome to PartnerPlus AI. "
                "To confirm receipt of the MOU, press 1. "
                "To request amendments, press 2. "
                "To speak with our officer, press 3."
            ),
            "responses": {
                "1": "MOU receipt confirmed. Our team will follow up shortly.",
                "2": "Amendment request recorded. Our team will contact you.",
                "3": "Connecting to our officer.",
            }
        },
        "general": {
            "menu": (
                "Welcome to PartnerPlus AI. "
                "To confirm your interest in partnering with our university, press 1. "
                "To request more information, press 2. "
                "To speak with our officer, press 3."
            ),
            "responses": {
                "1": "Partnership interest confirmed. Our team will contact you soon.",
                "2": "Information package will be sent to your email.",
                "3": "Connecting to our officer.",
            }
        }
    }

    data      = menus.get(call_purpose, menus["general"])
    menu_text = data["menu"]
    responses = data["responses"]
    action    = responses.get(digit, "Thank you. Goodbye.")

    return {
        "success":           True,
        "call_sid":          call_sid,
        "status":            "completed",
        "to_number":         to_number,
        "from_number":       TWILIO_NUMBER or "+19207892529",
        "contact_name":      contact_name,
        "purpose":           call_purpose,
        "duration":          f"{duration // 60}m {duration % 60}s",
        "demo_mode":         True,
        "ivr_menu_played":   menu_text,
        "digit_pressed":     digit,
        "recipient_action":  action,
        "transcript": (
            f"[System]: Call connected to {contact_name} at {to_number}\n"
            f"[IVR Voice]: {menu_text}\n"
            f"[{contact_name}]: Pressed {digit}\n"
            f"[IVR Voice]: {action}\n"
            f"[System]: Call ended. Duration: {duration}s"
        ),
        "message": (
            f"[DEMO] Simulated IVR call to {contact_name}. "
            f"Recipient pressed {digit}: {action}"
        ),
    }


def get_call_status(call_sid: str) -> dict:
    if DEMO_MODE or call_sid.startswith("DEMO-"):
        return {
            "call_sid":  call_sid,
            "status":    "completed",
            "duration":  str(random.randint(60, 300)),
            "direction": "outbound-api",
        }
    from twilio.rest import Client
    client = Client(ACCOUNT_SID, AUTH_TOKEN)
    call   = client.calls(call_sid).fetch()
    return {
        "call_sid":  call.sid,
        "status":    call.status,
        "duration":  call.duration,
        "direction": call.direction,
    }


def list_recent_calls(limit: int = 10) -> list:
    if DEMO_MODE:
        names  = ["Ahmed Malik", "Sara Noor", "Dr. Usman", "Fatima Zahra", "Bilal Ch"]
        digits = ["1", "2", "1", "3", "2"]
        return [
            {
                "call_sid":      f"DEMO-{random.randint(100000, 999999)}",
                "to":            f"+9230{random.randint(10000000, 99999999)}",
                "from":          TWILIO_NUMBER or "+19207892529",
                "status":        "completed",
                "duration":      str(random.randint(60, 300)),
                "start_time":    datetime.utcnow().isoformat(),
                "direction":     "outbound-api",
                "contact":       names[i % len(names)],
                "digit_pressed": digits[i % len(digits)],
            }
            for i in range(min(limit, 5))
        ]
    from twilio.rest import Client
    client = Client(ACCOUNT_SID, AUTH_TOKEN)
    calls  = client.calls.list(limit=limit)
    return [
        {
            "call_sid":   c.sid,
            "to":         c.to,
            "from":       c.from_,
            "status":     c.status,
            "duration":   c.duration,
            "start_time": str(c.start_time),
            "direction":  c.direction,
        }
        for c in calls
    ]