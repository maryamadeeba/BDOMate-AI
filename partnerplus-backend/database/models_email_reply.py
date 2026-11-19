"""
database/models_email_reply.py
────────────────────────────────────────────────────────────────────────────
SQLAlchemy ORM model for the email_replies table.

"""

from sqlalchemy import Column, Integer, String, Text, Boolean, DateTime
from sqlalchemy.sql import func
from database.db import Base          # your existing declarative Base


class EmailReply(Base):
    __tablename__ = "email_replies"

    id           = Column(Integer, primary_key=True, index=True)
    sender_email = Column(String(255), nullable=False)
    sender_name  = Column(String(255), default="")
    subject      = Column(String(500), nullable=False)
    body         = Column(Text, nullable=False)
    is_read      = Column(Boolean, default=False, nullable=False)
    created_at   = Column(DateTime(timezone=True), server_default=func.now())

    def __repr__(self):
        return f"<EmailReply id={self.id} from={self.sender_email} read={self.is_read}>"

