"""
PartnerPlus.AI — Automated Calling Service
Uses Twilio SDK for AI-powered voice calls.
DEMO_MODE=true in .env returns realistic mock responses for FYP presentation.
"""
import os
import random
from datetime import datetime
from dotenv import load_dotenv

load_dotenv()

DEMO_MODE = os.getenv("DEMO_MODE", "false").lower() == "true"

# ── OmniDimension client (only loaded when not in demo mode) ──
_client = None

def get_client():
    global _client
    if _client is None:
        from omnidimension import Client
        api_key = os.getenv("OMNIDIM_API_KEY")
        if not api_key:
            raise Exception("OMNIDIM_API_KEY not found in .env file.")
        _client = Client(api_key)
    return _client


_agent_id = None

def get_or_create_agent() -> int:
    global _agent_id
    if _agent_id:
        return _agent_id
    client = get_client()
    try:
        agents     = client.agent.list(page=1, page_size=10)
        agent_list = agents.get("agents", []) or agents.get("data", [])
        for agent in agent_list:
            if agent.get("name") == "BDOMate BDO Agent":
                _agent_id = agent["id"]
                return _agent_id
    except Exception:
        pass
    response  = client.agent.create(
        name            = "BDOMate BDO Agent",
        welcome_message = (
            "Hello! I am calling on behalf of the Business Development Office "
            "at the University of South Asia, Lahore. "
            "Am I speaking with the right person?"
        ),
        context_breakdown = [
            {
                "title": "Identity",
                "body": (
                    "You are an AI assistant representing the Business Development Office "
                    "of the University of South Asia, Lahore, Pakistan."
                ),
                "is_enabled": True
            },
            {
                "title": "Purpose",
                "body": (
                    "You are calling to follow up on partnership opportunities, "
                    "MOU signings, event collaborations, and sponsorship discussions."
                ),
                "is_enabled": True
            },
        ]
    )
    _agent_id = response.get("id") or response.get("agent", {}).get("id")
    return _agent_id


# ─────────────────────────────────────────────────────────────
#  DEMO HELPERS
# ─────────────────────────────────────────────────────────────

def _demo_call_id() -> str:
    return f"DEMO-CALL-{random.randint(100000, 999999)}"

def _demo_transcript(contact_name: str, purpose: str) -> str:
    return (
        f"[AI Agent]: Hello, am I speaking with {contact_name}?\n"
        f"[{contact_name}]: Yes, speaking.\n"
        f"[AI Agent]: I am calling from the Business Development Office at the "
        f"University of South Asia regarding {purpose}. "
        f"Would you be available to discuss this further?\n"
        f"[{contact_name}]: Yes, that sounds good. Please send us the details.\n"
        f"[AI Agent]: Absolutely. We will send you the complete information via email. "
        f"Thank you for your time and have a great day!\n"
        f"[{contact_name}]: Thank you. Goodbye."
    )

def _demo_summary(contact_name: str, purpose: str, organization: str) -> str:
    return (
        f"Call Summary: Successfully reached {contact_name} from {organization}. "
        f"Discussed {purpose}. "
        f"Contact showed positive interest and requested email follow-up. "
        f"Recommended action: Send MOU draft and schedule a formal meeting."
    )


# ─────────────────────────────────────────────────────────────
#  SINGLE CALL
# ─────────────────────────────────────────────────────────────

def make_single_call(
    phone_number: str,
    contact_name: str,
    call_purpose: str,
    organization: str = ""
) -> dict:
    """Makes a single AI-powered call. Uses demo mode if DEMO_MODE=true."""

    if DEMO_MODE:
        call_id = _demo_call_id()
        return {
            "success":      True,
            "call_id":      call_id,
            "status":       "completed",
            "to_number":    phone_number,
            "contact_name": contact_name,
            "organization": organization,
            "purpose":      call_purpose,
            "duration":     f"{random.randint(1, 5)}m {random.randint(10, 59)}s",
            "transcript":   _demo_transcript(contact_name, call_purpose),
            "summary":      _demo_summary(contact_name, call_purpose, organization),
            "called_at":    datetime.utcnow().isoformat(),
            "demo_mode":    True,
            "message":      (
                f"[DEMO MODE] Simulated AI call to {contact_name} at {phone_number}. "
                f"In production, OmniDimension will place a real AI voice call."
            ),
        }

    # ── Real call ────────────────────────────────────────────
    client          = get_client()
    agent_id        = get_or_create_agent()
    phone_numbers   = client.phone_number.list(page=1, page_size=5)
    number_list     = phone_numbers.get("phone_numbers", [])
    if not number_list:
        raise Exception(
            "No phone number assigned to your OmniDimension account. "
            "Please add a phone number in your OmniDimension dashboard, "
            "or set DEMO_MODE=true in .env for FYP demonstration."
        )
    phone_number_id = number_list[0]["id"]
    response = client.calling.make_call(
        agent_id        = agent_id,
        phone_number_id = phone_number_id,
        to_number       = phone_number,
        context         = (
            f"You are calling {contact_name} from {organization}. "
            f"Purpose: {call_purpose}. Be professional."
        )
    )
    return {
        "success":      True,
        "call_id":      response.get("id") or response.get("call_id"),
        "status":       response.get("status", "initiated"),
        "to_number":    phone_number,
        "contact_name": contact_name,
        "purpose":      call_purpose,
        "demo_mode":    False,
        "message":      f"AI call initiated to {contact_name} at {phone_number}",
    }


# ─────────────────────────────────────────────────────────────
#  BULK CALLS
# ─────────────────────────────────────────────────────────────

def make_bulk_calls(
    contacts:      list,
    campaign_name: str = "BDOMate BDO Campaign"
) -> dict:
    """Makes AI calls to multiple contacts. Uses demo mode if DEMO_MODE=true."""

    if DEMO_MODE:
        campaign_id = f"DEMO-CAMPAIGN-{random.randint(10000, 99999)}"
        results = []
        for c in contacts:
            cid = _demo_call_id()
            results.append({
                "call_id":      cid,
                "contact_name": c.get("customer_name", "Partner"),
                "phone_number": c.get("phone_number"),
                "status":       "completed",
                "duration":     f"{random.randint(1, 4)}m {random.randint(10, 59)}s",
                "summary":      _demo_summary(
                    c.get("customer_name", "Partner"),
                    c.get("purpose", "Partnership follow-up"),
                    ""
                ),
            })
        return {
            "success":        True,
            "campaign_id":    campaign_id,
            "campaign_name":  campaign_name,
            "total_contacts": len(contacts),
            "status":         "completed",
            "calls":          results,
            "demo_mode":      True,
            "message":        (
                f"[DEMO MODE] Simulated bulk AI calls to {len(contacts)} contacts. "
                f"In production, OmniDimension will place real AI voice calls."
            ),
        }

    # ── Real bulk call ───────────────────────────────────────
    client          = get_client()
    agent_id        = get_or_create_agent()
    phone_numbers   = client.phone_number.list(page=1, page_size=5)
    number_list     = phone_numbers.get("phone_numbers", [])
    if not number_list:
        raise Exception(
            "No phone number assigned to your OmniDimension account. "
            "Set DEMO_MODE=true in .env for FYP demonstration."
        )
    phone_number_id = number_list[0]["id"]
    formatted       = [
        {
            "phone_number":  c.get("phone_number"),
            "customer_name": c.get("customer_name", "Partner"),
            "purpose":       c.get("purpose", "Partnership follow-up"),
        }
        for c in contacts
    ]
    response = client.bulk_call.create_bulk_calls(
        name            = campaign_name,
        contact_list    = formatted,
        phone_number_id = phone_number_id,
        agent_id        = agent_id,
    )
    return {
        "success":        True,
        "campaign_id":    response.get("id") or response.get("bulk_call_id"),
        "campaign_name":  campaign_name,
        "total_contacts": len(formatted),
        "status":         response.get("status", "scheduled"),
        "demo_mode":      False,
        "message":        f"Bulk call campaign started for {len(formatted)} contacts",
    }


# ─────────────────────────────────────────────────────────────
#  GET CALL TRANSCRIPT
# ─────────────────────────────────────────────────────────────

def get_call_transcript(call_id: str) -> dict:
    """Gets transcription of a completed call."""

    if DEMO_MODE or call_id.startswith("DEMO-"):
        return {
            "success":       True,
            "call_id":       call_id,
            "status":        "completed",
            "duration":      f"{random.randint(2, 6)}m {random.randint(10, 59)}s",
            "transcript":    _demo_transcript("Partner Contact", "MOU and partnership discussion"),
            "summary":       _demo_summary("Partner Contact", "MOU signing", "Partner Organization"),
            "recording_url": "",
            "demo_mode":     True,
        }

    client = get_client()
    try:
        response = client.calling.get_call(call_id)
        return {
            "success":       True,
            "call_id":       call_id,
            "status":        response.get("status", "unknown"),
            "duration":      response.get("duration", 0),
            "transcript":    response.get("transcript", "Transcript not available yet."),
            "summary":       response.get("summary", "Summary not available yet."),
            "recording_url": response.get("recording_url", ""),
            "demo_mode":     False,
        }
    except Exception as e:
        return {
            "success":    False,
            "call_id":    call_id,
            "transcript": "Not available",
            "summary":    "Not available",
            "error":      str(e),
        }


# ─────────────────────────────────────────────────────────────
#  CALL HISTORY
# ─────────────────────────────────────────────────────────────

def get_call_history(page: int = 1, page_size: int = 10) -> dict:
    """Returns list of all calls."""

    if DEMO_MODE:
        names   = ["Ahmed Malik", "Sara Noor", "Dr. Usman Tariq", "Fatima Zahra", "Bilal Chaudhry"]
        orgs    = ["KDA", "National Bank", "Aga Khan University", "PTCL", "Punjab RSP"]
        statuses = ["completed", "completed", "completed", "no_answer", "completed"]
        calls   = []
        for i in range(min(page_size, 5)):
            calls.append({
                "call_id":    f"DEMO-CALL-{100000 + i}",
                "to_number":  f"+9230{random.randint(10000000, 99999999)}",
                "contact":    names[i],
                "organization": orgs[i],
                "status":     statuses[i],
                "duration":   f"{random.randint(1, 5)}m {random.randint(10, 59)}s",
                "created_at": datetime.utcnow().isoformat(),
            })
        return {
            "success":   True,
            "total":     len(calls),
            "page":      page,
            "calls":     calls,
            "demo_mode": True,
        }

    client = get_client()
    try:
        response = client.calling.list_calls(page=page, page_size=page_size)
        calls    = response.get("calls", []) or response.get("data", [])
        return {
            "success":   True,
            "total":     len(calls),
            "page":      page,
            "calls": [
                {
                    "call_id":   c.get("id"),
                    "to_number": c.get("to_number") or c.get("destination"),
                    "status":    c.get("status"),
                    "duration":  c.get("duration", 0),
                    "created_at": c.get("created_at", ""),
                }
                for c in calls
            ],
            "demo_mode": False,
        }
    except Exception as e:
        return {"success": False, "total": 0, "calls": [], "error": str(e)}