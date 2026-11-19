"""
services/gmail_scanner.py
Scans Gmail inbox for replies to BDOMate.AI emails.
Runs every 5 minutes in a separate terminal.
"""
import os
import re
import time
import base64
import requests
from datetime import datetime
from google.oauth2.credentials import Credentials
from google_auth_oauthlib.flow import InstalledAppFlow
from google.auth.transport.requests import Request
from googleapiclient.discovery import build

# Gmail API scope
SCOPES = ['https://www.googleapis.com/auth/gmail.modify']

# Your SMTP email
MY_EMAIL = os.getenv("SMTP_USER", "nooriqbal504@gmail.com")

# Backend URL
BACKEND_URL = "http://127.0.0.1:8000/notifications/process-bdo-email"

# Check every 5 minutes
CHECK_INTERVAL = 300


def get_gmail_service():
    """Authenticate and return Gmail API service."""
    creds = None

    if os.path.exists('token.json'):
        creds = Credentials.from_authorized_user_file('token.json', SCOPES)

    if not creds or not creds.valid:
        if creds and creds.expired and creds.refresh_token:
            creds.refresh(Request())
        else:
            flow = InstalledAppFlow.from_client_secrets_file(
                'credentials.json', SCOPES
            )
            creds = flow.run_local_server(port=0)
        with open('token.json', 'w') as token:
            token.write(creds.to_json())

    return build('gmail', 'v1', credentials=creds)


def get_message_body(msg):
    """Extract plain text body from Gmail message."""
    try:
        if 'parts' in msg['payload']:
            for part in msg['payload']['parts']:
                if part['mimeType'] == 'text/plain':
                    data = part['body'].get('data', '')
                    return base64.urlsafe_b64decode(data).decode('utf-8')
        else:
            data = msg['payload']['body'].get('data', '')
            return base64.urlsafe_b64decode(data).decode('utf-8')
    except Exception:
        return ''


def scan_and_process():
    """Scan Gmail for replies to BDOMate.AI emails."""
    try:
        service = get_gmail_service()

        # Search for unread emails in inbox
        results = service.users().messages().list(
            userId='me',
            q='is:unread in:inbox',
            maxResults=20
        ).execute()

        messages = results.get('messages', [])

        if not messages:
            print(f"[{datetime.now().strftime('%H:%M:%S')}] No unread emails")
            return

        processed = 0

        for msg_ref in messages:
            msg = service.users().messages().get(
                userId='me',
                id=msg_ref['id'],
                format='full'
            ).execute()

            # Get headers
            headers = {h['name']: h['value'] for h in msg['payload']['headers']}
            sender  = headers.get('From', '')
            subject = headers.get('Subject', '')

            # Skip our own emails
            # Skip our own emails and automated senders
            if (MY_EMAIL in sender or
                "brevosend.com" in sender or
                "noreply" in sender.lower() or
                "no-reply" in sender.lower() or
                "donotreply" in sender.lower() or
                "mailer" in sender.lower()):
                
                # Mark as read so it doesn't get scanned again in the next loop
                try:
                    service.users().messages().batchModify(
                        userId='me',
                        body={'ids': [msg_meta['id']], 'removeLabelIds': ['UNREAD']}
                    ).execute()
                except Exception:
                    pass
                continue

            # Extract sender info
            email_match  = re.search(r'<([^>]+)>', sender)
            sender_email = email_match.group(1) if email_match else sender
            sender_name  = sender.split('<')[0].strip().strip('"')
            body         = get_message_body(msg)

            # Send to backend
            payload = {
                "sender_email": sender_email,
                "sender_name":  sender_name,
                "subject":      subject,
                "body":         body[:500]
            }

            try:
                response = requests.post(
                    BACKEND_URL,
                    json=payload,
                    timeout=10
                )
                if response.status_code in (200, 201):
                    # Mark as read
                    service.users().messages().modify(
                        userId='me',
                        id=msg_ref['id'],
                        body={'removeLabelIds': ['UNREAD']}
                    ).execute()
                    print(f"[{datetime.now().strftime('%H:%M:%S')}] ✅ Reply from {sender_email}: {subject}")
                    processed += 1
                else:
                    print(f"[{datetime.now().strftime('%H:%M:%S')}] ❌ Backend error {response.status_code}")
            except Exception as e:
                print(f"[{datetime.now().strftime('%H:%M:%S')}] ❌ Backend error: {e}")

        if processed == 0:
            print(f"[{datetime.now().strftime('%H:%M:%S')}] No BDO replies found")

    except Exception as e:
        print(f"[{datetime.now().strftime('%H:%M:%S')}] ❌ Error: {e}")


if __name__ == "__main__":
    print("🔍 BDOMate.AI Gmail Scanner started")
    print(f"📧 Monitoring replies to: {MY_EMAIL}")
    print(f"⏱  Checking every {CHECK_INTERVAL // 60} minutes")
    print("Press Ctrl+C to stop\n")

    while True:
        scan_and_process()
        time.sleep(CHECK_INTERVAL)