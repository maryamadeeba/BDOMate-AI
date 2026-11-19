"""
database/models_notifications.py
────────────────────────────────────────────────────────────────────────────
"""

from sqlalchemy import Column, Integer, String, Boolean, DateTime, Text
from sqlalchemy.sql import func
from database.db import Base


class AppNotification(Base):
    __tablename__ = "app_notifications"

    id           = Column(Integer, primary_key=True, index=True)
    title        = Column(String(255), nullable=False)
    body         = Column(Text,        default="")
    type         = Column(String(50),  default="general")   # email_reply | event | call | system
    reference_id = Column(String(100), default=None)        # links to reply id, event id, etc.
    is_read      = Column(Boolean,     default=False, nullable=False)
    created_at   = Column(DateTime(timezone=True), server_default=func.now())
