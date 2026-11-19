"""
migrate_notifications.py
Run once:  python migrate_notifications.py
"""
from database.db import engine, Base
from database.models_notifications import AppNotification   # registers ORM model
import sqlalchemy as sa

Base.metadata.create_all(bind=engine)

# Also ensure email_replies has all needed columns
COLS = [
    ("sender_name", "VARCHAR(255) DEFAULT ''"),
    ("is_read",     "BOOLEAN DEFAULT FALSE"),
]
with engine.connect() as conn:
    for col, defn in COLS:
        try:
            conn.execute(sa.text(
                f"ALTER TABLE email_replies ADD COLUMN IF NOT EXISTS {col} {defn};"
            ))
        except Exception:
            pass
    conn.commit()

print("✅ app_notifications table ready.")
print("✅ email_replies columns verified.")
