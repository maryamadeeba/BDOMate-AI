"""
PartnerPlus.AI — AI Service
Calls Google Gemini REST API directly.
FIX: Added retry logic, longer timeout, rate-limit handling,
     and graceful fallback so the chat never returns a 500.
"""
import os
import time
import requests
from dotenv import load_dotenv
from services.mou_templates import get_mou_template

load_dotenv()

GEMINI_API_KEY = os.getenv("OPENAI_API_KEY")

OPENROUTER_API_KEY = os.getenv("OPENAI_API_KEY")
REQUEST_TIMEOUT = 30

def _call_gemini(prompt: str, retries: int = 2) -> str:
    """
    Calls Google Gemini via OpenRouter — free tier, no credit card needed.
    Falls back to a friendly message if the API is unavailable.
    """
    url = "https://openrouter.ai/api/v1/chat/completions"
    headers = {
        "Authorization": f"Bearer {OPENROUTER_API_KEY}",
        "Content-Type": "application/json",
        "HTTP-Referer": "http://localhost:8000",
        "X-Title": "PartnerPlus.AI",
    }
    body = {
        "model": "openrouter/free",
        "messages": [{"role": "user", "content": prompt}],
        "max_tokens": 2048,
        "temperature": 0.4,
    }

    for attempt in range(retries):
        try:
            response = requests.post(
                url, headers=headers,
                json=body, timeout=REQUEST_TIMEOUT
            )
            if response.status_code == 200:
                data = response.json()
                return data["choices"][0]["message"]["content"].strip()
            elif response.status_code == 429:
                time.sleep(2)
                continue
            else:
                print(f"[AI Service] OpenRouter error: {response.status_code} {response.text}")
                break
        except requests.exceptions.Timeout:
            time.sleep(1)
            continue
        except Exception as e:
            print(f"[AI Service] Exception: {e}")
            break

    return (
        "I'm having trouble reaching the AI right now. "
        "Please try again in a moment."
    )
    last_error = ""

    for model in MODELS_TO_TRY:
        url = (
            f"https://generativelanguage.googleapis.com"
            f"/v1beta/models/{model}:generateContent"
            f"?key={GEMINI_API_KEY}"
        )

        for attempt in range(retries):
            try:
                response = requests.post(
                    url, headers=headers, json=body,
                    timeout=REQUEST_TIMEOUT
                )

                if response.status_code == 200:
                    data = response.json()
                    # Sometimes Gemini returns empty candidates (safety filter)
                    candidates = data.get("candidates", [])
                    if candidates:
                        parts = candidates[0].get("content", {}).get("parts", [])
                        if parts:
                            return parts[0].get("text", "").strip()
                    # Empty response — try next model
                    last_error = f"{model}: empty response from Gemini"
                    break

                elif response.status_code == 429:
                    # Rate limited — wait and retry
                    wait = RETRY_DELAY * (attempt + 1)
                    last_error = f"{model}: rate limited (429), waiting {wait}s"
                    time.sleep(wait)
                    continue

                elif response.status_code == 404:
                    # Model not available — try next
                    last_error = f"{model}: not found (404)"
                    break

                elif response.status_code in (500, 503):
                    # Gemini server error — retry
                    last_error = f"{model}: Gemini server error {response.status_code}"
                    time.sleep(RETRY_DELAY)
                    continue

                else:
                    last_error = f"{model}: HTTP {response.status_code}"
                    break

            except requests.exceptions.Timeout:
                last_error = f"{model}: timed out (attempt {attempt + 1}/{retries})"
                time.sleep(RETRY_DELAY)
                continue

            except requests.exceptions.ConnectionError:
                last_error = f"{model}: connection error"
                time.sleep(RETRY_DELAY)
                continue

            except Exception as e:
                last_error = f"{model}: {str(e)}"
                break

    # All models and retries exhausted — return a polite fallback
    # instead of raising (which would cause a 500 to the frontend)
    print(f"[AI Service] All models failed. Last error: {last_error}")
    return (
        "I'm having trouble reaching the AI right now. "
        "Please try again in a moment. "
        f"(Details: {last_error})"
    )


# ─────────────────────────────────────────────────────────────
#  MOU GENERATOR
# ─────────────────────────────────────────────────────────────

def generate_mou(partner_name: str, mou_type: str,
                 duration: int, focus_areas: str,
                 special_notes: str = "") -> str:
    example = get_mou_template(mou_type)
    prompt = f"""You are a professional legal document writer for the University of South Asia, Lahore, Pakistan.

Generate a complete formal Memorandum of Understanding (MOU) using these details:
- Party 1     : University of South Asia, 47-Tufail Road, Lahore Cantt
- Party 2     : {partner_name}
- MOU Type    : {mou_type}
- Duration    : {duration} years
- Focus Areas : {focus_areas}
- Special Notes: {special_notes if special_notes else "None"}

Follow this university style template:
{example}

Write a complete formal MOU including:
Purpose, Responsibilities of both parties, Confidentiality clause,
Duration and Termination, Signature blocks with Name/Designation/CNIC/Date,
and a Witnesses section at the bottom.
Replace all placeholder text with the actual values provided above."""

    return _call_gemini(prompt)


# ─────────────────────────────────────────────────────────────
#  EMAIL GENERATOR
# ─────────────────────────────────────────────────────────────

def generate_email(recipient_name: str, recipient_org: str,
                   email_purpose: str, context: str = "") -> dict:
    prompt = f"""You are a Business Development Officer at the University of South Asia, Lahore.

Write a formal professional email:
- Recipient : {recipient_name} at {recipient_org}
- Purpose   : {email_purpose}
- Context   : {context if context else "None"}

Return in EXACTLY this format:
SUBJECT: [subject line here]
BODY:
[full email body here]

Sign off as: Business Development Office, University of South Asia"""

    text    = _call_gemini(prompt)
    subject = ""
    body    = text

    if "SUBJECT:" in text and "BODY:" in text:
        parts   = text.split("BODY:", 1)
        subject = parts[0].replace("SUBJECT:", "").strip()
        body    = parts[1].strip()

    return {"subject": subject, "body": body}


# ─────────────────────────────────────────────────────────────
#  AI CHAT ASSISTANT
# ─────────────────────────────────────────────────────────────

def chat_with_assistant(user_message: str,
                        conversation_history: list = []) -> str:
    system = (
        "You are PartnerPlus.AI, an intelligent assistant for "
        "Business Development Officers at the University of South Asia, Lahore. "
        "Help with: MOU queries, partner management, email drafting, "
        "event planning, and business development advice. "
        "Be professional, concise, and helpful.\n\n"
    )

    history_text = ""
    for msg in conversation_history[-10:]:   # only last 10 messages to avoid huge prompts
        role          = "User" if msg.get("role") == "user" else "Assistant"
        history_text += f"{role}: {msg.get('content', '')}\n"

    full_prompt = f"{system}{history_text}User: {user_message}\nAssistant:"
    return _call_gemini(full_prompt)


# ─────────────────────────────────────────────────────────────
#  MARKETING CONTENT GENERATOR
# ─────────────────────────────────────────────────────────────

def generate_marketing_content(event_name: str, event_type: str,
                                event_date: str, platform: str) -> str:
    tone_map = {
        "instagram": "exciting, emoji-rich, youth-friendly",
        "linkedin":  "professional, formal, industry-focused",
        "facebook":  "friendly, informative, community-focused",
        "email":     "formal, detailed, invitation-style",
    }
    prompt = f"""Write {platform} marketing content for a university event.
- Event  : {event_name} ({event_type})
- Date   : {event_date}
- Tone   : {tone_map.get(platform.lower(), 'professional')}
- Uni    : University of South Asia, Lahore
Write compelling content that encourages attendance.
Include relevant hashtags for social media."""

    return _call_gemini(prompt)
