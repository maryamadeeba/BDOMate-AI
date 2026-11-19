"""
migrate_email_replies.py
────────────────────────────────────────────────────────────────────────────
Run ONCE to create the email_replies table in PostgreSQL.

Usage:
    python migrate_email_replies.py
"""

from database.db import engine, Base
from database.models_email_reply import EmailReply   # registers the ORM model

Base.metadata.create_all(bind=engine)
print("✅ email_replies table ready.")
