"""
services/email_sender.py
"""
import os
import asyncio
from email.mime.multipart import MIMEMultipart
from email.mime.text import MIMEText
import aiosmtplib
from dotenv import load_dotenv

load_dotenv()

SMTP_HOST      = os.getenv("SMTP_HOST",      "smtp-relay.brevo.com")
SMTP_PORT      = int(os.getenv("SMTP_PORT",  "587"))
SMTP_USER      = os.getenv("SMTP_USER",      "")
SMTP_PASSWORD  = os.getenv("SMTP_PASSWORD",  "")
SMTP_FROM_NAME = os.getenv("SMTP_FROM_NAME", "PartnerPlus.AI")

# Verified configuration identity channel
SENDER_EMAIL   = "nooriqbal504@gmail.com" 

_USE_SSL       = SMTP_PORT == 465


def _build_mime(to_email: str, to_name: str, subject: str, body: str) -> MIMEMultipart:
    msg            = MIMEMultipart("alternative")
    msg["Subject"] = subject
    msg["From"]    = f"{SMTP_FROM_NAME} <{SENDER_EMAIL}>"
    msg["To"]      = f"{to_name} <{to_email}>" if to_name else to_email
    
    msg.attach(MIMEText(body, "plain", "utf-8"))
    html = f"""<html><body style="font-family:Arial,sans-serif;font-size:14px;color:#222;">
    <div style="max-width:600px;margin:auto;padding:24px;">
      {body.replace(chr(10), '<br>')}
      <hr style="margin-top:32px;border:none;border-top:1px solid #eee;">
      <p style="font-size:11px;color:#999;">Sent via BDOMate.AI Auto-Responder — University of South Asia</p>
    </div></body></html>"""
    msg.attach(MIMEText(html, "html", "utf-8"))
    return msg


async def send_email_async(to_email: str, to_name: str, subject: str, body: str) -> dict:
    if not SMTP_USER or not SMTP_PASSWORD:
        return {"sent": False, "error": "SMTP credentials missing in .env"}
    try:
        msg = _build_mime(to_email, to_name, subject, body)
        kwargs = dict(
            hostname=SMTP_HOST, port=SMTP_PORT,
            username=SMTP_USER, password=SMTP_PASSWORD,
            timeout=20,
        )
        if _USE_SSL:
            kwargs["use_tls"] = True
        else:
            kwargs["start_tls"] = True

        await aiosmtplib.send(msg, **kwargs)
        print(f"[EmailSender] ✅ Automatic reply delivered to {to_email}")
        return {"sent": True}

    except aiosmtplib.SMTPAuthenticationError:
        err = "SMTP auth failed — check SMTP_USER / SMTP_PASSWORD in .env"
    except aiosmtplib.SMTPConnectError:
        err = f"Cannot connect to {SMTP_HOST}:{SMTP_PORT}"
    except asyncio.TimeoutError:
        err = "SMTP timed out after 20s"
    except Exception as e:
        err = str(e)

    print(f"[EmailSender] ❌ {err}")
    return {"sent": False, "error": err}


def send_email_background(to_email: str, to_name: str, subject: str, body: str) -> None:
    async def _run():
        result = await send_email_async(to_email, to_name, subject, body)
        if not result["sent"]:
            print(f"[EmailSender] Background automatic reply failed: {result.get('error')}")
    try:
        loop = asyncio.get_event_loop()
        if loop.is_running():
            asyncio.ensure_future(_run())
        else:
            loop.run_until_complete(_run())
    except RuntimeError:
        asyncio.run(_run())