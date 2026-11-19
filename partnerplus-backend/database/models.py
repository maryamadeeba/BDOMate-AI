"""
BDOMate.AI — Database Models
"""
from sqlalchemy import (
    Column, Integer, String, Text, DateTime,
    ForeignKey, Boolean, Float
)
from sqlalchemy.sql import func
from database.db import Base
from datetime import datetime

class User(Base):
    __tablename__ = "users"
    id            = Column(Integer, primary_key=True, index=True)
    full_name     = Column(String,  nullable=False)
    email         = Column(String,  unique=True, nullable=False)
    password_hash = Column(String,  nullable=False)
    designation   = Column(String)
    role          = Column(String,  default="bdo")
    is_active     = Column(Boolean, default=True)
    created_at    = Column(DateTime, server_default=func.now())


class Partner(Base):
    __tablename__  = "partners"
    id             = Column(Integer, primary_key=True, index=True)
    name           = Column(String,  nullable=False)
    type           = Column(String)
    contact_person = Column(String)
    email          = Column(String)
    phone          = Column(String)
    address        = Column(Text)
    status         = Column(String,  default="active")
    created_at     = Column(DateTime, server_default=func.now())


class MOURequest(Base):
    __tablename__       = "mou_requests"
    id                  = Column(Integer, primary_key=True, index=True)
    partner_id          = Column(Integer, ForeignKey("partners.id"))
    mou_type            = Column(String)
    collaboration_focus = Column(Text)
    duration_years      = Column(Integer, default=2)
    special_notes       = Column(Text)
    status              = Column(String,  default="draft")
    created_at          = Column(DateTime, server_default=func.now())


class GeneratedMOU(Base):
    __tablename__ = "generated_mous"
    id            = Column(Integer, primary_key=True, index=True)
    request_id    = Column(Integer, ForeignKey("mou_requests.id"))
    mou_text      = Column(Text)
    version       = Column(Integer, default=1)
    created_at    = Column(DateTime, server_default=func.now())


class Event(Base):
    __tablename__ = "events"
    id            = Column(Integer, primary_key=True, index=True)
    title         = Column(String,  nullable=False)
    # ── ML fields ─────────────────────────────────────────────────────────────
    event_type            = Column(String)
    department            = Column(String)
    day_of_week           = Column(String)
    time_slot             = Column(String)
    season                = Column(String)
    capacity              = Column(Integer)
    is_free               = Column(Boolean, default=True)
    has_food              = Column(Boolean, default=False)
    industry_guests       = Column(Boolean, default=False)
    weeks_promoted        = Column(Integer, default=1)
    past_avg_attendance   = Column(Integer, default=60)
    predicted_attendance  = Column(String,  nullable=True)
    prediction_confidence = Column(Float,   nullable=True)
    actual_attendance     = Column(Integer, nullable=True)
    # ── ✅ Full event detail fields (added via migration) ─────────────────────
    description           = Column(Text,    default="")
    status                = Column(String,  default="upcoming")
    start_date            = Column(DateTime, nullable=True)
    end_date              = Column(DateTime, nullable=True)
    venue                 = Column(String,  default="TBD")
    expected_attendees    = Column(Integer, default=0)
    organizer             = Column(String,  default="BDO")
    is_virtual            = Column(Boolean, default=False)
    meeting_link          = Column(Text,    nullable=True)
    created_at            = Column(DateTime, server_default=func.now())


class FollowUp(Base):
    __tablename__  = "follow_ups"
    id             = Column(Integer, primary_key=True, index=True)
    mou_id         = Column(Integer, ForeignKey("generated_mous.id"))
    description    = Column(Text)
    follow_up_date = Column(DateTime)
    completed      = Column(Boolean, default=False)
    created_at     = Column(DateTime, server_default=func.now())


class Call(Base):
    __tablename__  = "calls"
    id             = Column(Integer,  primary_key=True, index=True)
    call_sid       = Column(String,   unique=True, index=True)
    contact_name   = Column(String)
    contact_phone  = Column(String)
    partner_id     = Column(Integer,  ForeignKey("partners.id"), nullable=True)
    call_purpose   = Column(String,   default="general")
    status         = Column(String,   default="initiated")
    duration_secs  = Column(Integer,  default=0)
    is_demo        = Column(Boolean,  default=True)
    created_at     = Column(DateTime, server_default=func.now())


class CallIVRResponse(Base):
    __tablename__  = "call_ivr_responses"
    id             = Column(Integer,  primary_key=True, index=True)
    call_id        = Column(Integer,  ForeignKey("calls.id"), nullable=True)
    call_sid       = Column(String,   index=True)
    digit_pressed  = Column(String)
    action_taken   = Column(String)
    call_purpose   = Column(String)
    response_text  = Column(Text)
    created_at     = Column(DateTime, server_default=func.now())


class CallTranscript(Base):
    __tablename__ = "call_transcripts"
    id            = Column(Integer,  primary_key=True, index=True)
    call_id       = Column(Integer,  ForeignKey("calls.id"), nullable=True)
    call_sid      = Column(String,   index=True)
    transcript    = Column(Text)
    summary       = Column(Text)
    created_at    = Column(DateTime, server_default=func.now())


class Notification(Base):
    __tablename__ = "notifications"
    id            = Column(Integer,  primary_key=True, index=True)
    title         = Column(String,   nullable=False)
    message       = Column(Text)
    notify_type   = Column(String)
    related_id    = Column(Integer,  nullable=True)
    is_read       = Column(Boolean,  default=False)
    scheduled_at  = Column(DateTime, nullable=True)
    fired_at      = Column(DateTime, nullable=True)
    created_at    = Column(DateTime, server_default=func.now())


class Email(Base):
    __tablename__   = "emails"
    id              = Column(Integer,  primary_key=True, index=True)
    recipient_name  = Column(String)
    recipient_org   = Column(String)
    recipient_email = Column(String)
    subject         = Column(String)
    body            = Column(Text)
    email_purpose   = Column(String)
    status          = Column(String,   default="draft")
    partner_id      = Column(Integer,  ForeignKey("partners.id"), nullable=True)
    is_ai_generated = Column(Boolean,  default=True)
    sent_at         = Column(DateTime, nullable=True)
    created_at      = Column(DateTime, server_default=func.now())


class Campaign(Base):
    __tablename__   = "campaigns"
    id              = Column(Integer,  primary_key=True, index=True)
    name            = Column(String,   nullable=False)
    campaign_type   = Column(String)
    event_name      = Column(String)
    event_type      = Column(String)
    event_date      = Column(String)
    target_audience = Column(String)
    content         = Column(Text)
    status          = Column(String,   default="draft")
    total_reach     = Column(Integer,  default=0)
    is_ai_generated = Column(Boolean,  default=True)
    created_at      = Column(DateTime, server_default=func.now())


class SponsorSegment(Base):
    __tablename__    = "sponsor_segments"
    id               = Column(Integer,  primary_key=True, index=True)
    partner_id       = Column(Integer,  ForeignKey("partners.id"), nullable=True)
    sponsor_name     = Column(String)
    sector           = Column(String)
    budget           = Column(Float)
    engagement_score = Column(Float)
    past_events      = Column(Integer,  default=0)
    tier             = Column(String)
    tier_score       = Column(Float,    nullable=True)
    created_at       = Column(DateTime, server_default=func.now())


class PasswordResetToken(Base):
    __tablename__ = "password_reset_tokens"
    __table_args__ = {'extend_existing': True}
    id         = Column(Integer,  primary_key=True, index=True)
    user_id    = Column(Integer,  ForeignKey("users.id"), nullable=False)
    token      = Column(String,   unique=True, index=True, nullable=False)
    expires_at = Column(DateTime, nullable=False)
    used       = Column(Boolean,  default=False)
    created_at = Column(DateTime, default=datetime.utcnow)

# ✅ EmailReply lives in database/models_email_reply.py — imported here so
# SQLAlchemy create_all() picks it up alongside the other models.
from database.models_email_reply import EmailReply  # noqa: F401
from database.models_notifications import AppNotification  # noqa: F401